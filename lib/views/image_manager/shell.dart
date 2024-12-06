import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/components/app_bar_linear_progress.dart';
import 'package:localbooru/components/dialogs/image_selector_dialog.dart';
import 'package:localbooru/utils/platform_tools.dart';
import 'package:localbooru/views/image_manager/form.dart';
import 'package:localbooru/views/image_manager/general_collection_manager.dart';
import 'package:path/path.dart' as p;

class ImageManagerShell extends StatefulWidget {
    const ImageManagerShell({super.key, this.sendable});

    final ManageImageSendable? sendable;

    @override
    State<ImageManagerShell> createState() => _ImageManagerShellState();
}

class _ImageManagerShellState extends State<ImageManagerShell> {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    
    late VirtualPresetCollection preset;
    List<bool> errorOnPages = [false];
    bool isSaving = false;
    bool saveCollection = false;
    int savedImages = 0;
    int imagePage = 0;

    bool isCorelated = false;

    @override
    void initState() {
        super.initState();
        if(widget.sendable == null) preset = VirtualPresetCollection(pages: [PresetImage()]);
        if(widget.sendable is PresetManageImageSendable) preset = VirtualPresetCollection(pages: [(widget.sendable as PresetManageImageSendable).preset]);
        if(widget.sendable is PresetListManageImageSendable) preset = VirtualPresetCollection(pages: (widget.sendable as PresetListManageImageSendable).presets);
        if(widget.sendable is VirtualPresetManageImageSendable) {
            saveCollection = true;
            preset = (widget.sendable as VirtualPresetManageImageSendable).preset;
        }

        if(preset.pages == null || preset.pages!.isEmpty) preset.pages = [PresetImage()];
        errorOnPages.addAll(List.generate(preset.pages!.length, (index) => preset.pages![index].image == null || preset.pages![index].tags == null));
    }

    void saveImages() async {
        setState(() => isSaving = true);
        
        final booru = await getCurrentBooru();
        final listLength = await booru.getListLength();

        final List<ImageID> imaginaryIDs = preset.pages!.mapIndexed((index, preset) {
            if(preset.replaceID != null) return preset.replaceID!;
            return "${index + listLength}";
        }).toList();
        
        for (final (index, imagePreset) in preset.pages!.indexed) {
            if(isCorelated && preset.pages!.length > 1) {
                final selfID = imaginaryIDs[index];
                imagePreset.relatedImages = imaginaryIDs.where((id) => id != selfID).toList();
            }
            imagePreset.replaceID ??= imaginaryIDs[index];

            await insertImage(imagePreset);
            setState(() => savedImages++);
        }

        if(saveCollection) await insertCollection(PresetCollection.fromVirtualPresetCollection(preset));
        
        if(context.mounted) context.pop();
    }

    String generateName(PresetImage imagePreset) {
        return imagePreset.image != null ? p.basenameWithoutExtension(imagePreset.image!.path) : "Image ${preset.pages!.indexOf(imagePreset) + 1}";
    }

    bool hasError() => errorOnPages.any((element) => element,);

    void addMultipleImages(List<PlatformFile> files) {
        for (PlatformFile file in files) {
            if(file.path != null) {
                preset.pages!.add(PresetImage(image: File(file.path!), key: UniqueKey()));
                errorOnPages.add(true);
            }
        }
    }

