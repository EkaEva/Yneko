use std::{
    fs,
    path::{Path, PathBuf},
    time::{SystemTime, UNIX_EPOCH},
};

use sqlx::{Row, SqlitePool, sqlite::SqlitePoolOptions};
use yneko_core::{
    CollectionStatus, Episode, EpisodeSourceBinding, FavoriteItem, PlaybackProgress,
    RuleGroupSummary, RuleRepositorySubscription, SourcePackageRecord, SourcePackageSummary,
    SourcePackageText, SubjectSourceBinding, SubjectSummary, WatchHistoryItem, YnekoError,
    YnekoResult,
};

pub const INITIAL_SCHEMA: &str = r#"
CREATE TABLE IF NOT EXISTS playback_progress (
  subject_id INTEGER NOT NULL,
  episode_id INTEGER NOT NULL,
  position_ms INTEGER NOT NULL,
  duration_ms INTEGER,
  updated_at_ms INTEGER NOT NULL,
  subject_json TEXT,
  episode_json TEXT,
  PRIMARY KEY (subject_id, episode_id)
);

CREATE TABLE IF NOT EXISTS favorite_subjects (
  subject_id INTEGER NOT NULL PRIMARY KEY,
  subject_json TEXT NOT NULL,
  status TEXT NOT NULL,
  created_at_ms INTEGER NOT NULL,
  updated_at_ms INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS source_packages (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  version TEXT NOT NULL,
  enabled INTEGER NOT NULL,
  format TEXT NOT NULL DEFAULT 'yaml',
  source_url TEXT,
  diagnostics_json TEXT NOT NULL,
  imported_at_ms INTEGER NOT NULL,
  updated_at_ms INTEGER NOT NULL,
  raw_text TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS rule_groups (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  enabled INTEGER NOT NULL,
  rule_ids_json TEXT NOT NULL,
  disabled_rule_ids_json TEXT NOT NULL,
  updated_at_ms INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS rule_repository_subscriptions (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  url TEXT NOT NULL,
  enabled INTEGER NOT NULL,
  updated_at_ms INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS subject_source_bindings (
  subject_id INTEGER NOT NULL,
  rule_id TEXT NOT NULL,
  source_item_key TEXT NOT NULL,
  source_title TEXT NOT NULL,
  detail_url TEXT NOT NULL,
  updated_at_ms INTEGER NOT NULL,
  PRIMARY KEY (subject_id, rule_id)
);

CREATE TABLE IF NOT EXISTS episode_source_bindings (
  subject_id INTEGER NOT NULL,
  episode_id INTEGER NOT NULL,
  episode_order INTEGER NOT NULL,
  rule_id TEXT NOT NULL,
  source_episode_key TEXT NOT NULL,
  title TEXT NOT NULL,
  play_url TEXT NOT NULL,
  fallback_play_urls_json TEXT NOT NULL,
  referer_url TEXT,
  confidence TEXT NOT NULL,
  updated_at_ms INTEGER NOT NULL,
  PRIMARY KEY (subject_id, episode_id, rule_id)
);

CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT NOT NULL PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at_ms INTEGER NOT NULL
);
"#;

pub const DEFAULT_RULE_GROUP_ID: &str = "default";
pub const DEFAULT_RULE_REPOSITORY_SUBSCRIPTION_ID: &str = "kazumi-rules";
pub const DEFAULT_RULE_REPOSITORY_SUBSCRIPTION_NAME: &str = "KazumiRules";
pub const DEFAULT_RULE_REPOSITORY_SUBSCRIPTION_URL: &str =
    "https://github.com/Predidit/KazumiRules";
pub const APPEARANCE_THEME_MODE_KEY: &str = "appearance.theme_mode";
pub const APPEARANCE_COLOR_SCHEME_KEY: &str = "appearance.color_scheme";
pub const SEARCH_HISTORY_KEY: &str = "search.history";
pub const DEFAULT_APPEARANCE_THEME_MODE: &str = "light";
pub const DEFAULT_APPEARANCE_COLOR_SCHEME: &str = "yneko";
const SEARCH_HISTORY_LIMIT: usize = 12;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AppearanceSettings {
    pub theme_mode: String,
    pub color_scheme: String,
}

#[derive(Debug, Clone)]
pub struct StorageService {
    pool: SqlitePool,
}

impl StorageService {
    pub async fn open_default() -> YnekoResult<Self> {
        Self::open(default_database_path()?).await
    }

    pub async fn open(path: impl AsRef<Path>) -> YnekoResult<Self> {
        let path = path.as_ref();
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent).map_err(storage_error)?;
        }
        let url = format!(
            "sqlite://{}?mode=rwc",
            path.to_string_lossy().replace('\\', "/")
        );
        let pool = SqlitePoolOptions::new()
            .max_connections(1)
            .connect(&url)
            .await
            .map_err(storage_error)?;
        let service = Self { pool };
        service.initialize().await?;
        Ok(service)
    }

    pub async fn open_memory() -> YnekoResult<Self> {
        let pool = SqlitePoolOptions::new()
            .max_connections(1)
            .connect("sqlite::memory:")
            .await
            .map_err(storage_error)?;
        let service = Self { pool };
        service.initialize().await?;
        Ok(service)
    }

    pub async fn initialize(&self) -> YnekoResult<()> {
        for statement in INITIAL_SCHEMA.split(';') {
            let trimmed = statement.trim();
            if trimmed.is_empty() {
                continue;
            }
            sqlx::query(trimmed)
                .execute(&self.pool)
                .await
                .map_err(storage_error)?;
        }
        self.migrate_legacy_schema().await?;
        self.ensure_default_rule_repository_subscription().await?;
        Ok(())
    }

    pub async fn get_appearance_settings(&self) -> YnekoResult<AppearanceSettings> {
        let theme_mode = self
            .get_app_setting(APPEARANCE_THEME_MODE_KEY)
            .await?
            .filter(|value| is_valid_theme_mode(value))
            .unwrap_or_else(|| DEFAULT_APPEARANCE_THEME_MODE.to_string());
        let color_scheme = self
            .get_app_setting(APPEARANCE_COLOR_SCHEME_KEY)
            .await?
            .filter(|value| is_valid_color_scheme(value))
            .unwrap_or_else(|| DEFAULT_APPEARANCE_COLOR_SCHEME.to_string());
        Ok(AppearanceSettings {
            theme_mode,
            color_scheme,
        })
    }

    pub async fn save_appearance_settings(
        &self,
        settings: AppearanceSettings,
    ) -> YnekoResult<AppearanceSettings> {
        let normalized = AppearanceSettings {
            theme_mode: if is_valid_theme_mode(&settings.theme_mode) {
                settings.theme_mode
            } else {
                DEFAULT_APPEARANCE_THEME_MODE.to_string()
            },
            color_scheme: if is_valid_color_scheme(&settings.color_scheme) {
                settings.color_scheme
            } else {
                DEFAULT_APPEARANCE_COLOR_SCHEME.to_string()
            },
        };
        self.set_app_setting(APPEARANCE_THEME_MODE_KEY, &normalized.theme_mode)
            .await?;
        self.set_app_setting(APPEARANCE_COLOR_SCHEME_KEY, &normalized.color_scheme)
            .await?;
        Ok(normalized)
    }

    pub async fn list_search_history(&self) -> YnekoResult<Vec<String>> {
        let Some(raw) = self.get_app_setting(SEARCH_HISTORY_KEY).await? else {
            return Ok(Vec::new());
        };
        let history = serde_json::from_str::<Vec<String>>(&raw)
            .map(normalize_search_history)
            .unwrap_or_default();
        Ok(history)
    }

    pub async fn save_search_history(&self, history: Vec<String>) -> YnekoResult<Vec<String>> {
        let normalized = normalize_search_history(history);
        let raw = serde_json::to_string(&normalized).map_err(storage_error)?;
        self.set_app_setting(SEARCH_HISTORY_KEY, &raw).await?;
        Ok(normalized)
    }

    async fn get_app_setting(&self, key: &str) -> YnekoResult<Option<String>> {
        let row = sqlx::query("SELECT value FROM app_settings WHERE key = ?1")
            .bind(key)
            .fetch_optional(&self.pool)
            .await
            .map_err(storage_error)?;
        row.map(|row| row.try_get("value").map_err(storage_error))
            .transpose()
    }

    async fn set_app_setting(&self, key: &str, value: &str) -> YnekoResult<()> {
        sqlx::query(
            r#"
INSERT INTO app_settings (key, value, updated_at_ms)
VALUES (?1, ?2, ?3)
ON CONFLICT(key) DO UPDATE SET
  value = excluded.value,
  updated_at_ms = excluded.updated_at_ms
"#,
        )
        .bind(key)
        .bind(value)
        .bind(now_ms())
        .execute(&self.pool)
        .await
        .map_err(storage_error)?;
        Ok(())
    }

    async fn migrate_legacy_schema(&self) -> YnekoResult<()> {
        self.ensure_column(
            "source_packages",
            "format",
            "ALTER TABLE source_packages ADD COLUMN format TEXT NOT NULL DEFAULT 'yaml'",
        )
        .await?;
        self.ensure_column(
            "source_packages",
            "source_url",
            "ALTER TABLE source_packages ADD COLUMN source_url TEXT",
        )
        .await?;
        self.ensure_column(
            "source_packages",
            "diagnostics_json",
            "ALTER TABLE source_packages ADD COLUMN diagnostics_json TEXT NOT NULL DEFAULT '[]'",
        )
        .await?;
        self.ensure_column(
            "source_packages",
            "imported_at_ms",
            "ALTER TABLE source_packages ADD COLUMN imported_at_ms INTEGER NOT NULL DEFAULT 0",
        )
        .await?;
        self.ensure_column(
            "source_packages",
            "updated_at_ms",
            "ALTER TABLE source_packages ADD COLUMN updated_at_ms INTEGER NOT NULL DEFAULT 0",
        )
        .await?;
        self.ensure_column(
            "source_packages",
            "raw_text",
            "ALTER TABLE source_packages ADD COLUMN raw_text TEXT NOT NULL DEFAULT ''",
        )
        .await?;
        self.ensure_column(
            "playback_progress",
            "subject_json",
            "ALTER TABLE playback_progress ADD COLUMN subject_json TEXT",
        )
        .await?;
        self.ensure_column(
            "playback_progress",
            "episode_json",
            "ALTER TABLE playback_progress ADD COLUMN episode_json TEXT",
        )
        .await?;
        Ok(())
    }

    async fn ensure_column(&self, table: &str, column: &str, alter_sql: &str) -> YnekoResult<()> {
        let pragma = format!("PRAGMA table_info({table})");
        let rows = sqlx::query(&pragma)
            .fetch_all(&self.pool)
            .await
            .map_err(storage_error)?;
        let exists = rows.iter().any(|row| {
            row.try_get::<String, _>("name")
                .map(|name| name == column)
                .unwrap_or(false)
        });
        if !exists {
            sqlx::query(alter_sql)
                .execute(&self.pool)
                .await
                .map_err(storage_error)?;
        }
        Ok(())
    }

    async fn ensure_default_rule_repository_subscription(&self) -> YnekoResult<()> {
        let count: i64 = sqlx::query(
            "SELECT COUNT(*) AS count FROM rule_repository_subscriptions WHERE id = ?1",
        )
        .bind(DEFAULT_RULE_REPOSITORY_SUBSCRIPTION_ID)
        .fetch_one(&self.pool)
        .await
        .map_err(storage_error)?
        .try_get("count")
        .map_err(storage_error)?;
        if count > 0 {
            return Ok(());
        }
        sqlx::query(
            r#"
INSERT INTO rule_repository_subscriptions (
  id, name, url, enabled, updated_at_ms
) VALUES (?1, ?2, ?3, 1, ?4)
"#,
        )
        .bind(DEFAULT_RULE_REPOSITORY_SUBSCRIPTION_ID)
        .bind(DEFAULT_RULE_REPOSITORY_SUBSCRIPTION_NAME)
        .bind(DEFAULT_RULE_REPOSITORY_SUBSCRIPTION_URL)
        .bind(now_ms())
        .execute(&self.pool)
        .await
        .map_err(storage_error)?;
        Ok(())
    }

    pub async fn upsert_source_package(
        &self,
        package: SourcePackageRecord,
    ) -> YnekoResult<SourcePackageSummary> {
        let diagnostics_json =
            serde_json::to_string(&package.diagnostics).map_err(storage_error)?;
        sqlx::query(
            r#"
INSERT INTO source_packages (
  id, name, version, enabled, format, source_url, diagnostics_json,
  imported_at_ms, updated_at_ms, raw_text
) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10)
ON CONFLICT(id) DO UPDATE SET
  name = excluded.name,
  version = excluded.version,
  format = excluded.format,
  source_url = excluded.source_url,
  diagnostics_json = excluded.diagnostics_json,
  updated_at_ms = excluded.updated_at_ms,
  raw_text = excluded.raw_text
"#,
        )
        .bind(&package.id)
        .bind(&package.name)
        .bind(&package.version)
        .bind(i64::from(package.enabled))
        .bind(&package.format)
        .bind(&package.source_url)
        .bind(diagnostics_json)
        .bind(package.imported_at_ms)
        .bind(package.updated_at_ms)
        .bind(&package.raw_text)
        .execute(&self.pool)
        .await
        .map_err(storage_error)?;
        Ok(SourcePackageSummary::from(&package))
    }

    pub async fn list_source_packages(&self) -> YnekoResult<Vec<SourcePackageSummary>> {
        let rows = sqlx::query(
            r#"
SELECT id, name, version, enabled, source_url, diagnostics_json,
       format, imported_at_ms, updated_at_ms
FROM source_packages
ORDER BY updated_at_ms DESC, name ASC
"#,
        )
        .fetch_all(&self.pool)
        .await
        .map_err(storage_error)?;
        rows.into_iter().map(summary_from_row).collect()
    }

    pub async fn list_enabled_source_package_records(
        &self,
    ) -> YnekoResult<Vec<SourcePackageRecord>> {
        let rows = sqlx::query(
            r#"
SELECT id, name, version, enabled, source_url, diagnostics_json,
       format, imported_at_ms, updated_at_ms, raw_text
FROM source_packages
WHERE enabled = 1
ORDER BY updated_at_ms DESC, name ASC
"#,
        )
        .fetch_all(&self.pool)
        .await
        .map_err(storage_error)?;
        rows.into_iter().map(record_from_row).collect()
    }

    pub async fn set_source_package_enabled(&self, id: &str, enabled: bool) -> YnekoResult<()> {
        let result = sqlx::query(
            r#"
UPDATE source_packages
SET enabled = ?2, updated_at_ms = ?3
WHERE id = ?1
"#,
        )
        .bind(id)
        .bind(i64::from(enabled))
        .bind(now_ms())
        .execute(&self.pool)
        .await
        .map_err(storage_error)?;
        if result.rows_affected() == 0 {
            return Err(YnekoError::InvalidInput(format!(
                "source package `{id}` does not exist"
            )));
        }
        Ok(())
    }

    pub async fn delete_source_package(&self, id: &str) -> YnekoResult<()> {
        sqlx::query("DELETE FROM source_packages WHERE id = ?1")
            .bind(id)
            .execute(&self.pool)
            .await
            .map_err(storage_error)?;
        self.remove_rule_id_from_groups(id).await?;
        sqlx::query("DELETE FROM subject_source_bindings WHERE rule_id = ?1")
            .bind(id)
            .execute(&self.pool)
            .await
            .map_err(storage_error)?;
        sqlx::query("DELETE FROM episode_source_bindings WHERE rule_id = ?1")
            .bind(id)
            .execute(&self.pool)
            .await
            .map_err(storage_error)?;
        Ok(())
    }

    pub async fn get_source_package_text(
        &self,
        id: &str,
    ) -> YnekoResult<Option<SourcePackageText>> {
        let row = sqlx::query(
            r#"
SELECT id, name, format, raw_text
FROM source_packages
WHERE id = ?1
"#,
        )
        .bind(id)
        .fetch_optional(&self.pool)
        .await
        .map_err(storage_error)?;
        row.map(|row| {
            Ok(SourcePackageText {
                id: row.try_get("id").map_err(storage_error)?,
                name: row.try_get("name").map_err(storage_error)?,
                format: row.try_get("format").map_err(storage_error)?,
                body: row.try_get("raw_text").map_err(storage_error)?,
            })
        })
        .transpose()
    }

    pub async fn list_source_package_records(&self) -> YnekoResult<Vec<SourcePackageRecord>> {
        let rows = sqlx::query(
            r#"
SELECT id, name, version, enabled, source_url, diagnostics_json,
       format, imported_at_ms, updated_at_ms, raw_text
FROM source_packages
ORDER BY updated_at_ms DESC, name ASC
"#,
        )
        .fetch_all(&self.pool)
        .await
        .map_err(storage_error)?;
        rows.into_iter().map(record_from_row).collect()
    }

    pub async fn list_rule_groups(&self) -> YnekoResult<Vec<RuleGroupSummary>> {
        self.ensure_default_rule_group().await?;
        let rows = sqlx::query(
            r#"
SELECT id, name, enabled, rule_ids_json, disabled_rule_ids_json
FROM rule_groups
ORDER BY CASE WHEN id = ?1 THEN 0 ELSE 1 END, updated_at_ms DESC, name ASC
"#,
        )
        .bind(DEFAULT_RULE_GROUP_ID)
        .fetch_all(&self.pool)
        .await
        .map_err(storage_error)?;
        rows.into_iter().map(rule_group_from_row).collect()
    }

    pub async fn upsert_rule_group(
        &self,
        group: RuleGroupSummary,
    ) -> YnekoResult<RuleGroupSummary> {
        validate_id(&group.id)?;
        let rule_ids_json = serde_json::to_string(&unique_strings(group.rule_ids.clone()))
            .map_err(storage_error)?;
        let disabled_rule_ids_json =
            serde_json::to_string(&unique_strings(group.disabled_rule_ids.clone()))
                .map_err(storage_error)?;
        let now = now_ms();
        sqlx::query(
            r#"
INSERT INTO rule_groups (
  id, name, enabled, rule_ids_json, disabled_rule_ids_json, updated_at_ms
) VALUES (?1, ?2, ?3, ?4, ?5, ?6)
ON CONFLICT(id) DO UPDATE SET
  name = excluded.name,
  enabled = excluded.enabled,
  rule_ids_json = excluded.rule_ids_json,
  disabled_rule_ids_json = excluded.disabled_rule_ids_json,
  updated_at_ms = excluded.updated_at_ms
"#,
        )
        .bind(&group.id)
        .bind(group.name.trim())
        .bind(i64::from(group.enabled))
        .bind(rule_ids_json)
        .bind(disabled_rule_ids_json)
        .bind(now)
        .execute(&self.pool)
        .await
        .map_err(storage_error)?;
        Ok(RuleGroupSummary {
            id: group.id,
            name: group.name,
            enabled: group.enabled,
            rule_ids: unique_strings(group.rule_ids),
            disabled_rule_ids: unique_strings(group.disabled_rule_ids),
        })
    }

    pub async fn delete_rule_group(&self, id: &str) -> YnekoResult<()> {
        if id == DEFAULT_RULE_GROUP_ID {
            return Err(YnekoError::InvalidInput(
                "default rule group cannot be deleted".to_string(),
            ));
        }
        sqlx::query("DELETE FROM rule_groups WHERE id = ?1")
            .bind(id)
            .execute(&self.pool)
            .await
            .map_err(storage_error)?;
        Ok(())
    }

    pub async fn add_rule_to_group(&self, group_id: &str, rule_id: &str) -> YnekoResult<()> {
        let mut groups = self.list_rule_groups().await?;
        let index = groups
            .iter()
            .position(|group| group.id == group_id)
            .unwrap_or(0);
        let mut group = groups.remove(index);
        group.rule_ids = unique_strings([group.rule_ids, vec![rule_id.to_string()]].concat());
        group.disabled_rule_ids.retain(|id| id != rule_id);
        self.upsert_rule_group(group).await?;
        Ok(())
    }

    async fn ensure_default_rule_group(&self) -> YnekoResult<()> {
        let count: i64 = sqlx::query("SELECT COUNT(*) AS count FROM rule_groups WHERE id = ?1")
            .bind(DEFAULT_RULE_GROUP_ID)
            .fetch_one(&self.pool)
            .await
            .map_err(storage_error)?
            .try_get("count")
            .map_err(storage_error)?;
        if count > 0 {
            return Ok(());
        }
        let packages = self.list_source_packages().await?;
        self.upsert_rule_group(RuleGroupSummary {
            id: DEFAULT_RULE_GROUP_ID.to_string(),
            name: "默认规则组".to_string(),
            enabled: true,
            rule_ids: packages.into_iter().map(|package| package.id).collect(),
            disabled_rule_ids: Vec::new(),
        })
        .await?;
        Ok(())
    }

    async fn remove_rule_id_from_groups(&self, rule_id: &str) -> YnekoResult<()> {
        let groups = self.list_rule_groups().await?;
        for mut group in groups {
            let before = (group.rule_ids.len(), group.disabled_rule_ids.len());
            group.rule_ids.retain(|id| id != rule_id);
            group.disabled_rule_ids.retain(|id| id != rule_id);
            if before != (group.rule_ids.len(), group.disabled_rule_ids.len()) {
                self.upsert_rule_group(group).await?;
            }
        }
        Ok(())
    }

    pub async fn list_rule_repository_subscriptions(
        &self,
    ) -> YnekoResult<Vec<RuleRepositorySubscription>> {
        let rows = sqlx::query(
            r#"
SELECT id, name, url, enabled, updated_at_ms
FROM rule_repository_subscriptions
ORDER BY updated_at_ms DESC, name ASC
"#,
        )
        .fetch_all(&self.pool)
        .await
        .map_err(storage_error)?;
        rows.into_iter()
            .map(repository_subscription_from_row)
            .collect()
    }

    pub async fn upsert_rule_repository_subscription(
        &self,
        subscription: RuleRepositorySubscription,
    ) -> YnekoResult<RuleRepositorySubscription> {
        validate_id(&subscription.id)?;
        let now = now_ms();
        sqlx::query(
            r#"
INSERT INTO rule_repository_subscriptions (
  id, name, url, enabled, updated_at_ms
) VALUES (?1, ?2, ?3, ?4, ?5)
ON CONFLICT(id) DO UPDATE SET
  name = excluded.name,
  url = excluded.url,
  enabled = excluded.enabled,
  updated_at_ms = excluded.updated_at_ms
"#,
        )
        .bind(&subscription.id)
        .bind(subscription.name.trim())
        .bind(subscription.url.trim())
        .bind(i64::from(subscription.enabled))
        .bind(now)
        .execute(&self.pool)
        .await
        .map_err(storage_error)?;
        Ok(RuleRepositorySubscription {
            updated_at_ms: now,
            ..subscription
        })
    }

    pub async fn delete_rule_repository_subscription(&self, id: &str) -> YnekoResult<()> {
        sqlx::query("DELETE FROM rule_repository_subscriptions WHERE id = ?1")
            .bind(id)
            .execute(&self.pool)
            .await
            .map_err(storage_error)?;
        Ok(())
    }

    pub async fn save_subject_source_binding(
        &self,
        binding: SubjectSourceBinding,
    ) -> YnekoResult<()> {
        sqlx::query(
            r#"
INSERT INTO subject_source_bindings (
  subject_id, rule_id, source_item_key, source_title, detail_url, updated_at_ms
) VALUES (?1, ?2, ?3, ?4, ?5, ?6)
ON CONFLICT(subject_id, rule_id) DO UPDATE SET
  source_item_key = excluded.source_item_key,
  source_title = excluded.source_title,
  detail_url = excluded.detail_url,
  updated_at_ms = excluded.updated_at_ms
"#,
        )
        .bind(binding.subject_id)
        .bind(&binding.rule_id)
        .bind(&binding.source_item_key)
        .bind(&binding.source_title)
        .bind(&binding.detail_url)
        .bind(now_ms())
        .execute(&self.pool)
        .await
        .map_err(storage_error)?;
        Ok(())
    }

    pub async fn get_subject_source_binding(
        &self,
        subject_id: i64,
        rule_id: &str,
    ) -> YnekoResult<Option<SubjectSourceBinding>> {
        sqlx::query(
            r#"
SELECT subject_id, rule_id, source_item_key, source_title, detail_url
FROM subject_source_bindings
WHERE subject_id = ?1 AND rule_id = ?2
"#,
        )
        .bind(subject_id)
        .bind(rule_id)
        .fetch_optional(&self.pool)
        .await
        .map_err(storage_error)?
        .map(subject_binding_from_row)
        .transpose()
    }

    pub async fn save_episode_source_bindings(
        &self,
        bindings: Vec<EpisodeSourceBinding>,
    ) -> YnekoResult<()> {
        for binding in bindings {
            let fallback_json =
                serde_json::to_string(&binding.fallback_play_urls).map_err(storage_error)?;
            sqlx::query(
                r#"
INSERT INTO episode_source_bindings (
  subject_id, episode_id, episode_order, rule_id, source_episode_key, title,
  play_url, fallback_play_urls_json, referer_url, confidence, updated_at_ms
) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11)
ON CONFLICT(subject_id, episode_id, rule_id) DO UPDATE SET
  episode_order = excluded.episode_order,
  source_episode_key = excluded.source_episode_key,
  title = excluded.title,
  play_url = excluded.play_url,
  fallback_play_urls_json = excluded.fallback_play_urls_json,
  referer_url = excluded.referer_url,
  confidence = excluded.confidence,
  updated_at_ms = excluded.updated_at_ms
"#,
            )
            .bind(binding.subject_id)
            .bind(binding.episode_id)
            .bind(binding.episode_order)
            .bind(&binding.rule_id)
            .bind(&binding.source_episode_key)
            .bind(&binding.title)
            .bind(&binding.play_url)
            .bind(fallback_json)
            .bind(&binding.referer_url)
            .bind(&binding.confidence)
            .bind(now_ms())
            .execute(&self.pool)
            .await
            .map_err(storage_error)?;
        }
        Ok(())
    }

    pub async fn list_episode_source_bindings(
        &self,
        subject_id: i64,
        rule_id: &str,
    ) -> YnekoResult<Vec<EpisodeSourceBinding>> {
        let rows = sqlx::query(
            r#"
SELECT subject_id, episode_id, episode_order, rule_id, source_episode_key, title,
       play_url, fallback_play_urls_json, referer_url, confidence
FROM episode_source_bindings
WHERE subject_id = ?1 AND rule_id = ?2
ORDER BY episode_order ASC
"#,
        )
        .bind(subject_id)
        .bind(rule_id)
        .fetch_all(&self.pool)
        .await
        .map_err(storage_error)?;
        rows.into_iter().map(episode_binding_from_row).collect()
    }

    pub async fn list_favorites(
        &self,
        status: Option<CollectionStatus>,
    ) -> YnekoResult<Vec<FavoriteItem>> {
        let mut query = String::from(
            r#"
SELECT subject_json, status, updated_at_ms
FROM favorite_subjects
"#,
        );
        if status.is_some() {
            query.push_str("WHERE status = ?1\n");
        }
        query.push_str("ORDER BY updated_at_ms DESC");
        let mut query = sqlx::query(&query);
        if let Some(status) = status {
            query = query.bind(collection_status_to_str(status));
        }
        let rows = query.fetch_all(&self.pool).await.map_err(storage_error)?;
        rows.into_iter().map(favorite_from_row).collect()
    }

    pub async fn is_favorite(&self, subject_id: i64) -> YnekoResult<bool> {
        let count: i64 =
            sqlx::query("SELECT COUNT(*) AS count FROM favorite_subjects WHERE subject_id = ?1")
                .bind(subject_id)
                .fetch_one(&self.pool)
                .await
                .map_err(storage_error)?
                .try_get("count")
                .map_err(storage_error)?;
        Ok(count > 0)
    }

    pub async fn save_favorite(
        &self,
        subject: SubjectSummary,
        status: CollectionStatus,
    ) -> YnekoResult<FavoriteItem> {
        if subject.id <= 0 {
            return Err(YnekoError::InvalidInput(
                "subject_id must be positive".to_string(),
            ));
        }
        let now = now_ms();
        let subject_json = serde_json::to_string(&subject).map_err(storage_error)?;
        sqlx::query(
            r#"
INSERT INTO favorite_subjects (
  subject_id, subject_json, status, created_at_ms, updated_at_ms
) VALUES (?1, ?2, ?3, ?4, ?4)
ON CONFLICT(subject_id) DO UPDATE SET
  subject_json = excluded.subject_json,
  status = excluded.status,
  updated_at_ms = excluded.updated_at_ms
"#,
        )
        .bind(subject.id)
        .bind(subject_json)
        .bind(collection_status_to_str(status))
        .bind(now)
        .execute(&self.pool)
        .await
        .map_err(storage_error)?;
        Ok(FavoriteItem {
            subject,
            status,
            updated_at_ms: now,
        })
    }

    pub async fn delete_favorite(&self, subject_id: i64) -> YnekoResult<()> {
        sqlx::query("DELETE FROM favorite_subjects WHERE subject_id = ?1")
            .bind(subject_id)
            .execute(&self.pool)
            .await
            .map_err(storage_error)?;
        Ok(())
    }

    pub async fn save_playback_progress(&self, progress: PlaybackProgress) -> YnekoResult<()> {
        self.save_playback_progress_with_snapshots(progress, None, None)
            .await
    }

    pub async fn save_playback_progress_with_snapshots(
        &self,
        progress: PlaybackProgress,
        subject: Option<SubjectSummary>,
        episode: Option<Episode>,
    ) -> YnekoResult<()> {
        if progress.subject_id <= 0 || progress.episode_id <= 0 {
            return Err(YnekoError::InvalidInput(
                "subject_id and episode_id must be positive".to_string(),
            ));
        }
        if let Some(subject) = &subject
            && subject.id != progress.subject_id
        {
            return Err(YnekoError::InvalidInput(
                "subject snapshot must match progress subject_id".to_string(),
            ));
        }
        if let Some(episode) = &episode
            && (episode.id != progress.episode_id || episode.subject_id != progress.subject_id)
        {
            return Err(YnekoError::InvalidInput(
                "episode snapshot must match progress ids".to_string(),
            ));
        }
        let subject_json = subject
            .as_ref()
            .map(serde_json::to_string)
            .transpose()
            .map_err(storage_error)?;
        let episode_json = episode
            .as_ref()
            .map(serde_json::to_string)
            .transpose()
            .map_err(storage_error)?;
        sqlx::query(
            r#"
INSERT INTO playback_progress (
  subject_id, episode_id, position_ms, duration_ms, updated_at_ms,
  subject_json, episode_json
) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)
ON CONFLICT(subject_id, episode_id) DO UPDATE SET
  position_ms = excluded.position_ms,
  duration_ms = excluded.duration_ms,
  updated_at_ms = excluded.updated_at_ms,
  subject_json = COALESCE(excluded.subject_json, playback_progress.subject_json),
  episode_json = COALESCE(excluded.episode_json, playback_progress.episode_json)
"#,
        )
        .bind(progress.subject_id)
        .bind(progress.episode_id)
        .bind(progress.position_ms)
        .bind(progress.duration_ms)
        .bind(progress.updated_at_ms)
        .bind(subject_json)
        .bind(episode_json)
        .execute(&self.pool)
        .await
        .map_err(storage_error)?;
        Ok(())
    }

    pub async fn get_playback_progress(
        &self,
        subject_id: i64,
        episode_id: i64,
    ) -> YnekoResult<Option<PlaybackProgress>> {
        sqlx::query(
            r#"
SELECT subject_id, episode_id, position_ms, duration_ms, updated_at_ms
FROM playback_progress
WHERE subject_id = ?1 AND episode_id = ?2
"#,
        )
        .bind(subject_id)
        .bind(episode_id)
        .fetch_optional(&self.pool)
        .await
        .map_err(storage_error)?
        .map(progress_from_row)
        .transpose()
    }

    pub async fn latest_playback_progress_for_subject(
        &self,
        subject_id: i64,
    ) -> YnekoResult<Option<PlaybackProgress>> {
        sqlx::query(
            r#"
SELECT subject_id, episode_id, position_ms, duration_ms, updated_at_ms
FROM playback_progress
WHERE subject_id = ?1
ORDER BY updated_at_ms DESC
LIMIT 1
"#,
        )
        .bind(subject_id)
        .fetch_optional(&self.pool)
        .await
        .map_err(storage_error)?
        .map(progress_from_row)
        .transpose()
    }

    pub async fn list_watch_history(
        &self,
        limit: Option<u32>,
    ) -> YnekoResult<Vec<WatchHistoryItem>> {
        let limit = limit.unwrap_or(100).clamp(1, 500);
        let rows = sqlx::query(
            r#"
SELECT subject_json, episode_json, subject_id, episode_id, position_ms,
       duration_ms, updated_at_ms
FROM playback_progress
WHERE subject_json IS NOT NULL AND episode_json IS NOT NULL
ORDER BY updated_at_ms DESC
LIMIT ?1
"#,
        )
        .bind(i64::from(limit))
        .fetch_all(&self.pool)
        .await
        .map_err(storage_error)?;
        rows.into_iter().map(history_item_from_row).collect()
    }

    pub async fn delete_watch_history_item(
        &self,
        subject_id: i64,
        episode_id: i64,
    ) -> YnekoResult<()> {
        sqlx::query("DELETE FROM playback_progress WHERE subject_id = ?1 AND episode_id = ?2")
            .bind(subject_id)
            .bind(episode_id)
            .execute(&self.pool)
            .await
            .map_err(storage_error)?;
        Ok(())
    }

    pub async fn clear_watch_history(&self) -> YnekoResult<()> {
        sqlx::query("DELETE FROM playback_progress")
            .execute(&self.pool)
            .await
            .map_err(storage_error)?;
        Ok(())
    }
}

