## 网格动画时间设置说明

### 1. 跳转动画时间设置

在 `main.dart` 文件中，`createHoloRoute` 函数定义了网格动画的时间参数：

```dart
Route<T> createHoloRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 900),
    reverseTransitionDuration: const Duration(milliseconds: 700),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return _HoloGridOverlay(
        animation: curved,
        child: child,
      );
    },
  );
}
```

### 2. 参数说明

- **`transitionDuration`**：正向跳转动画时长（毫秒）
  - 当前值：900毫秒（0.9秒）
  - 影响：从当前页面跳转到新页面时的网格动画时长

- **`reverseTransitionDuration`**：反向跳转动画时长（毫秒）
  - 当前值：700毫秒（0.7秒）
  - 影响：从新页面返回原页面时的网格动画时长

### 3. 调节方法

要修改动画时间，只需调整这两个参数的值即可：

```dart
// 示例：将正向动画改为1秒，反向动画改为0.5秒
transitionDuration: const Duration(milliseconds: 1000),
reverseTransitionDuration: const Duration(milliseconds: 500),
```

### 4. 动画曲线

- **`Curves.easeOutCubic`**：正向动画曲线（先快后慢）
- **`Curves.easeInCubic`**：反向动画曲线（先慢后快）

你也可以根据需要修改动画曲线，例如：
- `Curves.linear`：线性动画
- `Curves.easeInOut`：先慢后快再慢
- `Curves.bounceInOut`：弹跳动画

### 5. 网格动画逻辑

网格动画的具体绘制逻辑在 `_HoloGridPainter` 类中实现，主要分为两个阶段：

1. **出现阶段（0-0.7秒）**：网格从顶部向下逐渐展开
2. **消失阶段（0.7-1.0秒）**：网格从底部向上逐渐消失

这种设计让动画看起来更加流畅自然。