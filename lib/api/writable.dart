part of localbooru_api;

Future writeSettings(Booru booru, Map raw) async {
    await File(p.join(booru.path, "repoinfo.json")).writeAsString(const JsonEncoder.withIndent('  ').convert(raw));
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

    await writeSettings(booru, raw);

    return (await booru.getImage(id))!;
}

Future rebase() async {
    final Booru booru = await getCurrentBooru();

    Map raw = await booru.getRawInfo();
    List files = raw["files"];

    for(final (index, file) in files.indexed) {
        //recount all ids
        file["id"] = index.toString();

        files[index] = file;
    }

    raw["files"] = files;

    await File(p.join(booru.path, "repoinfo.json")).writeAsString(const JsonEncoder.withIndent('  ').convert(raw));
}

Future removeImage(String id) async {
    final Booru booru = await getCurrentBooru();
    final BooruImage? image = await booru.getImage(id);
    if(image == null) throw "Image $id does not exist";
    final file = File(image.path);

    // remove file association
    Map raw = await booru.getRawInfo();
    List files = raw["files"];

    files.removeWhere((e) => e["id"] == id);
    raw["files"] = files;

    await writeSettings(booru, raw);

    // remove file
    await file.delete();

    // rebase to update ids
    await rebase();
}