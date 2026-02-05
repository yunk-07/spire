// 作用：集中缓存关键锚点坐标，减少重复的坐标查询与布局依赖
import 'package:flutter/material.dart';

class AnchorCache with ChangeNotifier {
  final Map<String, Offset> _anchors = {};

  void set(String id, Offset pos) {
    _anchors[id] = pos;
    notifyListeners();
  }

  Offset? get(String id) => _anchors[id];

  void remove(String id) {
    _anchors.remove(id);
    notifyListeners();
  }

  void clear() {
    _anchors.clear();
    notifyListeners();
  }
}
