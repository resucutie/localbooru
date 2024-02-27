import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_compression/image_compression.dart' as imageCompression;
import 'package:image_compression/image_compression_io.dart';
import 'package:localbooru/api/index.dart';
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

    final input = ImageFile(
        filePath: image.path,
        rawBytes: await image.getImage().readAsBytes()
    );

    debugPrint("Compressing $filename");

    final compressedImage = await compressImage(input, thumbnailFile.path);

    debugPrint("Obtained ${p.basename(thumbnailFile.path)}");

    await thumbnailFile.writeAsBytes(compressedImage.rawBytes);

    return thumbnailFile;
}

Future<ImageFile> compressImage(ImageFile file, String path) {
    return imageCompression.compressInQueue(imageCompression.ImageFileConfiguration(
        input: file,
        config: const imageCompression.Configuration(
            jpgQuality: 30,
        )
    ));
}