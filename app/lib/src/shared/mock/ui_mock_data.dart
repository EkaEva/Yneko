import 'package:flutter/material.dart';

import '../domain/index.dart';

const mockAnimeCards = [
  UiAnimeCard(
    id: 1001,
    title: '星轨回响',
    subtitle: '2026 · 原创 · 12 话',
    score: '8.7',
    coverColor: Color(0xFFFF8CB1),
    accent: Color(0xFFFF6699),
    summary: '在近未来轨道城中，三位少女追踪失落电台信号。',
  ),
  UiAnimeCard(
    id: 1002,
    title: '海风便利店',
    subtitle: '日常 · 治愈 · 连载中',
    score: '8.2',
    coverColor: Color(0xFF73C4DF),
    accent: Color(0xFF00A1D6),
    summary: '夏天、海街、夜班便利店，以及一点点不可思议。',
  ),
  UiAnimeCard(
    id: 1003,
    title: '第七图书馆',
    subtitle: '奇幻 · 悬疑 · 24 话',
    score: '9.1',
    coverColor: Color(0xFFAEA3FF),
    accent: Color(0xFF7C6BD8),
    summary: '每本书都保存着一条未被选择的人生。',
  ),
  UiAnimeCard(
    id: 1004,
    title: '凌晨三点的发明部',
    subtitle: '校园 · 喜剧 · 13 话',
    score: '7.9',
    coverColor: Color(0xFFEFB07C),
    accent: Color(0xFFD9824B),
    summary: '一群睡眠不足的学生试图制造改变校园的机器。',
  ),
  UiAnimeCard(
    id: 1005,
    title: '薄荷色行星',
    subtitle: '科幻 · 公路 · 10 话',
    score: '8.5',
    coverColor: Color(0xFF5FD6BD),
    accent: Color(0xFF16A085),
    summary: '穿越被植物覆盖的城市，寻找最后一次日出。',
  ),
  UiAnimeCard(
    id: 1006,
    title: '旧雨伞同盟',
    subtitle: '都市 · 群像 · 12 话',
    score: '8.0',
    coverColor: Color(0xFFF7D66E),
    accent: Color(0xFFD6A821),
    summary: '下雨天才会出现的社团，守护被遗忘的约定。',
  ),
];

List<UiEpisodeItem> mockEpisodesForSubject(int subjectId) {
  return List.generate(
    12,
    (index) => UiEpisodeItem(
      id: subjectId * 100 + index + 1,
      order: index + 1,
      title: ['开场的电波', '雨后的街灯', '候选源测试', '夜航之前'][index % 4],
      progress: index < 3 ? (index + 1) * 0.18 : 0,
    ),
  );
}

const mockSourceCandidates = [
  UiSourceCandidate(name: '默认规则组', status: '已匹配', detail: '3 个候选 · 推荐线路 A', matched: true),
  UiSourceCandidate(name: '备用规则组', status: '待确认', detail: '2 个候选 · 需要人工选择', matched: true),
  UiSourceCandidate(name: '实验规则组', status: '未命中', detail: '标题匹配度不足', matched: false),
];

const mockPlaybackState = UiPlaybackState(
  title: '星轨回响 [第01话]',
  subtitle: '等待 media_kit adapter 接入真实播放流',
  positionLabel: '03:18',
  durationLabel: '24:00',
  progress: 0.14,
  isPlaying: false,
);