pub fn now_ms() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_millis().min(i64::MAX as u128) as i64)
        .unwrap_or_default()
}

fn default_database_path() -> YnekoResult<PathBuf> {
    let base = std::env::var_os("LOCALAPPDATA")
        .map(PathBuf::from)
        .or_else(|| std::env::var_os("APPDATA").map(PathBuf::from))
        .unwrap_or_else(|| PathBuf::from(".yneko"));
    Ok(base.join("Yneko").join("yneko.sqlite"))
}

fn summary_from_row(row: sqlx::sqlite::SqliteRow) -> YnekoResult<SourcePackageSummary> {
    Ok(SourcePackageSummary {
        id: row.try_get("id").map_err(storage_error)?,
        name: row.try_get("name").map_err(storage_error)?,
        version: row.try_get("version").map_err(storage_error)?,
        enabled: row.try_get::<i64, _>("enabled").map_err(storage_error)? != 0,
        format: row.try_get("format").map_err(storage_error)?,
        source_url: row.try_get("source_url").map_err(storage_error)?,
        diagnostics: diagnostics_from_json(
            &row.try_get::<String, _>("diagnostics_json")
                .map_err(storage_error)?,
        )?,
        imported_at_ms: row.try_get("imported_at_ms").map_err(storage_error)?,
        updated_at_ms: row.try_get("updated_at_ms").map_err(storage_error)?,
    })
}

