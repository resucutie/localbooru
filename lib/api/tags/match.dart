part of tag_manager;

Future<bool> wouldImageBeSelected({required List<SearchTag> tags, required Map file}) async {
    final List<SearchTag> additionTags = [];
    final List<SearchTag> otherTags = [];

    for (final SearchTag searchTag in tags) {
        if(searchTag.modifier == Modifier.additionModifier) additionTags.add(searchTag);
        else otherTags.add(searchTag);
    }

    bool hasTagWithInclusion = await Future.wait(additionTags.map((additionTag) async {
        // debugPrint("File: ${file["id"]}; fileTags: ${file["tags"]}; searchTag: $tagSearch; doesItInclude: ${tagSearch.startsWith("+")}");
        return await checkIfFileRespectsTag(file: file, tag: additionTag.tag);
    })).then((results) => results.any((result) => result));
    if (hasTagWithInclusion) return true;

    bool hasTag = await Future.wait(otherTags.map((searchTag) async {
        if (searchTag.modifier == Modifier.exclusionModifier) {
            return !(await checkIfFileRespectsTag(file: file, tag: searchTag.tag));
        }
        return await checkIfFileRespectsTag(file: file, tag: searchTag.tag);
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

Future<bool> checkIfFileRespectsTag({required Map file, required Tag tag}) async {
    if(tag is Metatag) {
        switch (tag.selector) {
            case "rating":
                return (tag.value == "none" && file["rating"] == null) // none
                    || ((tag.value == "safe" || tag.value == "s") && file["rating"] == "safe") // safe
                    || ((tag.value == "questionable" || tag.value == "q") && file["rating"] == "questionable") // questionable
                    || ((tag.value == "explicit" || tag.value == "e") && file["rating"] == "explicit") // explicit
                    || ((tag.value == "illegal" || tag.value == "i") && file["rating"] == "illegal") // borderline (old name)
                    || ((tag.value == "borderline" || tag.value == "b") && file["rating"] == "illegal"); // borderline (new name)
            case "id":
                return rangeMatch(double.parse(file["id"]), tag.value) || tag.value == file["id"];
            case "type":
                final String mime = lookupMimeType(file["filename"])!;
                return wildcardMatch(mime, tag.value) || 
                    p.extension(file["filename"]).substring(1) == tag.value ||
                    (tag.value == "animated" && (mime.startsWith("video/") || mime == "image/gif")) ||
                    (tag.value == "static" && (mime.startsWith("image/") && mime != "image/gif"));
            case "file":
                return wildcardMatch(file["filename"], tag.value);
            case "source":
                final List<String> sources = List<String>.from(file["sources"]);
                return sources.any((source) => wildcardMatch(Uri.parse(source).host, tag.value)) || 
                    (tag.value == "none" && sources.isEmpty);
            case "collection":
                final booru = await getCurrentBooru();
                final obtainedCollections = await booru.obtainMatchingCollection(file["id"]);
                return obtainedCollections.any((collection) => rangeMatch(double.parse(collection.id), tag.value) || collection.id == tag.value);
            default:
                return false;
        }
    } else {
        return file["tags"].toLowerCase().contains(_spaceMatch((tag as NormalTag).text));
    }
}

//this was made so that it wouldn't ignore if there was a space on the tag that was being searched for
RegExp _spaceMatch(String match) {
    return RegExp(r"(?<!\\)" + RegExp.escape(match) + r"(?=\W|$)", caseSensitive: false);
}