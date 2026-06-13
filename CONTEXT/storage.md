# Storage Context

SQLite stores local application state:

- Installed source repositories and packages.
- Source enablement.
- Favorites.
- Watch history.
- Playback progress.
- Settings.

SQLite access belongs in `yneko-storage`. Flutter does not access the database
directly.

