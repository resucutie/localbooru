
part of localbooru_api;

// ignore: non_constant_identifier_names
final int INDEX_IMAGE_LIMIT = settingsDefaults["page_size"];

class Booru {
    Booru(this.path);
    
    String path;

    Future<Map<String, dynamic>> getRawInfo() async {
        final File file = File(p.join(path, "repoinfo.json"));
        final String fileinfo = await file.readAsString();
        final Map<String, dynamic> json = jsonDecode(fileinfo);
        return json;
    }
    Future<Map<String, dynamic>> rebaseRaw() async {
        return rebase(Map.from(await getRawInfo()));
    }



    Future<BooruImage?> getImage(String id) async {
        final List<Map<String, dynamic>> files = List<Map<String, dynamic>>.from((await getRawInfo())["files"]);
        
        //check if metadata exists
        // if(!files.asMap().containsKey(id)) throw "File of index $id does not exist";
        var fileToCheck = files.firstWhereOrNull((file) => file["id"] == id);
        if(fileToCheck == null) return null;
        
        //cehck if metadata is valid
        final metadataToCheck = ["filename", "tags", "id"];
        for (String metadata in metadataToCheck) {
            if(!fileToCheck.containsKey(metadata)) throw "File  $id doesn't contain property $metadata";
        }

        final Rating? rating = switch(fileToCheck["rating"]) {
            "safe" => Rating.safe,
            "questionable" => Rating.questionable,
            "explicit" => Rating.explicit,
            "illegal" => Rating.illegal,
            _ => null
        };

        return BooruImage(
            id: id,
            path: p.join(path, "files", fileToCheck["filename"]),
            tags: fileToCheck["tags"],
            rating: rating,
            note: fileToCheck["note"],
            sources: List<String>.from(fileToCheck["sources"] ?? []),
            relatedImages: List<String>.from(fileToCheck["related"] ?? []),
        );
    }



    Future<List<BooruImage>> getImagesFromRange(List list, {required int from, required int to}) async {
        final List rangedList = list.getRange(from, to).toList();
        // debugPrint("rangedList: $rangedList");

        List<BooruImage> mappedList = [];
        for (Map item in rangedList) {
            mappedList.add((await getImage(item["id"]))!);
        }
        return mappedList.reversed.toList();
    }
    Future<List<BooruImage>> getImagesFromIndex(List list, {int index = 0, int? size}) async {
        size ??= INDEX_IMAGE_LIMIT;

        final int length = list.length;

        int from = length - (size * (index + 1));
        int to = length - (size * index);
        if(from < 0) from = 0;
        if(to < 0) to = length;

        final List<BooruImage> range = await getImagesFromRange(list, from: from, to: to);

        return range;
    }
    Future<List<BooruImage>> getRecentImages() async => await getImagesFromIndex((await getRawInfo())["files"]);

    Future<List> _doTagFiltering(String tags) async {
        final List<String> tagList = tags.split(" ").where((s) => s.isNotEmpty).toList();
        final List files = (await getRawInfo())["files"];
        List filteredFiles = [];
        if(tagList.isEmpty) return files;
        for (final file in files) {
            if(await wouldImageBeSelected(inputTags: tagList, file: file)) filteredFiles.add(file);
        }

        return filteredFiles;
    }
    Future<List<BooruImage>> searchByTags(String tags, {int index = 0, int? size}) async => await getImagesFromIndex(await _doTagFiltering(tags), index: index, size: size);

    Future<int> getIndexNumberLength(tags, {int? size}) async {
        size ??= INDEX_IMAGE_LIMIT;

        final list = await _doTagFiltering(tags);

        return (list.length / size).ceil();
    }
    Future<int> getListLength([List? list]) async {
        list ??= (await getRawInfo())["files"];

        return list?.length ?? 0;
    }


