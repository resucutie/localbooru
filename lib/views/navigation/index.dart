import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/context_menu.dart';
import 'package:localbooru/components/window_frame.dart';
import 'package:localbooru/utils/platform_tools.dart';
import 'package:localbooru/views/image_manager/peripherals.dart';

class BrowseScreen extends StatelessWidget {
    const BrowseScreen({super.key, required this.child, required this.uri});

    final Widget child;
    final Uri uri;

    bool _isHome() => uri.path == "/home";
    bool isOnSearch() => uri.path.contains("/search");
    bool isOnView() => uri.path.contains("/view");
    String _getTitle(Uri uri) {
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
                                    context.push("/manage_image/internal/$id");
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