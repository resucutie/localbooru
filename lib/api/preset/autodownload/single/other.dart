part of preset;

// any: assumes that it returns an image
Future<PresetImage> anyURLToPreset(String url) async {
    final downloadedFileInfo = await presetCache.downloadFile(url);

    final mime = lookupMimeType(downloadedFileInfo.file.basename)!;

    if(!(mime.startsWith("image/") || mime.startsWith("video/"))) throw "Unknown file type";
    
    return PresetImage(
        image: downloadedFileInfo.file,
        sources: [url],
    );
}