import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/context_menu.dart';
import 'package:localbooru/utils/platform_tools.dart';
import 'package:photo_view/photo_view.dart';
import 'package:localbooru/components/window_frame.dart';


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

    @override
    Widget build(BuildContext context) {
        final AppBar appBar = AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(widget.image.filename),
            actions: [
                PopupMenuButton(
                    itemBuilder: (context) => imageShareItems(widget.image),
                )
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
                                appBar
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
                            controller.scale = (controller.scale ?? 1) * (1 + scrollBy);
                            controller.position = Offset(controller.position.dx * (1 + scrollBy), controller.position.dy * (1 + scrollBy));
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
}