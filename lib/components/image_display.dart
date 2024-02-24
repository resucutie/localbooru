import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

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

    String? getType(String filename) {
        final mime = lookupMimeType(filename)!;
        if(mime.startsWith("video")) return "video";
        if(mime.startsWith("image/gif")) return "gif";
        return "image";
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
                        padding: const EdgeInsets.all(4.0),
                        child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                                onTap: () {if(onPressed != null) onPressed!(image);},
                                child: Stack(
                                    children: [
                                        AspectRatio(
                                            aspectRatio: 1,
                                            child: getType(image.filename) == "video"
                                                ? VideoPreview(image: image,)
                                                : Image.file(image.getImage(), fit: BoxFit.cover,),
                                        ),
                                        if(getType(image.filename) != "image") Positioned(
                                            // top:6,
                                            // left:6,
                                            child: Container(
                                                decoration: const BoxDecoration(
                                                    color: Color.fromARGB(160, 0, 0, 0),
                                                    borderRadius: BorderRadius.only(
                                                        bottomRight: Radius.circular(8),
                                                    )
                                                ),
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                child: Text(getType(image.filename)!.toUpperCase(),
                                                    style: const TextStyle(
                                                        fontSize: 12
                                                    ),
                                                ),
                                            ),
                                        ),
                                    ],
                                ),
                            )
                        ),
                    );
                }).toList()),
            );
        }
    }
}

class VideoPreview extends StatefulWidget {
    const VideoPreview({super.key, required this.image});

    final BooruImage image;

    @override
    State<VideoPreview> createState() => _VideoPreviewState();
}
class _VideoPreviewState extends State<VideoPreview> {
    final _player = Player();
    
    Future<Uint8List> getVideoPreview(String videoPath) async {
        final controller = VideoController(_player); // has to be created according to https://github.com/media-kit/media-kit/issues/419#issuecomment-1703855470
        await _player.open(Media(videoPath), play: false);
        await controller.waitUntilFirstFrameRendered;
        await Future.delayed(const Duration(milliseconds: 500)); // idk why but this works
        await _player.seek(Duration.zero); 
        final bytes = await _player.screenshot();
        return bytes!;
    }

    @override
    void dispose() {
        _player.dispose();
        super.dispose();
    }

    @override
    Widget build(context) {
        return FutureBuilder(
            future: getVideoPreview(widget.image.path),
            builder: (context, snapshot) {
                if(snapshot.hasData) return Image.memory(snapshot.data!, fit: BoxFit.cover,);
                if(snapshot.hasError) throw snapshot.error!;
                return const Center(child: CircularProgressIndicator(),);
            }
        );
    }
}