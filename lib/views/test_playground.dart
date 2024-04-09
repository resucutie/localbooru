import 'dart:io';

import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/window_frame.dart';
import 'package:localbooru/utils/compressor.dart';
import 'package:localbooru/utils/misc.dart';

class TestPlaygroundScreen extends StatefulWidget {
    const TestPlaygroundScreen({super.key});

    @override
    State<TestPlaygroundScreen> createState() => _TestPlaygroundScreenState();
}

class _TestPlaygroundScreenState extends State<TestPlaygroundScreen> {
    Future<List<File>>? _data = null;

    @override
    void initState() {
        super.initState();
        (() async {
            final booru = await getCurrentBooru();
            final List<BooruImage> images = await booru.getRecentImages();
            setState(() {_data = (() async {
                List<File> e = [];
                for(final image in images) {
                    final file = await getImageThumbnail(image);
                    debugPrint(formatSize(await file.length()));
                    e.add(file);
                }
                return e;
            })();});
        })();
    }

    @override
    Widget build(context) {
        return Scaffold(
            appBar: WindowFrameAppBar(
                title: "Playground",
                appBar: AppBar(
                    title: const Text("Playground"),
                ),
            ),
            body: _data != null ? FutureBuilder(
                future: _data,
                builder: (context, snapshot) {
                    if(snapshot.hasData) {
                        return ListView.builder(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                                return Image(
                                    image: ResizeImage(
                                        FileImage(snapshot.data![index]),
                                        width: 100,
                                        height: 100,
                                        policy: ResizeImagePolicy.fit
                                    ),
                                );
                            },
                        );
                    }
                    if(snapshot.hasError) throw snapshot.error!;
                    return const CircularProgressIndicator();
                },
            ) : const CircularProgressIndicator()
        );
    }
}