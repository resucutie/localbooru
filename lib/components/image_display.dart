import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/context_menu.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/image_thumbnailer.dart';
import 'package:mime/mime.dart';


class SilverRepoGrid extends StatefulWidget {
    const SilverRepoGrid({super.key, required this.images, this.onPressed, this.autoadjustColumns});

    final List<BooruImage> images;
    final Function(BooruImage image)? onPressed;
    final int? autoadjustColumns;

    @override
    State<SilverRepoGrid> createState() => _SilverRepoGridState();
}

class _SilverRepoGridState extends State<SilverRepoGrid> {
    late LongPressDownDetails longTap;
    
    String? getType(String filename) {
        final mime = lookupMimeType(filename)!;
        if(mime.startsWith("video")) return "video";
        if(mime.startsWith("image/gif")) return "gif";
        return "image";
    }
    @override
    void dispose() {
        // clear memory leak
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
        super.dispose();
    }
  
    @override
    Widget build(BuildContext context) {
        // it is formatted in this way for better visibility of the formula
        int columns = (
            MediaQuery.of(context).size.width
            /
            (
                (20*50)
                /
                (widget.autoadjustColumns ?? settingsDefaults["grid_size"])
            )
        ).ceil();

        if(widget.images.isEmpty) {
            return const SizedBox.shrink();
        } else {
            return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                ),
                delegate: SliverChildListDelegate(widget.images.map((image) {
                    void openContextMenu(Offset offset) {
                        final RenderObject? overlay = Overlay.of(context).context.findRenderObject();
                        showMenu(
                            context: context,
                            position: RelativeRect.fromRect(
                                Rect.fromLTWH(offset.dx, offset.dy, 10, 10),
                                Rect.fromLTWH(0, 0, overlay!.paintBounds.size.width, overlay.paintBounds.size.height),
                            ),
                            items: [
                                ...imageShareItems(image),
                                const PopupMenuDivider(),
                                ...imageManagementItems(image, context: context),
                            ]
                        );
                    }
                    return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                                onTap: () {if(widget.onPressed != null) widget.onPressed!(image);},
                                onLongPress: () => openContextMenu(getOffsetRelativeToBox(offset: longTap.globalPosition, renderObject: context.findRenderObject()!)),
                                onLongPressDown: (tap) => longTap = tap,
                                onSecondaryTapDown: (tap) => openContextMenu(getOffsetRelativeToBox(offset: tap.globalPosition, renderObject: context.findRenderObject()!)),
                                child: Stack(
                                    children: [
                                        AspectRatio(
                                            aspectRatio: 1,
                                            child: FutureBuilder(
                                                future: getImageThumbnail(image),
                                                builder: (context, snapshot) {
                                                    if(snapshot.hasData) {
                                                        return Image(
                                                            image: FileImage(snapshot.data!),
                                                            fit: BoxFit.cover,
                                                        );
                                                    }
                                                    return const Center(child: CircularProgressIndicator(),);
                                                },
                                            )
                                        ),
                                        if(getType(image.filename) != "image") Positioned(
                                            child: Container(
                                                decoration: const BoxDecoration(
                                                    color: Color.fromARGB(160, 0, 0, 0),
                                                    borderRadius: BorderRadius.only(
                                                        bottomRight: Radius.circular(8),
                                                    )
                                                ),
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                child: Text(getType(image.filename)!.toUpperCase(),
                                                    style: const TextStyle(
                                                        fontSize: 12
                                                    ),
                                                ),
                                            ),
                                        ),
                                    ],
                                ),
                            )
                        ),
                    );
                }).toList()),
            );
        }
    }
}