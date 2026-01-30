import 'package:flutter/material.dart';
import 'card_data.dart';
import 'game_state.dart';

/// 统一管理卡牌样式、配色和系列相关配置
class ThemeConfig {
  /// 根据卡牌套装(Suite)确定视觉风格颜色
  static Color getSuiteColor(CardSuite suite) {
    switch (suite) {
      case CardSuite.classic:
        return GameState.getThemeColor();
      case CardSuite.overload:
        return const Color(0xFFFF4444); // 红色
      case CardSuite.secure:
        return const Color(0xFFC3A6FF); // 紫色
      case CardSuite.industrial:
        return const Color(0xFFFFB344); // 橙色
      case CardSuite.quantum:
        return const Color(0xFFE26CFF); // 粉色
      case CardSuite.demon:
        return const Color(0xFF9D00FF); // 深紫色
      case CardSuite.holy:
        return const Color(0xFFFFD700); // 金色
    }
  }

  /// 根据稀有度等级获取颜色
  static Color getRarityColor(int level, {CardSuite? suite}) {
    if (suite == CardSuite.demon || suite == CardSuite.holy) {
      return const Color(0xFFFF0000); // 特殊牌红
    }
    switch (level) {
      case 1:
        return const Color(0xFF44FF44); // 绿色
      case 2:
        return GameState.getThemeColor(); // 主题蓝/青
      case 3:
        return const Color(0xFFE26CFF); // 粉紫色
      case 4:
        return const Color(0xFFFFD700); // 金色
      case 5:
        return const Color(0xFFFF4444); // 红色
      default:
        return Colors.white70;
    }
  }

  /// 获取卡牌背景色
  static Color getCardBgColor(CardSuite suite) {
    switch (suite) {
      case CardSuite.overload:
        return const Color(0xFF1A0A0A);
      case CardSuite.secure:
        return const Color(0xFF1A0A1A);
      case CardSuite.industrial:
        return const Color(0xFF1A140A);
      case CardSuite.quantum:
        return const Color(0xFF140A1A);
      case CardSuite.classic:
        return const Color(0xFF101722);
      case CardSuite.demon:
        return const Color(0xFF0F001A);
      case CardSuite.holy:
        return const Color(0xFF1A1A0A);
    }
  }

  /// 获取套装对应的图标
  static IconData getSuiteIcon(CardSuite suite) {
    switch (suite) {
      case CardSuite.classic:
        return Icons.bolt_rounded;
      case CardSuite.overload:
        return Icons.warning_amber_rounded;
      case CardSuite.secure:
        return Icons.security_rounded;
      case CardSuite.industrial:
        return Icons.settings_rounded;
      case CardSuite.quantum:
        return Icons.auto_awesome_rounded;
      case CardSuite.demon:
        return Icons.pest_control_rodent_rounded;
      case CardSuite.holy:
        return Icons.auto_awesome;
    }
  }

  /// 获取卡牌类型的显示文本
  static String getTypeName(CardType type) {
    switch (type) {
      case CardType.exploit:
        return 'EXPLOIT';
      case CardType.encryption:
        return 'ENCRYPT';
      case CardType.routine:
        return 'ROUTINE';
      case CardType.module:
        return 'MODULE';
    }
  }
}
