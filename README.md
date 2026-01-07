# 摸牌扫描带效果实现说明

## 功能实现

### 1. 扫描带覆盖整个卡牌并按等级区分颜色
- 在`_cardView`方法中添加了`getScanColor`函数，根据卡牌等级返回不同颜色
- 实现了扫描网格背景和扫描线的Stack布局
- 扫描线使用LinearGradient实现渐变效果

### 2. 扫描完成后等待500ms再显示完整卡牌
- 修改了`_randomDrawCards`方法，在原有820ms延迟后增加了500ms延迟
- 将`_dealingCards.remove(cid)`及动画控制器释放逻辑包裹在新的Future.delayed中

### 3. 扫描完成的特写动画
- 修改了`_cardWidget`方法，添加了`showCompleteAnimation`参数
- 实现了TweenAnimationBuilder的缩放动画，从1.5倍缩放到1.0倍，使用Curves.bounceOut曲线

## 代码结构

### GridPainter类
- 自定义绘制类，用于绘制扫描网格背景
- 实现了水平和垂直网格线的绘制
- 支持半透明效果

### getScanColor函数
- 根据卡牌等级返回不同颜色
- Lv1: 绿色
- Lv2: 蓝色
- Lv3: 紫色
- Lv4: 橙色
- Lv5: 红色

### 扫描带动画实现
- 使用AnimatedBuilder和ClipRect实现高度变化的扫描效果
- 扫描线从顶部到底部移动，覆盖整个卡牌
- 扫描网格背景随扫描线移动

## 使用说明

在游戏中，当玩家抽牌时，会触发扫描带动画：
1. 卡牌从牌堆中飞出
2. 扫描线从顶部到底部扫描卡牌
3. 扫描完成后等待500ms
4. 显示完整卡牌并播放特写动画

## 注意事项

- 确保Flutter SDK版本>=3.0.0
- 确保所有依赖包已正确安装
- 动画效果可能会影响性能，建议在高性能设备上运行
