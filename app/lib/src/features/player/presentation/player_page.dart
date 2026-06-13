import 'package:flutter/material.dart';

class PlayerSurface extends StatelessWidget {
  const PlayerSurface({
    super.key,
    required this.subjectId,
    required this.episodeId,
  });

  final int subjectId;
  final int episodeId;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111617),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle_fill, color: Colors.white70, size: 72),
            const SizedBox(height: 12),
            Text(
              'PlayerSurface',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'subject=$subjectId episode=$episodeId',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}
