// 作用：封装五类攻击特效的独立组件，便于复用与局部重建
import 'dart:math';
import 'package:flutter/material.dart';
import 'animation_constants.dart';
import 'effect_styles.dart';
import 'laser_painter.dart';
import 'slash_painter.dart';
import 'particle_emitter.dart';
import 'main.dart' show AttackEffect;

class ImpactEffectWidget extends StatelessWidget {
  final AttackEffect e;
  const ImpactEffectWidget(this.e, {super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AnimDurations.impact,
      curve: AnimCurves.fastOut,
      builder: (_, t, __) {
        final opacity = (1.0 - t).clamp(0.0, 1.0);
        final scale = 0.5 + t * 2.0;
        return Stack(
          children: [
            Positioned(
              left: e.end.dx + 50 - (40 * scale),
              top: e.end.dy + 60 - (40 * scale),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 80 * scale,
                  height: 80 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: EffectColors.laserPrimary.withValues(alpha: opacity),
                      width: 4 * (1 - t),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: EffectColors.laserPrimary.withValues(alpha: opacity * 0.5),
                        blurRadius: 20 * t,
                        spreadRadius: 5 * t,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class LaserEffectWidget extends StatelessWidget {
  final AttackEffect e;
  const LaserEffectWidget(this.e, {super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AnimDurations.laser,
      builder: (_, t, __) {
        final opacity = t < 0.2 ? t / 0.2 : (t < 0.8 ? 1.0 : 1.0 - (t - 0.8) / 0.2);
        final width = t < 0.3 ? t / 0.3 * 8.0 : (1.0 - (t - 0.3) / 0.7) * 8.0;
        return Stack(
          children: [
            CustomPaint(
              painter: LaserPainter(
                start: e.start + const Offset(40, 48),
                end: e.end + const Offset(50, 60),
                progress: t,
                color: EffectColors.laserPrimary,
                width: width,
                opacity: opacity,
              ),
            ),
            if (t > 0.2 && t < 0.8)
              Positioned(
                left: e.end.dx + 50 - 30,
                top: e.end.dy + 60 - 30,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 200),
                  builder: (_, v, __) => Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: EffectColors.laserPrimary.withValues(alpha: 1.0 - v), width: 2),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class SlashEffectWidget extends StatelessWidget {
  final AttackEffect e;
  const SlashEffectWidget(this.e, {super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AnimDurations.slash,
      builder: (_, t, __) {
        final center = e.end + const Offset(50, 60);
        final secondPhase = ((t - 0.2) / 0.8).clamp(0.0, 1.0);
        return Stack(
          children: [
            // 第一段弧形斩击
            CustomPaint(
              painter: SlashPainter(
                center: center,
                progress: t,
                color: EffectColors.slashPrimary,
              ),
            ),
            // 第二段交叉斩击（延迟触发，角度相反）
            if (secondPhase > 0)
              Transform.rotate(
                angle: -0.25,
                child: CustomPaint(
                  painter: SlashPainter(
                    center: center.translate(-10, -6),
                    progress: secondPhase,
                    color: Colors.white,
                  ),
                ),
              ),
            // 命中冲击环
            if (t > 0.5)
              Positioned(
                left: center.dx - 20,
                top: center.dy - 20,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 250),
                  curve: AnimCurves.fastOut,
                  builder: (_, v, __) {
                    return Opacity(
                      opacity: (1.0 - v).clamp(0.0, 1.0),
                      child: Container(
                        width: 40 + 20 * v,
                        height: 40 + 20 * v,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: EffectColors.slashPrimary.withValues(alpha: 0.8 * (1.0 - v)), width: 2),
                        ),
                      ),
                    );
                  },
                ),
              ),
            // 命中粒子爆裂
            if (t > 0.55)
              ParticleBurst(
                center: center,
                count: ParticleConfig.impactCount,
                color: EffectColors.slashPrimary,
                duration: const Duration(milliseconds: 420),
              ),
          ],
        );
      },
    );
  }
}

class ExplosionEffectWidget extends StatelessWidget {
  final AttackEffect e;
  const ExplosionEffectWidget(this.e, {super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AnimDurations.explosion,
      builder: (_, t, __) {
        return Stack(
          children: [
            if (t < 0.4)
              Positioned(
                left: Offset.lerp(e.start, e.end, t / 0.4)!.dx + 40,
                top: Offset.lerp(e.start, e.end, t / 0.4)!.dy + 40,
                child: Transform.rotate(
                  angle: t * 10,
                  child: const Icon(Icons.brightness_high, color: Color(0xFFFF9500), size: 24),
                ),
              ),
            if (t >= 0.3)
              ...List.generate(12, (i) {
                final progress = ((t - 0.3) / 0.7).clamp(0.0, 1.0);
                if (progress <= 0 || progress >= 1) return const SizedBox();
                final angle = (i * 30) * pi / 180;
                final dist = progress * 80;
                return Positioned(
                  left: e.end.dx + 50 + cos(angle) * dist,
                  top: e.end.dy + 60 + sin(angle) * dist,
                  child: Opacity(
                    opacity: 1.0 - progress,
                    child: Container(
                      width: 8 * (1 - progress),
                      height: 8 * (1 - progress),
                      decoration: const BoxDecoration(color: Color(0xFFFF4444), shape: BoxShape.circle),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

class InjectEffectWidget extends StatelessWidget {
  final AttackEffect e;
  const InjectEffectWidget(this.e, {super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AnimDurations.inject,
      builder: (_, t, __) {
        return Stack(
          children: [
            if (t < 0.6)
              ...List.generate(5, (i) {
                final delay = i * 0.1;
                final progress = ((t - delay) / 0.5).clamp(0.0, 1.0);
                if (progress <= 0 || progress >= 1) return const SizedBox();
                final pos = Offset.lerp(e.start + const Offset(40, 48), e.end + const Offset(50, 60), progress)!;
                return Positioned(
                  left: pos.dx,
                  top: pos.dy,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(color: EffectColors.injectPrimary, shape: BoxShape.circle),
                  ),
                );
              }),
            if (t > 0.4)
              ...List.generate(3, (i) {
                final progress = ((t - 0.4) / 0.6).clamp(0.0, 1.0);
                return Positioned(
                  left: e.end.dx + 30 + (i * 20),
                  top: e.end.dy + 80 - (progress * 60),
                  child: Opacity(
                    opacity: (1.0 - progress) * 0.7,
                    child: Text(
                      (i % 2 == 0 ? "101" : "011"),
                      style: TextStyle(color: EffectColors.injectPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
