import 'dart:io';
import 'dart:typed_data';
import "dart:ui" as dui;

import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/utils/listeners.dart';
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

    void loadData() {
        _data = (() async {
            final Uint8List bytes = await File(widget.path).readAsBytes();
            return {
                "image": lookupMimeType(widget.path)!.startsWith("video/") ? null : await decodeImageFromList(bytes),
                "size": bytes.lengthInBytes
            };
        })();
    }

    @override
    void initState() {
        super.initState();
        loadData();
    }
    @override
    void didUpdateWidget(_) {
        super.didUpdateWidget(_);
        loadData();
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

class BooruLoader extends StatefulWidget {
    const BooruLoader({super.key, required this.builder});
    final Widget Function(BuildContext context, Booru booru) builder;

    @override
    State<BooruLoader> createState() => _BooruLoaderState();
}
class _BooruLoaderState extends State<BooruLoader> {
    late Future<Booru> booru;

    @override
    void initState() {
        super.initState();
        booru = getCurrentBooru();
    }

    @override
    Widget build(BuildContext context) {
        return ListenableBuilder(listenable: booruUpdateListener,
            builder: (_, __) {
                return FutureBuilder<Booru>(
                    future: booru,
                    builder: (context, AsyncSnapshot<Booru> snapshot) {
                        if(snapshot.hasData) {
                            return widget.builder(context, snapshot.data!);
                        } else if(snapshot.hasError) {
                            throw snapshot.error!;
                        }
                        return const Center(child: CircularProgressIndicator());
                    }
                );
            }
        );
    }   
}

typedef BooruImageWidgetBuilder = Widget Function(BuildContext context, BooruImage image);
class BooruImageLoader extends StatelessWidget {
    const BooruImageLoader({super.key, required this.builder, required this.booru, required this.id});

    final Booru booru;
    final String id;

    final BooruImageWidgetBuilder builder;
    
    @override
    Widget build(BuildContext context) {
        return FutureBuilder<BooruImage?>(
            future: booru.getImage(id),
            builder: (context, AsyncSnapshot<BooruImage?> snapshot) {
                if(snapshot.hasData) {
                    if(snapshot.data == null) return const Text("File does not exist");
                    return builder(context, snapshot.data!);
                } else if(snapshot.hasError) {
                    throw snapshot.error!;
                }
                return const Center(child: CircularProgressIndicator());
            }
        );
    }   
}