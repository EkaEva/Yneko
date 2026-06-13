use std::{
    collections::HashMap,
    future::Future,
    sync::Arc,
    time::{Duration, Instant},
};

use tokio::sync::{Mutex, Notify};
use yneko_core::YnekoResult;

const MAX_CACHE_ENTRIES: usize = 256;

#[derive(Debug)]
pub(super) struct MetadataRequestCache {
    entries: Mutex<HashMap<String, CacheEntry>>,
    failures: Mutex<HashMap<String, FailureEntry>>,
    in_flight: Mutex<HashMap<String, Arc<Notify>>>,
}

#[derive(Debug, Clone)]
struct CacheEntry {
    body: String,
    expires_at: Instant,
}

#[derive(Debug, Clone)]
struct FailureEntry {
    message: String,
    expires_at: Instant,
}

impl MetadataRequestCache {
    pub(super) fn new() -> Self {
        Self {
            entries: Mutex::new(HashMap::new()),
            failures: Mutex::new(HashMap::new()),
            in_flight: Mutex::new(HashMap::new()),
        }
    }

    pub(super) async fn load_or_fetch<F, Fut>(
        &self,
        key: String,
        ttl: Duration,
        failure_backoff: Duration,
        fetch: F,
    ) -> YnekoResult<String>
    where
        F: FnOnce() -> Fut,
        Fut: Future<Output = YnekoResult<String>>,
    {
        let mut fetch = Some(fetch);

        loop {
            if let Some(body) = self.cached_body(&key).await {
                return Ok(body);
            }
            if let Some(message) = self.recent_failure(&key).await {
                return Err(yneko_core::YnekoError::MetadataUnavailable(format!(
                    "recent Bangumi request failed; backing off before retry: {message}"
                )));
            }

            let wait_for = {
                let mut in_flight = self.in_flight.lock().await;
                if let Some(notify) = in_flight.get(&key) {
                    Some(notify.clone())
                } else {
                    in_flight.insert(key.clone(), Arc::new(Notify::new()));
                    None
                }
            };

            if let Some(notify) = wait_for {
                notify.notified().await;
                continue;
            }

            let result = fetch
                .take()
                .expect("metadata cache fetch closure should only be consumed by owner")(
            )
            .await;

            if let Ok(body) = &result {
                self.store_body(key.clone(), body.clone(), ttl).await;
                self.clear_failure(&key).await;
            } else if let Err(error) = &result {
                self.store_failure(key.clone(), error.to_string(), failure_backoff)
                    .await;
            }

            self.finish_in_flight(&key).await;
            return result;
        }
    }

    async fn cached_body(&self, key: &str) -> Option<String> {
        let now = Instant::now();
        let mut entries = self.entries.lock().await;
        match entries.get(key) {
            Some(entry) if entry.expires_at > now => Some(entry.body.clone()),
            Some(_) => {
                entries.remove(key);
                None
            }
            None => None,
        }
    }

    async fn recent_failure(&self, key: &str) -> Option<String> {
        let now = Instant::now();
        let mut failures = self.failures.lock().await;
        match failures.get(key) {
            Some(entry) if entry.expires_at > now => Some(entry.message.clone()),
            Some(_) => {
                failures.remove(key);
                None
            }
            None => None,
        }
    }

    async fn store_body(&self, key: String, body: String, ttl: Duration) {
        let now = Instant::now();
        let mut entries = self.entries.lock().await;
        entries.retain(|_, entry| entry.expires_at > now);

        if !entries.contains_key(&key)
            && entries.len() >= MAX_CACHE_ENTRIES
            && let Some(oldest_key) = entries
                .iter()
                .min_by_key(|(_, entry)| entry.expires_at)
                .map(|(key, _)| key.clone())
        {
            entries.remove(&oldest_key);
        }

        entries.insert(
            key,
            CacheEntry {
                body,
                expires_at: now + ttl,
            },
        );
    }

    async fn store_failure(&self, key: String, message: String, backoff: Duration) {
        if backoff.is_zero() {
            return;
        }

        let now = Instant::now();
        let mut failures = self.failures.lock().await;
        failures.retain(|_, entry| entry.expires_at > now);

        if !failures.contains_key(&key)
            && failures.len() >= MAX_CACHE_ENTRIES
            && let Some(oldest_key) = failures
                .iter()
                .min_by_key(|(_, entry)| entry.expires_at)
                .map(|(key, _)| key.clone())
        {
            failures.remove(&oldest_key);
        }

        failures.insert(
            key,
            FailureEntry {
                message,
                expires_at: now + backoff,
            },
        );
    }

    async fn clear_failure(&self, key: &str) {
        self.failures.lock().await.remove(key);
    }

    async fn finish_in_flight(&self, key: &str) {
        let notify = self.in_flight.lock().await.remove(key);
        if let Some(notify) = notify {
            notify.notify_waiters();
        }
    }
}
