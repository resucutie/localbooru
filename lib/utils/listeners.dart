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

class LockListener with ChangeNotifier {
    bool isLocked = false;

    void unlock() {
        isLocked = false;
        notifyListeners();
    }

    void lock() {
        isLocked = true;
        notifyListeners();
    }
}
LockListener lockListener = LockListener();

class ImportListener with ChangeNotifier {
    bool isImporting = false;

    void updateImportStatus(bool status) {
        isImporting = status;
        notifyListeners();
    }
}
ImportListener importListener = ImportListener();