fn record_from_row(row: sqlx::sqlite::SqliteRow) -> YnekoResult<SourcePackageRecord> {
    Ok(SourcePackageRecord {
        id: row.try_get("id").map_err(storage_error)?,
        name: row.try_get("name").map_err(storage_error)?,
        version: row.try_get("version").map_err(storage_error)?,
        enabled: row.try_get::<i64, _>("enabled").map_err(storage_error)? != 0,
        format: row.try_get("format").map_err(storage_error)?,
        source_url: row.try_get("source_url").map_err(storage_error)?,
        diagnostics: diagnostics_from_json(
            &row.try_get::<String, _>("diagnostics_json")
                .map_err(storage_error)?,
        )?,
        imported_at_ms: row.try_get("imported_at_ms").map_err(storage_error)?,
        updated_at_ms: row.try_get("updated_at_ms").map_err(storage_error)?,
        raw_text: row.try_get("raw_text").map_err(storage_error)?,
    })
}

fn diagnostics_from_json(value: &str) -> YnekoResult<Vec<String>> {
    serde_json::from_str(value).map_err(storage_error)
}

fn strings_from_json(value: &str) -> YnekoResult<Vec<String>> {
    serde_json::from_str(value).map_err(storage_error)
}

fn rule_group_from_row(row: sqlx::sqlite::SqliteRow) -> YnekoResult<RuleGroupSummary> {
    Ok(RuleGroupSummary {
        id: row.try_get("id").map_err(storage_error)?,
        name: row.try_get("name").map_err(storage_error)?,
        enabled: row.try_get::<i64, _>("enabled").map_err(storage_error)? != 0,
        rule_ids: strings_from_json(
            &row.try_get::<String, _>("rule_ids_json")
                .map_err(storage_error)?,
        )?,
        disabled_rule_ids: strings_from_json(
            &row.try_get::<String, _>("disabled_rule_ids_json")
                .map_err(storage_error)?,
        )?,
    })
}

