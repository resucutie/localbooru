import 'dart:async';
import 'dart:io';

import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/misc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:path/path.dart' as p;

Future<List<SimpleFileFormat>> obtainValidFileTypeOnClipboard(ClipboardReader reader) async {
    return SuperFormats.all.where((format) => reader.canProvide(format),).toList();
}
Future<File> getImageFromClipboard({required ClipboardReader reader, required SimpleFileFormat fileType}) async {
    final downloadDir = await getTemporaryDirectory();

    final completer = Completer<File>();
    final progress = reader.getFile(fileType, (clipboardFile) async {
        String? name = clipboardFile.fileName;
        if(name == null) {
             final ext = SuperFormats.getFileExtensionFromFormat(fileType);
             assert(ext != null, Exception("Could not obtain file extension"));
             name = p.setExtension(getRandomString(20), ".$ext");
        }
        final file = File(p.join(downloadDir.path, name));

        try {
            final sink = file.openWrite();
            await clipboardFile.getStream().map((event) { //convert to List<int>
                return event.map((e) => e,).toList();
            },).pipe(sink);
            completer.complete(file);
        } catch (e) {
            completer.completeError(e);
        }
    }, onError: completer.completeError,);
    if(progress == null) completer.completeError(FileSystemException("File on clipboard is empty"));

    return await completer.future;
}