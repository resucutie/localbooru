import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
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
        )
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