import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/context_menu.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

class AddImageDropRegion extends StatefulWidget {
    const AddImageDropRegion({super.key, required this.child});

    final Widget child;

    @override
    State<AddImageDropRegion> createState() => _AddImageDropRegionState();
}

class _AddImageDropRegionState extends State<AddImageDropRegion> {
    bool _isDragAndDrop = false;

    @override
    Widget build(BuildContext context) {
        return DropRegion(
            formats: Formats.standardFormats,
            child: Stack(
                children: [
                    widget.child,
                    Positioned(
                        left: 8, right: 8, bottom: 8, top: 8,
                        child: AnimatedOpacity(
                            opacity: _isDragAndDrop ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: IgnorePointer(
                                child: DottedBorder(
                                    strokeWidth: 4,
                                    radius: const Radius.circular(24),
                                    borderType: BorderType.RRect,
                                    color: Theme.of(context).colorScheme.primary,
                                    strokeCap: StrokeCap.round,
                                    dashPattern: const [16, 16],
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 5.0),
                                        child: ClipRRect(
                                            borderRadius: const BorderRadius.all(Radius.circular(18)),
                                            child: Container(
                                                color: Color.alphaBlend(Theme.of(context).colorScheme.primary.withOpacity(0.4), Colors.black.withOpacity(0.4)),
                                                child: const Center(
                                                    child: Wrap(
                                                        direction: Axis.vertical,
                                                        crossAxisAlignment: WrapCrossAlignment.center,
                                                        spacing: 48,
                                                        children: [
                                                            Icon(Icons.add, size: 96,),
                                                            Text("Drag to add",style: TextStyle(fontSize: 36, color: Colors.white))
                                                        ],
                                                    ),
                                                ),
                                            ),
                                        ),
                                    ),
                                ),
                            ),
                        )
                    )
                ],
            ),
            onDropOver: (event) {
                final item = event.session.items.first;
                    
                if(item.localData is Map) return DropOperation.none; // it is a drag from inside the app, ignore;

                setState(() => _isDragAndDrop = true);

                if(event.session.allowedOperations.contains(DropOperation.copy)) return DropOperation.copy;
                else return DropOperation.none;
            },
            onDropLeave: (p0) => setState(() => _isDragAndDrop = false),
            onPerformDrop: (event) async {
                List<PresetImage> presets = [];

                for (final item in event.session.items) {
                    final reader = item.dataReader!;
                    
                    final sentFormats = reader.getFormats(SuperFormats.all);
                    if(sentFormats.isEmpty) {ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Unknown format dragged"))); return;}
                    final SimpleFileFormat insertedFormat = sentFormats[0] as SimpleFileFormat;
                    debugPrint("inserted format: $insertedFormat");

                    reader.getFile(insertedFormat, (file) async {
                        final fileExtension = insertedFormat.mimeTypes!.first.split("/")[1];
                        final draggedFile = await DefaultCacheManager().putFileStream("drag&Drop${file.fileName ?? ""}${file.fileSize}", file.getStream(), fileExtension: fileExtension);
                        presets.add(PresetImage(image: draggedFile));
                        if(presets.length == event.session.items.length && context.mounted) GoRouter.of(context).push("/manage_image", extra: presets);
                    }, onError: (error) {
                        debugPrint('Error reading value $error');
                    });
                }
            },
        );
    }
}

class BrowseScreenPopupMenuButton extends StatelessWidget {
    const BrowseScreenPopupMenuButton({super.key, this.image});

    final BooruImage? image;

    @override
    Widget build(context) {
        return PopupMenuButton(
            // child: Icon(Icons.more_vert),
            itemBuilder: (context) {
                final List<PopupMenuEntry> filteredList = booruItems();
                if(image != null) {
                    filteredList.add(const PopupMenuDivider());
                    filteredList.addAll(imageShareItems(image!));
                    filteredList.add(const PopupMenuDivider());
                    filteredList.addAll(imageManagementItems(image!, context: context));
                };
                return filteredList;
            }
        );
    }
}