fn repository_subscription_from_row(
    row: sqlx::sqlite::SqliteRow,
) -> YnekoResult<RuleRepositorySubscription> {
    Ok(RuleRepositorySubscription {
        id: row.try_get("id").map_err(storage_error)?,
        name: row.try_get("name").map_err(storage_error)?,
        url: row.try_get("url").map_err(storage_error)?,
        enabled: row.try_get::<i64, _>("enabled").map_err(storage_error)? != 0,
        updated_at_ms: row.try_get("updated_at_ms").map_err(storage_error)?,
    })
}

fn favorite_from_row(row: sqlx::sqlite::SqliteRow) -> YnekoResult<FavoriteItem> {
    let subject_json: String = row.try_get("subject_json").map_err(storage_error)?;
    let status: String = row.try_get("status").map_err(storage_error)?;
    Ok(FavoriteItem {
        subject: serde_json::from_str(&subject_json).map_err(storage_error)?,
        status: collection_status_from_str(&status)?,
        updated_at_ms: row.try_get("updated_at_ms").map_err(storage_error)?,
    })
}

fn subject_binding_from_row(row: sqlx::sqlite::SqliteRow) -> YnekoResult<SubjectSourceBinding> {
    Ok(SubjectSourceBinding {
        subject_id: row.try_get("subject_id").map_err(storage_error)?,
        rule_id: row.try_get("rule_id").map_err(storage_error)?,
        source_item_key: row.try_get("source_item_key").map_err(storage_error)?,
        source_title: row.try_get("source_title").map_err(storage_error)?,
        detail_url: row.try_get("detail_url").map_err(storage_error)?,
    })
}

