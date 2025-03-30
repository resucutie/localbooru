part of tag_manager;

abstract class GradioAutotagger extends ModelInterface with CanCustomTaggingServer {
    GradioAutotagger(super.file);

    String get GRADIO_PROCESS_ENDPOINT;

    Future<String> uploadFile() async {
        http.MultipartRequest req = http.MultipartRequest("POST", host.replace(path: "upload"));
        req.headers['Content-Type'] = 'multipart/form-data';
        req.files.add(http.MultipartFile.fromBytes("files", await file.readAsBytes(), filename: p.basename(file.path)));
        req.fields["format"] = "json";
        http.Response response = await http.Response.fromStream(await req.send());

        final List<String> urls = List<String>.from(JsonDecoder().convert(response.body));

        return urls[0];
    }

    Future<String> createEvent(List<dynamic> data) async {
        debugPrint(host.toString());
        final eventResponse = await lbHttp.post(host.replace(path: "call/$GRADIO_PROCESS_ENDPOINT"), 
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
        final resultResponse = await lbHttp.get(host.replace(path: "call/$GRADIO_PROCESS_ENDPOINT/$eventId"));
        
        final match = RegExp(r'event:\s*complete\s*[\r\n]+data:\s*(.*)').firstMatch(resultResponse.body);
        if(match == null) throw "Invalid response";
        final parsedResponse = match.group(1);
        if(parsedResponse == null) throw "Invalid response";
        final Map<String, dynamic> resultSummary = JsonDecoder().convert(parsedResponse)[1];

        return resultSummary;
    }
}

mixin GradioWithConfidenceReturn on ModelInterface {
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

class JointTaggerProjectAutotagger extends GradioAutotagger with TagFilter, GradioWithConfidenceReturn {
  JointTaggerProjectAutotagger(super.file);

    @override
    Uri get DEFAULT_SERVER_HOST => Uri(scheme: "https", host: "jointtag.enzomtp.party"); // resources donated by enzomtpYT (https://github.com/enzomtpYT)
    @override
    String get GRADIO_PROCESS_ENDPOINT => 'run_classifier';

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

class Z3DE621ConvnextAutotagger extends GradioAutotagger with TagFilter, GradioWithConfidenceReturn {
  Z3DE621ConvnextAutotagger(super.file);

    @override
    Uri get DEFAULT_SERVER_HOST => Uri(scheme: "https", host: "z3d.enzomtp.party"); // resources donated by enzomtpYT (https://github.com/enzomtpYT)
    @override
    String get GRADIO_PROCESS_ENDPOINT => 'predict';

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