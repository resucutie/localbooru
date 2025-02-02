part of tag_manager;

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