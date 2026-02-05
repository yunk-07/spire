// 作用：集中管理项目的动画时长、曲线、粒子与发光等参数，统一特效风格与节奏
import 'package:flutter/material.dart';

class AnimDurations {
  static const laser = Duration(milliseconds: 800);
  static const slash = Duration(milliseconds: 1200);
  static const impact = Duration(milliseconds: 600);
  static const explosion = Duration(milliseconds: 700);
  static const inject = Duration(milliseconds: 650);

  static const popup = Duration(milliseconds: 850);
  static const gridPulse = Duration(milliseconds: 1500);
  static const screenOverload = Duration(milliseconds: 400);
}

class AnimCurves {
  static const fastOut = Curves.easeOutCubic;
  static const mediumOut = Curves.easeOutQuart;
  static const gentleOut = Curves.easeOutQuad;
  static const elastic = Curves.elasticOut;
  static const bounce = Curves.bounceOut;
  static const linear = Curves.linear;
}

class ParticleConfig {
  static const impactCount = 24;
  static const shieldShardCount = 18;
  static const bloodMistCount = 20;
  static const victorySparkles = 30;
}

class GlowConfig {
  static const laserCore = 3.0;
  static const laserEdge = 6.0;
  static const slashTrail = 5.0;
  static const impactRing = 4.0;
}

class ZOrders {
  static const background = 0;
  static const gridPulse = 1;
  static const roleEffects = 2;
  static const attackEffects = 3;
  static const popups = 4;
  static const overlays = 5;
}
