import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mime/mime.dart';

class VideoView extends StatefulWidget {
  const VideoView(this.path, {Key? key}) : super(key: key);
  
  final String path;
  
  @override
  State<VideoView> createState() => VideoViewState();
}

class VideoViewState extends State<VideoView> {
    late final player = Player();

    late final controller = VideoController(player);

    @override
    void initState() {
        super.initState();

        player.open(Media(widget.path), play: lookupMimeType(widget.path) == "image/gif");
        player.setPlaylistMode(PlaylistMode.single);
    }

    @override
    void dispose() {
        player.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.width,
            child: Video(controller: controller, fill: Colors.transparent),
        );
    }
}