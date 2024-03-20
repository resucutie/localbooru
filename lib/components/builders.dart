import 'dart:io';
import "dart:ui" as dui;

import 'package:flutter/material.dart';
import 'package:mime/mime.dart';

class ImageInfoBuilder extends StatefulWidget {
    const ImageInfoBuilder({super.key, required this.builder, required this.path});
    
    final Widget Function(BuildContext context, int size, dui.Image? image) builder;
    final String path;

    @override
    State<ImageInfoBuilder> createState() => _ImageInfoBuilderState();
}
class _ImageInfoBuilderState extends State<ImageInfoBuilder> {
    late Future<Map> _data;

    @override
    void initState() {
        super.initState();

        _data = (() async => {
            "image": lookupMimeType(widget.path)!.startsWith("video/") ? null : await decodeImageFromList(await File(widget.path).readAsBytes()),
            "size": await File(widget.path).length()
        })();
    }
    
    @override
    Widget build(BuildContext context) {
        return FutureBuilder<Map>(
            future: _data,
            builder: (context, snapshot) {
                if(snapshot.hasData || snapshot.hasError) {
                    return widget.builder(context, snapshot.data!["size"]!, snapshot.data?["image"]);
                }
                return const CircularProgressIndicator();
            }
        );
    }   
}