// 作用：管理各类攻击特效的独立动画域，减少全局重建与重绘压力
import 'package:flutter/material.dart';
import 'main.dart' show AttackEffect, AttackEffectType;

typedef EffectWidgetBuilder = Widget Function(AttackEffect e);

class EffectLayerManager extends ChangeNotifier {
  final Map<AttackEffectType, List<AttackEffect>> _effects = {
    AttackEffectType.impact: [],
    AttackEffectType.laser: [],
    AttackEffectType.slash: [],
    AttackEffectType.explosion: [],
    AttackEffectType.inject: [],
  };

  void add(AttackEffect e) {
    _effects[e.type]!.add(e);
    notifyListeners();
  }

  void remove(AttackEffect e) {
    _effects[e.type]!.remove(e);
    notifyListeners();
  }

  List<AttackEffect> of(AttackEffectType type) => List.unmodifiable(_effects[type]!);
}

class EffectLayer extends StatelessWidget {
  final EffectLayerManager manager;
  final AttackEffectType type;
  final EffectWidgetBuilder builder;

  const EffectLayer({
    super.key,
    required this.manager,
    required this.type,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: manager,
      builder: (_, __) {
        final items = manager.of(type);
        return RepaintBoundary(
          child: Stack(
            children: [
              for (final e in items) builder(e),
            ],
          ),
        );
      },
    );
  }
}
