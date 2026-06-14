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
  UiSourceCandidate(
    name: '默认规则组',
    status: '已匹配',
    detail: '3 个候选 · 推荐线路 A',
    matched: true,
  ),
  UiSourceCandidate(
    name: '备用规则组',
    status: '待确认',
    detail: '2 个候选 · 需要人工选择',
    matched: true,
  ),
  UiSourceCandidate(
    name: '实验规则组',
    status: '未命中',
    detail: '标题匹配度不足',
    matched: false,
  ),
];

const mockPlaybackState = UiPlaybackState(
  title: '星轨回响 [第01话]',
  subtitle: '等待 media_kit adapter 接入真实播放流',
  positionLabel: '03:18',
  durationLabel: '24:00',
  progress: 0.14,
  isPlaying: false,
);

const mockMineLibrary = [
  UiMineItem(
    subjectId: 1001,
    title: '星轨回响',
    description: '看到第 3 话 · 近未来轨道城',
    meta: '在看',
    color: Color(0xFFFF8CB1),
    progress: 0.42,
    status: 'watching',
  ),
  UiMineItem(
    subjectId: 1002,
    title: '海风便利店',
    description: '治愈日常 · 连载中',
    meta: '想看',
    color: Color(0xFF73C4DF),
    status: 'wish',
  ),
  UiMineItem(
    subjectId: 1003,
    title: '第七图书馆',
    description: '24 话已完结 · 奇幻悬疑',
    meta: '看过',
    color: Color(0xFFAEA3FF),
    progress: 1,
    status: 'watched',
  ),
  UiMineItem(
    subjectId: 1005,
    title: '薄荷色行星',
    description: '公路科幻 · 等待更新',
    meta: '在看',
    color: Color(0xFF5FD6BD),
    progress: 0.18,
    status: 'watching',
  ),
];

const mockMineHistory = [
  UiMineItem(
    subjectId: 1001,
    title: '星轨回响',
    description: '第 3 话 · 03:18 / 24:00',
    meta: '今天 21:08',
    color: Color(0xFFFF8CB1),
    progress: 0.14,
  ),
  UiMineItem(
    subjectId: 1004,
    title: '凌晨三点的发明部',
    description: '第 1 话 · 12:44 / 23:40',
    meta: '昨天',
    color: Color(0xFFEFB07C),
    progress: 0.54,
  ),
  UiMineItem(
    subjectId: 1006,
    title: '旧雨伞同盟',
    description: '第 8 话 · 已看完',
    meta: '上周',
    color: Color(0xFFF7D66E),
    progress: 1,
  ),
];

const mockMineCache = [
  UiMineItem(
    title: '星轨回响 第 1-3 话',
    description: '缓存占位 · 1.2 GB',
    meta: '离线缓存',
    color: Color(0xFFFF8CB1),
    progress: 1,
  ),
  UiMineItem(
    title: '海风便利店 第 1 话',
    description: '缓存占位 · 426 MB',
    meta: '离线缓存',
    color: Color(0xFF73C4DF),
    progress: 0.72,
  ),
];
