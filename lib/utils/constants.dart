import 'dart:io';

import 'package:flutter/material.dart';
import 'package:localbooru/utils/platform_tools.dart';

final Map<String, dynamic> settingsDefaults = {
    "grid_size": 4,
    "page_size": isDestkop() ? 54 : 32,
    "monet": Platform.isAndroid ? true : false,
    "theme": "system",
    "autotag_accuracy": 0.15,
};

final Map<String, dynamic> defaultFileInfoJson  = {
    "files": [],
    "specificTags": {}
};

// final Map<String, Color> specificTagsColors = {
//     "generic": Colors.blueAccent,
//     "artist": Colors.yellowAccent,
//     "character": Colors.greenAccent,
//     "copyright": Colors.deepPurpleAccent,
//     "species": Colors.pinkAccent,
// };

class SpecificTagsColors {
    static const generic = Colors.blueAccent;
    static const artist = Colors.yellowAccent;
    static const character = Colors.greenAccent;
    static const copyright = Colors.deepPurpleAccent;
    static const species = Colors.pinkAccent;

    Color getColor(String type) {
        if(type == "artist") return artist;
        if(type == "character") return character;
        if(type == "copyright") return copyright;
        if(type == "species") return species;
        return generic;
    }
}