fn episode_binding_from_row(row: sqlx::sqlite::SqliteRow) -> YnekoResult<EpisodeSourceBinding> {
    Ok(EpisodeSourceBinding {
        subject_id: row.try_get("subject_id").map_err(storage_error)?,
        episode_id: row.try_get("episode_id").map_err(storage_error)?,
        episode_order: row.try_get("episode_order").map_err(storage_error)?,
        rule_id: row.try_get("rule_id").map_err(storage_error)?,
        source_episode_key: row.try_get("source_episode_key").map_err(storage_error)?,
        title: row.try_get("title").map_err(storage_error)?,
        play_url: row.try_get("play_url").map_err(storage_error)?,
        fallback_play_urls: strings_from_json(
            &row.try_get::<String, _>("fallback_play_urls_json")
                .map_err(storage_error)?,
        )?,
        referer_url: row.try_get("referer_url").map_err(storage_error)?,
        confidence: row.try_get("confidence").map_err(storage_error)?,
    })
}

fn progress_from_row(row: sqlx::sqlite::SqliteRow) -> YnekoResult<PlaybackProgress> {
    Ok(PlaybackProgress {
        subject_id: row.try_get("subject_id").map_err(storage_error)?,
        episode_id: row.try_get("episode_id").map_err(storage_error)?,
        position_ms: row.try_get("position_ms").map_err(storage_error)?,
        duration_ms: row.try_get("duration_ms").map_err(storage_error)?,
        updated_at_ms: row.try_get("updated_at_ms").map_err(storage_error)?,
    })
}

