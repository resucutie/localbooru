import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/api/tags/index.dart';
import 'package:localbooru/components/dialogs/image_selector_dialog.dart';
import 'package:localbooru/components/headers.dart';
import 'package:localbooru/components/dialogs/radio_dialogs.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/views/image_manager/components/image_upload.dart';
import 'package:localbooru/views/image_manager/components/list_string_text_input.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/views/image_manager/components/related_images.dart';
import 'package:localbooru/views/image_manager/components/tagfield.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImageManagerForm extends StatefulWidget {
    const ImageManagerForm({super.key, this.preset, required this.onChanged, this.onMultipleImagesAdded, this.onErrorUpdate, this.showRelatedImagesCard = true});

    final PresetImage? preset;
    final bool showRelatedImagesCard;
    // final bool shouldOpenRecents;
    final void Function(PresetImage preset) onChanged;
    final void Function(bool hasError)? onErrorUpdate;
    final void Function(List<PlatformFile> files)? onMultipleImagesAdded;

    @override
    State<ImageManagerForm> createState() => _ImageManagerFormState();
}

class _ImageManagerFormState extends State<ImageManagerForm> {
    final _formKey = GlobalKey<FormState>();

    final tagController = TextEditingController();
    final artistTagController = TextEditingController();
    final characterTagController = TextEditingController();
    final copyrightTagController = TextEditingController();
    final speciesTagController = TextEditingController();

    final totallyNotTemporary = TextEditingController();

    bool isEditing = false;
    bool isGeneratingTags = false;
    bool isSaving = false;
    
    Rating? rating;

    List<String> urlList = [];
    String loadedImage = "";

    List<ImageID> relatedImages = [];

    @override
    void initState() {
        super.initState();
        isEditing = widget.preset?.replaceID != null;
        
        if(widget.preset != null) {
            final preset = widget.preset!;
            if(preset.image != null) loadedImage = preset.image!.path;
            if(preset.sources != null) urlList = preset.sources!;
            rating = preset.rating;
            if(preset.relatedImages != null) relatedImages = preset.relatedImages ?? [];

            if(preset.tags != null) {
                tagController.text = preset.tags!["generic"]?.join(" ") ?? "";
                artistTagController.text = preset.tags!["artist"]?.join(" ") ?? "";
                characterTagController.text = preset.tags!["character"]?.join(" ") ?? "";
                copyrightTagController.text = preset.tags!["copyright"]?.join(" ") ?? "";
                speciesTagController.text = preset.tags!["species"]?.join(" ") ?? "";
            }
        }
    }

    @override
    void dispose() {
        super.dispose();

        tagController.dispose();
        artistTagController.dispose();
        characterTagController.dispose();
        copyrightTagController.dispose();
        speciesTagController.dispose();
    }

    void sendPreset() async {
        final validation = _formKey.currentState!.validate();
        widget.onChanged(PresetImage(
            image: File(loadedImage),
            tags: {
                "generic": tagController.text.split(" ").where((e) => e.isNotEmpty).toList(),
                "artist": artistTagController.text.split(" ").where((e) => e.isNotEmpty).toList(),
                "character": characterTagController.text.split(" ").where((e) => e.isNotEmpty).toList(),
                "copyright": copyrightTagController.text.split(" ").where((e) => e.isNotEmpty).toList(),
                "species": speciesTagController.text.split(" ").where((e) => e.isNotEmpty).toList()
            },
            sources: urlList,
            rating: rating,
            replaceID: widget.preset?.replaceID,
            relatedImages: relatedImages,
            key: widget.preset?.key,
            note: widget.preset?.note
        ));
        if(widget.onErrorUpdate != null) widget.onErrorUpdate!(!validation);
    }

