import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/context_menu.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/compressor.dart';
import 'package:localbooru/utils/shared_prefs_widget.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:super_drag_and_drop/super_drag_and_drop.dart';


class SliverRepoGrid extends StatefulWidget {
    const SliverRepoGrid({super.key, required this.images, this.onPressed, this.onLongPress, this.onContextMenu, this.autoadjustColumns, this.imageQualityScale, this.dragOutside = false, this.selectedElements = const []});

    final List<BooruImage> images;
    final Function(BooruImage image)? onPressed;
    final Function(BooruImage image)? onLongPress;
    final Function(Offset offset, BooruImage image)? onContextMenu;
    final int? autoadjustColumns;
    final double? imageQualityScale;
    final bool dragOutside;
    final List<ImageID> selectedElements;

    @override
    State<SliverRepoGrid> createState() => _SliverRepoGridState();
}

class _SliverRepoGridState extends State<SliverRepoGrid> {
    late LongPressDownDetails longTap;
    
    String? getType(String filename) {
        final mime = lookupMimeType(filename)!;
        if(mime.startsWith("video")) return "video";
        if(mime.startsWith("image/gif")) return "gif";
        return "image";
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

        double resizeSize = (MediaQuery.of(context).size.width / columns) + 10;

        if(widget.images.isEmpty) {
            return const SizedBox.shrink();
        } else {
            return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                ),
                delegate: SliverChildListDelegate(widget.images.map((image) {
                    return SharedPreferencesBuilder(
                        key: ValueKey(image.id), //fun fact: 
                        builder: (_, prefs) {
                            final Widget dragWidget = GestureDetector(
                                onTap: () {if(widget.onPressed != null) widget.onPressed!(image);},
                                onLongPress: () {if(widget.onLongPress != null) widget.onLongPress!(image);},
                                onLongPressDown: (tap) => longTap = tap,
                                onSecondaryTapDown: (tap) {if(widget.onContextMenu != null) widget.onContextMenu!(getOffsetRelativeToBox(offset: tap.globalPosition, renderObject: context.findRenderObject()!), image);},
                                child: ImageGrid(
                                    image: image,
                                    resizeSize: resizeSize * (prefs.getDouble("thumbnail_quality") ?? settingsDefaults["thumbnail_quality"]),
                                    selected: widget.selectedElements.contains(image.id),
                                    showSelectionCheckbox: widget.selectedElements.isNotEmpty,
                                )
                            );
                            return Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: !widget.dragOutside ? dragWidget : DragItemWidget(
                                        dragItemProvider: (request) {
                                            final item = DragItem(
                                                localData: {'context': "image_grid"},
                                                suggestedName: image.filename
                                            );
                                            final format = SuperFormats.getFormatFromFileExtension(p.extension(image.filename));
                                            // debugPrint("$format");
                                            if(format != null) item.add(format.lazy(image.getImage().readAsBytes));
                                            return item;
                                        },
                                        allowedOperations: () => [DropOperation.copy],
                                        child: DraggableWidget(child: dragWidget),
                                    )
                                ),
                            );
                        }
                    );
                }).toList()),
            );
        }
    }
}

class ImageGrid extends StatefulWidget {
    const ImageGrid({super.key, required this.image, this.resizeSize, this.selected = false, this.showSelectionCheckbox = false});
    final BooruImage image;
    final double? resizeSize;
    final bool selected;
    final bool showSelectionCheckbox;

    @override
    State<ImageGrid> createState() => _ImageGridState();
}

class _ImageGridState extends State<ImageGrid> {   
    late Future<File> imageThumbnail;
    
    String? getType(String filename) {
        final mime = lookupMimeType(filename)!;
        if(mime.startsWith("video")) return "video";
        if(mime.startsWith("image/gif")) return "gif";
        return "image";
    }

    @override
    void initState() {
        super.initState();

        imageThumbnail = getImageThumbnail(widget.image);
    }
    
    @override
    Widget build(context) {
        return Stack(
            children: [
                AnimatedScale(
                    scale: widget.selected ? 0.85 : 1,
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeOut,
                    child: AspectRatio(
                        aspectRatio: 1,
                        child: FutureBuilder(
                            future: imageThumbnail,
                            builder: (context, snapshot) {
                                if(snapshot.hasData) {
                                    final thumbnail = snapshot.data!;
                                    final hasResize = widget.resizeSize != null;
                                    final ImageProvider provider = hasResize ? ResizeImage(FileImage(thumbnail),
                                        width: widget.resizeSize!.ceil(),
                                        height: widget.resizeSize!.ceil(),
                                        policy: ResizeImagePolicy.fit
                                    ) : FileImage(thumbnail) as ImageProvider;
                                    return Image(
                                        image: provider,
                                        fit: BoxFit.cover,
                                    );
                                }
                                return const Center(child: CircularProgressIndicator(),);
                            },
                        )
                    ),
                ),
                if(getType(widget.image.filename) != "image") Positioned(
                    child: Container(
                        decoration: const BoxDecoration(
                            color: Color.fromARGB(160, 0, 0, 0),
                            borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(8),
                            )
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(getType(widget.image.filename)!.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 12
                            ),
                        ),
                    ),
                ),
                if(widget.selected || widget.showSelectionCheckbox) Positioned(
                    top: 8,
                    right: 8,
                    child: widget.selected
                        ? CircleAvatar(
                            radius: 12,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: const Icon(Icons.check, color: Colors.black, size: 20,),
                        )
                        : Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade400.withOpacity(0.7), width: 2.5)
                                
                            ),
                        )
                ),
            ],
        );
    }
}