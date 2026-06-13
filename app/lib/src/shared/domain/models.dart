class AnimeSubject {
  const AnimeSubject({
    required this.id,
    required this.name,
    this.nameCn,
    this.coverUrl,
    this.summary,
  });

  final int id;
  final String name;
  final String? nameCn;
  final String? coverUrl;
  final String? summary;
}

class AnimeEpisode {
  const AnimeEpisode({
    required this.id,
    required this.sort,
    required this.title,
    this.titleCn,
  });

  final int id;
  final int sort;
  final String title;
  final String? titleCn;
}

class PlaybackContract {
  const PlaybackContract({
    required this.id,
    required this.subjectId,
    required this.episodeId,
    required this.sourcePackageId,
    required this.title,
    required this.url,
    this.headers = const {},
  });

  final String id;
  final int subjectId;
  final int episodeId;
  final String sourcePackageId;
  final String title;
  final String url;
  final Map<String, String> headers;
}

