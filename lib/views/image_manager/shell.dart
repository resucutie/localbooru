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

    bool isCorelated = false;

    @override
    void initState() {
        super.initState();

        presets = (widget.defaultPresets ?? [PresetImage()]).map((preset) {
            preset.key = UniqueKey();
            return preset;
        }).toList();
    }

    void saveImages() async {
        setState(() => isSaving = true);
        
        final booru = await getCurrentBooru();
        final listLength = await booru.getListLength();
        final futureImageIDs = presets.asMap().keys.map((index) => "${index + listLength}").toList();
        
        for (final (index, preset) in presets.indexed) {
            if(isCorelated && presets.length > 1) {
                preset.relatedImages = futureImageIDs.where((e) => e != futureImageIDs[index]).toList();
            }
            preset.replaceID = futureImageIDs[index];

            await insertImage(preset);
            setState(() => savedImages++);
        }
        
        if(context.mounted) context.pop();
    }

    String generateName(PresetImage preset) {
        return preset.image != null ? p.basenameWithoutExtension(preset.image!.path) : "Image ${presets.indexOf(preset) + 1}";
    }

    @override
    Widget build(BuildContext context) {
        return OrientationBuilder(
            builder: (context, orientation) => Scaffold(
                key: _scaffoldKey,
                appBar: AppBar(
                    title: imagePage >= 0 ? ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text("${presets[imagePage].replaceID != null ? "Edit" : "Add"} image", style: const TextStyle(fontSize: 20.0), overflow: TextOverflow.ellipsis),
                        subtitle: Text(generateName(presets[imagePage]), style: const TextStyle(fontSize: 14.0), overflow: TextOverflow.ellipsis),
                    ) : const Text("Manage images"),
                    actions: [
                        IconButton(
                            icon: Badge(
                                label: Text("${presets.length}"),
                                offset: const Offset(7, -7),
                                isLabelVisible: presets.length > 1,
                                child: const Icon(Icons.library_add)
                            ),
                            tooltip: "Add images in bulk",
                            onPressed: () => _scaffoldKey.currentState!.openEndDrawer(),
                        ),
                        if(orientation == Orientation.portrait) IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: !isSaving && !hasError ? saveImages : null
                        ) else TextButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text("Done"),
                            onPressed: !isSaving && !hasError ? saveImages : null
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
                                    child: Text("Bulk Adding"),
                                ),
                                ListTile(
                                    title: const Text("Manage images"),
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
                                    title: Text(generateName(presets[index])),
                                    leading: const Icon(Icons.image_outlined),
                                    textColor: imagePage == index ? Theme.of(context).colorScheme.primary : null,
                                    iconColor: imagePage == index ? Theme.of(context).colorScheme.primary : null,
                                    onTap: imagePage == index ? null : () {
                                        setState(() => imagePage = index);
                                        _scaffoldKey.currentState!.closeEndDrawer();
                                    },
                                    trailing: presets.length == 1 ? null : IconButton(
                                        tooltip: "Remove",
                                        icon: const Icon(Icons.close),
                                        onPressed: () {
                                            presets.removeAt(index);
                                            setState(() => imagePage = imagePage >= index ? imagePage - 1 : imagePage);
                                        },
                                    ),
                                )),
                                const Divider(),
                                ListTile(
                                    title: const Text("Add image"),
                                    leading: const Icon(Icons.add),
                                    onTap: () async {
                                        FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.media, allowMultiple: true);
                                        if (result != null) {
                                            if(presets.first.image == null && result.files.length > 1) presets = [];
                                            for (PlatformFile file in result.files) {
                                                if(file.path != null) presets.add(PresetImage(image: File(file.path!), key: UniqueKey()));
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
                body: PopScope(
                    canPop: false,
                    onPopInvoked: (didPop) {
                        if(didPop) return;
                        if(imagePage == 0) {
                            context.pop();
                        } else {
                            setState(() => imagePage = 0);
                        }
                    },
                    child: IndexedStack(
                        index: imagePage + 1,
                        children: [
                            GeneralCollectionManagerScreen(
                                corelated: isCorelated,
                                onCorelatedChanged: (value) => setState(() => isCorelated = value),
                            ),
                            for (final (index, preset) in presets.indexed) ImageManagerForm(
                                key: preset.key, // replace index by something else
                                preset: preset,
                                onChanged: (preset) => setState(() => presets[index] = preset),
                                onErrorUpdate: (containsError) => setState(() => hasError = containsError),
                            )
                        ],
                    ),
                ),
            )
        );
    }
}