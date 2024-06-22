library preset;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/svg.dart';
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:localbooru/api/index.dart';
import 'package:html/parser.dart' show parse;
import 'package:localbooru/utils/get_meta_property.dart';
import 'package:mime/mime.dart';
import 'package:string_validator/string_validator.dart';

part 'autodownload/image_boards.dart';
part 'autodownload/generic.dart';
part 'autodownload/art_directed.dart';
part 'autodownload/other.dart';
part 'getter/index.dart';
part 'getter/accurate.dart';

final presetCache = DefaultCacheManager();


// presets are essentially a format that represents a BooruImage before it gets added
class PresetImage {
    PresetImage({this.image, this.tags, this.sources, this.replaceID, this.rating, this.relatedImages, this.uniqueKey});

    File? image;
    Map<String, List<String>>? tags;
    List<String>? sources;
    Rating? rating;
    ImageID? replaceID;
    List<ImageID>? relatedImages;

    UniqueKey? uniqueKey;

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

    static Future<PresetImage> urlToPreset(String url, {bool? accurate}) async {
        if(await File(url).exists()) return PresetImage(image: File(url));
        
        if(!isURL(url)) throw "Not a URL";

        Uri uri = Uri.parse(url);

        Websites? website;
        if(accurate == true) website = await accurateGetWebsite(uri);
        else website = getWebsiteByURL(uri);

        final preset = switch (website) {
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