    @override
    Widget build(BuildContext context) {
        return OrientationBuilder(
            builder: (context, orientation) => Scaffold(
                key: _scaffoldKey,
                appBar: AppBar(
                    title: imagePage >= 0 ? ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text("${preset.pages![imagePage].replaceID != null ? "Edit" : "Add"} image", style: const TextStyle(fontSize: 20.0), overflow: TextOverflow.ellipsis),
                        subtitle: Text(generateName(preset.pages![imagePage]), style: const TextStyle(fontSize: 14.0), overflow: TextOverflow.ellipsis),
                    ) : Text("${preset.pages!.length} images"),
                    actions: [
                        IconButton(
                            icon: Badge(
                                padding: EdgeInsets.zero,
                                label: Wrap(
                                    children: [
                                        if(saveCollection) Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Theme.of(context).colorScheme.onTertiaryContainer
                                            ),
                                            child: const Text("C"),
                                        ),
                                        if(preset.pages!.length > 1) Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            child: Text("${preset.pages!.length}"),
                                        )
                                    ],
                                ),
                                offset: Offset(preset.pages!.length > 1 && saveCollection ? 0 : 7, -7),
                                isLabelVisible: preset.pages!.length > 1 || saveCollection,
                                child: const Icon(Icons.library_add),
                            ),
                            // icon: Icon(Icons.library_add),
                            tooltip: preset.pages!.length > 1 || saveCollection
                                // ignore: prefer_interpolation_to_compose_strings
                                ? "${preset.pages!.length} images will be added" + (saveCollection ? " and put inside a new collection": "")
                                : "Add images in bulk",
                            onPressed: () => _scaffoldKey.currentState!.openEndDrawer(),
                        ),
                        // Tooltip(
                        //     message: hasError() ? "There's some errors to resolve" : null,
                        //     child: ,
                        // ),
                        orientation == Orientation.portrait ? IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: !isSaving && !hasError() ? saveImages : null,
                            tooltip: !hasError() ? "Done" : null,
                        ) : TextButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text("Done"),
                            onPressed: !isSaving && !hasError() ? saveImages : null,
                        )
                    ],
                    bottom: isSaving ? AppBarLinearProgressIndicator(value: savedImages != 0 ? savedImages / preset.pages!.length : null,) : null,
                ),
                endDrawer: Drawer(
                    child: SingleChildScrollView(
                        child: SafeArea(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Padding(
                                        padding: const EdgeInsets.all(16).copyWith(top: isMobile() ? 4 : 16),
                                        child: const Text("Bulk Adding"),
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
                                    ...List.generate(preset.pages!.length, (index) => ListTile(
                                        title: Text(generateName(preset.pages![index])),
                                        leading: const Icon(Icons.image_outlined),
                                        textColor: imagePage == index ? Theme.of(context).colorScheme.primary : null,
                                        iconColor: imagePage == index ? Theme.of(context).colorScheme.primary : null,
                                        onTap: imagePage == index ? null : () {
                                            setState(() => imagePage = index);
                                            _scaffoldKey.currentState!.closeEndDrawer();
                                        },
                                        trailing: preset.pages!.length == 1 ? null : IconButton(
                                            tooltip: "Remove",
                                            icon: const Icon(Icons.close),
                                            onPressed: () {
                                                preset.pages!.removeAt(index);
                                                errorOnPages.removeAt(index);
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
                                                // if(preset.pages!.first.image == null && result.files.length > 1) preset.pages = [];
                                                addMultipleImages(result.files);
                                                setState(() => imagePage = preset.pages!.length - 1);
                                                _scaffoldKey.currentState!.closeEndDrawer();
                                            }
                                        }
                                    ),
                                    ListTile(
                                        title: const Text("Edit existing image"),
                                        leading: const Icon(Icons.edit),
                                        onTap: () async {
                                            final images = await openSelectionDialog(
                                                context: context,
                                                excludeImages: preset.pages!.where((imagePreset) => imagePreset.replaceID != null,).map((imagePreset) => imagePreset.replaceID!).toList()
                                            );
                                            if(images == null) return;
                                            final booru = await getCurrentBooru();
                                            preset.pages!.addAll(await Future.wait(images.map((id) async {
                                                PresetImage image = await PresetImage.fromExistingImage((await booru.getImage(id))!);
                                                image.key = UniqueKey();
                                                errorOnPages.add(false);
                                                return image;
                                            })));
                                            setState(() => imagePage = preset.pages!.length - 1);
                                            _scaffoldKey.currentState!.closeEndDrawer();
                                        }
                                    ),
                                ],
                            ),
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
                                displayImages: List<ImageProvider?>.generate(3, (index) => preset.pages!.asMap().containsKey(index) && preset.pages![index].image != null ? FileImage(preset.pages![index].image!) : null,),
                                corelated: isCorelated,
                                onCorelatedChanged: (value) => setState(() => isCorelated = value),
                                saveCollectionToggle: saveCollection,
                                onSaveCollectionToggle: (value) => setState(() => saveCollection = value),
                                collection: preset,
                                onErrorChange: (value) => setState(() => errorOnPages[0] = value),
                            ),
                            for (final (index, imagePreset) in preset.pages!.indexed) ImageManagerForm(
                                key: imagePreset.key, // replace index by something else
                                preset: imagePreset,
                                onChanged: (imagePreset) => setState(() => preset.pages![index] = imagePreset),
                                onErrorUpdate: (containsError) => setState(() => errorOnPages[index + 1] = containsError),
                                onMultipleImagesAdded: addMultipleImages,
                                showRelatedImagesCard: !isCorelated,
                            )
                        ],
                    ),
                ),
                // floatingActionButton: FloatingActionButton(onPressed: () => debugPrint("$errorOnPages"),),
            )
        );
    }
}

abstract class ManageImageSendable {}
class PresetManageImageSendable extends ManageImageSendable {
    PresetManageImageSendable(this.preset);
    PresetImage preset;
}
class PresetListManageImageSendable extends ManageImageSendable {
    PresetListManageImageSendable(this.presets);
    List<PresetImage> presets;
}
class VirtualPresetManageImageSendable extends ManageImageSendable {
    VirtualPresetManageImageSendable(this.preset);
    VirtualPresetCollection preset;
}

ManageImageSendable handleSendable(VirtualPreset preset) {
    if(preset is VirtualPresetCollection) return VirtualPresetManageImageSendable(preset);
    else return PresetManageImageSendable(preset as PresetImage);
}