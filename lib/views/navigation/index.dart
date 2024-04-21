import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/builders.dart';
import 'package:localbooru/components/context_menu.dart';
import 'package:localbooru/components/window_frame.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/platform_tools.dart';
import 'package:localbooru/views/image_manager/peripherals.dart';
import 'package:localbooru/views/image_manager/preset_api.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

class BrowseScreen extends StatefulWidget {
    const BrowseScreen({super.key, required this.child, required this.uri});

    final Widget child;
    final Uri uri;

    @override
    State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
    bool _isDragAndDrop = false;

    bool _isHome() => widget.uri.path == "/home";
    bool _isOnSearch() => widget.uri.path.contains("/search");
    bool _isOnView() => widget.uri.path.contains("/view");
    String _getTitle(Uri uri) {
        final String? tags = uri.queryParameters["tag"];
        if(_isOnSearch()) {
            if(tags != null && tags.isNotEmpty) return "Browse";
            return "Recent";
        }
        if(_isOnView()) return "Image";
        return "Home";
    }
    String? _getSubtitle(Uri uri) {
        final String? index = uri.queryParameters["index"];
        if(_isOnSearch()) {
            final int page = index == null ? 1 : int.parse(index) + 1;
            return "Page $page";
        }
        if(_isOnView()) {
            final String id = uri.pathSegments[1];
            return "ID $id";
        }
        return null;
    }


    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: WindowFrameAppBar(
                appBar: AppBar(
                    title: Builder(
                        builder: (builder) {
                            final String title = _getTitle(widget.uri);
                            final String? subtitle = _getSubtitle(widget.uri);
                            return ListTile(
                                title: Text(title, style: const TextStyle(fontSize: 20.0), textAlign: isApple() ? TextAlign.center : TextAlign.start),
                                subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 14.0), textAlign: isApple() ? TextAlign.center : TextAlign.start) : null,
                                contentPadding: EdgeInsets.zero,
                            );
                        }
                    ),
                    leading: !_isHome() ? IconButton(
                        icon: Icon(isApple() ? Icons.arrow_back_ios_new : Icons.arrow_back),
                        onPressed: () {
                            context.pop();
                        },
                    ) : null,
                    actions: [
                        IconButton(
                            icon: _isOnView() ? const Icon(Icons.edit) : const Icon(Icons.add),
                            tooltip: "${_isOnView() ? "Edit" : "Add"} image",
                            onPressed: () {
                                if(_isOnView()) {
                                    final String id = widget.uri.pathSegments[1];
                                    context.push("/manage_image/internal/$id");
                                } else {
                                    context.push("/manage_image");
                                }
                            },
                        ),
                        Builder(builder: (context) {
                            if(widget.uri.path.contains("/view")) {
                                final String id = widget.uri.pathSegments[1];
                                return BooruLoader(builder: (_, booru) => BooruImageLoader(booru: booru, id: id,
                                    builder: (context, image) => BrowseScreenPopupMenuButton(image: image),
                                ));
                            }
                            return const BrowseScreenPopupMenuButton();
                        })
                    ],
                ),
            ),
            drawer: Drawer(
                child: Builder(
                    builder: (context) => ListView(
                        padding: EdgeInsets.zero,
                        children: <Widget>[
                            SizedBox(height: MediaQuery.of(context).viewPadding.top),
                            const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text("LocalBooru", style: TextStyle(
                                    fontSize: 20.0
                                )),
                            ),

                            ListTile(
                                title: const Text("Add image"),
                                leading: const Icon(Icons.add),
                                onTap: () {
                                    Scaffold.of(context).closeDrawer();
                                    context.push("/manage_image");
                                },
                            ),
                            ListTile(
                                title: const Text("Import from service"),
                                leading: const Icon(Icons.link),
                                onTap: () {
                                    Scaffold.of(context).closeDrawer();
                                    showDialog(
                                        context: context,
                                        builder: (context) {
                                            return const InsertURLDialog();
                                        },
                                    );
                                },
                            ),
                            ListTile(
                                title: const Text("Settings"),
                                leading: const Icon(Icons.settings),
                                onTap: () {
                                    Scaffold.of(context).closeDrawer();
                                    context.push("/settings");
                                },
                            ),

                            if(kDebugMode) ...[
                                const Divider(),
                                const Padding(
                                    padding: EdgeInsets.only(left: 16.0, top: 16.0),
                                    child: Text("Dev mode"),
                                ),
                                ListTile(
                                    title: const Text("Playground"),
                                    onTap: () {
                                        Scaffold.of(context).closeDrawer();
                                        context.push("/playground");
                                    },
                                ),
                                ListTile(
                                    title: const Text("Go to permissions screen"),
                                    onTap: () {
                                        Scaffold.of(context).closeDrawer();
                                        context.push("/permissions");
                                    },
                                ),
                                ListTile(
                                    title: const Text("Go to set booru screen"),
                                    onTap: () {
                                        Scaffold.of(context).closeDrawer();
                                        context.push("/setbooru");
                                    },
                                ),
                                ListTile(
                                    title: const Text("Desktop size"),
                                    onTap: () {
                                        appWindow.size = const Size(1280, 720);
                                    },
                                ),
                                ListTile(
                                    title: const Text("Phone size"),
                                    onTap: () {
                                        appWindow.size = const Size(320, 840);
                                    },
                                ),
                            ]
                        ],
                    ),
                ),
            ),
            body: DropRegion(
                formats: Formats.standardFormats,
                child: Stack(
                    children: [
                        widget.child,
                        Positioned(
                            left: 12, right: 12, bottom: 12, top: 12,
                            child: AnimatedOpacity(
                                opacity: _isDragAndDrop ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: IgnorePointer(
                                    child: DottedBorder(
                                        strokeWidth: 6,
                                        radius: const Radius.circular(24),
                                        borderType: BorderType.RRect,
                                        color: Theme.of(context).colorScheme.primary,
                                        strokeCap: StrokeCap.round,
                                        dashPattern: [32, 16],
                                        child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 9.0),
                                            child: ClipRRect(
                                                borderRadius: const BorderRadius.all(Radius.circular(18)),
                                                child: Container(
                                                    color: Color.alphaBlend(Theme.of(context).colorScheme.primary.withOpacity(0.4), Colors.black.withOpacity(0.4)),
                                                    child: const Center(
                                                        child: Text("Drag to add", style: TextStyle(fontSize: 42, color: Colors.white),),
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
                    final item = event.session.items.first;
                    final reader = item.dataReader!;
                    debugPrint("got it, ${item.platformFormats}");
                    
                    final sentFormats = reader.getFormats(SuperFormats.all);
                    if(sentFormats.isEmpty) {ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Unknown format dragged"))); return;}
                    final SimpleFileFormat insertedFormat = sentFormats[0] as SimpleFileFormat;
                    debugPrint("inserted format: $insertedFormat");

                    // late StreamSubscription ss;
                    reader.getFile(insertedFormat, (file) async {
                        final fileExtension = insertedFormat.mimeTypes!.first.split("/")[1];
                        final mmm = await cache.putFileStream("drag&Drop${file.fileName ?? ""}${file.fileSize}", file.getStream(), fileExtension: fileExtension);
                        debugPrint(mmm.path);
                        if(context.mounted) GoRouter.of(context).pushNamed("drag_path", pathParameters: {"path": mmm.path});
                    }, onError: (error) {
                        debugPrint('Error reading value $error');
                    });
                },
            ),
        );
    }
}

class BrowseScreenPopupMenuButton extends StatelessWidget {
    const BrowseScreenPopupMenuButton({super.key, this.image});

    final BooruImage? image;

    @override
    Widget build(context) {
        return PopupMenuButton(
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