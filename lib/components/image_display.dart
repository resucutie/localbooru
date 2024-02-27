import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gif_view/gif_view.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/image_thumbnailer.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mime/mime.dart';

class SilverRepoGrid extends StatefulWidget {
    const SilverRepoGrid({super.key, required this.images, this.onPressed, this.autoadjustColumns});

    final List<BooruImage> images;
    final Function(BooruImage image)? onPressed;
    final int? autoadjustColumns;

    @override
    State<SilverRepoGrid> createState() => _SilverRepoGridState();
}

class _SilverRepoGridState extends State<SilverRepoGrid> {
    String? getType(String filename) {
        final mime = lookupMimeType(filename)!;
        if(mime.startsWith("video")) return "video";
        if(mime.startsWith("image/gif")) return "gif";
        return "image";
    }
    @override
    void dispose() {
        // clear memory leak
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
        super.dispose();
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
                (widget.autoadjustColumns ?? settingsDefaults["grid_size"])
            )
        ).ceil();

        if(widget.images.isEmpty) {
            return const SizedBox.shrink();
        } else {
            return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                ),
                delegate: SliverChildListDelegate(widget.images.map((image) {
                    return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                                onTap: () {if(widget.onPressed != null) widget.onPressed!(image);},
                                child: Stack(
                                    children: [
                                        AspectRatio(
                                            aspectRatio: 1,
                                            child: getType(image.filename) == "video"
                                                ? VideoPreview(image: image,)
                                                : getType(image.filename) == "gif"
                                                    ? GifView(image: FileImage(image.getImage()), fit: BoxFit.cover, controller: GifController(autoPlay: false),)
                                                    : FutureBuilder(
                                                        future: getImageThumbnail(image),
                                                        builder: (context, snapshot) {
                                                            if(snapshot.hasData) {
                                                                return Image(
                                                                    image: FileImage(snapshot.data!),
                                                                    fit: BoxFit.cover,
                                                                );
                                                            }
                                                            return const Center(child: CircularProgressIndicator(),);
                                                        },
                                                    )
                                        ),
                                        if(getType(image.filename) != "image") Positioned(
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