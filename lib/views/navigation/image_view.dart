import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/builders.dart';
import 'package:localbooru/components/context_menu.dart';
import 'package:localbooru/components/fileinfo.dart';
import 'package:localbooru/components/headers.dart';
import 'package:localbooru/components/image_grid_display.dart';
import 'package:localbooru/components/tag.dart';
import 'package:localbooru/components/video_view.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/shared_prefs_widget.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/views/image_manager/shell.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ImageViewShell extends StatelessWidget {
    const ImageViewShell({super.key, required this.image, required this.child, this.shouldShowImageOnPortrait = false, this.collections});

    final BooruImage image;
    final Widget child;
    final bool shouldShowImageOnPortrait;
    final List<BooruCollection>? collections;

    @override
    Widget build(BuildContext context) {
        final Widget appBarTitle = ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Image", style: TextStyle(fontSize: 20.0)),
            subtitle: Text("ID ${image.id}", style: const TextStyle(fontSize: 14.0)),
        );
        final Widget appBarLeading = BackButton(
            onPressed: context.pop,
        );
        final List<Widget> appBarActions = [
            IconButton(
                icon: const Icon(Icons.edit),
                tooltip: "Edit image",
                onPressed: () async => context.push("/manage_image", extra: PresetManageImageSendable(await PresetImage.fromExistingImage(image)))
            ),
            PopupMenuButton(
                // child: Icon(Icons.more_vert),
                itemBuilder: (context) {
                    return [
                        ...booruItems(),
                        const PopupMenuDivider(),
                        ...imageShareItems(image),
                        const PopupMenuDivider(),
                        ...imageManagementItems(image, context: context, doulbeExitOnDelete: true)
                    ];
                }
            )
        ];
        final PreferredSizeWidget? appBarBottom = (collections != null && collections!.isNotEmpty) ? PreferredSize(
            preferredSize: Size.fromHeight(40.0 * collections!.length),
            child: Column(
                children: collections!.map((collection) => CollectionSwitcher(collection: collection, image: image,)).toList(),
            )
        ) : null;
        return OrientationBuilder(
            builder: (context, orientation) {
                if(orientation == Orientation.portrait) {
                    return CustomScrollView(
                        slivers: [
                            SliverAppBar(
                                title: appBarTitle,
                                leading: appBarLeading, 
                                actions: appBarActions,
                                bottom: appBarBottom,
                                pinned: true,
                                floating: appBarBottom != null,
                                // snap: true,
                            ),
                            SliverList(
                                delegate: SliverChildListDelegate([
                                    if(shouldShowImageOnPortrait) ImageViewDisplay(image),
                                    child
                                ])
                            )
                        ],
                    );
                } else {
                    return Scaffold(
                        appBar: AppBar(
                            title: appBarTitle,
                            leading: appBarLeading, 
                            actions: appBarActions,
                            bottom: appBarBottom,
                        ),
                        body: ScrollConfiguration(
                            behavior: const MaterialScrollBehavior().copyWith(
                                dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.trackpad, PointerDeviceKind.stylus},
                            ),
                            child: Row(
                                children: [
                                    Expanded(
                                        child: ImageViewDisplay(image)
                                    ),
                                    ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 400.0),
                                        child: LayoutBuilder(
                                            builder: (context, constrains) {
                                                return SingleChildScrollView(
                                                    child: ConstrainedBox(
                                                        constraints: constrains.copyWith(minHeight: constrains.maxHeight, maxHeight: double.infinity, minWidth: 400),
                                                        child: child,
                                                    ),
                                                );
                                            }
                                        )
                                    )
                                    
                                ],
                            )
                        ),
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

class ImageViewProprieties extends StatefulWidget {
    const ImageViewProprieties(this.image, {super.key});
    
    final BooruImage image;
    
    @override
    State<StatefulWidget> createState() => _ImageViewProprietiesState();
}

class _ImageViewProprietiesState extends State<ImageViewProprieties> {
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
                    // const Header("Tags", padding: EdgeInsets.zero),
                    FutureBuilder(
                        future: getCurrentBooru().then((booru) => booru.separateTagsByType(widget.image.tags.split(" "))),
                        builder: (context, snapshot) {
                            if (snapshot.hasData) {
                                final tags = snapshot.data!;
                                return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        if (tags["artist"] != null && tags["artist"]!.isNotEmpty) ...[
                                            const Padding(
                                                padding: EdgeInsets.only(bottom: 2),
                                                child: Wrap(
                                                    spacing: 4,
                                                    crossAxisAlignment: WrapCrossAlignment.center,
                                                    children: [
                                                        Icon(SpecificTagsIcons.artist, color: SpecificTagsColors.artist, size: 20,),
                                                        Text("Artist", style: TextStyle(color: SpecificTagsColors.artist, fontSize: 16),),
                                                    ],
                                                ),
                                            ),
                                            Wrap(children: List.from(tags["artist"]!..sort()).map((e) {
                                                return Tag(e, color: SpecificTagsColors.artist, renderObject: ro, onTap: () => context.push("/search/?tag=$e"),);
                                            }).toList())
                                        ],
                                        if (tags["character"] != null && tags["character"]!.isNotEmpty) ...[
                                            const Padding(
                                                padding: EdgeInsets.only(top: 8, bottom: 2),
                                                child: Wrap(
                                                    spacing: 4,
                                                    crossAxisAlignment: WrapCrossAlignment.center,
                                                    children: [
                                                        Icon(SpecificTagsIcons.character, color: SpecificTagsColors.character, size: 20,),
                                                        Text("Character", style: TextStyle(color: SpecificTagsColors.character, fontSize: 16),),
                                                    ],
                                                ),
                                            ),
                                            Wrap(children: List.from(tags["character"]!..sort()).map((e) {
                                                return Tag(e, color: SpecificTagsColors.character, renderObject: ro, onTap: () => context.push("/search/?tag=$e"));
                                            }).toList())
                                        ],
                                        if (tags["copyright"] != null && tags["copyright"]!.isNotEmpty) ...[
                                            const Padding(
                                                padding: EdgeInsets.only(top: 8, bottom: 2),
                                                child: Wrap(
                                                    spacing: 4,
                                                    crossAxisAlignment: WrapCrossAlignment.center,
                                                    children: [
                                                        Icon(SpecificTagsIcons.copyright, color: SpecificTagsColors.copyright, size: 20,),
                                                        Text("Copyright", style: TextStyle(color: SpecificTagsColors.copyright, fontSize: 16),),
                                                    ],
                                                ),
                                            ),
                                            Wrap(children: List.from(tags["copyright"]!..sort()).map((e) {
                                                return Tag(e, color: SpecificTagsColors.copyright, renderObject: ro, onTap: () => context.push("/search/?tag=$e"));
                                            }).toList())
                                        ],
                                        if (tags["species"] != null && tags["species"]!.isNotEmpty) ...[
                                            const Padding(
                                                padding: EdgeInsets.only(top: 8, bottom: 2),
                                                child: Wrap(
                                                    spacing: 4,
                                                    crossAxisAlignment: WrapCrossAlignment.center,
                                                    children: [
                                                        Icon(SpecificTagsIcons.species, color: SpecificTagsColors.species, size: 20,),
                                                        Text("Species", style: TextStyle(color: SpecificTagsColors.species, fontSize: 16),),
                                                    ],
                                                ),
                                            ),
                                            Wrap(children: List.from(tags["species"]!..sort()).map((e) {
                                                return Tag(e, color: SpecificTagsColors.species, renderObject: ro, onTap: () => context.push("/search/?tag=$e"));
                                            }).toList())
                                        ],
                                        const Padding(
                                            padding: EdgeInsets.only(top: 8, bottom: 2),
                                            child: Wrap(
                                                spacing: 4,
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                children: [
                                                    Icon(SpecificTagsIcons.generic, color: SpecificTagsColors.generic, size: 20,),
                                                    Text("Generic", style: TextStyle(color: SpecificTagsColors.generic, fontSize: 16),),
                                                ],
                                            ),
                                        ),
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
                        const SizedBox(height: 16,),
                        Card(
                            child: ListTile(
                                title: const SmallHeader("Rating", padding: EdgeInsets.zero,),
                                leading: Icon(getRatingIcon(widget.image.rating!), color: Theme.of(context).colorScheme.primary),
                                subtitle: Text(getRatingText(widget.image.rating)),
                            )
                        )
                    ],

                    if(widget.image.relatedImages.isNotEmpty) ...[
                        const SizedBox(height: 16,),
                        Card(
                            clipBehavior: Clip.antiAlias,
                            child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                width: double.infinity,
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        const SmallHeader("Related images", padding: EdgeInsets.only(bottom: 8, left: 16),),
                                        SizedBox(
                                            height: 80,
                                            child: BooruLoader(
                                                builder: (context, booru) => ListView.separated(
                                                    scrollDirection: Axis.horizontal,
                                                    itemCount: widget.image.relatedImages.length,
                                                    separatorBuilder: (context, index) => const SizedBox(width: 12,),
                                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                                    itemBuilder: (context, index) {
                                                        final imageId = widget.image.relatedImages[index];
                                                        return ClipRRect(
                                                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                                                            child: MouseRegion(
                                                                cursor: WidgetStateMouseCursor.clickable,
                                                                child: GestureDetector(
                                                                    onTap: () => context.push("/view/$imageId"),
                                                                    child: BooruImageLoader(
                                                                        booru: booru,
                                                                        id: imageId,
                                                                        builder: (context, relatedImage) => ImageGrid(
                                                                            image: relatedImage,
                                                                            resizeSize: 200,
                                                                        ), 
                                                                    ),
                                                                ),
                                                            ),
                                                        );
                                                    }
                                                )
                                            ),
                                        )
                                    ],
                                ),
                            )
                        ),
                    ],
                    
                    if(widget.image.sources.isNotEmpty) ...[
                        const SizedBox(height: 16,),
                        Card(
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: ListTile.divideTiles(
                                    context: context,
                                    tiles: widget.image.sources.map((url) {
                                        final uri = Uri.parse(url);
                                        final website = getWebsiteByURL(uri);
                                        return MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: GestureDetector(
                                                onLongPress: () => openContextMenu(offset: getOffsetRelativeToBox(offset: longPress.globalPosition, renderObject: ro), url: url),
                                                onLongPressDown: (details) => longPress = details,
                                                onSecondaryTapDown: (tap) => openContextMenu(offset: getOffsetRelativeToBox(offset: tap.globalPosition, renderObject: ro), url: url),
                                                child: ListTile(
                                                    leading: website != null ? getWebsiteIcon(website) : Icon(Icons.question_mark, color: Theme.of(context).colorScheme.primary),
                                                    onTap: () => launchUrlString(url),
                                                    title: SmallHeader(website != null ? getWebsiteName(website) : uri.host, padding: EdgeInsets.zero,),
                                                    subtitle: Text(url)
                                                ),
                                            )
                                        );
                                    }).toList()
                                ).toList()
                            ),
                        ),
                    ],

                    const SizedBox(height: 16,),
                    Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                            title: const SmallHeader("Notes", padding: EdgeInsets.zero,),
                            leading: Icon(Icons.notes, color: Theme.of(context).colorScheme.primary,),
                            subtitle: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 60, minHeight: 30),
                                child: widget.image.note == null
                                    ? const Text("Click here to set a note", style: TextStyle(color: Colors.grey),)
                                    : Text(widget.image.note!),
                            ),
                            onTap: () => context.push("/view/${widget.image.id}/note"),
                        ),
                    ),

                    const SizedBox(height: 16,),
                    Card(
                        child: ListTile(
                            title: const SmallHeader("File information", padding: EdgeInsets.only(bottom: 4),),
                            leading: Icon(Icons.info, color: Theme.of(context).colorScheme.primary,),
                            subtitle: FileInfo(widget.image.getImage())
                        )
                    )
                ],
            ),
        );
    }
}

