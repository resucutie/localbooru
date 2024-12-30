import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:localbooru/utils/http_client.dart';
import 'package:localbooru/utils/listeners.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

typedef HandleChunk = Function(List<int> chunk, http.StreamedResponse response);

int hasDownloaded = 0;
Future<File> downloadFile(Uri uri, {HandleChunk? handleChunk}) async {
    final downloadDir = await getTemporaryDirectory();
    final file = File(p.join(downloadDir.path, uri.pathSegments.last));
    
    final request = http.Request("GET", uri);
    final response = await lbHttp.send(request);
    final sink = file.openWrite();

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