fn history_item_from_row(row: sqlx::sqlite::SqliteRow) -> YnekoResult<WatchHistoryItem> {
    let subject_json: String = row.try_get("subject_json").map_err(storage_error)?;
    let episode_json: String = row.try_get("episode_json").map_err(storage_error)?;
    Ok(WatchHistoryItem {
        subject: serde_json::from_str(&subject_json).map_err(storage_error)?,
        episode: serde_json::from_str(&episode_json).map_err(storage_error)?,
        progress: progress_from_row(row)?,
    })
}

fn collection_status_to_str(status: CollectionStatus) -> &'static str {
    match status {
        CollectionStatus::Wish => "wish",
        CollectionStatus::Watching => "watching",
        CollectionStatus::Watched => "watched",
        CollectionStatus::Paused => "paused",
        CollectionStatus::Dropped => "dropped",
    }
}

fn collection_status_from_str(value: &str) -> YnekoResult<CollectionStatus> {
    match value {
        "wish" => Ok(CollectionStatus::Wish),
        "watching" => Ok(CollectionStatus::Watching),
        "watched" => Ok(CollectionStatus::Watched),
        "paused" => Ok(CollectionStatus::Paused),
        "dropped" => Ok(CollectionStatus::Dropped),
        other => Err(YnekoError::Storage(format!(
            "invalid collection status `{other}`"
        ))),
    }
}

