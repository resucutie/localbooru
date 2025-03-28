part of tag_manager;

typedef AccuracyTagList = Map<String, double>;

abstract class ModelInterface {
    ModelInterface(this.file, this.filterPercentage);

    File file;
    double filterPercentage = 0.3;
    Future<AccuracyTagList> execute();

    @protected
    AccuracyTagList flterAccurateResults(AccuracyTagList tags) {
        return AccuracyTagList.from(tags)..removeWhere((tag, accuracy) => accuracy < filterPercentage);
    }
}

class DanbooruAutotagger extends ModelInterface {
  DanbooruAutotagger(super.file, super.filterPercentage);

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