    Future<List<String>> getAllTags() async {
        final List files = (await getRawInfo())["files"];
        List<String> allTags = List<String>.empty(growable: true);
        for (var file in files) {
            List<String> fileTags = file["tags"].split(" ");
            for (String tag in fileTags) {
                if(allTags.isEmpty || !allTags.contains(tag)) allTags.add(tag);
            }
        }
        
        return allTags;
    }



    Future<String> getTagType(String tag) async {
        final Map<String, List> allSpecificTags = Map.from((await getRawInfo())["specificTags"]);
        return allSpecificTags.keys.firstWhere((type) => allSpecificTags[type]!.contains(tag), orElse: () => "generic");
    }
    Future<List<String>> getAllTagsFromType(String type) async {
        final Map specificTags = Map.from((await getRawInfo())["specificTags"]);
        if (type == "generic") {
            final allTags = await getAllTags();
            final allSpecificTags = specificTags.values.expand((i) => i).toList();
            allTags.removeWhere((element) => allSpecificTags.contains(element));
            return allTags;
        }
        return List<String>.from(specificTags[type] ?? []);
    }
    Future<Map<String, List<String>>> separateTagsByType(List<String> tags) async {
        List<String> genericList = List.from(tags);
        final Map<String, List> specificTags = Map.from((await getRawInfo())["specificTags"]);
        final Map<String, List<String>> result = {};
        for (final type in specificTags.keys) {
            result[type] = List.from(tags.toSet().intersection(specificTags[type]!.toSet()));
            genericList.removeWhere((element) => result[type]!.contains(element));
        }
        result["generic"] = genericList;
        return result;
    }



    Future<BooruCollection?> getCollection(CollectionID id) async {
        final List<Map<String, dynamic>> collections = List<Map<String, dynamic>>.from((await getRawInfo())["collections"]);

        final matchingCollection = collections.firstWhereOrNull((collection) => collection["id"] == id);
        if(matchingCollection == null) return null;

        final metadataToCheck = ["pages", "name", "id"];
        for (String metadata in metadataToCheck) {
            if(!matchingCollection.containsKey(metadata)) throw "Collection $id doesn't contain property $metadata";
        }

        return BooruCollection(
            pages: List<ImageID>.from(matchingCollection["pages"]),
            name: matchingCollection["name"] as String,
            id: id
        );
    }
    Future<List<BooruCollection>> getAllCollections() async {
        final List<Map<String, dynamic>> collections = List<Map<String, dynamic>>.from((await getRawInfo())["collections"]);

        return await Future.wait(
            collections.map((map) async {
                return (await getCollection("${map["id"]}"))!;
            }).toList()
        );
    }
    Future<List<BooruCollection>> obtainMatchingCollection(ImageID imageID) async {
        final List<Map<String, dynamic>> collections = List<Map<String, dynamic>>.from((await getRawInfo())["collections"]);

        final foundCollections = collections.where((collection) => List<ImageID>.from(collection["pages"]).contains(imageID));

        return await Future.wait(foundCollections.map((collection) async => (await getCollection(collection["id"] as String))!));
    }

    Future<List<BooruImage>> getImagesFromCollectionOnIndex(BooruCollection collection, {int index = 0, int? size}) async {
        final List files = (await getRawInfo())["files"];
        final obtainedList = collection.pages.map((id) => files[int.parse(id)]).toList();
        return await getImagesFromIndex(obtainedList, index: index, size: size);
    }
}

typedef ImageID = String;
class BooruImage {
    BooruImage({required this.id, required this.path, required this.tags, this.sources = const [], this.rating, this.note, this.relatedImages = const []}) {
        filename = p.basename(path);
    }

    ImageID id;
    String path;
    String filename = "";
    String tags;
    String? note;
    Rating? rating;
    List<String> sources;
    List<ImageID> relatedImages;

    File getImage() => File(path);
}

typedef CollectionID = String;
class BooruCollection {
    BooruCollection({required this.pages, required this.name, required this.id});

    List<ImageID> pages;
    String name;
    CollectionID id;
}

enum Rating {safe, questionable, explicit, illegal}
