import 'package:flutter/material.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/components/multi_image.dart';

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
                    title: const Text("Make elements correlate with eachother"),
                    subtitle: const Text("This will make each image relate to all other images that are being added"),
                    value: widget.corelated!,
                    onChanged: widget.onCorelatedChanged
                ),
                const Divider(),
                if(widget.saveCollectionToggle != null) SwitchListTile(
                    title: const Text("Save as a collection"),
                    value: widget.saveCollectionToggle!,
                    onChanged: (value) {
                        if(widget.onSaveCollectionToggle != null) widget.onSaveCollectionToggle!(value);
                        widget.onErrorChange!(value ? widget.collection.name?.isEmpty ?? true : false);
                    }
                ),
                if(widget.saveCollectionToggle ?? true) Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextFormField(
                        decoration: const InputDecoration(
                            labelText: "Name of collection"
                        ),
                        initialValue: widget.collection.name,
                        validator: (value) => value != null && value.isNotEmpty ? null : "Value is empty",
                        onChanged: (value) {
                            widget.collection.name = value;
                            if(widget.onErrorChange != null) widget.onErrorChange!(value.isEmpty);
                        },
                    ),
                ),
            ],
        );
    }
}