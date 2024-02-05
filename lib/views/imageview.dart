import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:path/path.dart';
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
                            Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.file(image.getImage(), fit: BoxFit.contain),
                            ),
                            ImageViewProprieties(image)
                        ],
                    );
                } else {
                    return Row(
                        children: [
                            Expanded(
                                child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.file(image.getImage(), fit: BoxFit.contain),
                                )
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


class ImageViewProprieties extends StatelessWidget {
    const ImageViewProprieties(this.image, {super.key});

    
    final BooruImage image;

    @override
    Widget build(BuildContext context) {
        final TextStyle linkText = TextStyle(color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline, decorationColor: Theme.of(context).colorScheme.primary);
        
        debugPrint("sources ${image.source}");
        return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                // mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    const Header("Tags"),
                    Wrap(children: image.tags.split(" ").map((e) => Tag(e)).toList()),

                    const Header("Sources"),
                    image.source == null || image.source!.isEmpty ? const Text("None") : Column(
                        children: image.source!.map((e) => MouseRegion(
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

class Header extends StatelessWidget {
    const Header(this.title, {super.key});

    final String title;

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(title, style: const TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold
            )),
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