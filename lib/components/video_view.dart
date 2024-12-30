import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoView extends StatefulWidget {
  const VideoView(this.path, {super.key, this.showControls = true, this.soundOnStart = true, this.playOnStart = true});
  
  final String path;
  final bool showControls;
  final bool soundOnStart;
  final bool playOnStart;
  
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
                    autoPlay: widget.playOnStart,
                    looping: true,
                    allowFullScreen: false, // apparently full screen calls dispose()
                    showControls: widget.showControls
                );
				if(!widget.soundOnStart) _videoController.setVolume(0);
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
            child: _isLoaded ? VisibilityDetector(
                key: Key("unique key"),
                onVisibilityChanged: (info) {
                    debugPrint("${info.visibleFraction} of my widget is visible");
                    if(info.visibleFraction == 0){
                        _videoController.pause();
                    }
                    else{
                        _videoController.play();
                    }
                },
                child: Chewie(controller: _chewieController,)
            ): const SizedBox(height: 0,)
        );
    }
}