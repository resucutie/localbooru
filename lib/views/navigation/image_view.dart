import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/context_menu.dart';
import 'package:localbooru/components/fileinfo.dart';
import 'package:localbooru/components/headers.dart';
import 'package:localbooru/components/window_frame.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/get_website.dart';
import 'package:localbooru/utils/shared_prefs_widget.dart';
import 'package:mime/mime.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:media_kit/media_kit.dart'; // Provides [Player], [Media], [Playlist] etc.
import 'package:media_kit_video/media_kit_video.dart'; // Provides [VideoController] & [Video] etc.        

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
                            ImageViewProprieties(image, renderObject: context.findRenderObject())
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
                                        ImageViewProprieties(image, renderObject: context.findRenderObject(),)
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

class ImageViewDisplay extends StatefulWidget {
    const ImageViewDisplay(this.image, {super.key});

    final BooruImage image;

    @override
    State<ImageViewDisplay> createState() => _ImageViewDisplayState();
}

class _ImageViewDisplayState extends State<ImageViewDisplay> {
    late LongPressDownDetails longPress;

    void openContextMenu(Offset offset) {
        final RenderObject? overlay = Overlay.of(context).context.findRenderObject();
        showMenu(
            context: context,
            position: RelativeRect.fromRect(
                Rect.fromLTWH(offset.dx, offset.dy, 10, 10),
                Rect.fromLTWH(0, 0, overlay!.paintBounds.size.width, overlay.paintBounds.size.height),
            ),
            items: imageShareItems(widget.image)
        );
    }

    @override
    Widget build(BuildContext context) {
        return SharedPreferencesBuilder(
            builder: (_, prefs) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                    child: lookupMimeType(widget.image.filename)!.startsWith("video/") || ((prefs.getBool("gif_video") ?? settingsDefaults["gif_video"]) && lookupMimeType(widget.image.filename) == "image/gif")
                        ? VideoView(widget.image.path)
                        : MouseRegion(
                            cursor: SystemMouseCursors.zoomIn,
                            child: GestureDetector(
                                onTap: () => {
                                    GoRouter.of(context).push("/zoom_image/${widget.image.id}")
                                },
                                onLongPress: () => openContextMenu(getOffsetRelativeToBox(offset: longPress.globalPosition, renderObject: context.findRenderObject()!)),
                                onLongPressDown: (tap) => setState(() => longPress = tap),
                                onSecondaryTapDown: (tap) => openContextMenu(getOffsetRelativeToBox(offset: tap.globalPosition, renderObject: context.findRenderObject()!)),
                                child: Hero(
                                    tag: "detailed",
                                    child: Image.file(widget.image.getImage(), fit: BoxFit.contain),
                                ),
                            ),
                        ),
                    ),
                ),
        );
    }
}

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

class ImageViewZoom extends StatefulWidget {
    const ImageViewZoom(this.image, {super.key});

    final BooruImage image;
  
    @override
    State<ImageViewZoom> createState() => _ImageViewZoomState();
}

class _ImageViewZoomState extends State<ImageViewZoom> {
    final Color _appBarColor = const Color.fromARGB(150, 0, 0, 0);

    PhotoViewController controller = PhotoViewController();

