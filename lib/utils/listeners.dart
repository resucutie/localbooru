import 'package:flutter/material.dart';

class BooruUpdateListener with ChangeNotifier {
    void update() {
        notifyListeners();
    }
}
BooruUpdateListener booruUpdateListener = BooruUpdateListener();

class ThemeListener with ChangeNotifier {
    void update() {
        notifyListeners();
    }
}
ThemeListener themeListener = ThemeListener();