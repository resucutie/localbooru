import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/components/builders.dart';
import 'package:localbooru/components/dialogs/textfield_dialogs.dart';

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
                actions: [
                    IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () async {
                            final name = await showDialog<String>(
                                context: context,
                                builder: (context) => const AddCollectionDialog()
                            );
                            if(name == null) return;
                            await insertCollection(PresetCollection(
                                name: name,
                                pages: []
                            ));
                        },
                    ),
                    PopupMenuButton(
                        itemBuilder: (context) => [
                            PopupMenuItem(
                                child: const Text("Manage collections"),
                                onTap: () => context.push("/settings/booru/collections"),
                            )
                        ],
                    )
                ],
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
                            return CollectionCard(
                                collection: collection,
                                booru: widget.booru,
                                onPressed: () => context.push("/collections/${collection.id}"),
                            );
                        }).toList(),
                    );
                }
            ),
        );
    }
}

class CollectionCard extends StatelessWidget {
    const CollectionCard({super.key, required this.collection, required this.booru, this.onPressed});

    final BooruCollection collection;
    final Booru booru;
    final void Function()? onPressed;

    @override
    Widget build(BuildContext context) {
        return Card(
            clipBehavior: Clip.antiAlias,
            child: Stack(
                children: [
                    Positioned.fill(
                        child: collection.pages.isNotEmpty ? BooruImageLoader(
                            booru: booru,
                            id: collection.pages.first,
                            builder: (context, image) {
                                return Image(
                                    image: FileImage(image.getImage()),
                                    fit: BoxFit.cover,
                                );
                            }
                        ) : const Center(
                            child: Wrap(
                                direction: Axis.vertical,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 16,
                                children: [
                                    Icon(Icons.image_not_supported, size: 48,),
                                    Text("No images added", style: TextStyle(fontSize: 16),)
                                ],
                            ),
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
                            onTap: onPressed,
                        ),
                    )
                ],
            ),
            // onPressed: () => context.push("/collections/${collection.id}"),
        );
    }
}