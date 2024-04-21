import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/context_menu.dart';
import 'package:localbooru/components/fileinfo.dart';
import 'package:localbooru/components/headers.dart';
import 'package:localbooru/components/tag.dart';
import 'package:localbooru/components/window_frame.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/get_website.dart';
import 'package:localbooru/utils/shared_prefs_widget.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:photo_view/photo_view.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:media_kit/media_kit.dart'; // Provides [Player], [Media], [Playlist] etc.
import 'package:media_kit_video/media_kit_video.dart'; // Provides [VideoController] & [Video] etc.        

class ImageViewShell extends StatelessWidget {
    const ImageViewShell({super.key, required this.image, required this.child, this.shouldShowImageOnPortrait = false});

    final BooruImage image;
    final Widget child;
    final bool shouldShowImageOnPortrait;

    @override
    Widget build(BuildContext context) {
        return OrientationBuilder(
            builder: (context, orientation) {
                if(orientation == Orientation.portrait) {
                    return ListView(
                        children: [
                            if(shouldShowImageOnPortrait) ImageViewDisplay(image),
                            child
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
                                    children: [child],
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
                                    child: DragItemWidget(
                                        dragItemProvider: (request) {
                                            final item = DragItem(
                                                localData: {'context': "image_view"},
                                                suggestedName: widget.image.filename
                                            );
                                            final format = SuperFormats.getFormatFromFileExtension(p.extension(widget.image.filename));
                                            // debugPrint("$format");
                                            if(format != null) item.add(format.lazy(() async => await widget.image.getImage().readAsBytes()));
                                            return item;
                                        },
                                        allowedOperations: () => [DropOperation.copy],
                                        child: DraggableWidget(child: Image.file(widget.image.getImage(), fit: BoxFit.contain))
                                    ),
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

class ImageViewProprieties extends StatefulWidget {
    const ImageViewProprieties(this.image, {super.key});
    
    final BooruImage image;
    
    @override
    State<StatefulWidget> createState() => _ImageViewProprietiesState();
}

class _ImageViewProprietiesState extends State<ImageViewProprieties> {
    late final TextStyle linkText = TextStyle(color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline, decorationColor: Theme.of(context).colorScheme.primary);
    late LongPressDownDetails longPress;

    late RenderObject ro;

    @override
    void initState() {
        super.initState();
        WidgetsBinding.instance.addPostFrameCallback((_) {
            ro = context.findRenderObject()!;
        });
    }

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
                                                return Tag(e, color: SpecificTagsColors.artist, renderObject: ro, onTap: () => context.push("/search/?tag=$e"),);
                                            }).toList())
                                        ],
                                        if (tags["character"] != null && tags["character"]!.isNotEmpty) ...[
                                            const SmallHeader("Character", padding: EdgeInsets.only(top: 4)),
                                            Wrap(children: List.from(tags["character"]!..sort()).map((e) {
                                                return Tag(e, color: SpecificTagsColors.character, renderObject: ro, onTap: () => context.push("/search/?tag=$e"));
                                            }).toList())
                                        ],
                                        if (tags["copyright"] != null && tags["copyright"]!.isNotEmpty) ...[
                                            const SmallHeader("Copyright", padding: EdgeInsets.only(top: 4)),
                                            Wrap(children: List.from(tags["copyright"]!..sort()).map((e) {
                                                return Tag(e, color: SpecificTagsColors.copyright, renderObject: ro, onTap: () => context.push("/search/?tag=$e"));
                                            }).toList())
                                        ],
                                        if (tags["species"] != null && tags["species"]!.isNotEmpty) ...[
                                            const SmallHeader("Species", padding: EdgeInsets.only(top: 4)),
                                            Wrap(children: List.from(tags["species"]!..sort()).map((e) {
                                                return Tag(e, color: SpecificTagsColors.species, renderObject: ro, onTap: () => context.push("/search/?tag=$e"));
                                            }).toList())
                                        ],
                                        const SmallHeader("Generic", padding: EdgeInsets.only(top: 4)),
                                        Wrap(children: List.from(tags["generic"]!..sort()).map((e) {
                                            return Tag(e, renderObject: ro, onTap: () => context.push("/search/?tag=$e"));
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
                    if(widget.image.sources != null && widget.image.sources!.isNotEmpty) Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: ListTile.divideTiles(
                                context: context,
                                tiles: widget.image.sources!.map((url) {
                                    final uri = Uri.parse(url);
                                    return MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                            onLongPress: () => openContextMenu(offset: getOffsetRelativeToBox(offset: longPress.globalPosition, renderObject: ro), url: url),
                                            onLongPressDown: (details) => longPress = details,
                                            onSecondaryTapDown: (tap) => openContextMenu(offset: getOffsetRelativeToBox(offset: tap.globalPosition, renderObject: ro), url: url),
                                            child: ListTile(
                                                leading: getWebsiteIcon(uri, color: Theme.of(context).colorScheme.primary) ?? Icon(Icons.question_mark, color: Theme.of(context).colorScheme.primary),
                                                onTap: () => launchUrlString(url),
                                                title: Text(getWebsiteFormalType(uri) ?? "Website"),
                                                subtitle: Text(url, style: linkText)
                                            ),
                                        )
                                    );
                                }).toList()
                            ).toList()
                        ),
                    ),

                    const SizedBox(height: 16,),
                    Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                            title: const SmallHeader("Notes", padding: EdgeInsets.zero,),
                            subtitle: SizedBox(
                                height: 100,
                                child: widget.image.note == null
                                    ? const Text("Click here to set a note", style: TextStyle(color: Colors.grey),)
                                    : Text(widget.image.note!),
                            ),
                            onTap: () => context.push("/view/${widget.image.id}/note"),
                        ),
                    ),

                    // FilledButton(onPressed: () => context.push("/view/${widget.image.id}/note"), child: Text("notes")),

                    const SizedBox(height: 16,),
                    Card(
                        child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8,horizontal: 16.0),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    const SmallHeader("Information", padding: EdgeInsets.only(bottom: 4),),
                                    FileInfo(widget.image.getImage())
                                ],
                            ),
                        ),
                    )
                ],
            ),
        );
    }
}