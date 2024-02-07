import 'package:localbooru/utils/platform_tools.dart';

final Map<String, dynamic> settingsDefaults = {
    "grid_size": 4,
    "page_size": isDestkop() ? 54 : 32
};