// casino_screen.dart
// 作用：提供地下赌场页面，实现“21点”博弈玩法

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'game_state.dart';
import 'level_data.dart';
import 'main.dart';
import 'map_screen.dart';
import 'theme_config.dart';

class CasinoScreen extends StatefulWidget {
  final LevelInfo level;

  const CasinoScreen({super.key, required this.level});

  @override
  State<CasinoScreen> createState() => _CasinoScreenState();
}

class _CasinoScreenState extends State<CasinoScreen> with TickerProviderStateMixin {
  final Random _random = Random();
  
  // 游戏状态
  bool _isBetting = true; // 是否处于下注阶段
  bool _isGameOver = false;
  bool _isDealerRevealing = false; // 是否正在翻开敌方的牌
  String _gameResult = "";
  Color _resultColor = Colors.white;

  // 筹码逻辑
  final int _baseBet = 20;
  int _extraBetCount = 0; // 加注次数 (0-10)
  double _multiplier = 1.0; // 倍数 (1.0 - 2.0)

  // 卡牌逻辑
  List<String> _playerCards = [];
  List<String> _dealerCards = [];

  // 动画控制器
  AnimationController? _goldAnimController;
  Animation<int>? _goldAnimation;
  int _displayedGold = GameState.playerGold;

  @override
  void initState() {
    super.initState();
    _goldAnimController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    if (_goldAnimController != null) {
      _goldAnimation = IntTween(begin: GameState.playerGold, end: GameState.playerGold)
          .animate(CurvedAnimation(parent: _goldAnimController!, curve: Curves.easeOutCubic));
    }
    
    _startNewGame();
  }

  // 浮动文字提示
  final List<_FloatingText> _floatingTexts = [];

