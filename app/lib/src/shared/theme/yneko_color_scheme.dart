import 'package:flutter/material.dart';

enum YnekoColorScheme {
  yneko('Yneko 粉', [Color(0xFFFF6699), Color(0xFF00A1D6), Color(0xFFFFF0F5)]),
  blue('清爽蓝', [Color(0xFF2F8AF5), Color(0xFFEDF6FF), Color(0xFFF8FBFF)]),
  gray('经典灰', [Color(0xFF6C727A), Color(0xFFEDEFF2), Color(0xFFFBFBFC)]),
  mint('薄荷绿', [Color(0xFF16A085), Color(0xFFEDF9F5), Color(0xFFFBFFFD)]),
  spruce('云杉青', [Color(0xFF0F8B8D), Color(0xFFEDF8F8), Color(0xFFF9FDFD)]),
  lavender('晨雾紫', [Color(0xFF7C6BD8), Color(0xFFF2F0FF), Color(0xFFFCFBFF)]),
  apricot('暖杏白', [Color(0xFFD9824B), Color(0xFFFFF4EB), Color(0xFFFFFDF9)]),
  coral('珊瑚红', [Color(0xFFE56B5D), Color(0xFFFFF0EC), Color(0xFFFFFCFA)]),
  amber('琥珀黄', [Color(0xFFC98914), Color(0xFFFFF7E6), Color(0xFFFFFDF8)]),
  cyan('湖水蓝', [Color(0xFF2BA7B8), Color(0xFFECFAFC), Color(0xFFFAFEFF)]),
  rose('蔷薇粉', [Color(0xFFE85D8F), Color(0xFFFFF0F6), Color(0xFFFFFBFD)]),
  peach('蜜桃粉', [Color(0xFFE88772), Color(0xFFFFF1EC), Color(0xFFFFFCFA)]),
  lilac('丁香紫', [Color(0xFFB77BE8), Color(0xFFF8F0FF), Color(0xFFFEFBFF)]),
  sage('鼠尾草', [Color(0xFF6FA36F), Color(0xFFF0F8EF), Color(0xFFFBFFFA)]),
  indigo('靛蓝', [Color(0xFF5D73D8), Color(0xFFF0F3FF), Color(0xFFFBFCFF)]),
  cocoa('可可棕', [Color(0xFFA1704B), Color(0xFFF8F1EC), Color(0xFFFFFCFA)]);

  const YnekoColorScheme(this.label, this.previewColors);

  final String label;
  final List<Color> previewColors;

  static YnekoColorScheme fromValue(String value) {
    return YnekoColorScheme.values.firstWhere(
      (scheme) => scheme.name == value,
      orElse: () => YnekoColorScheme.yneko,
    );
  }

  static YnekoColorScheme fromLabel(String label) {
    return YnekoColorScheme.values.firstWhere(
      (scheme) => scheme.label == label,
      orElse: () => YnekoColorScheme.yneko,
    );
  }
}
