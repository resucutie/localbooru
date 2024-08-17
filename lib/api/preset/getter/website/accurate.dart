part of preset;

Future<Websites?> accurateGetWebsite(Uri uri) async {
    Websites? possibleWebsites;

    // Stopwatch stopwatch = Stopwatch()..start();

    possibleWebsites = await _determineWebsiteByWebcrawl(uri) ?? await _determineSPByAPIFetch(uri);

    // stopwatch.stop();
    // debugPrint("Found: $possibleWebsites. Took ${stopwatch.elapsed.inMilliseconds}ms\n");

    return possibleWebsites;
}

Future<Websites?> _determineSPByAPIFetch(Uri uri) async {
    Response res;

    res = await lbHttp.get(Uri.parse("${uri.origin}/posts.json"));
    if(res.statusCode == 200) {
        res = await lbHttp.get(Uri.parse("${uri.origin}/status.json"));
        if(res.statusCode == 200) return ServiceWebsites.danbooru2; // e621 does not support /status.json, but supports almost all API endpoints
        else return ServiceWebsites.e621; // e621 does not support /status.json, but supports almost all API endpoints
    }


    res = await lbHttp.get(Uri.parse("${uri.origin}/post/index.xml"));
    if(res.statusCode == 200) return ServiceWebsites.danbooru1;

    res = await lbHttp.get(Uri.parse("${uri.origin}/index.php?page=dapi&s=user&q=index"));
    if(res.statusCode == 200) {
        if(res.body.isEmpty) return ServiceWebsites.gelbooru020;
        else return ServiceWebsites.gelbooru025;
    }

    return null;
}

Future<Websites?> _determineWebsiteByWebcrawl(Uri uri) async {
    final webpage = await lbHttp.get(uri);
    final Document document = parse(webpage.body);

    final head = document.head;

    if(head!.querySelector("meta[content=\"Frost Dragon Art LLC\"]") != null ) return ServiceWebsites.furAffinity;
    if(head.querySelector("meta[content=\"DeviantArt\"]") != null ) return ServiceWebsites.deviantArt;
    if(head.querySelector("link[href^=\"https://abs.twimg.com/responsive-web/client-web/\"]") != null ) return ServiceWebsites.twitter;
    return null;
}