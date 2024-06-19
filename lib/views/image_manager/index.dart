import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/app_bar_linear_progress.dart';
import 'package:localbooru/components/dialogs/image_selector_dialog.dart';
import 'package:localbooru/components/headers.dart';
import 'package:localbooru/components/dialogs/radio_dialogs.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/views/image_manager/image_upload.dart';
import 'package:localbooru/views/image_manager/list_string_text_input.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/views/image_manager/related_images.dart';
import 'package:localbooru/views/image_manager/tagfield.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImageManagerView extends StatefulWidget {
    const ImageManagerView({super.key, this.preset, this.shouldOpenRecents = false});

    final PresetImage? preset;
    final bool shouldOpenRecents;

    @override
    State<ImageManagerView> createState() => _ImageManagerViewState();
}

class _ImageManagerViewState extends State<ImageManagerView> {
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

    void _submit() async {
        await addImage(PresetImage(
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
            relatedImages: relatedImages
        ));

        if(context.mounted) {
            context.pop();
            if(true) context.push("/recent");
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
                if(TagText(tag).isMetatag()) return "Metatags cannot be added";
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
            builder: (context, orientation) => Scaffold(
                appBar: AppBar(
                    title: Text("${isEditing ? "Edit" : "Add"} image"),
                    actions: [
                        TextButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text("Done"),
                            onPressed: !isSaving ? () {
                                if(_formKey.currentState!.validate()) {
                                    setState(() {
                                        isSaving = true;
                                    });
                                    _submit();
                                };
                            } : null
                        ),
                    ],
                    bottom: isSaving ? AppBarLinearProgressIndicator() : null,
                ),
                body: Form(
                    key: _formKey,
                    child: ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                            ImageUploadForm(
                                onChanged: (value) => setState(() => loadedImage = value),
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
                            ),
                            TagField(
                                controller: artistTagController,
                                decoration: const InputDecoration(
                                    labelText: "Artist(s)"
                                ),
                                type: "artist",
                                validator: (value) => validateTagTexts(value, "artist"),
                                style: const TextStyle(color: SpecificTagsColors.artist),
                            ),
                            TagField(
                                controller: characterTagController,
                                decoration: const InputDecoration(
                                    labelText: "Character(s)"
                                ),
                                type: "character",
                                validator: (value) => validateTagTexts(value, "character"),
                                style: const TextStyle(color: SpecificTagsColors.character),
                            ),
                            TagField(
                                controller: copyrightTagController,
                                decoration: const InputDecoration(
                                    labelText: "Copyright"
                                ),
                                type: "copyright",
                                validator: (value) => validateTagTexts(value, "copyright"),
                                style: const TextStyle(color: SpecificTagsColors.copyright),
                            ),
                            TagField(
                                controller: speciesTagController,
                                decoration: const InputDecoration(
                                    labelText: "Species"
                                ),
                                type: "species",
                                validator: (value) => validateTagTexts(value, "species"),
                                style: const TextStyle(color: SpecificTagsColors.species),
                            ),
                            
                            const SmallHeader("Rating", padding: EdgeInsets.only(top: 16.0)),
                            ListTile(
                                leading: Icon(getRatingIcon(rating)),
                                title: Text(switch(rating) {
                                    Rating.safe => "Safe",
                                    Rating.questionable => "Questionable",
                                    Rating.explicit => "Explicit",
                                    Rating.illegal => "Illegal",
                                    _ => "None"
                                }),
                                onTap: () async {
                                    final choosenRating = await showDialog(
                                        context: context,
                                        builder: (_) => RatingChooserDialog(selected: rating, hasNull: true,)
                                    );
                                    if(choosenRating == null) return;
                                    else if(choosenRating == "None") setState(() => rating = null);
                                    else setState(() => rating = choosenRating);
                                },
                            ),
            
                            const SmallHeader("Sources", padding: EdgeInsets.only(top: 16.0),),
                            ListStringTextInput(
                                addButton: const Text("Add source"),
                                onChanged: (list) => setState(() => urlList = list),
                                canBeEmpty: true,
                                defaultValue: urlList,
                                formValidator: (value) {
                                    if(value == null || value.isEmpty) return "Please either remove the URL or fill this field";
                                    return null;
                                },
                            ),

                            const SmallHeader("Related images", padding: EdgeInsets.only(top: 16.0, bottom: 8)),
                            RelatedImagesCard(
                                relatedImages: relatedImages,
                                onRemove: (imageID) => setState(() => relatedImages.remove(imageID)),
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
                                },
                            )
                        ],
                    ),
                )
            ),
        );
    }
}