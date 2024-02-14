import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/window_frame.dart';
import 'package:localbooru/utils/listeners.dart';
import 'package:localbooru/utils/platform_tools.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:super_clipboard/super_clipboard.dart';

class BrowseScreen extends StatelessWidget {
    const BrowseScreen({super.key, required this.child, required this.uri});

    final Widget child;
    final Uri uri;

    bool _isHome() => uri.path == "/home";
    bool isOnSearch() => uri.path.contains("/search");
    bool isOnView() => uri.path.contains("/view");
    String _getTitle(Uri uri) {
        // Uri.parse(url).queryParameters["tag"].isEmpty();
        final String? tags = uri.queryParameters["tag"];
        if(isOnSearch()) {
            if(tags != null && tags.isNotEmpty) return "Browse";
            return "Recent";
        }
        if(isOnView()) return "Image";
        return "Home";
    }
    String? _getSubtitle(Uri uri) {
        final String? index = uri.queryParameters["index"];
        if(isOnSearch()) {
            final int page = index == null ? 1 : int.parse(index) + 1;
            return "Page $page";
        }
        if(isOnView()) {
            final String id = uri.pathSegments[1];
            return "No. ${int.parse(id) + 1}";
        }
        return null;
    }


    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: WindowFrameAppBar(
                appBar: AppBar(
                    // backgroundColor: Colors.transparent,
                    title: Builder(
                        builder: (builder) {
                            final String title = _getTitle(uri);
                            final String? subtitle = _getSubtitle(uri);
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
                            if(context.canPop()) context.pop();
                        },
                    ) : null,
                    actions: [
                        IconButton(
                            icon: isOnView() ? const Icon(Icons.edit) : const Icon(Icons.add),
                            tooltip: "${isOnView() ? "Edit" : "Add"} image",
                            onPressed: () {
                                if(isOnView()) {
                                    final String id = uri.pathSegments[1];
                                    debugPrint("/manage_image/$id");
                                    context.push("/manage_image/$id");
                                } else {
                                    context.push("/manage_image");
                                }
                            },
                        ),
                        Builder(builder: (context) {
                            if(uri.path.contains("/view")) {
                                final String id = uri.pathSegments[1];
                                return BooruLoader(builder: (_, booru) => BooruImageLoader(booru: booru, id: id,
                                    builder: (context, image) => BrowseScreenPopupMenuButton(image: image),
                                ));
                            }
                            return const BrowseScreenPopupMenuButton();
                        })
                    ],
                ),
            ) ,
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
                                    title: Text("Nuke app data (Linux, borken)", style: TextStyle(color: Theme.of(context).colorScheme.error)),
                                    onTap: () async {
                                        Directory(r"~/.local/share/com.auser.localbooru").delete(recursive: true);
                                    },
                                )
                            ]
                        ],
                    ),
                ),
            ),
            body: child,
            // floatingActionButton: Wrap(
            //     children: [
            //         FloatingActionButton(
            //             onPressed: () async{
            //                 Booru booru = await getCurrentBooru();
            //                 addImage(
            //                     imageFile: File(join(booru.path, "testFile.jpeg"))
            //                 );
            //             },
            //             child: const Icon(Icons.add)
            //         ),
            //         FloatingActionButton(
            //             onPressed: () {
            //                 removeImage("5");
            //             },
            //             child: const Icon(Icons.remove)
            //         ),
            //     ]
            // )
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
                final List<PopupMenuEntry> filteredList = generalItems();
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

List<PopupMenuEntry> generalItems() {
    return [
        PopupMenuItem(
            child: const Text("Refresh"),
            onTap: () => booruUpdateListener.update(),
        )
    ];
}
List<PopupMenuEntry> imageShareItems(BooruImage image) {
    return [
        PopupMenuItem(
            child: const Text("Open image"),
            onTap: () => OpenFile.open(image.path),
        ),
        PopupMenuItem(
            // enabled: !isMobile(),
            child: const Text("Copy image to clipboard"),
            onTap: () async {
                final item = DataWriterItem();
                item.add(Formats.png(await File(image.path).readAsBytes()));
                await SystemClipboard.instance?.write([item]);
            },
        ),
        PopupMenuItem(
            child: const Text("Share image"),
            onTap: () async => await Share.shareXFiles([XFile(image.path)]),
        )
    ];
}

List<PopupMenuEntry> imageManagementItems(BooruImage image, {required BuildContext context}) {
    return [
        PopupMenuItem(
            child: const Text("Edit image metadata"),
            onTap: () => context.push("/manage_image/${image.id}")
        ),
        PopupMenuItem(
            child: Text("Delete image", style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () => showDialog(context: context,
                builder: (context) => DeleteImageDialogue(id: image.id)
            )
        ),
    ];
}

class DeleteImageDialogue extends StatelessWidget {
    const DeleteImageDialogue({super.key, required this.id});

    final String id;

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Text("Delete image"),
            content: const Text("Are you sure that you want to delete this image? This action will be irreversible"),
            actions: [
                TextButton(onPressed: Navigator.of(context).pop, child: const Text("No")),
                TextButton(
                    child: const Text("Yes"), 
                    onPressed: () async {
                        Navigator.of(context).pop(); //first to close menu
                        context.pop(); //second to close viewer
                        await removeImage(id);
                    }
                ),
            ],
        );
    }
}