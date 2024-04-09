import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/utils/get_website.dart';
import 'package:localbooru/utils/listeners.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:url_launcher/url_launcher_string.dart';
import "package:vector_math/vector_math_64.dart";

List<PopupMenuEntry> booruItems() {
    return [
        PopupMenuItem(
            child: const Text("Refresh"),
            onTap: () => booruUpdateListener.update(),
        ),
        PopupMenuItem(
            child: const Text("Open booru location"),
            onTap: () async  {
                final Booru booru = await getCurrentBooru();
                await launchUrlString("file://${booru.path}");
            },
        )
    ];
}

List<PopupMenuEntry> imageShareItems(BooruImage image) {
    return [
        PopupMenuItem(
            child: const Text("Open image in image viewer"),
            onTap: () => OpenFile.open(image.path),
        ),
        PopupMenuItem(
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
            onTap: () => context.push("/manage_image/internal/${image.id}")
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

List<PopupMenuEntry> urlItems(String url) {
    return [
        PopupMenuItem(
            child: const Text("Open URL"),
            onTap: () => launchUrlString(url),
        ),
        PopupMenuItem(
            child: const Text("Copy URL"),
            onTap: () async {
                final item = DataWriterItem();
                item.add(Formats.plainText(url));
                await SystemClipboard.instance?.write([item]);
            },
        ),
        PopupMenuItem(
            child: const Text("Share URL"),
            onTap: () async => await Share.share(url),
        ),
    ];
}

List<PopupMenuEntry> tagItems(String tag, BuildContext context) {
    return [
        PopupMenuItem(
            child: const Text("Search"),
            onTap: () async {
                final res = await showDialog<String>(context: context,
                    builder: (context) => ServiceActionsDialogue(tag: tag, title: "Search on",)
                );
                switch (res) {
                    case "Danbooru": launchUrlString("https://danbooru.donmai.us/posts?tags=$tag");
                    case "e926": launchUrlString("https://e926.net/posts?tags=$tag");
                    case "e621": launchUrlString("https://e621.net/posts?tags=$tag");
                    case "Gelbooru": launchUrlString("https://gelbooru.com/index.php?page=post&s=list&tags=$tag");
                }
            }
        ),
        PopupMenuItem(
            child: const Text("More information about"),
            onTap: () async {
                final res = await showDialog<String>(context: context,
                    builder: (context) => ServiceActionsDialogue(tag: tag, title: "Open wiki",)
                );
                switch (res) {
                    case "Danbooru": 
                        final booru = await getCurrentBooru();
                        final tagType = await booru.getTagType(tag);
                        if(tagType == "artist") {
                            launchUrlString("https://danbooru.donmai.us/artists/show_or_new?name=$tag");
                        } else {
                            launchUrlString("https://danbooru.donmai.us/wiki_pages/$tag");
                        }
                    case "e926": launchUrlString("https://e926.net/wiki_pages/show_or_new?title=$tag");
                    case "e621": launchUrlString("https://e621.net/wiki_pages/show_or_new?title=$tag");
                    case "Gelbooru": launchUrlString("https://gelbooru.com/index.php?page=wiki&s=list&search=$tag");
                }
            }
        ),
    ];
}
class ServiceActionsDialogue extends StatelessWidget {
    const ServiceActionsDialogue({super.key, required this.tag, this.title = "Select a service"});

    final String tag;
    final String title;

    @override
    Widget build(BuildContext context) {
        return SimpleDialog(
            title: Text(title),
            children: [
                ["Danbooru", "https://danbooru.donmai.us"],
                ["e621", "https://e621.net"],
                ["e926", "https://e926.net"],
                ["Gelbooru", "https://gelbooru.com"]
            ].map((e) => SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(e[0]),
                child: ListTile(
                    leading: getWebsiteIcon(Uri.parse(e[1])) ?? Icon(Icons.question_mark, color: Theme.of(context).colorScheme.primary),
                    title: Text(e[0]),
                ),
            )).toList(),
        );
    }
}

Offset getOffsetRelativeToBox({required Offset offset, required RenderObject renderObject}) {
    debugPrint(globalToLocal(renderObject, offset).toString());
    return globalToLocal(renderObject, offset);
}

Offset globalToLocal(RenderObject object, Offset point, { RenderObject? ancestor }) {
    // Copied from
    final Matrix4 transform = object.getTransformTo(ancestor);
    final double det = transform.invert();
    if (det == 0.0) {
        return Offset.zero;
    }
    final Vector3 n = Vector3(0.0, 0.0, 1.0);
    final Vector3 i = transform.perspectiveTransform(Vector3(0.0, 0.0, 0.0));
    final Vector3 d = transform.perspectiveTransform(Vector3(0.0, 0.0, 1.0)) - i;
    final Vector3 s = transform.perspectiveTransform(Vector3(point.dx, point.dy, 0.0));
    final Vector3 p = s - d * (n.dot(s) / n.dot(d));
    return Offset(p.x, p.y);
}