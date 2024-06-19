import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/components/app_bar_linear_progress.dart';
import 'package:localbooru/views/image_manager/form.dart';

class ImageManagerShell extends StatefulWidget {
    const ImageManagerShell({super.key, this.defaultPresets});

    final List<PresetImage>? defaultPresets;

    @override
    State<ImageManagerShell> createState() => _ImageManagerShellState();
}

class _ImageManagerShellState extends State<ImageManagerShell> {
    late List<PresetImage> presets;
    bool hasError = true;
    bool isSaving = false;
    int savedImages = 0;

    @override
    void initState() {
        super.initState();

        presets = widget.defaultPresets ?? [const PresetImage()];
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                // title: Text("${isEditing ? "Edit" : "Add"} image"),
                title: const Text("Add Image"),
                actions: [
                    TextButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text("Done"),

                        onPressed: !isSaving && !hasError ? () async {
                            setState(() => isSaving = true);
                            for (final preset in presets) {
                                await addImage(preset);
                                setState(() => savedImages++);
                            }
                            if(context.mounted) context.pop();
                        } : null
                    ),
                ],
                bottom: isSaving ? AppBarLinearProgressIndicator(value: savedImages / presets.length,) : null,
            ),
            body: ImageManagerForm(
                preset: presets[0],
                onChanged: (preset) => setState(() => presets[0] = preset),
                onErrorUpdate: (containsError) {
                    setState(() => hasError = containsError);
                    debugPrint("$hasError");
                },
            ),
        );
    }
}