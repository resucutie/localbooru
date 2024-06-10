library preset;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:localbooru/api/index.dart';
import 'package:html/parser.dart' show parse;
import 'package:localbooru/utils/get_meta_property.dart';
import 'package:localbooru/utils/get_website.dart';
import 'package:mime/mime.dart';
import 'package:string_validator/string_validator.dart';

part 'autodownload/image_boards.dart';
part 'autodownload/generic.dart';
part 'autodownload/art_directed.dart';
part 'autodownload/other.dart';

final presetCache = DefaultCacheManager();

class PresetImage {
    const PresetImage({this.image, this.tags, this.sources, this.replaceID, this.rating, this.relatedImages});

    final File? image;
    final Map<String, List<String>>? tags;
    final List<String>? sources;
    final Rating? rating;
    final ImageID? replaceID;
    final List<ImageID>? relatedImages;

    static Future<PresetImage> fromExistingImage(BooruImage image) async {
        final Booru booru = await getCurrentBooru();
        
        return PresetImage(
            image: File(image.path),
            sources: image.sources,
            tags: await booru.separateTagsByType(image.tags.split(" ")),
            rating: image.rating,
            replaceID: image.id,
            relatedImages: image.relatedImages
        );
    }

    static Future<PresetImage> urlToPreset(String url) async {
        if(await File(url).exists()) return PresetImage(image: File(url));
        
        if(!isURL(url)) throw "Not a URL";

        Uri uri = Uri.parse(url);
        final preset = switch (getWebsiteByURL(uri)) {
            ServiceWebsites.danbooru1 => await danbooru1ToPreset(url),
            ServiceWebsites.danbooru2 => await danbooru2ToPreset(url),
            ServiceWebsites.e621 => await e621ToPreset(url),
            ServiceWebsites.gelbooru020 || ServiceWebsites.gelbooru025 => await gelbooruToPreset(url),
            ServiceWebsites.twitter => await twitterToPreset(url),
            ServiceWebsites.furAffinity => await furaffinityToPreset(url),
            ServiceWebsites.deviantArt => await deviantartToPreset(url),
            // Websites.instagram => await instagramToPreset(url),
            _ => await anyURLToPreset(url)
        };
        return preset;
    }
}