part of preset;

// twitter: fxtwitter offers a url to give only the image. getting the artist is as easy as reading the first path segment
Future<PresetImage> twitterToPreset(String url) async {
    Uri uri = Uri.parse(url);
    // final res = await http.get(Uri.parse(["https://d.fxtwitter.com", uri.path].join()));

    final downloadedFileInfo = await presetCache.downloadFile(["https://d.fxtwitter.com", uri.path].join());
    
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

    final downloadedFileInfo = await presetCache.downloadFile(["https://d.ddinstagram.com", uri.path].join());

    debugPrint(downloadedFileInfo.file.path);
    
    return PresetImage(
        image: downloadedFileInfo.file,
        sources: [["https://instagram.com", uri.path].join("")],
        tags: {
            "artist": title != null ? [title.substring(1)] : [],
        }
    );
}