import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/builders.dart';

class CollectionsListPage extends StatefulWidget {
    const CollectionsListPage({super.key, required this.booru});

    final Booru booru;

    @override
    State<CollectionsListPage> createState() => _CollectionsListPageState();
}

class _CollectionsListPageState extends State<CollectionsListPage> {
    late Future<List<BooruCollection>> collectionFuture;

    @override
    void initState() {
        super.initState();
        collectionFuture = widget.booru.getAllCollections();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text("Collections"),
            ),
            body: FutureBuilder(
                future: collectionFuture,
                builder: (context, snapshot) {
                    if(!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    return GridView.extent(
                        maxCrossAxisExtent: 250,
                        childAspectRatio: 0.75,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        padding: const EdgeInsets.all(8),
                        children: snapshot.data!.map((collection) {
                            return Card(
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                    children: [
                                        Positioned.fill(
                                            child: BooruImageLoader(
                                                booru: widget.booru,
                                                id: collection.pages[0],
                                                builder: (context, image) {
                                                    return Image(
                                                        image: FileImage(image.getImage()),
                                                        fit: BoxFit.cover,
                                                    );
                                                }
                                            )
                                        ),
                                        Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                                decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                        begin: Alignment.topCenter, 
                                                        end: Alignment.bottomCenter,
                                                        colors: [Colors.transparent, Colors.black.withOpacity(0.6)]
                                                    )
                                                ),
                                                padding: const EdgeInsets.all(8).copyWith(
                                                    top: 96,
                                                    bottom: 16
                                                ),
                                                child: Text(collection.name,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.white,
                                                        shadows: [
                                                            Shadow(
                                                                color: Colors.black,
                                                                blurRadius: 5
                                                            )
                                                        ]
                                                    ),
                                                ),
                                            ),
                                        ),
                                        Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                                onTap: () => context.push("/collections/${collection.id}"),
                                            ),
                                        )
                                    ],
                                ),
                                // onPressed: () => context.push("/collections/${collection.id}"),
                            );
                        }).toList(),
                    );
                }
            ),
        );
    }
}