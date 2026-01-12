import 'card_data.dart';

/// 效果执行回调函数类型
typedef EffectCallback =
    void Function(String effect, CardData card, dynamic target, dynamic battle);

/// 卡牌效果执行器
class CardEffect {
  static EffectCallback? _executor;

  /// 设置效果执行器
  static void setExecutor(EffectCallback executor) {
    _executor = executor;
  }

  /// 执行效果
  static void execute(
    String effect,
    CardData card,
    dynamic target,
    dynamic battle,
  ) {
    _executor?.call(effect, card, target, battle);
  }
}

/// 标准卡牌效果执行器
class CardEffectExecutor {
  /// 执行卡牌效果
  void execute(String effect, CardData card, dynamic target, dynamic battle) {
    // 分割多个效果（支持分号或&&分隔）
    final effects = effect.split(RegExp(r';|&&')).map((e) => e.trim()).where((e) => e.isNotEmpty);
    
    for (final effectPart in effects) {
      _executeSingleEffect(effectPart, card, target, battle);
    }
  }
  
  /// 执行单个效果
  void _executeSingleEffect(String effectPart, CardData card, dynamic target, dynamic battle) {
    final parts = effectPart.split(' ');
    if (parts.isEmpty) return;
    
    final command = parts[0];
    
    switch (command) {
      case 'damage':
        if (target != null && parts.length > 1) {
          final value = int.tryParse(parts[1]) ?? card.value;
          battle.applyDamage(target, value);
        }
        break;
      case 'block':
        if (parts.length > 1) {
          final value = int.tryParse(parts[1]) ?? card.value;
          battle.player.block += value;
          battle.anim.showBlockGain(battle.player, value);
        }
        break;
      case 'draw':
        if (parts.length > 1) {
          final count = int.tryParse(parts[1]) ?? 1;
          battle.drawCount = count;
          battle.drawCards();
        }
        break;
      case 'energy':
        if (parts.length > 1) {
          final value = int.tryParse(parts[1]) ?? 1;
          battle.energy += value;
        }
        break;
      case 'vulnerable':
        if (target != null && parts.length > 1) {
          // 脆弱效果：目标受到额外伤害
          final turns = int.tryParse(parts[1]) ?? 1;
          target.vulnerable += turns;
        }
        break;
      case 'heal':
        if (target != null && parts.length > 1) {
          final value = int.tryParse(parts[1]) ?? card.value;
          target.hp = (target.hp + value).clamp(0, target.maxHp);
          battle.anim.showHeal(target, value);
        }
        break;
      case 'self_damage':
        if (parts.length > 1) {
          final value = int.tryParse(parts[1]) ?? card.value;
          // 修复：自损不计入算力加成，直接扣除HP
          battle.player.hp = (battle.player.hp - value).clamp(0, 999);
          battle.anim.showDamage(battle.player, value);
        }
        break;
      case 'weak':
        if (target != null && parts.length > 1) {
          // 虚弱效果：目标造成伤害减少
          final turns = int.tryParse(parts[1]) ?? 1;
          target.weak += turns;
        }
        break;
      case 'curse':
        if (target != null && parts.length > 1) {
          // 诅咒效果：目标受到各种负面效果
          final turns = int.tryParse(parts[1]) ?? 1;
          target.curse += turns;
        }
        break;
      default:
        break;
    }
  }
}