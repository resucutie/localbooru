import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/views/image_manager.dart';

class TagTypesSettings extends StatefulWidget {
    const TagTypesSettings({super.key, required this.booru});

    final Booru booru;

    @override
    State<TagTypesSettings> createState() => _TagTypesSettingsState();
}

class _TagTypesSettingsState extends State<TagTypesSettings> {
    final _formKey = GlobalKey<FormState>();

    final artistTagController = TextEditingController();
    final characterTagController = TextEditingController();
    final copyrightTagController = TextEditingController();
    final speciesTagController = TextEditingController();

    @override
    void initState() {
        super.initState();
        void asyncFunc() async {
            final separatedTags = await (await widget.booru.getRawInfo())["specificTags"];
            debugPrint(separatedTags.toString());
            artistTagController.text = separatedTags["artist"]?.join(" ") ?? "";
            characterTagController.text = separatedTags["character"]?.join(" ") ?? "";
            copyrightTagController.text = separatedTags["copyright"]?.join(" ") ?? "";
            speciesTagController.text = separatedTags["species"]?.join(" ") ?? "";
        }
        asyncFunc();
    }

    String? validateTagTexts(String? value, String type) {
        if(value == null || value.isNotEmpty) {
            // check for overlaps
            List hasOverlap = [false, ""];

            if(type != "artist" && !hasOverlap[0]) hasOverlap = [artistTagController.text.split(" ").toSet().intersection((value?.split(" ") ?? []).toSet()).isNotEmpty, "artist"];
            if(type != "character" && !hasOverlap[0]) hasOverlap = [characterTagController.text.split(" ").toSet().intersection((value?.split(" ") ?? []).toSet()).isNotEmpty, "character"];
            if(type != "copyright" && !hasOverlap[0]) hasOverlap = [copyrightTagController.text.split(" ").toSet().intersection((value?.split(" ") ?? []).toSet()).isNotEmpty, "copyright"];
            if(type != "species" && !hasOverlap[0]) hasOverlap = [speciesTagController.text.split(" ").toSet().intersection((value?.split(" ") ?? []).toSet()).isNotEmpty, "species"];
            
            if(hasOverlap[0]) return "Overlapping tags exists with the ${hasOverlap[1]} field";
        }

        return null;
    }

    @override
    Widget build(BuildContext context) {
        return Form(
            key: _formKey,
            child: ListView(
                children: [
                    const ListTile(
                        subtitle: Text("This is where you'll set the tag types for the tags that you want to set or change the types of tags that already exist or not\nYou can add one by typing its name on the respective field, the same way as how you would set a tag. If you want to mark it as generic, remove it"),
                    ),
                    Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        child: Column(
                            children: [
                                TagField(
                                    controller: artistTagController,
                                    decoration: const InputDecoration(
                                        labelText: "Artist(s)"
                                    ),
                                    type: "generic",
                                    validator: (value) => validateTagTexts(value, "artist"),
                                    style: const TextStyle(color: SpecificTagsColors.artist),
                                ),
                                TagField(
                                    controller: characterTagController,
                                    decoration: const InputDecoration(
                                        labelText: "Character(s)"
                                    ),
                                    type: "generic",
                                    validator: (value) => validateTagTexts(value, "character"),
                                    style: const TextStyle(color: SpecificTagsColors.character),
                                ),
                                TagField(
                                    controller: copyrightTagController,
                                    decoration: const InputDecoration(
                                        labelText: "Copyright"
                                    ),
                                    type: "generic",
                                    validator: (value) => validateTagTexts(value, "copyright"),
                                    style: const TextStyle(color: SpecificTagsColors.copyright),
                                ),
                                TagField(
                                    controller: speciesTagController,
                                    decoration: const InputDecoration(
                                        labelText: "Species"
                                    ),
                                    type: "generic",
                                    validator: (value) => validateTagTexts(value, "species"),
                                    style: const TextStyle(color: SpecificTagsColors.species),
                                ),
                            ]
                        ),
                    ),
                    ListTile(
                        title: const Text("Save changes"),
                        leading: const Icon(Icons.save),
                        onTap: () {
                            if(_formKey.currentState!.validate()) {
                                writeSpecificTags({
                                    "artist": artistTagController.text.split(" "),
                                    "character": characterTagController.text.split(" "),
                                    "copyright": copyrightTagController.text.split(" "),
                                    "species": speciesTagController.text.split(" "),
                                });
                                if(context.canPop()) context.pop();
                            }
                        }, 
                    ),
                ],
            )
        );
    }
}