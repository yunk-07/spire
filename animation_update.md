# 卡牌动画更新说明

## 更新概述
已成功删除原先的发牌动画以及弃牌动画，改为卡牌在扫描带下扫描逐渐显现和消失。

## 主要修改内容

### 1. 移除原有的发牌动画
- 删除了 `drawCards` 方法中的 `anim.playCardMotion` 调用
- 删除了 `_randomDrawCards` 方法中的 `anim.playCardMotion` 调用

### 2. 移除原有的弃牌动画
- 删除了 `endTurn` 方法中的 `anim.playCardMotion` 调用
- 删除了 `completeDiscardPhase` 方法中的 `anim.playCardMotion` 调用

### 3. 保留扫描带动画实现
- 保留了 `_cardView` 方法中的扫描带动画 UI 实现
- 保留了 `_cardAnimationControllers` 动画控制器管理
- 保留了 `dispose` 方法中的控制器释放逻辑

## 技术细节

### 动画原理
扫描带动画通过控制一个覆盖在卡牌上的渐变遮罩的高度来实现卡牌的逐渐显示/隐藏效果。当 heightFactor 从 0 变化到 1 时，遮罩逐渐向上移动，卡牌逐渐显示出来；当 heightFactor 从 1 变化到 0 时，遮罩逐渐向下移动，卡牌逐渐隐藏起来。

### 性能优化
- 每个卡牌使用独立的动画控制器，确保动画的独立性和流畅性
- 在动画结束后及时释放控制器，避免内存泄漏
- 使用 TickerProviderStateMixin 提供高效的动画帧回调

## 运行效果
应用已成功启动，可通过 http://localhost:8080 访问并测试动画效果。在游戏过程中，摸牌和弃牌操作都会显示扫描带动画，提升了游戏的视觉体验。