fn validate_id(id: &str) -> YnekoResult<()> {
    if id.trim().is_empty() {
        return Err(YnekoError::InvalidInput("id must not be empty".to_string()));
    }
    Ok(())
}

fn unique_strings(values: Vec<String>) -> Vec<String> {
    let mut unique = Vec::new();
    for value in values {
        if !value.trim().is_empty() && !unique.contains(&value) {
            unique.push(value);
        }
    }
    unique
}

fn storage_error(error: impl ToString) -> YnekoError {
    YnekoError::Storage(error.to_string())
}

fn is_valid_theme_mode(value: &str) -> bool {
    matches!(value, "light" | "dark")
}

fn is_valid_color_scheme(value: &str) -> bool {
    matches!(
        value,
        "yneko"
            | "blue"
            | "gray"
            | "mint"
            | "spruce"
            | "lavender"
            | "apricot"
            | "coral"
            | "amber"
            | "cyan"
            | "rose"
            | "peach"
            | "lilac"
            | "sage"
            | "indigo"
            | "cocoa"
    )
}

fn normalize_search_history(history: Vec<String>) -> Vec<String> {
    let mut seen = std::collections::HashSet::new();
    let mut normalized = Vec::new();
    for item in history {
        let clean = item.trim().to_owned();
        if clean.is_empty() || !seen.insert(clean.clone()) {
            continue;
        }
        normalized.push(clean);
        if normalized.len() >= SEARCH_HISTORY_LIMIT {
            break;
        }
    }
    normalized
}

#[cfg(test)]
mod tests {
    use super::*;

    fn package(id: &str) -> SourcePackageRecord {
        SourcePackageRecord {
            id: id.to_string(),
            name: "Demo".to_string(),
            version: "1.0.0".to_string(),
            enabled: true,
            format: "yaml".to_string(),
            source_url: None,
            diagnostics: vec!["ok".to_string()],
            imported_at_ms: 1,
            updated_at_ms: 2,
            raw_text: "id: demo".to_string(),
        }
    }

    fn subject(id: i64) -> SubjectSummary {
        SubjectSummary {
            id,
            name: "Sousou no Frieren".to_string(),
            name_cn: Some("葬送的芙莉莲".to_string()),
            aliases: vec!["Frieren".to_string()],
            cover_url: Some("https://example.test/frieren.jpg".to_string()),
            summary: Some("旅途之后的故事。".to_string()),
            air_date: Some("2023-09-29".to_string()),
            rating_score: Some(8.8),
            rating_rank: Some(18),
            tags: vec!["漫画改".to_string(), "奇幻".to_string()],
            total_episodes: 28,
        }
    }

    fn episode(subject_id: i64, id: i64, sort: i32) -> Episode {
        Episode {
            id,
            subject_id,
            sort,
            title: "The Journey Ends".to_string(),
            title_cn: Some("冒险的结束".to_string()),
            air_date: Some("2023-09-29".to_string()),
        }
    }

    fn progress(subject_id: i64, episode_id: i64, position_ms: i64) -> PlaybackProgress {
        PlaybackProgress {
            subject_id,
            episode_id,
            position_ms,
            duration_ms: Some(1_440_000),
            updated_at_ms: position_ms,
        }
    }

    #[test]
    fn schema_contains_progress_and_source_tables() {
        assert!(INITIAL_SCHEMA.contains("playback_progress"));
        assert!(INITIAL_SCHEMA.contains("favorite_subjects"));
        assert!(INITIAL_SCHEMA.contains("source_packages"));
        assert!(INITIAL_SCHEMA.contains("app_settings"));
    }

    #[tokio::test]
    async fn appearance_settings_default_save_and_normalize_invalid_values() {
        let storage = StorageService::open_memory().await.expect("storage");
        let defaults = storage
            .get_appearance_settings()
            .await
            .expect("default settings");
        assert_eq!(
            defaults,
            AppearanceSettings {
                theme_mode: "light".to_string(),
                color_scheme: "yneko".to_string(),
            }
        );

        let saved = storage
            .save_appearance_settings(AppearanceSettings {
                theme_mode: "dark".to_string(),
                color_scheme: "cyan".to_string(),
            })
            .await
            .expect("save settings");
        assert_eq!(saved.theme_mode, "dark");
        assert_eq!(saved.color_scheme, "cyan");
        assert_eq!(
            storage
                .get_appearance_settings()
                .await
                .expect("read saved settings"),
            saved
        );

        let normalized = storage
            .save_appearance_settings(AppearanceSettings {
                theme_mode: "system".to_string(),
                color_scheme: "unknown".to_string(),
            })
            .await
            .expect("normalize settings");
        assert_eq!(normalized.theme_mode, "light");
        assert_eq!(normalized.color_scheme, "yneko");
    }

    #[tokio::test]
    async fn search_history_round_trip_normalizes_entries() {
        let storage = StorageService::open_memory().await.expect("storage");
        assert!(
            storage
                .list_search_history()
                .await
                .expect("initial history")
                .is_empty()
        );

        let saved = storage
            .save_search_history(vec![
                " 葬送 ".to_string(),
                "".to_string(),
                "mono".to_string(),
                "葬送".to_string(),
                "奇幻".to_string(),
            ])
            .await
            .expect("save history");
        assert_eq!(saved, ["葬送", "mono", "奇幻"]);

        let loaded = storage.list_search_history().await.expect("loaded history");
        assert_eq!(loaded, saved);
    }

    #[tokio::test]
    async fn stores_lists_disables_and_deletes_source_packages() {
        let storage = StorageService::open_memory().await.expect("storage");
        storage
            .upsert_source_package(package("demo"))
            .await
            .expect("insert");

        let packages = storage.list_source_packages().await.expect("list");
        assert_eq!(packages.len(), 1);
        assert!(packages[0].enabled);

        storage
            .set_source_package_enabled("demo", false)
            .await
            .expect("disable");
        let enabled = storage
            .list_enabled_source_package_records()
            .await
            .expect("enabled");
        assert!(enabled.is_empty());

        storage.delete_source_package("demo").await.expect("delete");
        let packages = storage.list_source_packages().await.expect("list");
        assert!(packages.is_empty());
    }

    #[tokio::test]
    async fn seeds_kazumi_rules_repository_subscription() {
        let storage = StorageService::open_memory().await.expect("storage");
        let subscriptions = storage
            .list_rule_repository_subscriptions()
            .await
            .expect("subscriptions");
        assert_eq!(
            subscriptions
                .iter()
                .filter(|item| item.id == DEFAULT_RULE_REPOSITORY_SUBSCRIPTION_ID)
                .count(),
            1
        );
        let kazumi = subscriptions
            .iter()
            .find(|item| item.id == DEFAULT_RULE_REPOSITORY_SUBSCRIPTION_ID)
            .expect("kazumi");
        assert_eq!(kazumi.name, DEFAULT_RULE_REPOSITORY_SUBSCRIPTION_NAME);
        assert_eq!(kazumi.url, DEFAULT_RULE_REPOSITORY_SUBSCRIPTION_URL);
        assert!(kazumi.enabled);

        storage.initialize().await.expect("initialize again");
        let subscriptions = storage
            .list_rule_repository_subscriptions()
            .await
            .expect("subscriptions");
        assert_eq!(
            subscriptions
                .iter()
                .filter(|item| item.id == DEFAULT_RULE_REPOSITORY_SUBSCRIPTION_ID)
                .count(),
            1
        );
    }

