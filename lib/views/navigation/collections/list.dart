import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';

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
                    return ListView(
                        children: snapshot.data!.map((collection) {
                            return ElevatedButton(
                                child: Text(collection.name),
                                onPressed: () => context.push("/collections/${collection.id}"),
                            );
                        }).toList(),
                    );
                }
            ),
        );
    }
}