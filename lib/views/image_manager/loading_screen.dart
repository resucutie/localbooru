import 'package:flutter/material.dart';
import 'package:localbooru/components/window_frame.dart';

class ImageManagerLoadingScreen extends StatelessWidget {
    const ImageManagerLoadingScreen({super.key});

    @override
    Widget build(context) {
        return Scaffold(
            appBar: WindowFrameAppBar(title: "Image manager",
                appBar: AppBar(
                    title: const Text("Add image"),
                ),
            ),
            body: const Center(
                child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    direction: Axis.vertical,
                    spacing: 32,
                    children: [
                        Text("Downloading image"),
                        CircularProgressIndicator()
                    ],
                ),
            )
        );
    }
}