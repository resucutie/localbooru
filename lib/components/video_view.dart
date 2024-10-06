import 'dart:io';

import 'package:flutter/material.dart';
import 'package:localbooru/utils/platform_tools.dart';
import 'package:mime/mime.dart';
import 'package:video_player/video_player.dart';

class VideoView extends StatefulWidget {
  const VideoView(this.path, {Key? key}) : super(key: key);
  
  final String path;
  
  @override
  State<VideoView> createState() => VideoViewState();
}

class VideoViewState extends State<VideoView> {
    late VideoPlayerController _controller;


    @override
    void initState() {
        super.initState();

        _controller = VideoPlayerController.file(File(widget.path))
            ..initialize()
            .then((_) {
                setState(() {});
            });
    }

    @override
    void dispose() {
        _controller.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        if(isDesktop()) return const Text("Support for video playback on Desktop was removed");
        return AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
        );
    }
}