part of localbooru_api;

Future writeSettings(String path, Map raw) async {
    await File(p.join(path, "repoinfo.json")).writeAsString(const JsonEncoder.withIndent('  ').convert(raw));
    booruUpdateListener.update();
}

Future<BooruImage> addImage({required File imageFile,
    String? id,
    String tags = "",
    List<String> sources = const []
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

    Map toPush = {
        "id": id,
        "filename": p.basename(copiedFile.path),
        "tags": tags,
        "sources": sources
    };
    
    int index = files.indexWhere((e) => e["id"] == id);
    if (index < 0) files.add(toPush);
    else files[index] = toPush;

    raw["files"] = files;

    await writeSettings(booru.path, raw);

    return (await booru.getImage(id))!;
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

    await writeSpecificTags(raw["specificTags"]);
}

Map<String, dynamic> rebase(Map<String, dynamic> raw) {
    // check all files
    if(raw["files"] == null) raw["files"] = [];
    List files = raw["files"];
    for(final (index, file) in files.indexed) {
        //recount all ids
        file["id"] = index.toString();

        files[index] = file;
    }
    raw["files"] = files;

    // check specific tags
    if(raw["specificTags"] == null) raw["specificTags"] = defaultFileInfoJson["specificTags"];
    for (final type in raw["specificTags"].keys) {
        List<String> contents = List.from(raw["specificTags"][type]);
        contents = contents.where((e) => e.isNotEmpty).toList();
        raw["specificTags"][type] = contents;
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