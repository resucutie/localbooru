part of tag_manager;

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