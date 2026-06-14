import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/bridge/yneko_backend.dart';
import '../../../shared/domain/index.dart';

final watchSubjectDetailProvider = FutureProvider.family<SubjectDetail, int>((
  ref,
  subjectId,
) async {
  return ref.watch(ynekoBackendProvider).getSubjectDetail(subjectId);
});

String watchSubjectTitle(AnimeSubject subject) => subject.displayTitle;

String watchSubjectScoreLabel(AnimeSubject subject) {
  if (subject.ratingScore != null) {
    return '评分 ${subject.ratingScore!.toStringAsFixed(1)}';
  }
  if (subject.ratingRank != null) {
    return 'Rank ${subject.ratingRank}';
  }
  return '评分 --';
}

String watchSubjectAirDateLabel(AnimeSubject subject) {
  final value = subject.airDate?.trim();
  return value == null || value.isEmpty ? '开播未知' : value;
}

String watchSubjectEpisodeCountLabel(
  AnimeSubject subject,
  List<AnimeEpisode> episodes,
) {
  final total = subject.totalEpisodes > 0
      ? subject.totalEpisodes
      : episodes.length;
  return total > 0 ? '$total 话' : '集数未知';
}

String watchSubjectTagLabel(AnimeSubject subject) {
  return subject.tags.isEmpty ? 'Bangumi' : subject.tags.take(2).join(' · ');
}

Color watchSubjectCoverColor(int subjectId) {
  final hue = (subjectId.abs() * 37) % 360;
  return HSLColor.fromAHSL(1, hue.toDouble(), 0.38, 0.42).toColor();
}

Color watchSubjectAccentColor(int subjectId) {
  final hue = ((subjectId.abs() * 37) + 42) % 360;
  return HSLColor.fromAHSL(1, hue.toDouble(), 0.44, 0.56).toColor();
}
