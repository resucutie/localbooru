part of preset;

Future<bool> determineIfCollection(Uri uri) async {
    bool isCollection;

    Stopwatch stopwatch = Stopwatch()..start();

    isCollection = await _determineCollectionByURIHandling(uri);

    stopwatch.stop();
    debugPrint("Found: $isCollection. Took ${stopwatch.elapsed.inMilliseconds}ms\n");

    return isCollection;
}

Future<bool> _determineCollectionByURIHandling(Uri uri) async {
    // res = await http.get(Uri.parse("${[uri.origin, uri.path].join("/")}.json")); //danbooru2/e621
    // if(res.statusCode == 200) return true;

    if(int.tryParse(uri.pathSegments.last) != null) { //last path of danbooru/1/2/e621 is a number
        if(uri.pathSegments.first == "pool" //danbooru2
            || uri.pathSegments.first == "pools" //e621
            || (uri.pathSegments.first == "pools" && uri.pathSegments[1] == "show") //danbooru1
        ) return true;
    }

    if(uri.queryParameters["page"] == "pool") { //gelbooru's display for a pool is on the parameter "page"
        return true; //gebooru 0.2.0/0.2.5
    }

    return false;
}

// Future<Websites?> _webcrawl(Uri uri) async {
//     final webpage = await http.get(uri);
//     final Document document = parse(webpage.body);

//     final head = document.head;

//     if(head!.querySelector("meta[content=\"Frost Dragon Art LLC\"]") != null ) return ServiceWebsites.furAffinity;
//     if(head.querySelector("meta[content=\"DeviantArt\"]") != null ) return ServiceWebsites.deviantArt;
//     if(head.querySelector("link[href^=\"https://abs.twimg.com/responsive-web/client-web/\"]") != null ) return ServiceWebsites.twitter;
//     return null;
// }