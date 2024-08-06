part of preset;

// danbooru2 and e621/e926 share the same api endpoints when it comes to pools
// danbooru 2: if you add .json at the end of the post url, it'll return the JSON of that post
Future<VirtualPresetCollection> _danbooru2LikeAPIs(Uri uri, Function(Uri uri, {HandleChunk handleChunk}) importer) async {
    final res = await http.get(Uri.parse("${[uri.origin, uri.path].join("/")}.json"));
    final json = jsonDecode(res.body);

    final presets = await multiImageDownloader(
        postsToIterate: List<int>.from(json["post_ids"]),
        getter: (post, handler) {
            return importer(Uri.parse([uri.origin, "posts", post].join("/")), handleChunk: handler,);
        },
    );

    return VirtualPresetCollection(
        name: (json["name"] as String).replaceAll("_", " "),
        pages: addSourceToAllPresets(presets, [uri.origin, uri.path].join("/"))
    );
}
Future<VirtualPresetCollection> danbooru2ToCollectionPreset(Uri uri) => _danbooru2LikeAPIs(uri, danbooru2ToPresetImage);
Future<VirtualPresetCollection> e621ToCollectionPreset(Uri uri) => _danbooru2LikeAPIs(uri, e621ToPresetImage);

// danbooru 1: /pool/show.xml?id=(id) returns all of the posts already parsed
Future<VirtualPresetCollection> danbooru1ToCollectionPreset(Uri uri) async {
    final id = uri.pathSegments.last;
    final res = await http.get(Uri.parse("${uri.origin}/pool/show.json?id=$id"));
    final json = jsonDecode(res.body);

    final presets = await multiImageDownloader(
        postsToIterate: List<Map<String, dynamic>>.from(json["posts"]),
        getter: (post, handler) {
            return anyURLToPresetImage(post["file_url"], handleChunk: handler);
        },
    );

    return VirtualPresetCollection(
        name: (json["name"] as String).replaceAll("_", " "),
        pages: addSourceToAllPresets(presets, [uri.origin, uri.path].join("/"))
    );
}


List<PresetImage> addSourceToAllPresets(List<PresetImage> presets, String source) {
    return presets.map((preset) {
        if(preset.sources == null) preset.sources = [source];
        else preset.sources!.add(source);
        return preset;
    },).toList();
}