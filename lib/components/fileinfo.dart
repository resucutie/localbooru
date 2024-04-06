import 'dart:io';

import 'package:flutter/material.dart';
import 'package:localbooru/components/builders.dart';
import 'package:localbooru/utils/compressor.dart';
import 'package:localbooru/utils/misc.dart';

class FileInfo extends StatefulWidget {
    const FileInfo(this.file, {super.key, this.onCompressed});

    final File file;
    final ValueChanged<File>? onCompressed;

    @override
    State<FileInfo> createState() => _FileInfoState();
}
class _FileInfoState extends State<FileInfo> {
    bool isCompressing = false;

    @override
    Widget build(context) {
        return ImageInfoBuilder(
            path: widget.file.path,
            builder: (context, size, image) => Card(
                child: ListTile(
                    leading: Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
                    subtitle: SelectableText.rich(
                        TextSpan(
                            text: "Path: ${widget.file.path}\n",
                            children: [
                                if(image != null) TextSpan(text: "Dimensions: ${image.width}x${image.height}\n"),
                                TextSpan(
                                    text: "Size: ${formatSize(size)}",
                                    children: widget.onCompressed != null ? [
                                        WidgetSpan(
                                            alignment: PlaceholderAlignment.middle,
                                            child: Padding(
                                                padding: const EdgeInsets.only(left: 8),
                                                child: Builder(
                                                    builder: (_) {                                        
                                                        if(isCompressing) return const CircularProgressIndicator();
                                                        return OutlinedButton.icon(
                                                            icon: const Icon(Icons.compress),
                                                            onPressed: () async {
                                                                if(widget.onCompressed == null) return;
                                                                setState(() => isCompressing = true);
                                                                final compressed = await compress(widget.file);

                                                                widget.onCompressed!(compressed);
                                                                setState(() => isCompressing = false);
                                                            },
                                                            label: const Text("Compress")
                                                        );
                                                    },
                                                )
                                            ),
                                            )
                                    ] : null
                                ),
                            ]
                        )
                    ),
                ),
            ),
        );
    }
}