class CollectionSwitcher extends StatefulWidget {
    const CollectionSwitcher({super.key, required this.collection, required this.image});

    final BooruCollection collection;
    final BooruImage image;
    
    @override
    State<CollectionSwitcher> createState() => _CollectionSwitcherState();
}
class _CollectionSwitcherState extends State<CollectionSwitcher> {
    late int collectionPosition;

    @override
    void initState() {
        super.initState();
        collectionPosition = widget.collection.pages.indexOf(widget.image.id);
    }

    @override
    Widget build(BuildContext context) {
        return SizedBox(
            height: 40,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: collectionPosition > 0 ? () {
                            context.push("/view/${widget.collection.pages[collectionPosition - 1]}");
                        } : null
                    ),
                    Expanded(
                        child: Center(
                            child: TextButton(
                                child: RichText(
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    text: TextSpan(
                                        children: [
                                            TextSpan(
                                                text: widget.collection.name,
                                                style: TextStyle(
                                                    color: Theme.of(context).colorScheme.primary,
                                                    // decoration: TextDecoration.underline
                                                ),
                                            ),
                                            TextSpan(
                                                text: " • ",
                                                style: TextStyle(
                                                    color: Theme.of(context).disabledColor,
                                                ),
                                                children: [
                                                    TextSpan(
                                                        text: "${collectionPosition + 1}/${widget.collection.pages.length}",
                                                    ),
                                                ]
                                            ),
                                        ]
                                    ),
                                ),
                                onPressed: () => context.push("/collections/${widget.collection.id}"),
                            ),
                        )
                    ),
                    IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: (collectionPosition + 1) < widget.collection.pages.length ? () {
                            context.push("/view/${widget.collection.pages[collectionPosition + 1]}");
                        } : null
                    ),
                ],
            ),
        );
    }
}

class NotesView extends StatefulWidget {
    const NotesView({super.key, required this.id});

    final int id;

    @override
    State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
    final controller = TextEditingController();
    Timer? _debounce;
    late BooruImage image;

    @override
    void initState() {
        super.initState();
        setText();
    }

    void setText() async {
        final booru = await getCurrentBooru();
        image = (await booru.getImage(widget.id.toString()))!;
        controller.text = image.note ?? "";
    }
    
    @override
    Widget build(context) {
        return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    const Header("Note", padding: EdgeInsets.only(bottom: 16),),
                    TextField(
                        controller: controller,
                        keyboardType: TextInputType.multiline,
                        minLines: 10,
                        maxLines: null,
                        decoration: const InputDecoration(
                            hintText: 'Insert a note',
                            border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                            if (_debounce?.isActive ?? false) _debounce?.cancel();
                            _debounce = Timer(const Duration(seconds: 1), () async {
                                final preset = await PresetImage.fromExistingImage(image);
                                preset.note = value;
                                await insertImage(preset);
                            });
                        },
                    ),
                ],
            ),
        );
    }
}