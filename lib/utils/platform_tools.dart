

import 'dart:io';

bool isDesktop() {
    return Platform.isLinux || Platform.isMacOS || Platform.isWindows;
}

bool isMobile() {
    return Platform.isAndroid || Platform.isIOS;
}

bool isApple() {
    return Platform.isMacOS || Platform.isIOS;
}

bool hasWindowFrameNavigation() {
    return isDesktop();
}