    #[tokio::test]
    async fn migrates_legacy_source_package_table_without_format_column() {
        let path = std::env::temp_dir().join(format!("yneko-legacy-storage-{}.sqlite", now_ms()));
        let url = format!(
            "sqlite://{}?mode=rwc",
            path.to_string_lossy().replace('\\', "/")
        );
        let pool = SqlitePoolOptions::new()
            .max_connections(1)
            .connect(&url)
            .await
            .expect("legacy pool");
        sqlx::query(
            r#"
CREATE TABLE source_packages (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  version TEXT NOT NULL,
  enabled INTEGER NOT NULL,
  diagnostics_json TEXT NOT NULL,
  imported_at_ms INTEGER NOT NULL,
  updated_at_ms INTEGER NOT NULL,
  raw_text TEXT NOT NULL
)
"#,
        )
        .execute(&pool)
        .await
        .expect("legacy schema");
        sqlx::query(
            r#"
INSERT INTO source_packages (
  id, name, version, enabled, diagnostics_json,
  imported_at_ms, updated_at_ms, raw_text
) VALUES ('legacy', 'Legacy', '1.0.0', 1, '[]', 1, 1, 'id: legacy')
"#,
        )
        .execute(&pool)
        .await
        .expect("legacy row");
        pool.close().await;

        let storage = StorageService::open(&path).await.expect("migrate");
        let packages = storage.list_source_packages().await.expect("list");
        assert_eq!(packages.len(), 1);
        assert_eq!(packages[0].id, "legacy");
        assert_eq!(packages[0].format, "yaml");

        let _ = fs::remove_file(path);
    }

    #[tokio::test]
    async fn stores_updates_filters_and_deletes_favorites() {
        let storage = StorageService::open_memory().await.expect("storage");
        let saved = storage
            .save_favorite(subject(400602), CollectionStatus::Watching)
            .await
            .expect("save favorite");
        assert_eq!(saved.status, CollectionStatus::Watching);
        assert!(storage.is_favorite(400602).await.expect("favorite flag"));

        storage
            .save_favorite(subject(400602), CollectionStatus::Watched)
            .await
            .expect("update favorite");
        assert_eq!(
            storage
                .list_favorites(Some(CollectionStatus::Watching))
                .await
                .expect("watching")
                .len(),
            0
        );
        let watched = storage
            .list_favorites(Some(CollectionStatus::Watched))
            .await
            .expect("watched");
        assert_eq!(watched.len(), 1);
        assert_eq!(watched[0].subject.id, 400602);

        storage
            .delete_favorite(400602)
            .await
            .expect("delete favorite");
        assert!(!storage.is_favorite(400602).await.expect("favorite flag"));
        assert!(
            storage
                .list_favorites(None)
                .await
                .expect("favorites")
                .is_empty()
        );
    }

    #[tokio::test]
    async fn stores_reads_and_lists_playback_history() {
        let storage = StorageService::open_memory().await.expect("storage");
        storage
            .save_playback_progress_with_snapshots(
                progress(400602, 40060201, 42),
                Some(subject(400602)),
                Some(episode(400602, 40060201, 1)),
            )
            .await
            .expect("save first progress");
        storage
            .save_playback_progress_with_snapshots(
                progress(400602, 40060202, 84),
                Some(subject(400602)),
                Some(episode(400602, 40060202, 2)),
            )
            .await
            .expect("save second progress");

        let migrated_progress = storage
            .get_playback_progress(400602, 40060201)
            .await
            .expect("progress")
            .expect("progress row");
        assert_eq!(migrated_progress.position_ms, 42);

        let latest = storage
            .latest_playback_progress_for_subject(400602)
            .await
            .expect("latest")
            .expect("latest progress");
        assert_eq!(latest.episode_id, 40060202);

        let history = storage.list_watch_history(Some(1)).await.expect("history");
        assert_eq!(history.len(), 1);
        assert_eq!(history[0].episode.id, 40060202);

        storage
            .delete_watch_history_item(400602, 40060202)
            .await
            .expect("delete history item");
        let history = storage.list_watch_history(None).await.expect("history");
        assert_eq!(history.len(), 1);
        assert_eq!(history[0].episode.id, 40060201);

        storage.clear_watch_history().await.expect("clear history");
        assert!(
            storage
                .list_watch_history(None)
                .await
                .expect("history")
                .is_empty()
        );
        assert!(
            storage
                .get_playback_progress(400602, 40060201)
                .await
                .expect("progress")
                .is_none()
        );
    }

    #[tokio::test]
    async fn legacy_progress_rows_migrate_without_history_snapshots() {
        let path = std::env::temp_dir().join(format!("yneko-legacy-progress-{}.sqlite", now_ms()));
        let url = format!(
            "sqlite://{}?mode=rwc",
            path.to_string_lossy().replace('\\', "/")
        );
        let pool = SqlitePoolOptions::new()
            .max_connections(1)
            .connect(&url)
            .await
            .expect("legacy pool");
        sqlx::query(
            r#"
CREATE TABLE playback_progress (
  subject_id INTEGER NOT NULL,
  episode_id INTEGER NOT NULL,
  position_ms INTEGER NOT NULL,
  duration_ms INTEGER,
  updated_at_ms INTEGER NOT NULL,
  PRIMARY KEY (subject_id, episode_id)
)
"#,
        )
        .execute(&pool)
        .await
        .expect("legacy schema");
        sqlx::query(
            r#"
INSERT INTO playback_progress (
  subject_id, episode_id, position_ms, duration_ms, updated_at_ms
) VALUES (400602, 40060201, 42, 1440, 1)
"#,
        )
        .execute(&pool)
        .await
        .expect("legacy row");
        pool.close().await;

        let storage = StorageService::open(&path).await.expect("migrate");
        let legacy_progress = storage
            .get_playback_progress(400602, 40060201)
            .await
            .expect("progress")
            .expect("progress row");
        assert_eq!(legacy_progress.position_ms, 42);
        assert!(
            storage
                .list_watch_history(None)
                .await
                .expect("history")
                .is_empty()
        );

        storage
            .save_playback_progress_with_snapshots(
                progress(400602, 40060201, 84),
                Some(subject(400602)),
                Some(episode(400602, 40060201, 1)),
            )
            .await
            .expect("save snapshot progress");
        assert_eq!(
            storage
                .list_watch_history(None)
                .await
                .expect("history")
                .len(),
            1
        );

        let _ = fs::remove_file(path);
    }
}
