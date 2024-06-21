import 'package:flutter/material.dart';

class GeneralCollectionManagerScreen extends StatefulWidget {
  const GeneralCollectionManagerScreen({super.key, this.onCorelatedChanged, this.corelated});

  final void Function(bool value)? onCorelatedChanged;
  final bool? corelated;

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
                )
            ],
        );
    }
}