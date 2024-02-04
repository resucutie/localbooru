

import 'dart:io';

bool isDestkop () {
    return Platform.isLinux || Platform.isMacOS || Platform.isWindows;
}

bool isMobile () {
    return Platform.isAndroid || Platform.isIOS;
}