import 'package:flutter/material.dart';
import 'package:localbooru/api/preset/index.dart';

class GeneralCollectionManagerScreen extends StatefulWidget {
    const GeneralCollectionManagerScreen({super.key, this.onCorelatedChanged, this.corelated, this.saveCollectionToggle, this.onSaveCollectionToggle, required this.collection, this.onCollectionChange});

    final void Function(bool value)? onCorelatedChanged;
    final bool? corelated;
    final void Function(bool value)? onSaveCollectionToggle;
    final bool? saveCollectionToggle;
    final void Function(VirtualPresetCollection value)? onCollectionChange;
    final VirtualPresetCollection collection;

    @override
    State<GeneralCollectionManagerScreen> createState() => _GeneralCollectionManagerScreenState();
}

class _GeneralCollectionManagerScreenState extends State<GeneralCollectionManagerScreen> {
    @override
    Widget build(BuildContext context) {
        return ListView(
            children: [
                if(widget.corelated != null) SwitchListTile(
                    title: const Text("Enable corelated"),
                    value: widget.corelated!,
                    onChanged: widget.onCorelatedChanged
                ),
                if(widget.saveCollectionToggle != null) SwitchListTile(
                    title: const Text("Save as a collection"),
                    value: widget.saveCollectionToggle!,
                    onChanged: widget.onSaveCollectionToggle
                ),
                if(widget.saveCollectionToggle ?? true) ...[
                    TextFormField(
                        decoration: const InputDecoration(
                            labelText: "Name"
                        ),
                        initialValue: widget.collection.name,
                        validator: (value) => value != null && value.isNotEmpty ? null : "Value is empty",
                        onChanged: (value) {
                            widget.collection.name = value;
                        },
                    ),
                    const SizedBox(height: 8,),
                ],
            ],
        );
    }
}