import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/components/app_bar_linear_progress.dart';
import 'package:localbooru/views/image_manager/form.dart';
import 'package:localbooru/views/image_manager/general_collection_manager.dart';
import 'package:path/path.dart' as p;

class ImageManagerShell extends StatefulWidget {
    const ImageManagerShell({super.key, this.defaultPresets});

    final List<PresetImage>? defaultPresets;

    @override
    State<ImageManagerShell> createState() => _ImageManagerShellState();
}

class _ImageManagerShellState extends State<ImageManagerShell> {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    
    late List<PresetImage> presets;
    bool hasError = true;
    bool isSaving = false;
    int savedImages = 0;
    int imagePage = 0;

    @override
    void initState() {
        super.initState();

        presets = (widget.defaultPresets ?? [PresetImage()]).map((preset) {
            preset.uniqueKey = UniqueKey();
            return preset;
        }).toList();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
                // title: Text("${isEditing ? "Edit" : "Add"} image"),
                title: const Text("Add Image"),
                actions: [
                    IconButton(
                        icon: const Icon(Icons.library_add),
                        tooltip: "Collections",
                        onPressed: () => _scaffoldKey.currentState!.openEndDrawer(),
                    ),
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
            endDrawer: Drawer(
                child: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text("Collections"),
                            ),
                            ListTile(
                                title: const Text("Manage collections"),
                                textColor: imagePage == -1 ? Theme.of(context).colorScheme.primary : null,
                                iconColor: imagePage == -1 ? Theme.of(context).colorScheme.primary : null,
                                leading: const Icon(Icons.photo_library),
                                onTap: imagePage == -1 ? null : () {
                                    setState(() => imagePage = -1);
                                    _scaffoldKey.currentState!.closeEndDrawer();
                                },
                            ),
                            const Divider(),
                            ...List.generate(presets.length, (index) => ListTile(
                                title: Text(presets[index].image != null ? p.basenameWithoutExtension(presets[index].image!.path) : "Image ${index + 1}"),
                                leading: const Icon(Icons.image_outlined),
                                textColor: imagePage == index ? Theme.of(context).colorScheme.primary : null,
                                iconColor: imagePage == index ? Theme.of(context).colorScheme.primary : null,
                                onTap: imagePage == index ? null : () {
                                    setState(() => imagePage = index);
                                    _scaffoldKey.currentState!.closeEndDrawer();
                                },
                                trailing: presets.length == 1 ? null : IconButton(
                                    tooltip: "Delete",
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                        presets.removeAt(index);
                                        setState(() => imagePage = imagePage > index ? imagePage - 1 : imagePage);
                                    },
                                ),
                            )),
                            const Divider(),
                            ListTile(
                                title: const Text("Add image"),
                                leading: const Icon(Icons.add),
                                onTap: () async {
                                    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.media);
                                    if (result != null) {
                                        for (PlatformFile file in result.files) {
                                            if(file.path != null) presets.add(PresetImage(image: File(file.path!), uniqueKey: UniqueKey()));
                                        }
                                        setState(() => imagePage = presets.length - 1);
                                        _scaffoldKey.currentState!.closeEndDrawer();
                                    }
                                }
                            ),
                        ],
                    ),
                ),
            ),
            body: IndexedStack(
                index: imagePage + 1,
                children: [
                    const GeneralCollectionManagerScreen(),
                    for (final (index, preset) in presets.indexed) (() {
                        debugPrint("${presets.map((e) => e.image).toList()}");
                        return ImageManagerForm(
                            key: preset.uniqueKey, // replace index by something else
                            preset: preset,
                            onChanged: (preset) => setState(() => presets[index] = preset),
                            onErrorUpdate: (containsError) {
                                setState(() => hasError = containsError);
                                debugPrint("$hasError");
                            },
                        );
                    })()
                ],
            ),
        );
    }
}