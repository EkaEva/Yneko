use yneko_core::{
    PlaybackCandidate, PlaybackProgress, SourcePackage, SourceRepository, SubjectDetail,
    SubjectSummary, WatchHistoryItem, YnekoError, YnekoResult,
};

pub async fn search_subjects(query: String, page: u32) -> YnekoResult<Vec<SubjectSummary>> {
    yneko_metadata::BangumiClient::default()
        .search_subjects(&query, page)
        .await
}

pub async fn get_subject_detail(subject_id: i64) -> YnekoResult<SubjectDetail> {
    yneko_metadata::BangumiClient::default()
        .get_subject_detail(subject_id)
        .await
}

pub async fn import_source_repository(url: String) -> YnekoResult<SourceRepository> {
    if url.trim().is_empty() {
        return Err(YnekoError::InvalidInput(
            "url must not be empty".to_string(),
        ));
    }
    Err(YnekoError::NotImplemented(
        "source repository import".to_string(),
    ))
}

pub async fn install_source_package(package_ref: String) -> YnekoResult<SourcePackage> {
    if package_ref.trim().is_empty() {
        return Err(YnekoError::InvalidInput(
            "package_ref must not be empty".to_string(),
        ));
    }
    Err(YnekoError::NotImplemented(
        "source package installation".to_string(),
    ))
}

pub async fn list_source_packages() -> YnekoResult<Vec<SourcePackage>> {
    Ok(Vec::new())
}

pub async fn set_source_package_enabled(id: String, _enabled: bool) -> YnekoResult<()> {
    if id.trim().is_empty() {
        return Err(YnekoError::InvalidInput("id must not be empty".to_string()));
    }
    Err(YnekoError::NotImplemented(
        "source package enablement persistence".to_string(),
    ))
}

pub async fn resolve_playback(
    subject_id: i64,
    episode_id: i64,
) -> YnekoResult<Vec<PlaybackCandidate>> {
    if subject_id <= 0 || episode_id <= 0 {
        return Err(YnekoError::InvalidInput(
            "subject_id and episode_id must be positive".to_string(),
        ));
    }
    Ok(Vec::new())
}

pub async fn save_playback_progress(progress: PlaybackProgress) -> YnekoResult<()> {
    yneko_storage::StorageService::new()
        .save_playback_progress(progress)
        .await
}

pub async fn list_history() -> YnekoResult<Vec<WatchHistoryItem>> {
    Ok(Vec::new())
}

pub async fn set_favorite(subject_id: i64, _favorite: bool) -> YnekoResult<()> {
    if subject_id <= 0 {
        return Err(YnekoError::InvalidInput(
            "subject_id must be positive".to_string(),
        ));
    }
    Err(YnekoError::NotImplemented(
        "favorite persistence".to_string(),
    ))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn resolve_playback_rejects_invalid_ids() {
        let result = resolve_playback(0, 1).await;
        assert!(matches!(result, Err(YnekoError::InvalidInput(_))));
    }

    #[tokio::test]
    async fn list_source_packages_starts_empty() {
        assert!(list_source_packages().await.expect("packages").is_empty());
    }
}
