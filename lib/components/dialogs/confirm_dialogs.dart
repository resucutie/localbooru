import 'package:flutter/material.dart';

class DeleteImageDialogue extends StatelessWidget {
    const DeleteImageDialogue({super.key});

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Text("Delete image"),
            content: const Text("Are you sure that you want to delete this image? This action will be irreversible"),
            actions: [
                TextButton(onPressed: Navigator.of(context).pop, child: const Text("No")),
                TextButton(
                    child: const Text("Yes"), 
                    onPressed: () => Navigator.of(context).pop(true)
                ),
            ],
        );
    }
}

class UnsavedChangesDialogue extends StatelessWidget {
    const UnsavedChangesDialogue({super.key});

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Text("Unsaved changes"),
            content: const Text("You have unsaved changes. Do you want to discard the changes and exit?"),
            actions: [
                TextButton(
                    child: const Text("Yes"), 
                    onPressed: () => Navigator.of(context).pop(true)
                ),
                TextButton(onPressed: Navigator.of(context).pop, child: const Text("No")),
            ],
        );
    }
}