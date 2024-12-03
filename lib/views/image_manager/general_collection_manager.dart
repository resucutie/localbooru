import 'package:flutter/material.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/components/multi_image_display.dart';

class GeneralCollectionManagerScreen extends StatefulWidget {
    const GeneralCollectionManagerScreen({super.key, this.displayImages, this.onCorelatedChanged, this.corelated, this.saveCollectionToggle, this.onSaveCollectionToggle, required this.collection, this.onErrorChange});

    final List<ImageProvider?>? displayImages;
    final void Function(bool value)? onCorelatedChanged;
    final bool? corelated;
    final void Function(bool value)? onSaveCollectionToggle;
    final bool? saveCollectionToggle;
    final void Function(bool value)? onErrorChange;
    final VirtualPresetCollection collection;

    @override
    State<GeneralCollectionManagerScreen> createState() => _GeneralCollectionManagerScreenState();
}

class _GeneralCollectionManagerScreenState extends State<GeneralCollectionManagerScreen> {
    @override
    Widget build(BuildContext context) {
        return ListView(
            children: [
                if(widget.displayImages != null) ...[
                    // const SizedBox(height: 13,),
                    Center(
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 225),
                            child: AspectRatio(
                                aspectRatio: 1,
                                child: MultipleImage(
                                    images: widget.displayImages!,
                                ),
                            ),
                        ),
                    ),
                    const SizedBox(height: 16,)
                ],

                if(widget.corelated != null) SwitchListTile(
                    title: const Text("Relate all images together"),
                    subtitle: const Text("Make each added image related to the others in the batch. Useful if you want to add alternative versions of an image"),
                    secondary: Icon(Icons.hub_outlined),
                    value: widget.corelated!,
                    onChanged: widget.onCorelatedChanged
                ),
                // const Divider(),
                if(widget.saveCollectionToggle != null) ExpansionTile(
                    title: Text("Collections"),
                    subtitle: Text("Create a collection with all images"),
                    leading: Icon(Icons.photo_library, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    initiallyExpanded: true,
                    shape: RoundedRectangleBorder(side: BorderSide.none),
                    collapsedShape: RoundedRectangleBorder(side: BorderSide.none),
                    children: [
                        SwitchListTile(
                            title: const Text("Create a collection and put all images inside"),
                            subtitle: const Text("Creates a brand new collection and add all images to it"),
                            value: widget.saveCollectionToggle!,
                            onChanged: (value) {
                                if(widget.onSaveCollectionToggle != null) widget.onSaveCollectionToggle!(value);
                                widget.onErrorChange!(value ? widget.collection.name?.isEmpty ?? true : false);
                            }
                        ),
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: TextFormField(
                                decoration: const InputDecoration(
                                    labelText: "Name of collection"
                                ),
                                enabled: widget.saveCollectionToggle ?? true,
                                initialValue: widget.collection.name,
                                validator: (value) => value != null && value.isNotEmpty ? null : "Value is empty",
                                onChanged: (value) {
                                    widget.collection.name = value;
                                    if(widget.onErrorChange != null) widget.onErrorChange!(value.isEmpty);
                                },
                            ),
                        ),
                    ],
                )
            ],
        );
    }
}