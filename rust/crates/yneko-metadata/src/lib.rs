use yneko_core::{SubjectDetail, SubjectSummary, YnekoError, YnekoResult, clean_query};

#[derive(Debug, Clone)]
pub struct BangumiClient {
    base_url: String,
}

impl Default for BangumiClient {
    fn default() -> Self {
        Self {
            base_url: "https://api.bgm.tv".to_string(),
        }
    }
}

impl BangumiClient {
    pub fn new(base_url: impl Into<String>) -> Self {
        Self {
            base_url: base_url.into(),
        }
    }

    pub fn base_url(&self) -> &str {
        &self.base_url
    }

    pub async fn search_subjects(
        &self,
        query: &str,
        _page: u32,
    ) -> YnekoResult<Vec<SubjectSummary>> {
        let _query = clean_query(query)?;
        Err(YnekoError::NotImplemented(
            "Bangumi search HTTP integration".to_string(),
        ))
    }

    pub async fn get_subject_detail(&self, subject_id: i64) -> YnekoResult<SubjectDetail> {
        if subject_id <= 0 {
            return Err(YnekoError::InvalidInput(
                "subject_id must be positive".to_string(),
            ));
        }
        Err(YnekoError::NotImplemented(
            "Bangumi subject detail HTTP integration".to_string(),
        ))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn default_client_uses_bangumi_api() {
        assert_eq!(BangumiClient::default().base_url(), "https://api.bgm.tv");
    }
}
