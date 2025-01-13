part of "../../index.dart";

// danbooru 2: if you add .json at the end of the post url, it'll return the JSON of that post
Future<PresetImage> danbooru2ToPresetImage(Uri uri, {HandleChunk? handleChunk}) async {
    final res = await lbHttp.get(Uri.parse("${[uri.origin, uri.path].join("/")}.json"));
    final bodyRes = jsonDecode(res.body);

    final downloadedFileInfo = await downloadFile(Uri.parse(bodyRes["file_url"]), handleChunk: handleChunk);

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
Future<PresetImage> danbooru1ToPresetImage(Uri uri, {HandleChunk? handleChunk}) async {
    final postID = uri.pathSegments[2];
    final res = await lbHttp.get(Uri.parse([uri.origin, "post/index.json?tags=id:$postID"].join("/")));
    final post = jsonDecode(res.body)[0];

    final downloadedFileInfo = await downloadFile(Uri.parse(post["file_url"]), handleChunk: handleChunk);

    final webpage = await lbHttp.get(uri);
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
Future<PresetImage> e621ToPresetImage(Uri uri, {HandleChunk? handleChunk}) async {
    final res = await lbHttp.get(Uri.parse("${[uri.origin, uri.path].join("/")}.json"));
    final postRes = jsonDecode(res.body)["post"];
    
    final downloadedFileInfo = await downloadFile(Uri.parse(postRes["file"]["url"]), handleChunk: handleChunk);
    
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
final gelbooruILoveYou = HtmlUnescape(); // ❤️ https://github.com/resucutie/localbooru/issues/15
Future<PresetImage> gelbooruToPresetImage(Uri uri) async {
    final String imageID = uri.queryParameters["id"]!;

    final res = await lbHttp.get(Uri.parse([uri.origin, "index.php?page=dapi&s=post&q=index&json=1&id=$imageID"].join("/")));
    final json = jsonDecode(res.body);
    final bool is020 = json is List;
    final Map<String, dynamic> post = !is020 ? json["post"][0] : json[0]; // api differences, first one 0.2.5, second 0.2.0

    final String tags = gelbooruILoveYou.convert(post["tags"]);

    Map<String, List<String>> tagList = {
        "generic": [],
        "artist": [],
        "copyright": [],
        "character": [],
    };
    String imageURL;
    if(is020) { // probably 0.2.0, grab html documents
        // sadly it doesn't have an api to obtain tag types, or i couldn't find one
        final webpage = await lbHttp.get(Uri.parse([uri.origin, "index.php?page=post&s=view&id=$imageID"].join("/")));
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
        final tagTypesRes = await lbHttp.get(Uri.parse([uri.origin, "index.php?page=dapi&s=tag&q=index&json=1&names=$tags"].join("/")));
        
        final List<dynamic> tagTypes = jsonDecode(tagTypesRes.body)["tag"];

        for (var tag in tagTypes) {
            final type = gelbooruTagMap[tag["type"]];
            if(type != null) tagList[type]!.add(gelbooruILoveYou.convert(tag["name"]));
        }

        imageURL = post["file_url"];
    }

    final downloadedFileInfo = await downloadFile(Uri.parse(imageURL));

    return PresetImage(
        image: downloadedFileInfo,
        sources: [post["source"], "${uri.origin}/index.php?page=post&s=view&id=$imageID"].whereType<String>().toList(),
        tags: {
            "generic": List<String>.from(tagList["generic"]!),
            "artist": List<String>.from(tagList["artist"]!),
            "character": List<String>.from(tagList["character"]!),
            "copyright": List<String>.from(tagList["copyright"]!),
        }
    );
}

Future<PresetImage> philomenaToPresetImage(Uri uri, {HandleChunk? handleChunk}) async {
    final imageID = uri.pathSegments[1];
    final imageRes = await lbHttp.get(Uri.parse([uri.origin, "api", "v1", "json", "images", imageID].join("/")));
    final imageJson = jsonDecode(imageRes.body)["image"];

    final tagIDs = List<int>.from(imageJson["tag_ids"]);
    final querySearch = tagIDs.map<String>((id) => "id:$id").join(" || "); // "||" = OR operator
    final tageRes = await lbHttp.get(Uri(
        scheme: "https",
        host: uri.host,
        pathSegments: ["api", "v1", "json", "search", "tags"],
        queryParameters: {"q": querySearch}
    ));
    final tagJson = List<Map<String, dynamic>>.from(jsonDecode(tageRes.body)["tags"]);

    final Map<String, List<String>> tagList = {
        "generic": [],
        "artist": [],
        "character": [],
        "copyright": [],
        "species": [],
    };
    Rating? rating;
    for (final tag in tagJson) {
        String? tagIdentifier; // artist, editor, generator...
        String tagName;
        String? tagCategory = tag["category"];

        if(TagText(tag["name"]).isMetatag()) {
            final metatag = Metatag(tag["name"]);
            tagIdentifier = metatag.selector;
            tagName = metatag.value;
        } else {
            tagName = tag["name"];
        }
        if(tagCategory == "spoiler") tagName = tagName.replaceAll("spoiler:", "");

        if(tagName == "oc") continue; //skip if "oc"
        
        if(tagCategory == "rating") { // skip but sets the rating
            rating = switch(tagName) {
                "safe" || "semi-grimdark" => Rating.safe, // not exactly solid on semi-grimdark
                "explicit" => Rating.explicit,
                "suggestive" || "questionable" => Rating.questionable,
                "grimdark" || "grotesque" => Rating.illegal, // not so sure about bodily waste, but "grotesque" abranges more than that
                _ => null
            };
            continue;
        }
        final String category = switch(tagCategory) {
            "character" || "oc" => "character",
            "origin" => //looking at the tag name because apparently generator:stable diffusion does not have a namespace property
                   tagIdentifier == "artist"
                || tagIdentifier == "editor"
                || tagIdentifier == "prompter" //prompter is the one who inserts the prompt to an ai generate an image. will not touch on the argument of "ai art is not art" (personally me (resu) dislikes ai art but dadaism is a thing, apparently people forgot about it) but since i have to be abrangent when it comes to acceptance i'll have to accept
                || tagIdentifier == "photographer"
                || tagIdentifier == "colorist"
                || tagIdentifier == "author" //no idea whats this one about
                ? "artist" : "generic",
            "content-official" || "content-fanmade" => "copyright",
            "species" => "species",
            _ => "generic"
        };
        final String normalizedName = tagName.replaceAll(" ", "_").replaceAll(":", "");
        tagList[category]!.add(normalizedName);
    }
    
    final downloadedFileInfo = await downloadFile(Uri.parse(imageJson["view_url"]), handleChunk: handleChunk);
    
    return PresetImage(
        image: downloadedFileInfo,
        sources: [...(imageJson["source_urls"] ?? []), [uri.origin, uri.path].join("")],
        tags: tagList,
        rating: rating
    );
}