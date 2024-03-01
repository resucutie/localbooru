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

    ImageFile input;

    final mime = lookupMimeType(image.filename);
    if(mime!.startsWith("video/") || mime == "image/gif") {
        input = ImageFile(
            filePath: image.path,
            rawBytes: await getVideoThumbnail(image.path)
        );
    } else if(mime.startsWith("image/")) {
        input = ImageFile(
            filePath: image.path,
            rawBytes: await image.getImage().readAsBytes()
        );
    } else {
        throw "Unknown file type";
    }


    debugPrint("Compressing $filename");

    final compressedImage = await compressImage(input, thumbnailFile.path);

    debugPrint("Obtained ${p.basename(thumbnailFile.path)}");

    await thumbnailFile.writeAsBytes(compressedImage.rawBytes);

    return thumbnailFile;
}

Future<Uint8List> getVideoThumbnail(String path) async {
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

Future<ImageFile> compressImage(ImageFile file, String path) {
    return imageCompression.compressInQueue(imageCompression.ImageFileConfiguration(
        input: file,
        config: const imageCompression.Configuration(
            jpgQuality: 30,
        )
    ));
}