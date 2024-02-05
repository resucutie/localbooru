
part of localbooru_api;

// ignore: constant_identifier_names
const int INDEX_IMAGE_LIMIT = 30;

class Booru {
    Booru(this.path);
    
    String path;

    Future<Map> getRawInfo() async {
        final File file = File(p.join(path, "repoinfo.json"));
        final String fileinfo = await file.readAsString();
        final Map json = jsonDecode(fileinfo);
        return json;
    }

    Future<BooruImage> getImage(String id) async {
        final List files = (await getRawInfo())["files"];
        
        //check if metadata exists
        // if(!files.asMap().containsKey(id)) throw "File of index $id does not exist";
        var fileToCheck = files.firstWhere((file) => file["id"] == id);
        if(fileToCheck == null) throw "File  $id does not exist";
        if(fileToCheck is! Map) throw "File  $id doesn't contain valid metadata";
        
        //cehck if metadata is valid
        final metadataToCheck = ["filename", "tags", "id"];
        for (String metadata in metadataToCheck) {
            if(!fileToCheck.containsKey(metadata)) throw "File  $id doesn't contain property $metadata";
        }

        return BooruImage(
            id: id,
            path: p.join(path, "files", fileToCheck["filename"]),
            tags: fileToCheck["tags"],
            source: List<String>.from(fileToCheck["source"] ?? []) 
        );
    }

    Future<List<BooruImage>> getImagesFromRange(List list, {required int from, required int to}) async {
        final List rangedList = list.getRange(from, to).toList();
        // debugPrint("rangedList: $rangedList");

        List<BooruImage> mappedList = [];
        for (Map item in rangedList) {
            mappedList.add(await getImage(item["id"]));
        }
        return mappedList.reversed.toList();
    }

    Future<List<BooruImage>> getImagesFromIndex(List list, {int index = 0, int size = INDEX_IMAGE_LIMIT}) async {
        final int length = list.length;

        int from = length - (INDEX_IMAGE_LIMIT * (index + 1));
        int to = length - (INDEX_IMAGE_LIMIT * index);
        if(from < 0) from = 0;
        if(to < 0) to = length;

        final List<BooruImage> range = await getImagesFromRange(list, from: from, to: to);

        return range;
    }

    Future<List<BooruImage>> getRecentImages() async => await getImagesFromIndex((await getRawInfo())["files"]);

    Future<List> _doTagFiltering(String tags) async {
        final tagList = tags.split(" ");
        final List files = (await getRawInfo())["files"];
        final List filteredFiles = files.where((file) {
            return tagList.any((tag) => file["tags"].toLowerCase().contains(tag));
        }).toList();

        return filteredFiles;
    }

    Future<List<BooruImage>> searchByTags(String tags, {int index = 0}) async => await getImagesFromIndex(await _doTagFiltering(tags), index: index);

    Future<int> getIndexNumberLength(tags, {int size = INDEX_IMAGE_LIMIT}) async {
        final list = await _doTagFiltering(tags);

        return (list.length / size).ceil();
    }
}

class BooruImage {
    BooruImage({required this.id, required this.path, required this.tags, this.source}) {
        filename = p.basename(path);
    }

    String id;
    String path;
    String filename = "";
    String tags;
    List<String>? source;

    File getImage() => File(path);
}