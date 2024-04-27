part of localbooru_api;

Future writeSettings(String path, Map raw) async {
    await File(p.join(path, "repoinfo.json")).writeAsString(const JsonEncoder.withIndent('  ').convert(raw));
    booruUpdateListener.update();
}

Future<BooruImage> addImage({required File imageFile,
    ImageID? id,
    String tags = "",
    Rating? rating,
    List<String> sources = const [],
    List<ImageID>? relatedImages = const [],
}) async {
    final Booru booru = await getCurrentBooru();

    //copy image
    File copiedFile;
    if(p.dirname(imageFile.path) == p.join(booru.path, "files")) {
        copiedFile = imageFile;
    } else {
        copiedFile = await imageFile.copy(p.join(booru.path, "files", p.basename(imageFile.path)));
    }

    // add to json
    Map raw = await booru.getRawInfo();
    List files = raw["files"];

    if(id == null || int.parse(id) > files.length) id = "${files.length}";

    final String? ratingString = switch(rating) {
        Rating.safe => "safe",
        Rating.questionable => "questionable",
        Rating.explicit => "explicit",
        Rating.illegal => "illegal",
        _ => null
    };

    Map toPush = {
        "id": id,
        "filename": p.basename(copiedFile.path),
        "tags": tags,
        if(ratingString != null) "rating": ratingString,
        "sources": sources,
        "related": relatedImages
    };
    
    int index = files.indexWhere((e) => e["id"] == id);
    if (index < 0) files.add(toPush);
    else files[index] = toPush;

    raw["files"] = files;

    await writeSettings(booru.path, raw);

    return (await booru.getImage(id))!;
}

Future<void> editNote(String id, String? note) async {
    final Booru booru = await getCurrentBooru();

    // add to json
    Map raw = await booru.getRawInfo();
    List files = raw["files"];

    int index = files.indexWhere((e) => e["id"] == id);
    if (index < 0) throw "Does not exist";
    else {
        if(note == null || note.isEmpty) raw["files"][index].remove("note");
        else raw["files"][index]["note"] = note;
    }

    await writeSettings(booru.path, raw);
}

Future<void> writeSpecificTags(Map<String, List<String>> specificTags) async {
    final Booru booru = await getCurrentBooru();

    // add to json
    var raw = await booru.getRawInfo();
    raw["specificTags"] = specificTags;

    await writeSettings(booru.path, raw);
}

Future<void> addSpecificTags(List<String> tags, {required String type}) async {
    final Booru booru = await getCurrentBooru();

    // add to json
    var raw = await booru.getRawInfo();
    final specificTagsList = raw["specificTags"][type];
    List<String> specificTags = List<String>.from(specificTagsList ?? []);

    for(String tag in tags) {
        if(!specificTags.contains(tag)) specificTags.add(tag);
    }

    raw["specificTags"][type] = specificTags;

    Map<String, List<String>> iLoveDartsTypeSystem = {};
    for(String key in raw["specificTags"].keys) {
        iLoveDartsTypeSystem[key] = List<String>.from(raw["specificTags"][key]);
    }
    await writeSpecificTags(iLoveDartsTypeSystem);
}

Map<String, dynamic> rebase(Map<String, dynamic> raw) {
    // check all files
    if(raw["files"] == null) raw["files"] = [];
    List files = raw["files"];
    for(final (int index, Map file) in files.indexed) {
        //recount all ids
        file["id"] = index.toString();

        file["tags"] = (file["tags"] as String).split(" ")
            .where((tag) => !tag.contains(":")) //remove any metatags on the tags
            .join(" ");

        files[index] = file as dynamic;
    }
    raw["files"] = files;

    // check specific tags
    if(raw["specificTags"] == null) {
        raw["specificTags"] = defaultFileInfoJson["specificTags"];
    } else {
        for (final type in raw["specificTags"].keys) {
            List<String> contents = List.from(raw["specificTags"][type]);
            contents = contents.where((e) => e.isNotEmpty).toList();
            raw["specificTags"][type] = contents;
        }
    }
    debugPrint(raw["specificTags"].toString());

    return raw;
}

Future removeImage(String id) async {
    final Booru booru = await getCurrentBooru();
    final BooruImage? image = await booru.getImage(id);
    if(image == null) throw "Image $id does not exist";
    final file = File(image.path);

    // remove file association
    var raw = await booru.getRawInfo();
    List files = raw["files"];

    files.removeWhere((e) => e["id"] == id);
    raw["files"] = files;
    
    await writeSettings(booru.path, rebase(raw));

    // remove file
    await file.delete();

}