import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/index.dart';
import '../../../shared/domain/index.dart';
import '../../../shared/mock/index.dart';
import '../../../shared/theme/index.dart';
import '../../../shared/ui/index.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = YnekoThemeTokens.of(context);
    return ColoredBox(
      color: tokens.page,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 48),
        children: [
          YnekoSectionTitle(
            title: '今天想看点什么',
            subtitle: '推荐、续看和榜单先用静态数据承托最终视觉',
            trailing: FilledButton.icon(
              onPressed: () => ref.read(shellRouteProvider.notifier).openSearch(),
              icon: const Icon(Icons.travel_explore_rounded),
              label: const Text('去搜索'),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final item = mockAnimeCards[index % mockAnimeCards.length];
                return _TrendingCard(
                  item: item,
                  onTap: () => ref.read(shellRouteProvider.notifier).openSubjectDetail(item.id),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(width: 20),
              itemCount: 4,
            ),
          ),
          const SizedBox(height: 36),
          const YnekoSectionTitle(title: '继续观看', subtitle: '进度恢复后会显示最近播放记录'),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final item in mockAnimeCards.take(3))
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _ContinueCard(
                      item: item,
                      onTap: () => ref.read(shellRouteProvider.notifier).openEpisodePlayback(
                        subjectId: item.id,
                        episodeId: item.id * 100 + 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 36),
          const YnekoSectionTitle(title: '本季关注', subtitle: 'Bangumi-first 条目卡片样式'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width > 1280 ? 6 : width > 980 ? 5 : width > 720 ? 4 : 3;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 28,
                  childAspectRatio: 0.62,
                ),
                itemCount: mockAnimeCards.length,
                itemBuilder: (context, index) {
                  final item = mockAnimeCards[index];
                  return AnimePosterCard(
                    item: item,
                    onTap: () => ref.read(shellRouteProvider.notifier).openSubjectDetail(item.id),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({required this.item, required this.onTap});

  final UiAnimeCard item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [item.coverColor, item.accent],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xD326131A)],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Text(
                          '推荐',
                          style: TextStyle(color: item.accent, fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.title,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.item, required this.onTap});

  final UiAnimeCard item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return YnekoPanel(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 112,
          child: Row(
            children: [
              AspectRatio(
                aspectRatio: 1.05,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: item.coverColor,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                  ),
                  child: Center(
                    child: Text(
                      item.title.substring(0, 1),
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(
                        '看到第 1 话 · 还剩 20 分钟',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: tokens.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          value: 0.26,
                          backgroundColor: tokens.surfaceHigh,
                          color: tokens.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
