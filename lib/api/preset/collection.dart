part of preset;


// presets are essentially a format that represents a BooruImage before it gets added
class PresetCollection {
    PresetCollection({this.id, this.pages, this.name, this.uniqueKey});

    CollectionID? id;
    List<ImageID>? pages;
    String? name;

    UniqueKey? uniqueKey;

    static Future<PresetCollection> fromExistingPreset(BooruCollection collection) async {
        return PresetCollection(
            id: collection.id,
            pages: collection.pages,
            name: collection.name
        );
    }

    // static Future<PresetImage> urlToPreset(String url, {bool? accurate}) async {
    //     if(await File(url).exists()) return PresetImage(image: File(url));
        
    //     if(!isURL(url)) throw "Not a URL";

    //     Uri uri = Uri.parse(url);

    //     Websites? website;
    //     if(accurate == true) website = await accurateGetWebsite(uri);
    //     else website = getWebsiteByURL(uri);

    //     final preset = switch (website) {
    //         ServiceWebsites.danbooru1 => await danbooru1ToPreset(url),
    //         ServiceWebsites.danbooru2 => await danbooru2ToPreset(url),
    //         ServiceWebsites.e621 => await e621ToPreset(url),
    //         ServiceWebsites.gelbooru020 || ServiceWebsites.gelbooru025 => await gelbooruToPreset(url),
    //         ServiceWebsites.twitter => await twitterToPreset(url),
    //         ServiceWebsites.furAffinity => await furaffinityToPreset(url),
    //         ServiceWebsites.deviantArt => await deviantartToPreset(url),
    //         // Websites.instagram => await instagramToPreset(url),
    //         _ => await anyURLToPreset(url)
    //     };
    //     return preset;
    // }
}