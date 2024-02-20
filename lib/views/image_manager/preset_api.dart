import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:localbooru/api/index.dart';

final cache = DefaultCacheManager();


class PresetImage {
    const PresetImage({this.image, this.tags, this.sources, this.replaceID});

    final File? image;
    final Map<String, List<String>>? tags;
    final List<String>? sources;
    final String? replaceID;

    static Future<PresetImage> fromExistingImage(BooruImage image) async {
        final Booru booru = await getCurrentBooru();
        
        return PresetImage(
            image: File(image.path),
            sources: image.sources,
            tags: await booru.separateTagsByType(image.tags.split(" ")),
            replaceID: image.id
        );
    }
}

Future<PresetImage> urlToPreset(String url) {
    Uri uri = Uri.parse(url);
    if(uri.host.endsWith("donmai.us")) return danbooruToPreset(url);
    if(uri.host.endsWith("e621.net") || uri.host.endsWith("e926.net")) return e621ToPreset(url);
    throw "Unknown URL";
}

Future<PresetImage> danbooruToPreset(String url) async {
    Uri uri = Uri.parse(url);
    Uri fetchUrl = Uri.parse("${[uri.origin, uri.path].join("/")}.json");
    final res = await http.get(fetchUrl);
    final bodyRes = jsonDecode(res.body);

    final downloadedFileInfo = await cache.downloadFile(bodyRes["file_url"]);

    return PresetImage(
        image: downloadedFileInfo.file,
        sources: [bodyRes["source"], [uri.origin, uri.path].join("")],
        tags: {
            "generic": bodyRes["tag_string_general"].split(" "),
            "artist": bodyRes["tag_string_artist"].split(" "),
            "character": bodyRes["tag_string_character"].split(" "),
            "copyright": bodyRes["tag_string_copyright"].split(" "),
        }
    );
}

Future<PresetImage> e621ToPreset(String url) async {
    Uri uri = Uri.parse(url);
    Uri fetchUrl = Uri.parse("${[uri.origin, uri.path].join("/")}.json");
    final res = await http.get(fetchUrl);
    final postRes = jsonDecode(res.body)["post"];

    final downloadedFileInfo = await cache.downloadFile(postRes["file"]["url"]);

    return PresetImage(
        image: downloadedFileInfo.file,
        sources: [...(postRes["sources"] ?? []), [uri.origin, uri.path].join("")],
        tags: {
            "generic": List<String>.from(postRes["tags"]["general"]),
            "artist": List<String>.from(postRes["tags"]["artist"]),
            "character": List<String>.from(postRes["tags"]["character"]),
            "copyright": List<String>.from(postRes["tags"]["copyright"]),
            "species": List<String>.from(postRes["tags"]["species"]),
        }
    );
}