  void _addFloatingText(String text, Color color) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _floatingTexts.add(_FloatingText(id: id, text: text, color: color));
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _floatingTexts.removeWhere((item) => item.id == id);
        });
      }
    });
  }

  void _updateGoldWithAnimation(int targetGold) {
    if (!mounted || _goldAnimController == null) {
      setState(() {
        _displayedGold = targetGold;
      });
      return;
    }
    
    _goldAnimation = IntTween(begin: _displayedGold, end: targetGold)
        .animate(CurvedAnimation(parent: _goldAnimController!, curve: Curves.easeOutCubic))
      ..addListener(() {
        if (mounted) {
          setState(() {
            _displayedGold = _goldAnimation?.value ?? targetGold;
          });
        }
      });
    _goldAnimController!.forward(from: 0.0);
  }

  void _startNewGame() {
    setState(() {
      _isBetting = true;
      _isGameOver = false;
      _isDealerRevealing = false;
      _gameResult = "";
      _extraBetCount = 0;
      _multiplier = 1.0;
      _playerCards = [_drawRandomCard()];
      _dealerCards = [];
    });
  }

  String _drawRandomCard() {
    final ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];
    return ranks[_random.nextInt(ranks.length)];
  }

  int _calculatePoints(List<String> cards) {
    int points = 0;
    int aceCount = 0;

    for (var card in cards) {
      if (card == 'A') {
        aceCount++;
        points += 11;
      } else if (['J', 'Q', 'K'].contains(card)) {
        points += 10;
      } else {
        points += int.parse(card);
      }
    }

    while (points > 21 && aceCount > 0) {
      points -= 10;
      aceCount--;
    }

    return points;
  }

  int get _totalBet => _baseBet + _extraBetCount * 20;

  void _addBet() {
    if (_extraBetCount < 10) {
      setState(() {
        _extraBetCount++;
      });
    }
  }

  void _addMultiplier() {
    if (_multiplier < 2.0) {
      setState(() {
        _multiplier = double.parse((_multiplier + 0.1).toStringAsFixed(1));
      });
    }
  }

  // 状态提示相关
  String? _statusTip;
  Color? _statusTipColor;
  Timer? _statusTipTimer;

  void _showStatusTip(String message, Color color) {
    _statusTipTimer?.cancel();
    setState(() {
      _statusTip = message;
      _statusTipColor = color;
    });
    _statusTipTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _statusTip = null;
        });
      }
    });
  }

  void _confirmBet() {
    setState(() {
      _isBetting = false;
    });
  }

  void _playerStand() async {
    setState(() {
      _isDealerRevealing = true;
    });

    // 敌方摸牌 AI 逻辑
    while (true) {
      int currentPoints = _calculatePoints(_dealerCards);
      bool shouldHit = false;

      if (currentPoints < 12) {
        shouldHit = true;
      } else if (currentPoints < 14) {
        shouldHit = _random.nextDouble() < 0.50;
      } else if (currentPoints < 16) {
        shouldHit = _random.nextDouble() < 0.20;
      } else if (currentPoints < 18) {
        shouldHit = _random.nextDouble() < 0.10;
      } else if (currentPoints < 20) {
        shouldHit = _random.nextDouble() < 0.05;
      } else {
        // 等于 21 或 大于 21 (爆牌) 时停止
        shouldHit = false;
      }

      if (!shouldHit) break;

      // 执行摸牌
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        _dealerCards.add(_drawRandomCard());
      });

      // 如果摸完牌已经爆牌了，直接退出循环
      if (_calculatePoints(_dealerCards) >= 21) break;
    }

    // 等待最后一张牌展示一会儿再结算
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    int playerPoints = _calculatePoints(_playerCards);
    int dealerPoints = _calculatePoints(_dealerCards);

    setState(() {
      _isDealerRevealing = false;
    });

    if (dealerPoints > 21) {
      _endGame("对方爆牌！你赢了", Colors.greenAccent, true);
    } else if (playerPoints > dealerPoints) {
      _endGame("点数领先！你赢了", Colors.greenAccent, true);
    } else if (playerPoints < dealerPoints) {
      _endGame("点数落后！你输了", Colors.redAccent, false);
    } else {
      // 平局现在获得 100% 加注的金币（即 finalBet）
      _endGame("平局！全额退款！", Colors.amberAccent, true);
    }
  }

  void _endGame(String msg, Color color, bool? isWin, {bool isFold = false}) {
    setState(() {
      _isGameOver = true;
      _gameResult = msg;
      _resultColor = color;
      
      int goldChange = 0;
      // 倍率在结算时触发
      final int finalBet = (_totalBet * _multiplier).round();

      if (isFold) {
        goldChange = -(finalBet / 2).round();
      } else if (isWin == true) {
        goldChange = finalBet;
      } else if (isWin == false) {
        goldChange = -finalBet;
      }

      GameState.playerGold += goldChange;
      _updateGoldWithAnimation(GameState.playerGold);
      if (goldChange != 0) {
        _addFloatingText(
          goldChange > 0 ? "+$goldChange" : "$goldChange",
          goldChange > 0 ? Colors.amberAccent : Colors.redAccent,
        );
      }

      // 记录本次博弈
      if (isWin == true) {
        GameStatistics.totalBattlesWon++;
      }

      // 弹出结果对话框
      _showResultDialog(msg, color, goldChange);

      // 负债处罚逻辑
      if (GameState.playerGold < 0) {
        GameState.playerHp = (GameState.playerHp - 10).clamp(0, GameState.playerMaxHp);
        
        _showStatusTip("债务逾期，系统强制扣除生命值", Colors.redAccent);
        
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            GameProgress.markDefeated(widget.level.id);
            Navigator.pushReplacement(context, createHoloRoute(const MapScreen(canSelect: true)));
          }
        });
      }
    });
  }

  void _showResultDialog(String msg, Color color, int goldChange) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "GameResult",
      barrierColor: Colors.black.withValues(alpha: 0.8),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return Center(
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            child: FadeTransition(
              opacity: anim1,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D1117),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "TERMINAL_REPORT",
                          style: TextStyle(
                            color: color.withValues(alpha: 0.5),
                            fontSize: 10,
                            fontFamily: 'monospace',
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          msg,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: color,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            shadows: [
                              Shadow(color: color.withValues(alpha: 0.5), blurRadius: 10),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.05),
                            border: Border.all(color: color.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "CREDITS: ",
                                style: TextStyle(
                                  color: color.withValues(alpha: 0.7),
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Text(
                                goldChange >= 0 ? "+$goldChange" : "$goldChange",
                                style: TextStyle(
                                  color: goldChange >= 0 ? Colors.amber : Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: _actionButton(
                                "退出协议",
                                Colors.white.withValues(alpha: 0.5),
                                () {
                                  Navigator.pop(ctx);
                                  _exitCasino();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _actionButton(
                                "重启博弈",
                                color,
                                () {
                                  Navigator.pop(ctx);
                                  _startNewGame();
                                },
                                isPrimary: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _exitCasino() async {
    final themeColor = GameState.getThemeColor();
    if (await showCyberConfirmExit(
      context,
      color: themeColor,
      title: "系统中断协议",
      content: "检测到强制退出请求。当前博弈周期尚未结算，中断将导致所有未保存的数据丢失。确认要执行强制关机吗？",
      cancelLabel: "返回博弈",
      confirmLabel: "强制关机",
    )) {
      GameProgress.markDefeated(widget.level.id);
      if (mounted) {
        Navigator.pushReplacement(context, createHoloRoute(const MapScreen(canSelect: true)));
      }
    }
  }

  @override
  void dispose() {
    _statusTipTimer?.cancel();
    _goldAnimController?.dispose();
    super.dispose();
  }

  void _playerHit() {
    setState(() {
      _playerCards.add(_drawRandomCard());
      if (_calculatePoints(_playerCards) > 21) {
        _endGame("爆牌！你输了", Colors.redAccent, false);
      }
    });
  }

  Widget _buildStatusTip() {
    if (_statusTip == null) return const SizedBox.shrink();
    final color = _statusTipColor ?? Colors.cyanAccent;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F16).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Text(
          _statusTip!,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = GameState.getThemeColor();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _exitCasino();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF05060A),
        body: Stack(
          children: [
            // 背景层
            Positioned.fill(
              child: CustomPaint(
                painter: CyberGridPainter(color: themeColor, opacity: 0.05),
              ),
            ),
            
            // 扫描线装饰
            Positioned.fill(child: CyberScanline(color: themeColor.withValues(alpha: 0.3))),
            Positioned.fill(child: CyberScanline(color: themeColor.withValues(alpha: 0.1), isGlitch: true)),
            
            SafeArea(
              child: Column(
                children: [
                  // 顶部状态栏
                  _buildHeader(themeColor),
                  
                  Expanded(
                    child: Stack(
                      children: [
                        // 背景装饰：斜线
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.02,
                            child: CustomPaint(
                              painter: CyberBattleGridPainter(pulses: [], gridColor: themeColor),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 对方区域
                              _buildDealerArea(themeColor),
                              
                              const Spacer(),
                              
                              // 玩家区域
                              _buildPlayerArea(themeColor),
                            ],
                          ),
                        ),
                        // 居中显示的提示
                        _buildStatusTip(),
                      ],
                    ),
                  ),
                  
                  // 底部操作栏
                  _buildControls(themeColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color themeColor) {
    return Container(
      height: 90,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // HUD 背景装饰
          Positioned.fill(
            child: CustomPaint(
              painter: CyberHUDPainter(color: themeColor),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 14,
                          decoration: BoxDecoration(
                            color: themeColor,
                            boxShadow: [
                              BoxShadow(color: themeColor.withValues(alpha: 0.5), blurRadius: 4),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "SYSTEM_ACCESS: 0x4F2A",
                          style: TextStyle(
                            color: themeColor.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontFamily: 'monospace',
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "暗网博弈协议 v2.4",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(color: themeColor.withValues(alpha: 0.8), blurRadius: 10),
                          Shadow(color: Colors.white.withValues(alpha: 0.2), blurRadius: 2),
                        ],
                      ),
                    ),
                  ],
                ),
                // 金币显示区域 - 更加科幻的样式
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF05060A).withValues(alpha: 0.8),
                    border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.5), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.shade700.withValues(alpha: 0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.monetization_on, color: Colors.amber.shade700, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        "$_displayedGold",
                        style: TextStyle(
                          color: Colors.amber.shade400,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          shadows: [
                            Shadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 浮动文字显示层
          ..._floatingTexts.map((ft) => _buildFloatingText(ft)),
        ],
      ),
    );
  }

  Widget _buildFloatingText(_FloatingText ft) {
    return Positioned(
      top: 20,
      right: 20,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 1500),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutExpo,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, -40 * value),
            child: Opacity(
              opacity: (1 - value).clamp(0.0, 1.0),
              child: Text(
                ft.text,
                style: TextStyle(
                  color: ft.color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  shadows: [
                    Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 2, offset: const Offset(1, 1)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDealerArea(Color themeColor) {
    final points = _calculatePoints(_dealerCards);
    final isHidden = !_isDealerRevealing && !_isGameOver;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
              ),
              child: Text(
                "DEALER_CORE",
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontSize: 10,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (!isHidden)
              Text(
                "SCORE: $points",
                style: TextStyle(
                  color: points > 21 ? Colors.red : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 120,
          child: _dealerCards.isEmpty 
            ? _buildEmptyCardSlot(themeColor)
            : Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _dealerCards.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final card = entry.value;
                      final isFaceDown = isHidden && idx > 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _buildCyberCard(card, isFaceDown, Colors.red.shade400),
                      );
                    }).toList(),
                  ),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildPlayerArea(Color themeColor) {
    final points = _calculatePoints(_playerCards);
    
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _playerCards.map((card) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _buildCyberCard(card, false, themeColor),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.1),
                border: Border.all(color: themeColor.withValues(alpha: 0.5)),
              ),
              child: Text(
                "USER_NODE",
                style: TextStyle(
                  color: themeColor,
                  fontSize: 10,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "SCORE: $points",
              style: TextStyle(
                color: points > 21 ? Colors.red : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyCardSlot(Color themeColor) {
    return Container(
      width: 80,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: Center(
        child: Icon(Icons.qr_code_scanner, color: Colors.white.withValues(alpha: 0.1), size: 30),
      ),
    );
  }

  Widget _buildCyberCard(String rank, bool isFaceDown, Color themeColor) {
    return Container(
      width: 80,
      height: 110,
      decoration: BoxDecoration(
        color: isFaceDown ? const Color(0xFF1A1F26) : const Color(0xFF0D1117),
        border: Border.all(
          color: isFaceDown ? Colors.white.withValues(alpha: 0.2) : themeColor.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          if (!isFaceDown)
            BoxShadow(color: themeColor.withValues(alpha: 0.3), blurRadius: 12, spreadRadius: 1),
        ],
      ),
      child: Stack(
        children: [
          // 卡牌背景装饰线
          if (!isFaceDown)
            Positioned.fill(
              child: CustomPaint(
                painter: _CardTechDecorationPainter(color: themeColor.withValues(alpha: 0.2)),
              ),
            ),
            
          if (isFaceDown)
            Positioned.fill(
              child: CustomPaint(
                painter: CyberGridPainter(color: Colors.white, opacity: 0.1),
              ),
            )
          else ...[
            Positioned(
              top: 8,
              left: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rank,
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      height: 1,
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 2,
                    margin: const EdgeInsets.only(top: 2),
                    color: themeColor.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 0.05,
                    child: Icon(Icons.memory, color: themeColor, size: 50),
                  ),
                  Text(
                    rank,
                    style: TextStyle(
                      color: themeColor.withValues(alpha: 0.1),
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Transform.rotate(
                angle: pi,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rank,
                      style: TextStyle(
                        color: themeColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        height: 1,
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 2,
                      margin: const EdgeInsets.only(top: 2),
                      color: themeColor.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControls(Color themeColor) {
    final bool canAction = !_isGameOver && !_isDealerRevealing && !_isBetting;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF05060A).withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: themeColor.withValues(alpha: 0.4), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 状态提示条
          if (!_isDealerRevealing)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _isGameOver ? _resultColor : themeColor, 
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (_isGameOver) BoxShadow(color: _resultColor.withValues(alpha: 0.5), blurRadius: 4),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isGameOver 
                      ? "SESSION_RESULT: $_gameResult"
                      : (_isBetting ? "等待初始化协议..." : "等待用户指令..."),
                    style: TextStyle(
                      color: (_isGameOver ? _resultColor : themeColor).withValues(alpha: 0.7),
                      fontSize: 10,
                      fontFamily: 'monospace',
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // 显示当前赌注
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.05),
                        border: Border.all(color: themeColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("PROTOCOL_STAKE", style: TextStyle(color: themeColor.withValues(alpha: 0.5), fontSize: 8, fontFamily: 'monospace')),
                              Text("$_totalBet CREDITS", style: TextStyle(color: themeColor, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("RISK_FACTOR", style: TextStyle(color: themeColor.withValues(alpha: 0.5), fontSize: 8, fontFamily: 'monospace')),
                              Text("x${_multiplier.toStringAsFixed(1)}", style: TextStyle(color: Colors.purple.shade300, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _actionButton(
                      "要牌 (HIT)",
                      themeColor,
                      canAction ? _playerHit : null,
                      icon: Icons.add_circle_outline,
                      isPrimary: true,
                    ),
                    const SizedBox(height: 12),
                    _actionButton(
                      "停牌 (STAND)",
                      Colors.blue.shade400,
                      canAction ? _playerStand : null,
                      icon: Icons.front_hand_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _betAdjustButton(
                      "增加筹码",
                      Icons.keyboard_double_arrow_up,
                      _addBet,
                      Colors.amber.shade600,
                      enabled: _isBetting && _extraBetCount < 10,
                    ),
                    const SizedBox(height: 12),
                    _betAdjustButton(
                      "倍率系数",
                      Icons.bolt,
                      _addMultiplier,
                      Colors.purple.shade400,
                      enabled: _isBetting && _multiplier < 2.0,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isBetting)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _actionButton("初始化博弈开始", themeColor, _confirmBet, isPrimary: true),
            ),
        ],
      ),
    );
  }

  Widget _actionButton(
    String label,
    Color color,
    VoidCallback? onTap, {
    IconData? icon,
    bool isPrimary = false,
  }) {
    final enabled = onTap != null;
    bool isPressed = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTapDown: (_) => enabled ? setState(() => isPressed = true) : null,
          onTapUp: (_) => enabled ? setState(() => isPressed = false) : null,
          onTapCancel: () => enabled ? setState(() => isPressed = false) : null,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            transform: Matrix4.identity()..scale(isPressed ? 0.96 : 1.0),
            child: Opacity(
              opacity: enabled ? 1.0 : 0.4,
              child: CustomPaint(
                painter: CyberPanelPainter(color: color, isPrimary: isPrimary),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: isPrimary ? color : Colors.white70, size: 16),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          color: isPrimary ? color : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          letterSpacing: 2,
                          shadows: [
                            if (isPrimary) Shadow(color: color.withValues(alpha: 0.5), blurRadius: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _betAdjustButton(String label, IconData icon, VoidCallback onTap, Color color, {bool enabled = true}) {
    bool isPressed = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTapDown: (_) => enabled ? setState(() => isPressed = true) : null,
          onTapUp: (_) => enabled ? setState(() => isPressed = false) : null,
          onTapCancel: () => enabled ? setState(() => isPressed = false) : null,
          onTap: enabled ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            transform: Matrix4.identity()..scale(isPressed ? 0.92 : 1.0),
            child: Opacity(
              opacity: enabled ? 1.0 : 0.3,
              child: CustomPaint(
                painter: CyberPanelPainter(color: color, isPrimary: false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: color, size: 16),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label == "增加筹码" ? "$_extraBetCount/10" : "${_multiplier.toStringAsFixed(1)}x",
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FloatingText {
  final String id;
  final String text;
  final Color color;

  _FloatingText({required this.id, required this.text, required this.color});
}

// --- 科幻风格 Painter ---

class CyberHUDPainter extends CustomPainter {
  final Color color;
  CyberHUDPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    const double cutSize = 15.0;

    // 绘制主形状（带切角的 HUD 面板）
    path.moveTo(cutSize, 0);
    path.lineTo(size.width - cutSize, 0);
    path.lineTo(size.width, cutSize);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, cutSize);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    // 绘制顶部装饰线条
    final decoPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 2.0;
    
    canvas.drawLine(const Offset(cutSize, 0), Offset(cutSize + 40, 0), decoPaint);
    canvas.drawLine(Offset(size.width - cutSize - 40, 0), Offset(size.width - cutSize, 0), decoPaint);

    // 绘制角部装饰
    final cornerPaint = Paint()
      ..color = color
      ..strokeWidth = 3.0;
    
    canvas.drawLine(const Offset(0, cutSize), const Offset(0, cutSize + 10), cornerPaint);
    canvas.drawLine(Offset(size.width, cutSize), Offset(size.width, cutSize + 10), cornerPaint);
    
    // 绘制内部细网格
    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;
    
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 10) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 卡牌科技感装饰绘制器
class _CardTechDecorationPainter extends CustomPainter {
  final Color color;
  _CardTechDecorationPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 绘制四个角的装饰线
    const cornerSize = 15.0;
    
    // 左上
    canvas.drawLine(const Offset(cornerSize, 5), const Offset(5, 5), paint);
    canvas.drawLine(const Offset(5, 5), const Offset(5, cornerSize), paint);
    
    // 右下
    canvas.drawLine(Offset(size.width - cornerSize, size.height - 5), Offset(size.width - 5, size.height - 5), paint);
    canvas.drawLine(Offset(size.width - 5, size.height - 5), Offset(size.width - 5, size.height - cornerSize), paint);

    // 绘制中间的横线
    canvas.drawLine(Offset(10, size.height * 0.3), Offset(20, size.height * 0.3), paint);
    canvas.drawLine(Offset(size.width - 20, size.height * 0.7), Offset(size.width - 10, size.height * 0.7), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CyberPanelPainter extends CustomPainter {
  final Color color;
  final bool isPrimary;
  CyberPanelPainter({required this.color, this.isPrimary = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isPrimary ? color.withValues(alpha: 0.08) : const Color(0xFF0D1117)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color.withValues(alpha: isPrimary ? 0.6 : 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isPrimary ? 1.5 : 1.0;

    final path = Path();
    const double cut = 10.0;

    // 对角切角面板
    path.moveTo(cut, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - cut);
    path.lineTo(size.width - cut, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, cut);
    path.close();

    if (isPrimary) {
      // 绘制外发光
      canvas.drawPath(path, Paint()
        ..color = color.withValues(alpha: 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8));
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    // 装饰小点
    final dotPaint = Paint()..color = color.withValues(alpha: 0.5);
    canvas.drawCircle(const Offset(4, 4), 1, dotPaint);
    canvas.drawCircle(Offset(size.width - 4, size.height - 4), 1, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

