part of preset;

// any: assumes that it returns an image
Future<PresetImage> anyURLToPresetImage(String url, {HandleChunk? handleChunk}) async {
    final downloadedFileInfo = await downloadFile(Uri.parse(url), handleChunk: handleChunk);

    final mime = lookupMimeType(downloadedFileInfo.path)!;

    if(!(mime.startsWith("image/") || mime.startsWith("video/"))) throw "Unknown file type";
    
    return PresetImage(
        image: downloadedFileInfo,
        sources: [url],
    );
}