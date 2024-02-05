import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/window_frame.dart';
import 'package:path/path.dart';

class BrowseScreen extends StatelessWidget {
    const BrowseScreen({super.key, required this.child, required this.uri});

    final Widget child;
    final Uri uri;

    bool _isHome() => uri.path == "/home";
    String _getTitle(Uri uri) {
        // Uri.parse(url).queryParameters["tag"].isEmpty();
        final String? tags = uri.queryParameters["tag"];
        if(uri.path.contains("/search")) {
            if(tags != null && tags.isNotEmpty) return "Browse";
            return "Recent";
        }
        if(uri.path.contains("/view")) return "Image";
        return "Home";
    }
    String? _getSubtitle(Uri uri) {
        final String? index = uri.queryParameters["index"];
        if(uri.path.contains("/search")) {
            final int page = index == null ? 1 : int.parse(index) + 1;
            return "Page $page";
        }
        if(uri.path.contains("/view")) {
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
                                title: Text(title, style: const TextStyle(fontSize: 20.0)),
                                subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 14.0)) : null,
                                contentPadding: EdgeInsets.zero,
                            );
                        }
                    ),
                    leading: !_isHome() ? IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                            if(context.canPop()) context.pop();
                        },
                    ) : null,
                    actions: const [
                        BrowseScreenPopupMenuButton()
                    ],
                ),
            ) ,
            drawer: Drawer(
                child: Builder(
                    builder: (context) => ListView(
                        padding: EdgeInsets.zero,
                        children: <Widget>[
                            FilledButton(onPressed: () {
                                Scaffold.of(context).closeDrawer();
                                context.push("/permissions");
                            }, child: const Text("Go to permissions")),
                            FilledButton(onPressed: () {
                                Scaffold.of(context).closeDrawer();
                                context.push("/setbooru");
                            }, child: const Text("Go to set booru"))
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
    const BrowseScreenPopupMenuButton({super.key});

    List<PopupMenuEntry> generalItems() {
        return [
            PopupMenuItem(
                child: const Text("Refresh"),
                onTap: () => booruUpdateListener.update(),
            )
        ];
    }

    @override
    Widget build(context) {
        return PopupMenuButton(
            itemBuilder: (context) {
                final List<PopupMenuEntry> filteredList = generalItems();
                return filteredList;
            }
        );
    }
}