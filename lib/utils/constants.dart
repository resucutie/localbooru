import 'dart:io';

import 'package:flutter/material.dart';
import 'package:localbooru/utils/platform_tools.dart';
import 'package:super_clipboard/super_clipboard.dart';

final Map<String, dynamic> settingsDefaults = {
    "grid_size": 4,
    "page_size": isDestkop() ? 54 : 32,
    "monet": Platform.isAndroid ? true : false,
    "theme": "system",
    "autotag_accuracy": 0.15,
    "thumbnail_quality": 2.0,
    "update": true,
    "gif_video": false,
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

class SuperFormats {
    static const List<SimpleFileFormat> imageStaticOnly = [Formats.png, Formats.jpeg, Formats.bmp, Formats.webp];
    static const List<SimpleFileFormat> image = [...imageStaticOnly, Formats.gif];
    static const List<SimpleFileFormat> video = [Formats.mp4, Formats.webm, Formats.mpeg, Formats.mov, Formats.mkv];
    static const List<SimpleFileFormat> all = [...image, ...video];

    static SimpleFileFormat? getFormatFromFileExtension(String extension) {
        if(extension.startsWith(".")) extension = extension.substring(1);
        return switch(extension) {
            "png" => Formats.png,
            "jpeg" || "jpg" => Formats.jpeg,
            "bmp" => Formats.bmp,
            "webp" => Formats.webp,
            "gif" => Formats.gif,
            "mp4" => Formats.mp4,
            "webm" => Formats.webm,
            "mpeg" => Formats.mpeg,
            "mov" => Formats.mov,
            "mkv" => Formats.mkv,
            _ => null
        };
    }
}