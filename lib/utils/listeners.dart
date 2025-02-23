import 'package:flutter/material.dart';

class AcessibleNotifyListenerNotifier with ChangeNotifier {
    void update() {
        notifyListeners();
    }
}

class BooruUpdateListener with ChangeNotifier {
    void update() {
        notifyListeners();
        counterListener.update();
    }
}
BooruUpdateListener booruUpdateListener = BooruUpdateListener();

AcessibleNotifyListenerNotifier themeListener = AcessibleNotifyListenerNotifier();

AcessibleNotifyListenerNotifier counterListener = AcessibleNotifyListenerNotifier();

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