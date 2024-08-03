part of preset;

class PresetCollection extends Preset {
    PresetCollection({this.id, this.name, this.pages, super.key});

    List<ImageID>? pages;
    CollectionID? id;
    String? name;

    static PresetCollection fromExistingPreset(BooruCollection collection) {
        return PresetCollection(
            id: collection.id,
            pages: collection.pages,
            name: collection.name
        );
    }

    static PresetCollection fromVirtualPresetCollection(VirtualPresetCollection preset) {
        return PresetCollection(
            id: preset.id,
            pages: preset.pages?.mapIndexed((index, presetImage) {
                if(presetImage.replaceID == null) throw "PresetImage at $index does not contain an ID";
                return presetImage.replaceID!;
            }).toList(),
            name: preset.name
        );
    }
}

class VirtualPresetCollection extends VirtualPreset {
    VirtualPresetCollection({this.id, this.name, this.pages, super.key});

    List<PresetImage>? pages;
    CollectionID? id;
    String? name;

    static Future<VirtualPresetCollection> fromPresetCollection(PresetCollection preset) async {
        final booru = await getCurrentBooru();
        return VirtualPresetCollection(
            id: preset.id,
            pages: preset.pages != null ? await Future.wait(preset.pages!.mapIndexed((index, id) async {
                final image = await booru.getImage(id);
                if(image == null) throw "Element at $index does not exist";
                return PresetImage.fromExistingImage(image);
            })) : null,
            name: preset.name
        );
    }

    static Future<VirtualPresetCollection> urlToPreset(String url, {bool accurate = true}) async {        
        if(!isURL(url)) throw "Not a URL";

        Uri uri = Uri.parse(url);

        Websites? website;
        if(accurate == true) website = await accurateGetWebsite(uri);
        else website = getWebsiteByURL(uri);

        final VirtualPresetCollection preset = switch (website) {
            ServiceWebsites.e621 => await e621ToCollectionPreset(uri),
            // Websites.instagram => await instagramToSinglePreset(url),
            _ => throw "Could not identify"
        };
        return preset;
    }
}
