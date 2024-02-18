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

final Map<String, dynamic> defaultFileInfoJson = {
    "files": [],
    "specificTags": {
        "artist": [ // general tags
            "unknown_artist",
            "anonymous_artist",
            "third-party_edit",
            "artist_name"
        ],
        "character": [ // fun fact: there's WAY TOO MANY posts on e6 about mlp characters https://e621.net/tags?commit=Search&search%5Bcategory%5D=4&search%5Bhide_empty%5D=1&search%5Border%5D=count
            "fan_character"
        ],
        "copyright": [ // basic copyright tags
            "nintendo",
            "pokemon",
            "pokemon_(game)",
            "animal_crossing",
            "hasbro",
            "disney",
            "sega",
            "bandai_namco",
        ],
        "species": [ // some species tags
            "pokemon_(creature)",
            "pokemon_(species)",
            "humanoid",
            "mammal",
            "canid",
            "equid",
            "fox",
            "feline"
            "dragon"
            "wolf"
            "reptile"
        ]
    }
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
    static const artist = Color(0xFFFFC800);
    static const character = Color(0xFF56C58F);
    static const copyright = Colors.purpleAccent;
    static const species = Colors.redAccent;

    static Color getColor(String type) {
        if(type == "artist") return artist;
        if(type == "character") return character;
        if(type == "copyright") return copyright;
        if(type == "species") return species;
        return generic;
    }
}