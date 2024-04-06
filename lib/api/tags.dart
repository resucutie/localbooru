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
    final AccuracyTagList tags = AccuracyTagList.from(jsonDecode(response.body)[0]["tags"]);
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

    bool isMetatag() => text.contains(":");
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

bool wouldImageBeSelected({required List<String> inputTags, required Map file}) {
    return
        inputTags.any((tag) => tag.startsWith("+") ? doTagMatch(file: file, tag: TagText(tag)) : false)
        || inputTags.where((t) => !t.startsWith("+")).every((tagSearch) {
            final tag = TagText(tagSearch);
            if(tag.obtainSelector() == "-") {
                return !doTagMatch(file: file, tag: tag);
            }
            return doTagMatch(file: file, tag: tag);
        });
}

bool doTagMatch({required Map file, required TagText tag}) {
    if(tag.isMetatag()) {
        final Metatag metatag = Metatag(tag);
        switch (metatag.selector) {
            case "rating" :
                final ret = ((metatag.value == "safe" || metatag.value == "s") && file["rating"] == "safe")
                    || ((metatag.value == "questionable" || metatag.value == "q") && file["rating"] == "questionable")
                    || ((metatag.value == "explicit" || metatag.value == "e") && file["rating"] == "explicit")
                    || ((metatag.value == "illegal" || metatag.value == "i") && file["rating"] == "illegal");
                // debugPrint("checking for ${tag.rawText} on ${file["filename"]}, $ret");
                return ret;
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