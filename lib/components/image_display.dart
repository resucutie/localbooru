import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;


class SilverRepoGrid extends StatelessWidget {
    const SilverRepoGrid({super.key, required this.images, this.onPressed, this.autoadjustColumns});
    final List<BooruImage> images;
    final Function(BooruImage image)? onPressed;
    final int? autoadjustColumns;

    Future<Uint8List> getVideoPreview(String videoPath) async {
        if(!lookupMimeType(p.basename(videoPath))!.startsWith("video/")) throw "Not a video";

        final player = Player();
        final controller = VideoController(player); // has to be created according to https://github.com/media-kit/media-kit/issues/419#issuecomment-1703855470
        await player.open(Media(videoPath), play: false);
        await controller.waitUntilFirstFrameRendered;
        await Future.delayed(const Duration(seconds: 1));
        await player.seek(Duration.zero); 
        final bytes = await player.screenshot();
        return bytes!;
    }
  
    @override
    Widget build(BuildContext context) {
        // it is formatted in this way for better visibility of the formula
        int columns = (
            MediaQuery.of(context).size.width
            /
            (
                (20*50)
                /
                (autoadjustColumns ?? settingsDefaults["grid_size"])
            )
        ).ceil();

        if(images.isEmpty) {
            return const SizedBox.shrink();
        } else {
            return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                ),
                delegate: SliverChildListDelegate(images.map((image) {
                    return Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                                onTap: () {if(onPressed != null) onPressed!(image);},
                                child: FutureBuilder(
                                    future: getVideoPreview(image.path),
                                    builder: (context, snapshot) {
                                        if(snapshot.hasData || snapshot.hasError) {
                                            return Image(
                                                image: !snapshot.hasError
                                                    ? MemoryImage(snapshot.data!)
                                                    : FileImage(image.getImage()) as ImageProvider, 
                                                fit: BoxFit.cover
                                            );
                                        }
                                        if(snapshot.hasError && snapshot.error != "Not a video") throw snapshot.error!;
                                        return const Center(child: CircularProgressIndicator(),);
                                    })
                            ),
                        ),
                    );
                }).toList()),
            );
        }
    }
}