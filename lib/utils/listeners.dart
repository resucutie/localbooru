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
    double progress = 0;

    void updateImportStatus({
        bool? import,
        double? progress
    }) {
        if(import != null) isImporting = import;
        if(progress != null) this.progress = progress;
        notifyListeners();
    }

    void clear() {
        updateImportStatus(
            import: false,
            progress: 0,
        );
    }
}
ImportListener importListener = ImportListener();