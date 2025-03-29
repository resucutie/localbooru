part of tag_manager;

abstract class HuggingFaceSpacesAutotagger extends ModelInterface with TagFilter {
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

class JointTaggerProjectAutotagger extends HuggingFaceSpacesAutotagger {
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
        
        final List<Map<String, dynamic>> resultWithConfidences = List<Map<String, dynamic>>.from(resultSummary["confidences"]);

        AccuracyTagList returnedTags = {};
        for (final tag in resultWithConfidences) {
            returnedTags[(tag["label"] as String).replaceAll(" ", "_")] = tag["confidence"];
        }
        
        return returnedTags;
    }
}