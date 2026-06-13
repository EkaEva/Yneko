use serde::{Deserialize, Serialize};
use yneko_core::{SourcePackage, SourceRepository, YnekoError, YnekoResult};

const FORBIDDEN_FIELDS: &[&str] = &[
    "script",
    "scripts",
    "credential",
    "credentials",
    "drm_bypass",
    "login_bypass",
    "paywall_bypass",
    "anti_scraping_bypass",
];

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SourceRepositoryManifest {
    pub id: String,
    pub name: String,
    pub packages: Vec<SourcePackageManifest>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SourcePackageManifest {
    pub id: String,
    pub name: String,
    pub version: String,
}

pub fn validate_source_text(text: &str) -> YnekoResult<()> {
    let lowered = text.to_ascii_lowercase();
    for field in FORBIDDEN_FIELDS {
        if lowered.contains(field) {
            return Err(YnekoError::SourceRejected(format!(
                "forbidden field `{field}` is not allowed"
            )));
        }
    }
    Ok(())
}

pub fn repository_from_manifest(url: &str, manifest: SourceRepositoryManifest) -> SourceRepository {
    SourceRepository {
        id: manifest.id,
        name: manifest.name,
        url: url.to_string(),
        package_count: manifest.packages.len(),
    }
}

pub fn package_from_manifest(
    repository_id: Option<String>,
    manifest: SourcePackageManifest,
) -> SourcePackage {
    SourcePackage {
        id: manifest.id,
        repository_id,
        name: manifest.name,
        version: manifest.version,
        enabled: true,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rejects_script_fields() {
        let result = validate_source_text("name: demo\nscript: alert(1)");
        assert!(matches!(result, Err(YnekoError::SourceRejected(_))));
    }

    #[test]
    fn accepts_plain_declarative_text() {
        validate_source_text("name: demo\nselectors:\n  title: h1").expect("valid");
    }
}
