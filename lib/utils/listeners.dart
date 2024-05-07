import 'package:flutter/material.dart';

class BooruUpdateListener with ChangeNotifier {
    void update() {
        notifyListeners();
        counterListener.update();
    }
}
BooruUpdateListener booruUpdateListener = BooruUpdateListener();

class ThemeListener with ChangeNotifier {
    void update() {
        notifyListeners();
    }
}
ThemeListener themeListener = ThemeListener();

class CounterListener with ChangeNotifier {
    void update() {
        notifyListeners();
    }
}
CounterListener counterListener = CounterListener();