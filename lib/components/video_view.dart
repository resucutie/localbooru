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
                _controller.play();
            });
    }

    @override
    void dispose() {
        _controller.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
                children: [
                    VideoPlayer(_controller),
                    PlayerControls(
                        isPlaying: _controller.value.isPlaying,
                        onPlayPause: _controller.value.isPlaying ? _controller.pause : _controller.play
                    )
                ],
            ),
        );
    }
}

class PlayerControls extends StatelessWidget {
    const PlayerControls({super.key, this.onPlayPause, this.isPlaying});

    final void Function()? onPlayPause;
    final bool? isPlaying;

    @override
    Widget build(BuildContext context) {
        return Row(
            children: [
                ElevatedButton(onPressed: onPlayPause, child: isPlaying == false ? const Text("Play") : const Text("Pause"))
            ],
        );
    }
}