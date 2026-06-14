import 'package:flutter/material.dart';

class UiAnimeCard {
  const UiAnimeCard({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.score,
    required this.coverColor,
    required this.accent,
    this.coverUrl,
    this.summary = '',
  });

  final int id;
  final String title;
  final String subtitle;
  final String score;
  final Color coverColor;
  final Color accent;
  final String? coverUrl;
  final String summary;
}

class UiEpisodeItem {
  const UiEpisodeItem({
    required this.id,
    required this.order,
    required this.title,
    required this.progress,
    this.released = true,
  });

  final int id;
  final int order;
  final String title;
  final double progress;
  final bool released;

  String get label => '第 $order 话';
}

class UiSourceCandidate {
  const UiSourceCandidate({
    required this.name,
    required this.status,
    required this.detail,
    required this.matched,
  });

  final String name;
  final String status;
  final String detail;
  final bool matched;
}

class UiPlaybackState {
  const UiPlaybackState({
    required this.title,
    required this.subtitle,
    required this.positionLabel,
    required this.durationLabel,
    required this.progress,
    required this.isPlaying,
  });

  final String title;
  final String subtitle;
  final String positionLabel;
  final String durationLabel;
  final double progress;
  final bool isPlaying;
}

class UiMineItem {
  const UiMineItem({
    required this.title,
    required this.description,
    required this.meta,
    required this.color,
    this.subjectId,
    this.progress,
    this.status = 'watching',
  });

  final String title;
  final String description;
  final String meta;
  final Color color;
  final int? subjectId;
  final double? progress;
  final String status;
}