    void fetchTags() async {
        final prefs = await SharedPreferences.getInstance();
        setState(() => isGeneratingTags = true);
        autoTag(File(loadedImage)).then((tags) async {
            final moreAccurateTags = filterAccurateResults(tags, prefs.getDouble("autotag_accuracy") ?? settingsDefaults["autotag_accuracy"]);

            final separatedTags = await (await getCurrentBooru()).separateTagsByType(moreAccurateTags.keys.toList());

            if(separatedTags["generic"] != null) tagController.text = [tagController.text, ...separatedTags["generic"]!].where((e) => e.isNotEmpty).join(" ");
            if(separatedTags["artist"] != null) artistTagController.text = [artistTagController.text, ...separatedTags["artist"]!].where((e) => e.isNotEmpty).join(" ");
            if(separatedTags["character"] != null) characterTagController.text = [characterTagController.text, ...separatedTags["character"]!].where((e) => e.isNotEmpty).join(" ");
            if(separatedTags["copyright"] != null) copyrightTagController.text = [copyrightTagController.text, ...separatedTags["copyright"]!].where((e) => e.isNotEmpty).join(" ");
            if(separatedTags["species"] != null) speciesTagController.text = [speciesTagController.text, ...separatedTags["species"]!].where((e) => e.isNotEmpty).join(" ");
        }).catchError((error, stackTrace) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Could not obtain tag information, ${error.toString()}'),
            ));
            throw error;
        }).whenComplete(() {
            setState(() => isGeneratingTags = false);
        });
    }

    String? validateTagTexts(String? value, String type) {
        if(value == null || value.isNotEmpty) {
            final splitValue = value?.split(" ") ?? [];
            // check for overlaps
            List hasOverlap = [false, ""];

            if(type != "generic" && !hasOverlap[0]) hasOverlap = [tagController.text.split(" ").toSet().intersection(splitValue.toSet()).isNotEmpty, "generic"];
            if(type != "artist" && !hasOverlap[0]) hasOverlap = [artistTagController.text.split(" ").toSet().intersection(splitValue.toSet()).isNotEmpty, "artist"];
            if(type != "character" && !hasOverlap[0]) hasOverlap = [characterTagController.text.split(" ").toSet().intersection(splitValue.toSet()).isNotEmpty, "character"];
            if(type != "copyright" && !hasOverlap[0]) hasOverlap = [copyrightTagController.text.split(" ").toSet().intersection(splitValue.toSet()).isNotEmpty, "copyright"];
            if(type != "species" && !hasOverlap[0]) hasOverlap = [speciesTagController.text.split(" ").toSet().intersection(splitValue.toSet()).isNotEmpty, "species"];
            
            if(hasOverlap[0]) return "Overlapping tags exists with the ${hasOverlap[1]} field";
            
            //check for metatags
            for(final tag in splitValue) {
                if(Metatag.isMetatag(tag)) return "Metatags cannot be added";
            }
        }

        // check if it is empty
        if([tagController, artistTagController, characterTagController, copyrightTagController, speciesTagController]
            .every((controller) => controller.text.isEmpty)) return "Please insert a tag";

        return null;
    }

    @override
    Widget build(BuildContext context) {
        return OrientationBuilder(
            builder: (context, orientation) => Form(
                key: _formKey,
                child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                        ImageUploadForm(
                            onChanged: (value) {
                                setState(() => loadedImage = value.first.path!);
                                sendPreset();
                                if(value.length > 1 && widget.onMultipleImagesAdded != null) widget.onMultipleImagesAdded!(value..removeAt(0));
                            },
                            onCompressed: (value) {
                                setState(() => loadedImage = value);
                                sendPreset();
                            },
                            validator: (value) {
                                if (value == null || value.isEmpty) return 'Please select an image';
                                return null;
                            },
                            currentValue: loadedImage,
                            orientation: orientation,
                        ),
                        const SizedBox(height: 16,),
                        Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                                const SmallHeader("Tags", padding: EdgeInsets.zero),
                                TextButton(
                                    onPressed: (loadedImage.isEmpty || isGeneratingTags) ? null : fetchTags, 
                                    child: Wrap(
                                        spacing: 8,
                                        children: [
                                            const Icon(CupertinoIcons.sparkles),
                                            isGeneratingTags ? const Text("Generating...") : const Text("Generate tags")
                                        ],
                                    )
                                )
                            ],
                        ),
                        TagField(
                            controller: tagController,
                            decoration: const InputDecoration(
                                labelText: "General",
                            ),
                            style: const TextStyle(color: SpecificTagsColors.generic),
                            validator: (value) => validateTagTexts(value, "generic"),
                            onChanged: (_) => sendPreset()
                        ),
                        TagField(
                            controller: artistTagController,
                            decoration: const InputDecoration(
                                labelText: "Artist(s)"
                            ),
                            type: "artist",
                            style: const TextStyle(color: SpecificTagsColors.artist),
                            validator: (value) => validateTagTexts(value, "artist"),
                            onChanged: (_) => sendPreset()
                        ),
                        TagField(
                            controller: characterTagController,
                            decoration: const InputDecoration(
                                labelText: "Character(s)"
                            ),
                            type: "character",
                            style: const TextStyle(color: SpecificTagsColors.character),
                            validator: (value) => validateTagTexts(value, "character"),
                            onChanged: (_) => sendPreset()
                        ),
                        TagField(
                            controller: copyrightTagController,
                            decoration: const InputDecoration(
                                labelText: "Copyright"
                            ),
                            type: "copyright",
                            style: const TextStyle(color: SpecificTagsColors.copyright),
                            validator: (value) => validateTagTexts(value, "copyright"),
                            onChanged: (_) => sendPreset()
                        ),
                        TagField(
                            controller: speciesTagController,
                            decoration: const InputDecoration(
                                labelText: "Species"
                            ),
                            type: "species",
                            style: const TextStyle(color: SpecificTagsColors.species),
                            validator: (value) => validateTagTexts(value, "species"),
                            onChanged: (_) => sendPreset()
                        ),
                        
                        const SmallHeader("Rating", padding: EdgeInsets.only(top: 16.0)),
                        ListTile(
                            leading: Icon(getRatingIcon(rating)),
                            title: Text(getRatingText(rating)),
                            onTap: () async {
                                final choosenRating = await showDialog(
                                    context: context,
                                    builder: (_) => RatingChooserDialog(selected: rating, hasNull: true,)
                                );
                                if(choosenRating == null) return;
                                else if(choosenRating == "None") setState(() => rating = null);
                                else setState(() => rating = choosenRating);
                                debugPrint("from Rating");
                                sendPreset();
                            },
                        ),
            
                        const SmallHeader("Sources", padding: EdgeInsets.only(top: 16.0),),
                        ListStringTextInput(
                            addButton: const Text("Add source"),
                            onChanged: (list) {
                                setState(() => urlList = list);
                                sendPreset();
                            },
                            canBeEmpty: true,
                            defaultValue: urlList,
                            formValidator: (value) {
                                if(value == null || value.isEmpty) return "Please either remove the URL or fill this field";
                                return null;
                            },
                        ),
                        if(widget.showRelatedImagesCard) ...[
                            const SmallHeader("Related images", padding: EdgeInsets.only(top: 16.0, bottom: 8)),
                            RelatedImagesCard(
                                showBlockWarning: !widget.showRelatedImagesCard,
                                relatedImages: relatedImages,
                                onRemove: (imageID) {
                                    setState(() => relatedImages.remove(imageID));
                                    debugPrint("from RelatedImagesCard");
                                    sendPreset();
                                },
                                onAddButtonPress: () async {
                                    final imageList = await openSelectionDialog(
                                        context: context,
                                        selectedImages: relatedImages,
                                        excludeImages: widget.preset?.replaceID != null ? [widget.preset!.replaceID!] : null
                                    );
                                    if(imageList == null) return;
                                    setState(() {
                                        relatedImages = imageList;
                                    });
                                    sendPreset();
                                },
                            )
                        ]
                    ],
                ),
            )
        );
    }
}