import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:localbooru/utils/http_client.dart';
import 'package:localbooru/utils/listeners.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

typedef HandleChunk = Function(List<int> chunk, http.StreamedResponse response);

int hasDownloaded = 0;
Future<File> downloadFile(Uri uri, {HandleChunk? handleChunk, bool followRedirects = true}) async {
    http.Request request;
    http.StreamedResponse response;
    do { // lazy work for redirects; do-while because it'll run once if followRedirects = false
        request = http.Request("GET", uri);
        request.followRedirects = false;
        response = await lbHttp.send(request);   
        if(response.isRedirect) {
            final String? newUrl = response.headers['location'];
            if(newUrl != null) uri = Uri.parse(newUrl);
            else throw "Redirect does not have 'location' header";
        } else break;
    } while (followRedirects);

    final downloadDir = await getTemporaryDirectory();
    final name = uri.pathSegments.last;
    final file = File(p.join(downloadDir.path, name));
    IOSink sink = file.openWrite();

    await response.stream.map((chunk) {
        if(handleChunk == null) {
            hasDownloaded += chunk.length;
            if(response.contentLength != null) importListener.updateImportStatus(progress: hasDownloaded/response.contentLength!);
        } else {
            handleChunk(chunk, response);
        }
        return chunk;
    },).pipe(sink);

    hasDownloaded = 0;
    
    return File(file.path); //makes it so it doesn't return _File
}