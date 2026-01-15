// 作用：统一不同攻击类型与角色的颜色、粗细与发光强度，确保一致的美术风格
import 'package:flutter/material.dart';

class EffectColors {
  static const laserPrimary = Color(0xFF6EE7FF); // 冷蓝激光
  static const laserSecondary = Color(0xFF00C2FF);
  static const slashPrimary = Color(0xFFFF6B6B); // 热红斩击
  static const impactPrimary = Color(0xFFFFD166); // 冲击暖黄
  static const explosionPrimary = Color(0xFFFF9F1C); // 爆炸橙
  static const injectPrimary = Color(0xFF7C4DFF); // 注入紫

  static const shieldBlue = Color(0xFF5EC8FF);
  static const bloodPulse = Color(0xFFB00020);
  static const shadowCorrupt = Color(0xFF7B1FA2);
  static const hexGrid = Color(0xFF4FC3F7);
}

class EffectThickness {
  static const laserCore = 2.0;
  static const laserEdge = 6.0;
  static const slashBlade = 6.0;
  static const slashTrail = 3.0;
  static const impactRing = 4.0;
}

class EffectStyle {
  final Color primary;
  final Color secondary;
  final double thickness;
  final double glow;

  const EffectStyle({
    required this.primary,
    required this.secondary,
    required this.thickness,
    required this.glow,
  });

  static const laser = EffectStyle(
    primary: EffectColors.laserPrimary,
    secondary: EffectColors.laserSecondary,
    thickness: EffectThickness.laserCore,
    glow: 6.0,
  );

  static const slash = EffectStyle(
    primary: EffectColors.slashPrimary,
    secondary: Colors.white,
    thickness: EffectThickness.slashBlade,
    glow: 5.0,
  );

  static const impact = EffectStyle(
    primary: EffectColors.impactPrimary,
    secondary: Colors.white,
    thickness: EffectThickness.impactRing,
    glow: 4.0,
  );

  static const explosion = EffectStyle(
    primary: EffectColors.explosionPrimary,
    secondary: Colors.white,
    thickness: 5.0,
    glow: 5.0,
  );

  static const inject = EffectStyle(
    primary: EffectColors.injectPrimary,
    secondary: Colors.white,
    thickness: 3.0,
    glow: 4.0,
  );
}
