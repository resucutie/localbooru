part of localbooru_api;

Future writeSettings(String path, Map raw, {bool notify = true}) async {
    await File(p.join(path, "repoinfo.json")).writeAsString(const JsonEncoder.withIndent('  ').convert(raw));
    if(notify) booruUpdateListener.update();
}

Map<String, dynamic> rebase(Map<String, dynamic> raw) {
    // check all files
    if(raw["files"] == null) raw["files"] = defaultFileInfoJson["files"];
    List files = raw["files"];
    for(var (int index, Map file) in files.indexed) {
        //recount all ids
        file["id"] = index.toString();

        file["tags"] = (file["tags"] as String).split(" ")
            .where((tag) => !TagText(tag).isMetatag()) //remove any metatags on the tags
            .join(" ");
        file["related"] = (file["related"] ?? []).where((e) => int.tryParse(e) != null && files.elementAtOrNull(int.parse(e) - 1) != null).toList();

        files[index] = file as dynamic;
    }
    raw["files"] = files;

    // check specific tags
    if(raw["specificTags"] == null) {
        raw["specificTags"] = defaultFileInfoJson["specificTags"];
    } else {
        // clean empty types
        for (final type in raw["specificTags"].keys) {
            List<String> contents = List.from(raw["specificTags"][type]);
            contents = contents.where((e) => e.isNotEmpty).toList();
            raw["specificTags"][type] = contents;
        }
    }

    // check collections
    if(raw["collections"] == null) {
        raw["collections"] = defaultFileInfoJson["collections"];
    } else {
        final List<Map<String, dynamic>> collections = List<Map<String, dynamic>>.from(raw["collections"]);
        for (var (index, collection) in collections.indexed) {
            //recount collections
            collection["id"] = index.toString();

            raw["collections"][index] = collection;
        }
    }

    return raw;
}



Future<BooruImage> insertImage(PresetImage preset) async {
    final Booru booru = await getCurrentBooru();

    if(preset.image is! File) throw "Preset does not contain a file";

    // step 1: copy image
    File copiedFile;
    if(p.dirname(preset.image!.path) == p.join(booru.path, "files")) {
        copiedFile = preset.image!;
    } else {
        copiedFile = await preset.image!.copy(p.join(booru.path, "files", p.basename(preset.image!.path)));
    }

    // step 2: add to json
    Map raw = await booru.getRawInfo();
    List files = raw["files"];

    // determine id
    String id = preset.replaceID == null || int.parse(preset.replaceID!) > files.length ? "${files.length}" : preset.replaceID!;

    // set up tags
    if(preset.tags == null) throw "Preset does not contain tags";
    Set<String> tagSet = {};
    for (MapEntry<String, List<String>> tagType in preset.tags!.entries) {
        if(tagType.value.isNotEmpty) {
            tagSet.addAll(tagType.value); //you can add values to sets
            debugPrint("${tagType.key} ${tagType.value.length} $tagSet");
            if(tagType.key != "generic") await addSpecificTags(tagType.value, type: tagType.key);
        }
    }
    
    // determine rating
    final String? ratingString = switch(preset.rating) {
        Rating.safe => "safe",
        Rating.questionable => "questionable",
        Rating.explicit => "explicit",
        Rating.illegal => "illegal",
        _ => null
    };

    // map to push
    Map toPush = {
        "id": id,
        "filename": p.basename(copiedFile.path),
        "tags": tagSet.join(" "),
        if(ratingString != null) "rating": ratingString,
        "sources": preset.sources ?? [],
        "related": preset.relatedImages ?? []
    };
    
    // find if inputed id already exists, and if no add to its latest index, otherwise replace element on that id
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

Future removeImage(String id, {bool notify = true}) async {
    final Booru booru = await getCurrentBooru();
    final BooruImage? image = await booru.getImage(id);
    if(image == null) throw "Image $id does not exist";
    final file = File(image.path);

    // remove file association
    var raw = await booru.getRawInfo();
    List files = raw["files"];

    files.removeWhere((e) => e["id"] == id);
    raw["files"] = files;
    
    await writeSettings(booru.path, rebase(raw), notify: notify);

    // remove file
    await file.delete();

}



Future<BooruCollection> insertCollection(PresetCollection preset) async {
    final Booru booru = await getCurrentBooru();

    if(preset.pages is! List<String>) throw "Preset does not contain pages";
    if(preset.name == null) throw "Preset does not contain a name";

    Map raw = await booru.getRawInfo();
    List<Map<String, dynamic>> collections = List<Map<String, dynamic>>.from(raw["collections"]);

    // determine id
    String id = preset.id == null || int.parse(preset.id!) > collections.length ? "${collections.length}" : preset.id!;

    // map to push
    Map<String, dynamic> toPush = {
        "id": id,
        "pages": preset.pages,
        "name": preset.name
    };
    
    // find if inputed id already exists, and if no add to its latest index, otherwise replace element on that id
    int index = collections.indexWhere((e) => e["id"] == id);
    if (index < 0) collections.add(toPush);
    else collections[index] = toPush;

    raw["collections"] = collections;

    await writeSettings(booru.path, raw);

    return (await booru.getCollection(id))!;
}

Future removeCollection(CollectionID id, {bool notify = true}) async {
    final Booru booru = await getCurrentBooru();
    final collection = await booru.getCollection(id);
    if(collection == null) throw "Collection $id does not exist";

    // remove file association
    var raw = await booru.getRawInfo();
    List collections = raw["collections"];

    collections.removeWhere((e) => e["id"] == id);
    raw["collections"] = collections;
    
    await writeSettings(booru.path, rebase(raw), notify: notify);

}