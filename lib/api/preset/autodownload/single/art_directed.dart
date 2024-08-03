part of preset;

// furaffinity: it doesn't offer an api, but fxraffinity exists, and it bypasses the nsfw sign up wall, so we can extract its embed to
// obtain its image. the url nor fxraffinity's embed gives any clue about the poster, but furryaffinity's website title, as well as its
// embed title gives, so we just fetch those (and also bypasses the nsfw sign up wall)
Future<PresetImage> furaffinityToPresetImage(Uri uri) async {
    final fxReq = http.Request("Get", Uri.parse(["https://fxraffinity.net", uri.path, "?full"].join()))..followRedirects = false;
    final res = await http.Response.fromStream(await http.Client().send(fxReq));
    final websiteRes = await http.get(Uri.parse(["https://furaffinity.net", uri.path].join()));

    final fileUrl = getMetaProperty(parse(res.body), property: "og:image");
    if(fileUrl == null) throw "Could not grab image";

    final title = getMetaProperty(parse(websiteRes.body), property: "og:title");

    final downloadedFileInfo = await downloadFile(Uri.parse(fileUrl));
    
    return PresetImage(
        image: downloadedFileInfo,
        sources: [["https://furaffinity.net", uri.path].join()],
        tags: {
            "artist": title != null ? [title.split(" ").last.toLowerCase()] : [],
        }
    );
}

// devianart: use their oEmbed API
Future<PresetImage> deviantartToPresetImage(String url) async {
    final res = await http.get(Uri.parse(["https://backend.deviantart.com/oembed?url=", url].join()));
    final json = jsonDecode(res.body);

    final downloadedFileInfo = await downloadFile(Uri.parse(json["url"]));
    
    return PresetImage(
        image: downloadedFileInfo,
        sources: [url],
        tags: {
            "artist": [json["author_name"].toLowerCase()],
        }
    );
}