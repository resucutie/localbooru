import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_compression/image_compression.dart' as imageCompression;
import 'package:image_compression/image_compression_io.dart';
import 'package:localbooru/api/index.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

Future<Directory> obtainThumbnailDirectory() async {
    final String booruPath = (await getCurrentBooru()).path;

    final directory = Directory(p.join(booruPath, "thumbnails"));
    if(!(await Directory(p.join(booruPath, "thumbnails")).exists()))await directory.create();
    return directory;
}

Future<File> getImageThumbnail(BooruImage image) async {
    final filename = image.filename;
    final thumbDir = await obtainThumbnailDirectory();
    
    File thumbnailFile = File("${p.join(thumbDir.path, p.basenameWithoutExtension(filename))}.jpg");
    if(await thumbnailFile.exists()) return thumbnailFile;

    debugPrint("Compressing $filename");

    final compressedImage = await compressToThumbnail(image.getImage());
    debugPrint("Obtained ${p.basename(thumbnailFile.path)}");

    await thumbnailFile.writeAsBytes(compressedImage.rawBytes);

    return thumbnailFile;
}

Future<ImageFile> compressToThumbnail(File file,) async {
    ImageFile input;

    final mime = lookupMimeType(file.path);
    if(mime!.startsWith("video/") || mime == "image/gif") {
        input = ImageFile(
            filePath: file.path,
            rawBytes: await getVideoFirstFrame(file.path)
        );
    } else if(mime.startsWith("image/")) {
        input = ImageFile(
            filePath: file.path,
            rawBytes: await file.readAsBytes()
        );
    } else {
        throw "Unknown file type";
    }

    final compressedImage = await compressImage(input);
    return compressedImage;
}

Future<Uint8List> compress(File file,) async {
    final mime = lookupMimeType(file.path)!;
    if(false/*mime!.startsWith("video/") || mime == "image/gif"*/) {
        // input = ImageFile(
        //     filePath: file.path,
        //     rawBytes: await getFirstFrame(file.path)
        // );
        // return 
    } else if(mime.startsWith("image/")) {
        final compressedImage = await compressImage(ImageFile(
            filePath: file.path,
            rawBytes: await file.readAsBytes()
        ));
        return compressedImage.rawBytes;
    } else {
        throw "Unknown file type";
    }
}



Future<Uint8List> getVideoFirstFrame(String path) async {
    final player = Player();
    final controller = VideoController(player); // has to be created according to https://github.com/media-kit/media-kit/issues/419#issuecomment-1703855470
    
    await player.open(Media(path), play: false);
    await controller.waitUntilFirstFrameRendered;
    await Future.delayed(const Duration(milliseconds: 500)); // idk why but this works
    
    await player.seek(Duration.zero); 
    
    final bytes = await player.screenshot();
    
    player.dispose();
    
    return bytes!;
}

Future<ImageFile> compressImage(ImageFile file, {int quality = 30}) {
    return imageCompression.compressInQueue(imageCompression.ImageFileConfiguration(
        input: file,
        config: imageCompression.Configuration(
            jpgQuality: quality,
        )
    ));
}