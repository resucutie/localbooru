part of preset;


// presets are essentially a format that represents a BooruImage before it gets added
class PresetImage extends VirtualPreset{
    PresetImage({this.image, this.tags, this.sources, this.replaceID, this.rating, this.relatedImages, this.note, super.key});

    File? image;
    Map<String, List<String>>? tags;
    List<String>? sources;
    Rating? rating;
    ImageID? replaceID;
    List<ImageID>? relatedImages;
    String? note;

    static Future<PresetImage> fromExistingImage(BooruImage image) async {
        final Booru booru = await getCurrentBooru();
        
        return PresetImage(
            image: File(image.path),
            sources: image.sources,
            tags: await booru.separateTagsByType(image.tags.split(" ")),
            rating: image.rating,
            replaceID: image.id,
            relatedImages: image.relatedImages,
            note: image.note
        );
    }

    static Future<PresetImage> urlToPreset(String url, {bool accurate = true}) async {
        if(await File(url).exists()) return PresetImage(image: File(url));
        
        if(!isURL(url)) throw "Not a URL";

        Uri uri = Uri.parse(url);

        Websites? website;
        if(accurate) website = await accurateGetWebsite(uri);
        else website = getWebsiteByURL(uri);

        final preset = switch (website) {
            BooruWebsites.danbooru1 => await danbooru1ToPresetImage(uri),
            BooruWebsites.danbooru2 => await danbooru2ToPresetImage(uri),
            BooruWebsites.e621 => await e621ToPresetImage(uri),
            BooruWebsites.gelbooru020 || BooruWebsites.gelbooru025 => await gelbooruToPresetImage(uri),
            BooruWebsites.philomena || BooruWebsites.booruOnRails => await philomenaToPresetImage(uri, useBooruOnRails: website == BooruWebsites.booruOnRails),
            ServiceWebsites.twitter => await twitterToPresetImage(uri),
            ServiceWebsites.furAffinity => await furaffinityToPresetImage(uri),
            ServiceWebsites.deviantArt => await deviantartToPresetImage(url),
            // Websites.instagram => await instagramToPresetImage(url),
            _ => await anyURLToPresetImage(url)
        };
        return preset;
    }
}