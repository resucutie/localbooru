import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoView extends StatefulWidget {
  const VideoView(this.path, {super.key, this.showControls = true});
  
  final String path;
  final bool showControls;
  
  @override
  State<VideoView> createState() => VideoViewState();
}

class VideoViewState extends State<VideoView> {
    late VideoPlayerController _videoController;
    late ChewieController _chewieController;
    bool _isLoaded = false;


    @override
    void initState() {
        super.initState();

        _videoController = VideoPlayerController.file(File(widget.path))
            ..initialize().then((value) {        
                _chewieController = ChewieController(
                    videoPlayerController: _videoController,
                    autoPlay: true,
                    looping: true,
                    allowFullScreen: false, // apparently full screen calls dispose()
                    showControls: widget.showControls
                );
                setState(() {
                    _isLoaded = true;
                });
            },);
    }

    @override
    void dispose() {
        _videoController.dispose();
        _chewieController.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return AspectRatio(
            aspectRatio: _videoController.value.aspectRatio,
            child: _isLoaded ? Chewie(controller: _chewieController,) : const SizedBox(height: 0,)
        );
    }
}