    @override
    void dispose() {
        controller.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return Theme(
            data: ThemeData.dark(),
            child: Scaffold(
                extendBodyBehindAppBar: true,
                backgroundColor: Colors.transparent,
                appBar: WindowFrameAppBar(
                    title: "Zoom",
                    backgroundColor: _appBarColor,
                    appBar: AppBar(
                        backgroundColor: _appBarColor,
                        elevation: 0,
                        title: Text(widget.image.filename),
                        actions: [
                            PopupMenuButton(
                                itemBuilder: (context) => imageShareItems(widget.image),
                            )
                        ],
                    ),
                ),
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

class ImageViewProprieties extends StatefulWidget {
    const ImageViewProprieties(this.image, {super.key, this.renderObject});
    
    final BooruImage image;
    final RenderObject? renderObject;
    
    @override
    State<StatefulWidget> createState() => _ImageViewProprietiesState();
}

class _ImageViewProprietiesState extends State<ImageViewProprieties> {
    late final TextStyle linkText = TextStyle(color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline, decorationColor: Theme.of(context).colorScheme.primary);
    late LongPressDownDetails longPress;

    void openContextMenu({required Offset offset, required String url}) {
        final RenderObject? overlay = Overlay.of(context).context.findRenderObject();
        showMenu(
            context: context,
            position: RelativeRect.fromRect(
                Rect.fromLTWH(offset.dx, offset.dy, 10, 10),
                Rect.fromLTWH(0, 0, overlay!.paintBounds.size.width, overlay.paintBounds.size.height),
            ),
            items: [
                PopupMenuItem(
                    enabled: false,
                    height: 16,
                    child: Text(url, maxLines: 1),
                ),
                ...urlItems(url)
            ]
        );
    }

    @override
    Widget build(BuildContext context) {    
        return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    const Header("Tags", padding: EdgeInsets.zero),
                    FutureBuilder(
                        future: getCurrentBooru().then((booru) => booru.separateTagsByType(widget.image.tags.split(" "))),
                        builder: (context, snapshot) {
                            if (snapshot.hasData) {
                                final tags = snapshot.data!;
                                return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        if (tags["artist"] != null && tags["artist"]!.isNotEmpty) ...[
                                            const SmallHeader("Artist", padding: EdgeInsets.only(top: 4)),
                                            Wrap(children: List.from(tags["artist"]!..sort()).map((e) {
                                                return Tag(e, color: SpecificTagsColors.artist, renderObject: widget.renderObject,);
                                            }).toList())
                                        ],
                                        if (tags["character"] != null && tags["character"]!.isNotEmpty) ...[
                                            const SmallHeader("Character", padding: EdgeInsets.only(top: 4)),
                                            Wrap(children: List.from(tags["character"]!..sort()).map((e) {
                                                return Tag(e, color: SpecificTagsColors.character, renderObject: widget.renderObject,);
                                            }).toList())
                                        ],
                                        if (tags["copyright"] != null && tags["copyright"]!.isNotEmpty) ...[
                                            const SmallHeader("Copyright", padding: EdgeInsets.only(top: 4)),
                                            Wrap(children: List.from(tags["copyright"]!..sort()).map((e) {
                                                return Tag(e, color: SpecificTagsColors.copyright, renderObject: widget.renderObject,);
                                            }).toList())
                                        ],
                                        if (tags["species"] != null && tags["species"]!.isNotEmpty) ...[
                                            const SmallHeader("Species", padding: EdgeInsets.only(top: 4)),
                                            Wrap(children: List.from(tags["species"]!..sort()).map((e) {
                                                return Tag(e, color: SpecificTagsColors.species, renderObject: widget.renderObject,);
                                            }).toList())
                                        ],
                                        const SmallHeader("Generic", padding: EdgeInsets.only(top: 4)),
                                        Wrap(children: List.from(tags["generic"]!..sort()).map((e) {
                                            return Tag(e, renderObject: widget.renderObject,);
                                        }).toList())
                                    ],
                                );
                            }
                            return const CircularProgressIndicator();
                        }
                    ),

                    if(widget.image.rating != null) ...[
                        const Header("Rating"),
                        Text(switch(widget.image.rating) {
                            Rating.safe => "Safe",
                            Rating.questionable => "Questionable",
                            Rating.explicit => "Explicit",
                            Rating.illegal => "Illegal",
                            _ => widget.image.rating!.name
                        })
                    ],
                    
                    const SizedBox(height: 16,),
                    if(widget.image.sources != null && widget.image.sources!.isNotEmpty) Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: widget.image.sources!.map((url) {
                            final ro = widget.renderObject ?? context.findRenderObject()!;
                            final uri = Uri.parse(url);
                            return MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                    onLongPress: () => openContextMenu(offset: getOffsetRelativeToBox(offset: longPress.globalPosition, renderObject: ro), url: url),
                                    onLongPressDown: (details) => longPress = details,
                                    onSecondaryTapDown: (tap) => openContextMenu(offset: getOffsetRelativeToBox(offset: tap.globalPosition, renderObject: ro), url: url),
                                    child: Card(
                                        child: ListTile(
                                            leading: getWebsiteIcon(uri, color: Theme.of(context).colorScheme.primary) ?? Icon(Icons.question_mark, color: Theme.of(context).colorScheme.primary),
                                            onTap: () => launchUrlString(url),
                                            title: Text(getWebsiteFormalType(uri) ?? "Website"),
                                            subtitle: Text(url, style: linkText)
                                        ),
                                    )
                                )
                            );
                        }).toList()
                    ),

                    const SizedBox(height: 16,),
                    FileInfo(widget.image.getImage())
                ],
            ),
        );
    }
}

class Tag extends StatefulWidget {
    const Tag(this.tag, {super.key, this.color = SpecificTagsColors.generic, this.renderObject});

    final String tag;
    final Color color;
    final RenderObject? renderObject;

    @override
    State<Tag> createState() => _TagState();
}
class _TagState extends State<Tag> {
    bool _isHovering = false;
    late LongPressDownDetails longPress;

    void openContextMenu({required Offset offset, required String tag}) {
        final RenderObject? overlay = Overlay.of(context).context.findRenderObject();
        showMenu(
            context: context,
            position: RelativeRect.fromRect(
                Rect.fromLTWH(offset.dx, offset.dy, 10, 10),
                Rect.fromLTWH(0, 0, overlay!.paintBounds.size.width, overlay.paintBounds.size.height),
            ),
            items: [
                PopupMenuItem(
                    enabled: false,
                    height: 16,
                    child: Text(tag, maxLines: 1),
                ),
                ...tagItems(tag, context)
            ]
        );
    }

    @override
    Widget build(BuildContext context) {
        return GestureDetector(
            onTap: () => context.push("/search/?tag=${widget.tag}"),
            onLongPress: () => openContextMenu(offset: getOffsetRelativeToBox(offset: longPress.globalPosition, renderObject: widget.renderObject ?? context.findRenderObject()!), tag: widget.tag),
            onLongPressDown: (details) => longPress = details,
            onSecondaryTapDown: (tap) => openContextMenu(offset: getOffsetRelativeToBox(offset: tap.globalPosition, renderObject: widget.renderObject ?? context.findRenderObject()!), tag: widget.tag),
            child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (details) => setState(() => _isHovering = true),
                onExit: (details) => setState(() => _isHovering = false),
                child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(widget.tag, style: TextStyle(color: widget.color, decoration: _isHovering ? TextDecoration.underline : null, decorationColor: widget.color)),
                ),
            )
        );
    }
}