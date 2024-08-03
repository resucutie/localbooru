import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:localbooru/utils/listeners.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<File> downloadFile(Uri uri) async {
    final downloadDir = await getTemporaryDirectory();
    final file = File(p.join(downloadDir.path, uri.pathSegments.last));
    
    final request = http.Request("GET", uri);
    final response = await request.send();
    final sink = file.openWrite();
    
    int hasDownloaded = 0;
    await response.stream.map((chunk) {
        hasDownloaded += chunk.length;
        if(response.contentLength != null) importListener.updateImportStatus(progress: hasDownloaded/response.contentLength!);
        return chunk;
    },).pipe(sink);
    
    return File(file.path); //makes it so it doesn't return _File
}
