import '../models/card_data.dart';

/// 效果执行回调函数类型
typedef EffectCallback =
    void Function(String effect, CardData? card, dynamic target, dynamic battle);

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
    CardData? card,
    dynamic target,
    dynamic battle,
  ) {
    _executor?.call(effect, card, target, battle);
  }
}

/// 标准卡牌效果执行器
class CardEffectExecutor {
  /// 执行卡牌效果
  void execute(String effect, CardData? card, dynamic target, dynamic battle) {
    // 分割多个效果（支持分号或&&分隔）
    final effects = effect.split(RegExp(r';|&&')).map((e) => e.trim()).where((e) => e.isNotEmpty);
    
    for (final effectPart in effects) {
      _executeSingleEffect(effectPart, card, target, battle);
    }
  }
  
  /// 执行单个效果
  void _executeSingleEffect(String effectPart, CardData? card, dynamic target, dynamic battle) {
    final parts = effectPart.split(' ');
    if (parts.isEmpty) return;
    
    final command = parts[0];
    
    switch (command) {
      case 'damage':
        if (parts.length > 1) {
          final value = int.tryParse(parts[1]) ?? 0;
          if (card?.target == CardTarget.all) {
            for (final enemy in battle.activePrograms) {
              if (enemy.hp > 0) {
                battle.applyDamage(enemy, value);
              }
            }
          } else if (target != null) {
            battle.applyDamage(target, value);
          }
        }
        break;
      case 'block':
        if (parts.length > 1) {
          final value = int.tryParse(parts[1]) ?? 0;
          battle.player.block += value;
          battle.anim.showBlockGain(battle.player, value);
        }
        break;
      case 'draw':
        if (parts.length > 1) {
          final count = int.tryParse(parts[1]) ?? 1;
          battle.drawCards(count);
        }
        break;
      case 'energy':
        if (parts.length > 1) {
          final value = int.tryParse(parts[1]) ?? 1;
          battle.energy += value;
        }
        break;
      case 'vulnerable':
        if (parts.length > 1) {
          final turns = int.tryParse(parts[1]) ?? 1;
          if (card?.target == CardTarget.all) {
            for (final enemy in battle.activePrograms) {
              if (enemy.hp > 0) enemy.vulnerable += turns;
            }
          } else if (target != null) {
            target.vulnerable += turns;
          }
        }
        break;
      case 'heal':
        if (parts.length > 1) {
          final value = int.tryParse(parts[1]) ?? 0;
          battle.player.hp = (battle.player.hp + value).clamp(0, battle.player.maxHp);
          battle.anim.showHeal(battle.player, value);
        }
        break;
      case 'self_damage':
        if (parts.length > 1) {
          final value = int.tryParse(parts[1]) ?? 0;
          battle.player.hp = (battle.player.hp - value).clamp(0, 999);
          battle.anim.showDamage(battle.player, value);
        }
        break;
      case 'weak':
        if (parts.length > 1) {
          final turns = int.tryParse(parts[1]) ?? 1;
          if (card?.target == CardTarget.all) {
            for (final enemy in battle.activePrograms) {
              if (enemy.hp > 0) enemy.weak += turns;
            }
          } else if (target != null) {
            target.weak += turns;
          }
        }
        break;
      case 'curse':
        if (parts.length > 1) {
          final turns = int.tryParse(parts[1]) ?? 1;
          if (card?.target == CardTarget.all) {
            for (final enemy in battle.activePrograms) {
              if (enemy.hp > 0) enemy.curse += turns;
            }
          } else if (target != null) {
            target.curse += turns;
          }
        }
        break;
      case 'strength':
        if (parts.length > 1) {
          final value = int.tryParse(parts[1]) ?? 1;
          battle.player.strength += value;
        }
        break;
      case 'sturdy':
        if (parts.length > 1) {
          final value = int.tryParse(parts[1]) ?? 1;
          battle.player.sturdy += value;
        }
        break;
      case 'max_hp_up':
        if (parts.length > 1) {
          final value = int.tryParse(parts[1]) ?? 0;
          battle.player.maxHp += value;
          battle.player.hp += value; // 提升上限时也提升当前生命
          battle.anim.showHeal(battle.player, value);
        }
        break;
      default:
        break;
    }
  }
}