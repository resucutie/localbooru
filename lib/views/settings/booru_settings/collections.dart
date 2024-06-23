import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/components/builders.dart';
import 'package:localbooru/components/dialogs/image_selector_dialog.dart';
import 'package:localbooru/components/headers.dart';
import 'package:localbooru/components/image_grid_display.dart';

class CollectionsSettings extends StatefulWidget {
    const CollectionsSettings({super.key, required this.booru});

    final Booru booru;

    @override
    State<CollectionsSettings> createState() => _CollectionsSettingsState();
}

class _CollectionsSettingsState extends State<CollectionsSettings> {
    late List<PresetCollection> collectionPresets;
    bool hasLoaded = false;

    @override
    void initState() {
        super.initState();

        widget.booru.getAllCollections().then((collections) {
            collectionPresets = collections.map((collection) => PresetCollection.fromExistingPreset(collection)).toList();
            setState(() => hasLoaded = true);
        });
    }

    Future<void> savePresets() async{
        for(final preset in collectionPresets) {
            await insertCollection(preset);
        }
    }

    @override
    Widget build(BuildContext context) {
        return hasLoaded ? ListView.separated(
            itemCount: collectionPresets.length + 1,
            separatorBuilder: (context, index) {
                if(index == 0) return SmallHeader("Collections", padding: const EdgeInsets.symmetric(vertical: 8).copyWith(left: 8),);
                return const SizedBox(height: 8,);
            },
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemBuilder: (context, index) {
                if(index <= 0) return ListTile(
                    title: const Text("Save changes"),
                    leading: const Icon(Icons.save),
                    onTap: () async {
                        await savePresets();
                        if(context.mounted) context.pop();
                    },
                );
                return CollectionCard(
                    collection: collectionPresets[index - 1],
                    booru: widget.booru,
                    onChanged: (collection) => setState(() => collectionPresets[index - 1] = collection),
                );
            },
        ) : const Center(child: CircularProgressIndicator(),);
    }
}

class CollectionCard extends StatefulWidget {
    const CollectionCard({super.key, required this.collection, required this.booru, this.onChanged});

    final PresetCollection collection;
    final Booru booru;
    final void Function(PresetCollection collection)? onChanged;

    @override
    State<CollectionCard> createState() => _CollectionCardState();
}

class _CollectionCardState extends State<CollectionCard> {
    late PresetCollection loadedCollection;
    final TextEditingController nameController = TextEditingController();

    @override
    void initState() {
        super.initState();

        loadedCollection = widget.collection;
    }

    void sendChange() {
        if(widget.onChanged != null) widget.onChanged!(loadedCollection);
    }

    @override
    Widget build(BuildContext context) {
        return Card(
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
                title: Text(loadedCollection.name!),
                childrenPadding: const EdgeInsets.all(16).copyWith(top: 0),
                subtitle: Text("ID ${loadedCollection.id}"),
                children: [
                    TextFormField(
                        decoration: const InputDecoration(
                            labelText: "Name"
                        ),
                        initialValue: loadedCollection.name,
                        validator: (value) => value != null && value.isNotEmpty ? null : "Value is empty",
                        onChanged: (value) {
                            loadedCollection.name = value;
                            sendChange();
                        },
                    ),
                    const SizedBox(height: 8,),
                    ReorderableListView.builder(
                        itemCount: loadedCollection.pages!.length, 
                        buildDefaultDragHandles: false,
                        proxyDecorator: (child, index, animation) {
                            return AnimatedBuilder(
                                animation: animation,
                                builder: (BuildContext context, Widget? child) {
                                    return Material(
                                        elevation: 0,
                                        color: Colors.transparent,
                                        child: child,
                                    );
                                },
                                child: child,
                            );
                        },
                        itemBuilder: (context, index) {
                            final imageID = loadedCollection.pages![index];
                            return ReorderableDragStartListener(
                                key: ValueKey(imageID),
                                index: index,
                                child: BooruImageLoader(
                                    booru: widget.booru,
                                    id: imageID,
                                    builder: (context, image) => Card.filled(
                                        clipBehavior: Clip.antiAlias,
                                        child: ListTile(
                                            title: Text(image.filename),
                                            subtitle: Text("ID ${image.id}"),
                                            visualDensity: const VisualDensity(vertical: 0), // to expand
                                            contentPadding: const EdgeInsets.only(left: 9, right: 16),
                                            onTap: () {
                                                context.push("/zoom_image/$imageID");
                                            },
                                            trailing: IconButton(
                                                icon: const Icon(Icons.close),
                                                onPressed: () => setState(() => loadedCollection.pages!.removeAt(index)),
                                            ),
                                            leading: ClipRRect(
                                                borderRadius: const BorderRadius.all(Radius.circular(10)),
                                                clipBehavior: Clip.antiAlias,
                                                child: Stack(
                                                    children: [
                                                        ImageGrid(
                                                            image: image,
                                                            resizeSize: 200,
                                                        ),
                                                        Positioned.fill(
                                                            child: Container(
                                                                color: Colors.black.withOpacity(0.65),
                                                                child: Center(
                                                                    child: Text("${index + 1}",
                                                                        style: const TextStyle(
                                                                            color: Colors.white,
                                                                            fontSize: 22,
                                                                            fontWeight: FontWeight.bold
                                                                        ),
                                                                        textAlign: TextAlign.center,
                                                                    ),
                                                                ),
                                                            )
                                                        )
                                                    ],
                                                ),
                                            ),
                                        ),
                                    )
                                ),
                            );
                        }, 
                        shrinkWrap: true,
                        onReorder: (oldIndex, newIndex) {
                            if (oldIndex < newIndex) {
                                newIndex -= 1;
                            }
                            setState(() {
                                final String item = loadedCollection.pages!.removeAt(oldIndex);
                                loadedCollection.pages!.insert(newIndex, item);
                            });
                            sendChange();
                        },
                    ),
                    // const SizedBox(height: 8,),
                    Card.filled(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                            leading: const Icon(Icons.add),
                            // contentPadding: const EdgeInsets.all(4).copyWith(left: 16),
                            title: const Text("Add image"),
                            onTap: () async {
                                final imageList = await openSelectionDialog(
                                    context: context,
                                    selectedImages: loadedCollection.pages,
                                );
                                if(imageList == null) return;
                                setState(() {
                                    loadedCollection.pages = imageList;
                                });
                                sendChange();
                            },
                        ),
                    )
                ],
            ),
        );
    }
}