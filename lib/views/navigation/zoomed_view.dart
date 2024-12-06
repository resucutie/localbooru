import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/context_menu.dart';
import 'package:localbooru/utils/platform_tools.dart';
import 'package:photo_view/photo_view.dart';
import 'package:localbooru/components/window_frame.dart';
import 'package:window_manager/window_manager.dart';


class ImageViewZoom extends StatefulWidget {
    const ImageViewZoom(this.image, {super.key});

    final BooruImage image;
  
    @override
    State<ImageViewZoom> createState() => _ImageViewZoomState();
}

class _ImageViewZoomState extends State<ImageViewZoom> {

    PhotoViewController controller = PhotoViewController();

    @override
    void dispose() {
        controller.dispose();
        super.dispose();
    }

    void zoom(num scaleFactor) {
        controller.scale = (controller.scale ?? 1) * scaleFactor;
        controller.position = Offset(controller.position.dx * scaleFactor, controller.position.dy * scaleFactor);
    }

    @override
    Widget build(BuildContext context) {
        return OrientationBuilder(
            builder: (context, orientation) {
                final AppBar appBar = AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: Text(widget.image.filename),
                    actions: [
                        if(orientation == Orientation.landscape) ...[
                            IconButton(
                                icon: const Icon(Icons.zoom_in),
                                onPressed: () => zoom(1.5),
                            ),
                            IconButton(
                                icon: const Icon(Icons.zoom_out),
                                onPressed: () => zoom(0.7),
                            )
                        ],
                        PopupMenuButton(
                            itemBuilder: (context) => imageShareItems(widget.image),
                        ),
                    ],
                );
                return Theme(
                    data: ThemeData.dark(),
                    child: Scaffold(
                        extendBodyBehindAppBar: true,
                        backgroundColor: Colors.transparent,
                        appBar: isDesktop() ? PreferredSize(
                            preferredSize: Size.fromHeight(32 + appBar.preferredSize.height),
                            child: Container(
                                color: const Color.fromARGB(150, 0, 0, 0),
                                child: Wrap(
                                    direction: Axis.horizontal,
                                    children: [
                                        const WindowFrameAppBar(title: null),
                                        GestureDetector(
                                            onTapDown: (details) => windowManager.startDragging(),
                                            child: appBar,
                                        )
                                    ],
                                ),
                            ),
                        ) : appBar,
                        // appBar: appBar,
                        body: Listener(
                            onPointerSignal:(event) {
                                if(event is PointerScrollEvent) {
                                    double scrollBy = .15;
                                    if(!event.scrollDelta.dy.isNegative) {
                                        if((controller.scale ?? 1) <= .1) return;
                                        scrollBy = -scrollBy;
                                    }
                                    zoom(1 + scrollBy);
                                }
                            },
                            child: GestureDetector(
                                onVerticalDragEnd: (details) {
                                    if(details.velocity.pixelsPerSecond.dy.abs() > 0) context.pop();
                                },
                                child: PhotoViewGestureDetectorScope(
                                    axis: Axis.vertical,
                                    child: PhotoView(
                                        imageProvider: FileImage(widget.image.getImage()),
                                        heroAttributes: const PhotoViewHeroAttributes(tag: "detailed"),
                                        minScale: .1,
                                        controller: controller,
                                    ),
                                ),
                            )
                        )
                    ),
                );
            }
        );
    }
}