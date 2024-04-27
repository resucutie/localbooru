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

final cache = DefaultCacheManager();


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
        final preset = switch (getWebsite(uri)) {
            "danbooru1" => await danbooru1ToPreset(url),
            "danbooru2" => await danbooru2ToPreset(url),
            "e621" => await e621ToPreset(url),
            "gelbooru2" => await gelbooruToPreset(url),
            "twitter" => await twitterToPreset(url),
            "furaffinity" => await furaffinityToPreset(url),
            "deviantart" => await deviantartToPreset(url),
            // "instagram" => await instagramToPreset(url),
            _ => await anyURLToPreset(url)
        };
        return preset;
    }
}

// danbooru 2: if you add .json at the end of the post url, it'll return the JSON of that post
Future<PresetImage> danbooru2ToPreset(String url) async {
    Uri uri = Uri.parse(url);
    final res = await http.get(Uri.parse("${[uri.origin, uri.path].join("/")}.json"));
    final bodyRes = jsonDecode(res.body);

    final downloadedFileInfo = await cache.downloadFile(bodyRes["file_url"]);

    return PresetImage(
        image: downloadedFileInfo.file,
        sources: [bodyRes["source"], [uri.origin, uri.path].join("")].whereType<String>().toList(),
        tags: {
            "generic": bodyRes["tag_string_general"].split(" "),
            "artist": bodyRes["tag_string_artist"].split(" "),
            "character": bodyRes["tag_string_character"].split(" "),
            "copyright": bodyRes["tag_string_copyright"].split(" "),
        }
    );
}

// danbooru 1/moebooru: you can ask danbooru to do a search with the id: meta-tag. for obtaining the tag types, only webcrawling
// as we cant obtain tag types in bulk, nor does post.json returns tag types in its response like danbooru 2
Future<PresetImage> danbooru1ToPreset(String url) async {
    Uri uri = Uri.parse(url);
    final postID = uri.pathSegments[2];
    final res = await http.get(Uri.parse("${[uri.origin, "post.json?tags=id:$postID"].join("/")}.json"));
    final post = jsonDecode(res.body)[0];

    final downloadedFileInfo = await cache.downloadFile(post["file_url"]);

    final webpage = await http.get(uri);
    final document = parse(webpage.body);

    final tagsElements = document.getElementsByClassName("tag-link");

    // sadly it doesn't have an api to obtain tag types, or i couldn't find one
    Map<String, List<String>> tagList = {
        "generic": [],
        "artist": [],
        "copyright": [],
        "character": [],
    };
    for (var tag in tagsElements) {
        final name = tag.attributes["data-name"];
        String type = tag.classes.last.substring("tag-type-".length);
        if(type == "general") type = "generic";
        if(name != null && tagList[type] != null) tagList[type]!.add(name);
    }

    return PresetImage(
        image: downloadedFileInfo.file,
        sources: [post["source"], [uri.origin, uri.path].join("")].whereType<String>().toList(),
        tags: {
            "generic": List<String>.from(tagList["generic"]!),
            "artist": List<String>.from(tagList["artist"]!),
            "character": List<String>.from(tagList["character"]!),
            "copyright": List<String>.from(tagList["copyright"]!),
        }
    );
}

// e926/e621: same idea as danbooru 2, if you add .json at the end of the post url, it'll return the JSON of that post
Future<PresetImage> e621ToPreset(String url) async {
    Uri uri = Uri.parse(url);
    final res = await http.get(Uri.parse("${[uri.origin, uri.path].join("/")}.json"));
    final postRes = jsonDecode(res.body)["post"];

    final downloadedFileInfo = await cache.downloadFile(postRes["file"]["url"]);

    return PresetImage(
        image: downloadedFileInfo.file,
        sources: [...((postRes["sources"] as List<String>?)?.where((e) => !e.startsWith("-")) ?? []), [uri.origin, uri.path].join("")],
        tags: {
            "generic": List<String>.from(postRes["tags"]["general"]),
            "artist": List<String>.from(postRes["tags"]["artist"]),
            "character": List<String>.from(postRes["tags"]["character"]),
            "copyright": List<String>.from(postRes["tags"]["copyright"]),
            "species": List<String>.from(postRes["tags"]["species"]),
        }
    );
}

