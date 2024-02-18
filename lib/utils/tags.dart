import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

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

class TagSearchParams {
    const TagSearchParams(this.tagSearch);

    final String tagSearch;

    String get raw {
        if(obtainSelector() != null) return tagSearch.substring(1);
        else return tagSearch;
    }

    String? obtainSelector(){
        final String firstElement = tagSearch[0];
        if(selectors.contains(firstElement)) return firstElement;
        return null;
    }
}

bool shouldBeIncluded({required List<String> tagList, required String fileTags}) {
    return tagList
    .any((tag) => tag.startsWith("+") ? fileTags.contains(_spaceMatch(tag.substring(1))) : false) || tagList
    .every((tagSearch) {
        final tag = TagSearchParams(tagSearch);
        if(tag.obtainSelector() == "-") {
            return !fileTags.contains(_spaceMatch(tag.raw));
        }
        return fileTags.contains(_spaceMatch(tag.raw));
    });
}

//this was made so that it wouldn't ignore if there was a space on the tag that was being searched for
RegExp _spaceMatch(String match) {
    return RegExp(r"(?<!\\)" + RegExp.escape(match) + r"(?=\W|$)", caseSensitive: false);
}