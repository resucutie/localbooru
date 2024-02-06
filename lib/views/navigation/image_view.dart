import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/header.dart';
import 'package:localbooru/components/window_frame.dart';
import 'package:localbooru/views/navigation/index.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ImageView extends StatelessWidget {
    const ImageView({super.key, required this.image});

    final BooruImage image;

    @override
    Widget build(BuildContext context) {
        return OrientationBuilder(
            builder: (context, orientation) {
                if(orientation == Orientation.portrait) {
                    return ListView(
                        children: [
                            ImageViewDisplay(image),
                            ImageViewProprieties(image)
                        ],
                    );
                } else {
                    return Row(
                        children: [
                            Expanded(
                                child: ImageViewDisplay(image)
                            ),
                            ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 400.0),
                                child: ListView(
                                    children: [
                                        ImageViewProprieties(image)
                                    ],
                                )
                            )
                            
                        ],
                    );
                }
            },
        );
    }
}

class ImageViewDisplay extends StatelessWidget {
    const ImageViewDisplay(this.image, {super.key});

    final BooruImage image;

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Listener(
                child: Image.file(image.getImage(), fit: BoxFit.contain),
                onPointerDown: (PointerDownEvent event) async {
                    if(event.buttons == kPrimaryMouseButton) context.push("/dialogs/zoom_image/${image.id}");
                    if(event.buttons == kSecondaryMouseButton) {
                        await showMenu(
                            context: context,
                            position: RelativeRect.fromSize(event.position & const Size(48.0, 48.0), (Overlay.of(context).context.findRenderObject() as RenderBox).size),
                            items: imageShareItems(image)
                        );
                    }
                },
            ),
        );
    }
}

class ImageViewZoom extends StatelessWidget {
    const ImageViewZoom(this.image, {super.key});

    final BooruImage image;

    final Color _appBarColor = const Color.fromARGB(150, 0, 0, 0);

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: Colors.transparent,
            appBar: WindowFrameAppBar(
                title: "Zoom",
                backgroundColor: _appBarColor,
                appBar: AppBar(
                    // systemOverlayStyle: SystemUiOverlayStyle(statusBarColor: Colors.transparent),
                    backgroundColor: _appBarColor,
                    elevation: 0,
                    title: Text(image.filename),
                ),
            ),
            body: InteractiveViewer(
                minScale: 0.1,
                maxScale: double.infinity,
                boundaryMargin: EdgeInsets.all((MediaQuery.of(context).size.width + MediaQuery.of(context).size.height) / 4),
                child: Center(
                    child: Image.file(image.getImage())
                )
            ),
        );
    }
}

class ImageViewProprieties extends StatelessWidget {
    const ImageViewProprieties(this.image, {super.key});

    
    final BooruImage image;

    @override
    Widget build(BuildContext context) {
        final TextStyle linkText = TextStyle(color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline, decorationColor: Theme.of(context).colorScheme.primary);
        
        // debugPrint("sources ${image.source}");
        return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                // mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    const Header("Tags"),
                    Wrap(children: image.tags.split(" ").map((e) => Tag(e)).toList()),

                    const Header("Sources"),
                    image.sources == null || image.sources!.isEmpty ? const Text("None") : Column(
                        children: image.sources!.map((e) => MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                                onTap: () => launchUrlString(e),
                                child: Text(e, style: linkText)
                            )
                        )).toList()
                    ),

                    const Header("Other"),
                    SelectableText("Path: ${image.path}")
                ],
            ),
        );
    }
}

class Tag extends StatefulWidget {
    const Tag(this.tag, {super.key});

    final String tag;

    @override
    State<Tag> createState() => _TagState();
}
class _TagState extends State<Tag> {
    bool _isHovering = false;

    @override
    Widget build(BuildContext context) {
        const color = Colors.blueAccent;

        return GestureDetector(
            onTap: () => context.push("/search/?tag=${widget.tag}"),
            child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (details) => setState(() => _isHovering = true),
                onExit: (details) => setState(() => _isHovering = false),
                child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(widget.tag, style: TextStyle(color: color, decoration: _isHovering ? TextDecoration.underline : null, decorationColor: color)),
                ),
            )
        );
    }
}