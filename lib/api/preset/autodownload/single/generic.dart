part of preset;

// twitter: fxtwitter offers a url to give only the image. getting the artist is as easy as reading the first path segment
Future<PresetImage> twitterToPresetImage(Uri uri) async {
    // final res = await http.get(Uri.parse(["https://d.fxtwitter.com", uri.path].join()));

    final downloadedFileInfo = await downloadFile(Uri.parse(["https://d.fxtwitter.com", uri.path].join()));
    
    return PresetImage(
        image: downloadedFileInfo,
        sources: [["https://x.com", uri.path].join("")],
        tags: {
            "artist": List<String>.from([uri.pathSegments[0].toLowerCase()]),
        }
    );
}

// twitter: instafix offers a url to give only the image. getting the artist is as easy as reading the first path segment
Future<PresetImage> instagramToPresetImage(Uri uri) async {
    final fxReq = Request("Get", Uri.parse(["https://ddinstagram.com", uri.path].join()))..followRedirects = false;
    final response = await Response.fromStream(await lbHttp.send(fxReq));
    final title = getMetaProperty(parse(response.body), property: "twitter:title");

    debugPrint(response.body);

    final downloadedFileInfo = await downloadFile(Uri.parse(["https://d.ddinstagram.com", uri.path].join()));

    debugPrint(downloadedFileInfo.path);
    
    return PresetImage(
        image: downloadedFileInfo,
        sources: [["https://instagram.com", uri.path].join("")],
        tags: {
            "artist": title != null ? [title.substring(1)] : [],
        }
    );
}