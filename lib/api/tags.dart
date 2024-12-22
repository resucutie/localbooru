part of localbooru_api;

typedef AccuracyTagList = Map<String, double>;

Future<AccuracyTagList> autoTag(File file) async {
    //fetch it
    http.MultipartRequest req = http.MultipartRequest("POST", Uri.parse("https://autotagger.donmai.us/evaluate"));
    req.headers['Content-Type'] = 'application/json; charset=UTF-8';
    req.files.add(http.MultipartFile.fromBytes("file", await file.readAsBytes(), filename: p.basename(file.path)));
    req.fields["format"] = "json";
    http.Response response = await http.Response.fromStream(await req.send());

    // process it
    final AccuracyTagList tags = AccuracyTagList.from(jsonDecode(response.body)[0]["tags"])..removeWhere((tag, _) => TagText(tag).isMetatag());
    return tags;
}

AccuracyTagList filterAccurateResults(AccuracyTagList tags, double filterPercentage) {
    return AccuracyTagList.from(tags)..removeWhere((tag, accuracy) => accuracy < filterPercentage);
}

final List<String> selectors = ["+", "-"];

class TagText {
    const TagText(this.rawText);

    final String rawText;

    String get text {
        if(obtainSelector() != null) {
            return rawText.substring(1);
        } else {
            return rawText;
        }
    }

    String? obtainSelector(){
        final String firstElement = rawText[0];
        if(selectors.contains(firstElement)) return firstElement;
        return null;
    }

    bool isMetatag() {
        final split = text.split(":");
        return split.length == 2 && split.first.isNotEmpty && split.last.isNotEmpty;
    }
}

class Metatag {
    Metatag(this.rawTag) {
        if(!rawTag.isMetatag()) throw "${rawTag.text} is not a metatag";

        final List<String> split = rawTag.text.split(":");
        selector = split[0];
        value = split[1];
    }
    
    final TagText rawTag;

    late String selector;
    late String value;
}

Future<bool> wouldImageBeSelected({required List<String> inputTags, required Map file}) async {
    bool hasTagWithInclusion = await Future.wait(inputTags.where((t) => t.startsWith("+")).map((tagSearch) async {
        // debugPrint("File: ${file["id"]}; fileTags: ${file["tags"]}; searchTag: $tagSearch; doesItInclude: ${tagSearch.startsWith("+")}");
        return await doTagMatch(file: file, tag: TagText(tagSearch));
    })).then((results) => results.any((result) => result));
    if (hasTagWithInclusion) return true;

    bool hasTag = await Future.wait(inputTags.where((t) => !t.startsWith("+")).map((tagSearch) async {
        final tag = TagText(tagSearch);
        if (tag.obtainSelector() == "-") {
            return !(await doTagMatch(file: file, tag: tag));
        }
        return await doTagMatch(file: file, tag: tag);
    })).then((results) => results.every((result) => result));

    return hasTag;
}

// Future<bool> wouldImageBeSelected({required List<String> inputTags, required Map file}) async {
//     return
//         inputTags.any((tag) => tag.startsWith("+") ? (await doTagMatch(file: file, tag: TagText(tag))) : false)
//         || inputTags.where((t) => !t.startsWith("+")).every((tagSearch) {
//             final tag = TagText(tagSearch);
//             if(tag.obtainSelector() == "-") {
//                 return !(await doTagMatch(file: file, tag: tag));
//             }
//             return (await doTagMatch(file: file, tag: tag));
//         });
// }

Future<bool> doTagMatch({required Map file, required TagText tag}) async {
    if(tag.isMetatag()) {
        final Metatag metatag = Metatag(tag);
        switch (metatag.selector) {
            case "rating":
                return (metatag.value == "none" && file["rating"] == null) // none
                    || ((metatag.value == "safe" || metatag.value == "s") && file["rating"] == "safe") // safe
                    || ((metatag.value == "questionable" || metatag.value == "q") && file["rating"] == "questionable") // questionable
                    || ((metatag.value == "explicit" || metatag.value == "e") && file["rating"] == "explicit") // explicit
                    || ((metatag.value == "illegal" || metatag.value == "i") && file["rating"] == "illegal") // borderline (old name)
                    || ((metatag.value == "borderline" || metatag.value == "b") && file["rating"] == "illegal"); // borderline (new name)
            case "id":
                return rangeMatch(double.parse(file["id"]), metatag.value) || metatag.value == file["id"];
            case "type":
                final String mime = lookupMimeType(file["filename"])!;
                return wildcardMatch(mime, metatag.value) || 
                    p.extension(file["filename"]).substring(1) == metatag.value ||
                    (metatag.value == "animated" && (mime.startsWith("video/") || mime == "image/gif")) ||
                    (metatag.value == "static" && (mime.startsWith("image/") && mime != "image/gif"));
            case "file":
                return wildcardMatch(file["filename"], metatag.value);
            case "source":
                final List<String> sources = List<String>.from(file["sources"]);
                return sources.any((source) => wildcardMatch(Uri.parse(source).host, metatag.value)) || 
                    (metatag.value == "none" && sources.isEmpty);
            case "collection":
                final booru = await getCurrentBooru();
                final obtainedCollections = await booru.obtainMatchingCollection(file["id"]);
                debugPrint("${file["id"]} $obtainedCollections");
                return obtainedCollections.any((collection) => rangeMatch(double.parse(collection.id), metatag.value) || collection.id == metatag.value);
            default:
                return false;
        }
    } else {
        return file["tags"].toLowerCase().contains(_spaceMatch(tag.text));
    }
}

//this was made so that it wouldn't ignore if there was a space on the tag that was being searched for
RegExp _spaceMatch(String match) {
    return RegExp(r"(?<!\\)" + RegExp.escape(match) + r"(?=\W|$)", caseSensitive: false);
}