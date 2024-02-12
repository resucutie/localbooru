import 'dart:io';

import 'package:localbooru/utils/platform_tools.dart';

final Map<String, dynamic> settingsDefaults = {
    "grid_size": 4,
    "page_size": isDestkop() ? 54 : 32,
    "monet": Platform.isAndroid ? true : false,
    "theme": "system",
    "autotag_accuracy": 0.15,
};