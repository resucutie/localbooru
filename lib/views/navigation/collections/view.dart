import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/image_grid_display.dart';

class CollectionView extends StatefulWidget {
    const CollectionView({super.key, required this.booru, required this.collection, this.index = 0});

    final Booru booru;
    final BooruCollection collection;
    final int index;

    @override
    State<CollectionView> createState() => _CollectionViewState();
}

class _CollectionViewState extends State<CollectionView> {
    late Future<List<BooruImage>> collectionFuture;

    @override
    void initState() {
        super.initState();
        collectionFuture = widget.booru.getImagesFromCollectionOnIndex(widget.collection, index: widget.index);
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: Text(widget.collection.name),
            ),
            body: FutureBuilder(
                future: collectionFuture,
                builder: (context, snapshot) {
                    if(!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    return CustomScrollView(
                        slivers: [
                            SliverRepoGrid(
                                images: snapshot.data!,
                                onPressed: (image) => context.push("/view/${image.id}"),
                            )
                        ],
                    );
                }
            ),
        );
    }
}