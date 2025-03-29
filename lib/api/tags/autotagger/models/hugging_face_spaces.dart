part of tag_manager;

abstract class HuggingFaceSpacesAutotagger extends ModelInterface {
    HuggingFaceSpacesAutotagger(super.file);

    String get HF_SPACE;
    String get HF_PREDICT_ENDPOINT;

    Future<String> uploadFile() async {
        http.MultipartRequest req = http.MultipartRequest("POST", Uri.parse("$HF_SPACE/upload"));
        req.headers['Content-Type'] = 'multipart/form-data';
        req.files.add(http.MultipartFile.fromBytes("files", await file.readAsBytes(), filename: p.basename(file.path)));
        req.fields["format"] = "json";
        http.Response response = await http.Response.fromStream(await req.send());

        final List<String> urls = List<String>.from(JsonDecoder().convert(response.body));

        return urls[0];
    }

    Future<String> createEvent(List<dynamic> data) async {
        final eventResponse = await lbHttp.post(Uri.parse("$HF_SPACE/call/$HF_PREDICT_ENDPOINT"), 
            headers: {"Content-Type": "application/json"},
            body: JsonEncoder().convert({
                "data": data
            })
        );
        final String? eventId = JsonDecoder().convert(eventResponse.body)["event_id"];
        if(eventId == null) throw "Event ID not returned";
        return eventId;
    }

    Future<Map<String, dynamic>> returnEvent(String eventId) async {
        final resultResponse = await lbHttp.get(Uri.parse("$HF_SPACE/call/$HF_PREDICT_ENDPOINT/$eventId"));
        
        final match = RegExp(r'event:\s*complete\s*[\r\n]+data:\s*(.*)').firstMatch(resultResponse.body);
        if(match == null) throw "Invalid response";
        final parsedResponse = match.group(1);
        if(parsedResponse == null) throw "Invalid response";
        final Map<String, dynamic> resultSummary = JsonDecoder().convert(parsedResponse)[1];

        return resultSummary;
    }
}

mixin HuggingFaceWithConfidenceReturn on ModelInterface {
    AccuracyTagList convertConfidence(List<Map<String, dynamic>> resultWithConfidences) {
        AccuracyTagList returnedTags = {};
        for (final tag in resultWithConfidences) {
            final String name = tag["label"];
            if(Metatag.isMetatag(name)) continue;

            returnedTags[name.replaceAll(" ", "_")] = tag["confidence"];
        }
        
        return returnedTags;
    }
}

class JointTaggerProjectAutotagger extends HuggingFaceSpacesAutotagger with TagFilter, HuggingFaceWithConfidenceReturn {
  JointTaggerProjectAutotagger(super.file);

    @override
    String get HF_SPACE => 'https://redrocket-jointtaggerproject-inference.hf.space';
    @override
    String get HF_PREDICT_ENDPOINT => 'run_classifier';

    @override
    Future<AccuracyTagList> execute() async {
        final url = await uploadFile();

        final eventId = await createEvent([
            {"path": url},
            filterPercentage
        ]);

        final resultSummary = await returnEvent(eventId);
        
        return convertConfidence(List<Map<String, dynamic>>.from(resultSummary["confidences"]));
    }
}

class Z3DE621ConvnextAutotagger extends HuggingFaceSpacesAutotagger with TagFilter, HuggingFaceWithConfidenceReturn {
  Z3DE621ConvnextAutotagger(super.file);

    @override
    String get HF_SPACE => 'https://fancyfeast-z3d-e621-convnext-space.hf.space';
    @override
    String get HF_PREDICT_ENDPOINT => 'predict';

    @override
    Future<AccuracyTagList> execute() async {
        final url = await uploadFile();

        final eventId = await createEvent([
            {"path": url}
        ]);

        final resultSummary = await returnEvent(eventId);

        final AccuracyTagList tags = convertConfidence(List<Map<String, dynamic>>.from(resultSummary["confidences"]));
        
        return flterAccurateResults(tags);
    }
}