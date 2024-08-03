part of preset;

// e926/e621: same idea as danbooru 2, if you add .json at the end of the post url, it'll return the JSON of that post
Future<VirtualPresetCollection> e621ToCollectionPreset(Uri uri) async {
    final res = await http.get(Uri.parse("${[uri.origin, uri.path].join("/")}.json"));
    final json = jsonDecode(res.body);

    final postList = List<int>.from(json["post_ids"]);

    final completionist = MultiCompletionist(postList.length);

    final presets = await Future.wait(
        postList.mapIndexed((index, post) => e621ToPresetImage(Uri.parse([uri.origin, "posts", post].join("/")),
            handleChunk: completionist.chunkHandler(index),
        ))
    );

    return VirtualPresetCollection(
        name: (json["name"] as String).replaceAll("_", " "),
        pages: presets.map((preset) {
            final pool = [uri.origin, uri.path].join("/");
            if(preset.sources == null) preset.sources = [pool];
            else {
                preset.sources!.add(pool);
            }
            return preset;
        },).toList()
    );
}