import 'dart:convert';
import 'dart:io';

import 'package:ffmpeg_cli/ffmpeg_cli.dart';
import 'package:flutter/material.dart';
import 'package:image_compression/image_compression.dart' as imageCompression;
import 'package:image_compression/image_compression_io.dart';
import 'package:localbooru/api/index.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
    /*if(mime!.startsWith("video/") || mime == "image/gif") {
        input = ImageFile(
            filePath: file.path,
            rawBytes: await getVideoFirstFrame(file.path)
        );
    } else*/ if(mime!.startsWith("image/")) {
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

// update to not depend on media_kit
// Future<Uint8List> getVideoFirstFrame(String path) async {
//     final player = Player();
//     final controller = VideoController(player); // has to be created according to https://github.com/media-kit/media-kit/issues/419#issuecomment-1703855470
    
//     await player.open(Media(path), play: false);
//     await controller.waitUntilFirstFrameRendered;
//     await Future.delayed(const Duration(milliseconds: 500)); // idk why but this works
    
//     await player.seek(Duration.zero); 
    
//     final bytes = await player.screenshot();
    
//     player.dispose();
    
//     return bytes!;
// }


Future<File> compress(File file) async {
    final tempDir = await getTemporaryDirectory();
    
    final mime = lookupMimeType(file.path)!;
    if(mime.startsWith("video/") || mime == "image/gif") {
        final compressedVideo = await compressVideo(file);
        return compressedVideo;
    } else if(mime.startsWith("image/")) {
        final compressedImage = await compressImage(ImageFile(
            filePath: file.path,
            rawBytes: await file.readAsBytes()
        ), quality: 80);
        final newFile = File("${p.join(tempDir.path, p.basenameWithoutExtension(file.path))}.jpg");
        await newFile.writeAsBytes(compressedImage.rawBytes);
        return newFile;
    } else {
        throw "Unknown file type";
    }
}

Future<ImageFile> compressImage(ImageFile file, {int quality = 30}) {
    return imageCompression.compressInQueue(imageCompression.ImageFileConfiguration(
        input: file,
        config: imageCompression.Configuration(
            jpgQuality: quality,
        )
    ));
}

Future<File> compressVideo(File file, {int crf = 32}) async {
    // FFmpeg ffmpeg = createFFmpeg(CreateFFmpegParam(log: true, corePath: 'https://unpkg.com/@ffmpeg/core@0.11.0/dist/ffmpeg-core.js'));

    // await ffmpeg.load();

    // final extension = p.extension(file.path);

    // final inputFile = "input$extension";
    // final outputFile = "output$extension";

    // ffmpeg.writeFile(inputFile, await file.readAsBytes());

    // await ffmpeg.run(["-i", inputFile, "-crf", crf.toString(), "-o", outputFile]);

    // final data = ffmpeg.readFile(outputFile);

    // return data;

    final tempDir = await getTemporaryDirectory();
    final outputPath = p.join(tempDir.path, p.basename(file.path));

    final command = FfmpegCommand.simple(
        inputs: [
            FfmpegInput.asset(file.path)
        ],
        args: [
            CliArg(name: "crf", value: "$crf"),
            const CliArg(name: "y")
        ],
        outputFilepath: outputPath
    );

    debugPrint("Running ${command.expectedCliInput()}");

    final process = await Ffmpeg().run(command);

    // Pipe the process output to the Dart console.
    process.stderr.transform(utf8.decoder).listen((data) {
        debugPrint(data);
    });

    // // Allow the user to respond to FFMPEG queries, such as file overwrite
    // // confirmations.
    // stdin.pipe(process.stdin);

    debugPrint("processHell");

    await process.exitCode;

    return File(outputPath);
}