part of tag_manager;

class DanbooruAutotagger extends ModelInterface with TagFilter {
    DanbooruAutotagger(super.file);

    @override
    Future<AccuracyTagList> execute() async {
        http.MultipartRequest req = http.MultipartRequest("POST", Uri.parse("https://autotagger.donmai.us/evaluate"));
        req.headers['Content-Type'] = 'application/json; charset=UTF-8';
        req.files.add(http.MultipartFile.fromBytes("file", await file.readAsBytes(), filename: p.basename(file.path)));
        req.fields["format"] = "json";
        http.Response response = await http.Response.fromStream(await req.send());

        final AccuracyTagList tags = AccuracyTagList.from(jsonDecode(response.body)[0]["tags"])..removeWhere((tag, _) => Metatag.isMetatag(tag));
        return flterAccurateResults(tags);
    }
}