part of "../../index.dart";

// danbooru 2: if you add .json at the end of the post url, it'll return the JSON of that post
Future<PresetImage> danbooru2ToPreset(String url) async {
    Uri uri = Uri.parse(url);
    final res = await http.get(Uri.parse("${[uri.origin, uri.path].join("/")}.json"));
    final bodyRes = jsonDecode(res.body);

    final downloadedFileInfo = await downloadFile(Uri.parse(bodyRes["file_url"]));

    return PresetImage(
        image: downloadedFileInfo,
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
    final res = await http.get(Uri.parse([uri.origin, "post/index.json?tags=id:$postID"].join("/")));
    final post = jsonDecode(res.body)[0];

    final downloadedFileInfo = await downloadFile(Uri.parse(post["file_url"]));

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
        image: downloadedFileInfo,
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

    final downloadedFileInfo = await downloadFile(Uri.parse(postRes["file"]["url"]));

    return PresetImage(
        image: downloadedFileInfo,
        sources: [...(postRes["sources"] ?? []).where((e) => !e.startsWith("-")), [uri.origin, uri.path].join("")],
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

    final downloadedFileInfo = await downloadFile(Uri.parse(imageURL));

    return PresetImage(
        image: downloadedFileInfo,
        sources: [post["source"], [uri.origin, uri.path].join("")].whereType<String>().toList(),
        tags: {
            "generic": List<String>.from(tagList["generic"]!),
            "artist": List<String>.from(tagList["artist"]!),
            "character": List<String>.from(tagList["character"]!),
            "copyright": List<String>.from(tagList["copyright"]!),
        }
    );
}