final Map<int, String> gelbooruTagMap = {
    0: "generic",
    1: "artist",
    // 2: "unused",
    3: "copyright",
    4: "character",
    // 5: "metadata",
};
// wtf is this api
// gelbooru 2: for some reason everything works under index.php. we can filter for posts using the "s=post" and "id" query parameters.
// it is a weird system of post filtering ngl. 0.2.5 has an api to return tag types in bulk. on the other hand 0.2.0 doesn't include
// that api, and as such we need to webcrawl to obtain them
Future<PresetImage> gelbooruToPreset(String url) async {
    Uri uri = Uri.parse(url);
    final String imageID = uri.queryParameters["id"]!;

    final res = await http.get(Uri.parse([uri.origin, "index.php?page=dapi&s=post&q=index&json=1&id=$imageID"].join("/")));
    final json = jsonDecode(res.body);
    final bool is020 = json is List;
    final Map<String, dynamic> post = !is020 ? json["post"][0] : json[0]; // api differences, first one 0.2.5, second 0.2.0

    final String tags = post["tags"];

    Map<String, List<String>> tagList = {
        "generic": [],
        "artist": [],
        "copyright": [],
        "character": [],
    };
    String imageURL;
    if(is020) { // probably 0.2.0, grab html documents
        // sadly it doesn't have an api to obtain tag types, or i couldn't find one
        final webpage = await http.get(Uri.parse([uri.origin, "index.php?page=post&s=view&id=$imageID"].join("/")));
        final document = parse(webpage.body);

        final tagsElements = document.getElementsByClassName("tag");

        for (var tag in tagsElements) {
            final nameRedirectUri = Uri.parse(tag.children[0].attributes["href"]!);
            final name = nameRedirectUri.queryParameters["tags"] ?? nameRedirectUri.queryParameters["search"];
            String type = tag.classes.first.substring("tag-type-".length);
            if(type == "general") type = "generic";
            if(name != null && tagList[type] != null) tagList[type]!.add(name);
        }

        // nor images lmao
        final imageElement = document.getElementById("image");

        imageURL = imageElement!.attributes["src"]!;

    } else { // probably 0.2.5, use their api instead
        final tagTypesRes = await http.get(Uri.parse([uri.origin, "index.php?page=dapi&s=tag&q=index&json=1&names=$tags"].join("/")));
        
        final List<dynamic> tagTypes = jsonDecode(tagTypesRes.body)["tag"];

        for (var tag in tagTypes) {
            final type = gelbooruTagMap[tag["type"]];
            if(type != null) tagList[type]!.add(tag["name"]);
        }

        imageURL = post["file_url"];
    }

    final downloadedFileInfo = await cache.downloadFile(imageURL);

    return PresetImage(
        image: downloadedFileInfo.file,
        sources: [post["source"], [uri.origin, uri.path].join("")].whereType<String>().toList(),
        tags: {
            "generic": List<String>.from(tagList["generic"]!),
            "artist": List<String>.from(tagList["artist"]!),
            "character": List<String>.from(tagList["character"]!),
            "copyright": List<String>.from(tagList["copyright"]!),
        }
    );
}

// twitter: fxtwitter offers a url to give only the image. getting the artist is as easy as reading the first path segment
Future<PresetImage> twitterToPreset(String url) async {
    Uri uri = Uri.parse(url);
    // final res = await http.get(Uri.parse(["https://d.fxtwitter.com", uri.path].join()));

    final downloadedFileInfo = await cache.downloadFile(["https://d.fxtwitter.com", uri.path].join());
    
    return PresetImage(
        image: downloadedFileInfo.file,
        sources: [["https://x.com", uri.path].join("")],
        tags: {
            "artist": List<String>.from([uri.pathSegments[0].toLowerCase()]),
        }
    );
}

// twitter: instafix offers a url to give only the image. getting the artist is as easy as reading the first path segment
Future<PresetImage> instagramToPreset(String url) async {
    Uri uri = Uri.parse(url);
    final fxReq = http.Request("Get", Uri.parse(["https://ddinstagram.com", uri.path].join()))..followRedirects = false;
    final title = getMetaProperty(parse(fxReq.body), property: "twitter:title");

    debugPrint(fxReq.body);

    final downloadedFileInfo = await cache.downloadFile(["https://d.ddinstagram.com", uri.path].join());

    debugPrint(downloadedFileInfo.file.path);
    
    return PresetImage(
        image: downloadedFileInfo.file,
        sources: [["https://instagram.com", uri.path].join("")],
        tags: {
            "artist": title != null ? [title.substring(1)] : [],
        }
    );
}

// furaffinity: it doesn't offer an api, but fxraffinity exists, and it bypasses the nsfw sign up wall, so we can extract its embed to
// obtain its image. the url nor fxraffinity's embed gives any clue about the poster, but furryaffinity's website title, as well as its
// embed title gives, so we just fetch those (and also bypasses the nsfw sign up wall)
Future<PresetImage> furaffinityToPreset(String url) async {
    Uri uri = Uri.parse(url);
    final fxReq = http.Request("Get", Uri.parse(["https://fxraffinity.net", uri.path, "?full"].join()))..followRedirects = false;
    final res = await http.Response.fromStream(await http.Client().send(fxReq));
    final websiteRes = await http.get(Uri.parse(["https://furaffinity.net", uri.path].join()));

    final fileUrl = getMetaProperty(parse(res.body), property: "og:image");
    if(fileUrl == null) throw "Could not grab image";

    final title = getMetaProperty(parse(websiteRes.body), property: "og:title");

    final downloadedFileInfo = await cache.downloadFile(fileUrl);
    
    return PresetImage(
        image: downloadedFileInfo.file,
        sources: [["https://furaffinity.net", uri.path].join()],
        tags: {
            "artist": title != null ? [title.split(" ").last.toLowerCase()] : [],
        }
    );
}

// devianart: use their oEmbed API
Future<PresetImage> deviantartToPreset(String url) async {
    final res = await http.get(Uri.parse(["https://backend.deviantart.com/oembed?url=", url].join()));
    final json = jsonDecode(res.body);

    final downloadedFileInfo = await cache.downloadFile(json["url"]);
    
    return PresetImage(
        image: downloadedFileInfo.file,
        sources: [url],
        tags: {
            "artist": [json["author_name"].toLowerCase()],
        }
    );
}

// devianart: use their oEmbed API
Future<PresetImage> anyURLToPreset(String url) async {
    final downloadedFileInfo = await cache.downloadFile(url);

    final mime = lookupMimeType(downloadedFileInfo.file.basename)!;

    if(!(mime.startsWith("image/") || mime.startsWith("video/"))) throw "Unknown file type";
    
    return PresetImage(
        image: downloadedFileInfo.file,
        sources: [url],
    );
}