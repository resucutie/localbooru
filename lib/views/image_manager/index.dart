import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/fileinfo.dart';
import 'package:localbooru/components/headers.dart';
import 'package:localbooru/components/window_frame.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/tags.dart';
import 'package:localbooru/views/image_manager/preset_api.dart';
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

    bool isEditing = false;
    bool isGeneratingTags = false;

    List<String> urlList = [];
    String loadedImage = "";

    @override
    void initState() {
        super.initState();
        isEditing = widget.preset?.replaceID != null;

        
        if(widget.preset != null) {
            final preset = widget.preset!;
            if(preset.image != null) loadedImage = preset.image!.path;
            if(preset.sources != null) urlList = preset.sources!;

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
        final List<String> genericTags = tagController.text.split(" ");
        final List<String> artistTags = artistTagController.text.split(" ");
        final List<String> characterTags = characterTagController.text.split(" ");
        final List<String> copyrightTags = copyrightTagController.text.split(" ");
        final List<String> speciesTags = speciesTagController.text.split(" ");
        final allTags = <String>[
            ...genericTags,
            ...artistTags,
            ...characterTags,
            ...copyrightTags,
            ...speciesTags,
        ].where((e) => e.isNotEmpty).toList();

        debugPrint(allTags.toString(), wrapWidth: 9999);

        await addImage(
            imageFile: File(loadedImage),
            tags: allTags.join(" "),
            sources: urlList,
            id: widget.preset?.replaceID
        );
        await addSpecificTags(artistTags, type: "artist");
        await addSpecificTags(characterTags, type: "character");
        await addSpecificTags(copyrightTags, type: "copyright");
        await addSpecificTags(speciesTags, type: "species");

        final Booru booru = await getCurrentBooru();
        await writeSettings(booru.path, await booru.rebaseRaw());

        if(context.mounted) {
            context.pop();
            if(!widget.shouldOpenRecents) context.push("/recent");
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
            // check for overlaps
            List hasOverlap = [false, ""];

            if(type != "generic" && !hasOverlap[0]) hasOverlap = [tagController.text.split(" ").toSet().intersection((value?.split(" ") ?? []).toSet()).isNotEmpty, "generic"];
            if(type != "artist" && !hasOverlap[0]) hasOverlap = [artistTagController.text.split(" ").toSet().intersection((value?.split(" ") ?? []).toSet()).isNotEmpty, "artist"];
            if(type != "character" && !hasOverlap[0]) hasOverlap = [characterTagController.text.split(" ").toSet().intersection((value?.split(" ") ?? []).toSet()).isNotEmpty, "character"];
            if(type != "copyright" && !hasOverlap[0]) hasOverlap = [copyrightTagController.text.split(" ").toSet().intersection((value?.split(" ") ?? []).toSet()).isNotEmpty, "copyright"];
            if(type != "species" && !hasOverlap[0]) hasOverlap = [speciesTagController.text.split(" ").toSet().intersection((value?.split(" ") ?? []).toSet()).isNotEmpty, "species"];
            
            if(hasOverlap[0]) return "Overlapping tags exists with the ${hasOverlap[1]} field";
        }

        // check if it is empty
        if([tagController, artistTagController, characterTagController, copyrightTagController, speciesTagController]
            .every((controller) => controller.text.isEmpty)) return "Please insert a tag";

        return null;
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: WindowFrameAppBar(
                title: "Image manager",
                appBar: AppBar(
                    title: Text("${isEditing ? "Edit" : "Add"} image"),
                    actions: [
                        TextButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text("Done"),
                            onPressed: () {
                                if(_formKey.currentState!.validate()) _submit();
                            }
                        )
                    ],
                ),
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
                        ),
                        const SizedBox(height: 16,),
                        Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                                const Header("Tags", padding: EdgeInsets.zero),
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
                        const Header("Sources"),
                        ListStringTextInput(
                            addButton: const Text("Add source"),
                            onChanged: (list) => setState(() => urlList = list),
                            canBeEmpty: true,
                            defaultValue: urlList,
                            formValidator: (value) {
                                if(value == null || value.isEmpty) return "Please either remove the URL or fill this field";
                                return null;
                            },
                        )
                    ],
                ),
            )
        );
    }
}

class ImageUploadForm extends StatelessWidget {
    const ImageUploadForm({super.key, required this.onChanged, required this.validator, this.currentValue = ""});
    
    final ValueChanged<String> onChanged;
    final FormFieldValidator<String> validator;
    final String currentValue;
    
    @override
    Widget build(BuildContext context) {
        return FormField<String>(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            initialValue: currentValue,
            validator: validator,
            builder: (FormFieldState state) {
                return Column(
                    children: [
                        Container(
                            constraints: const BoxConstraints(maxHeight: 400),
                            child: DottedBorder(
                                strokeWidth: 2,
                                borderType: BorderType.RRect,
                                radius: const Radius.circular(24),
                                color: state.hasError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                                child: ClipRRect(borderRadius: const BorderRadius.all(Radius.circular(22)),
                                    child: TextButton(
                                        style: TextButton.styleFrom(
                                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero,),
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(100, 100),
                                        ),
                                        onPressed: () async {
                                            FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.media);
                                            if (result != null) {
                                                state.didChange(result.files.single.path);
                                                onChanged(result.files.single.path!);
                                            }
                                        },
                                        child: Builder(builder: (context) {
                                            if(state.value.isEmpty) {
                                                return const Icon(Icons.add);
                                            } else {
                                                return Image.file(File(state.value));
                                            }
                                        },),
                                    ),
                                )
                            ),
                        ),
                        if(!state.value.isEmpty) Padding(
                            padding: const EdgeInsets.all(8),
                            child: FileInfo(File(state.value),
                                onCompressed: (compressed) {
                                    state.didChange(compressed.path);
                                    onChanged(compressed.path);
                                }
                            )
                        ),
                        if(state.hasError) Text(state.errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error),)
                    ],
                );
            },
        );
    }
}

class TagField extends StatefulWidget {
    const TagField({super.key, this.controller,  this.decoration, this.validator, this.style, this.type = "generic"});

    final TextEditingController? controller;
    final InputDecoration? decoration;
    final FormFieldValidator<String>? validator;
    final TextStyle? style;
    final String type;

    @override
    State<TagField> createState() => _TagFieldState();
}
class _TagFieldState extends State<TagField> {
    final FocusNode _focusNode = FocusNode();
    late TextEditingController controller;
    GlobalKey textboxKey = GlobalKey();

    @override
    void initState() {
        super.initState();
        controller = widget.controller ?? TextEditingController();
    }

    bool spawnAtBottom() {
        if(textboxKey.currentContext == null) return true;
        RenderBox textboxRenderBox = textboxKey.currentContext!.findRenderObject() as RenderBox;
        double textboxPosY = textboxRenderBox.localToGlobal(Offset.zero).dy;
        return textboxPosY <= (MediaQuery.of(context).size.height / 2);
    }

    @override
    Widget build(context) {
        return RawAutocomplete<String>(
            textEditingController: controller,
            focusNode: _focusNode,
            optionsBuilder: (textEditingValue) async {
                if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                } else {
                    List<String> tagList = textEditingValue.text.split(" ");
                    List<String> restOfList = List.from(tagList);
                    restOfList.removeLast();
                    String tag = tagList.last;

                    Booru currentBooru = await getCurrentBooru();
                    List<String> allTags = await currentBooru.getAllTagsFromType(widget.type);

                    List<String> matches = List.from(allTags);

                    matches.retainWhere((s){
                        return s.contains(tag) && !restOfList.contains(s) && s != tag;
                    });
                    return matches.map((e) => restOfList.isEmpty ? e : "${restOfList.join(" ")} $e").toList();
                }
            },
            optionsViewBuilder: (context, onSelected, options) {
                int highlightedIndex = AutocompleteHighlightedOption.of(context);
                return Align(
                    alignment: spawnAtBottom() ? Alignment.topCenter : Alignment.bottomCenter,
                    child: Material(
                        elevation: 4.0,
                        child: Container(
                            constraints: const BoxConstraints(maxHeight: 300),
                            alignment: Alignment.bottomCenter,
                            child: ListView.builder(
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                    final currentOption = options.elementAt(index);
                                    return ListTile(
                                        title: Text(currentOption.split(" ").last),
                                        onTap: () => onSelected(currentOption),
                                        selected: highlightedIndex == index,
                                        selectedColor: widget.style?.color,
                                        selectedTileColor: widget.style?.color?.withOpacity(0.1),
                                    );
                                },
                            ),
                        )
                    ),
                );
            },
            optionsViewOpenDirection: spawnAtBottom() ? OptionsViewOpenDirection.down : OptionsViewOpenDirection.up,
            fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                return TextFormField(
                    key: textboxKey,
                    controller: textController,
                    focusNode: focusNode,
                    decoration: widget.decoration,
                    keyboardType: TextInputType.text,
                    minLines: 1,
                    maxLines: 6,
                    inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\n')),],
                    validator: widget.validator,
                    style: widget.style,
                    onFieldSubmitted: (value) {
                        debugPrint(value);
                        onFieldSubmitted();
                    },
                );
            },
        );
    }
}

class ListStringTextInput extends StatefulWidget {
    const ListStringTextInput({super.key, required this.onChanged, this.defaultValue = const [], this.canBeEmpty = false, this.formValidator, this.addButton = const Text("Add")});

    final Function(List<String>) onChanged;
    final List<String> defaultValue;
    final FormFieldValidator<String>? formValidator;
    final bool canBeEmpty;
    final Widget addButton;

    @override
    State<ListStringTextInput> createState() => _ListStringTextInputState();
}
class _ListStringTextInputState extends State<ListStringTextInput> {
    List<String> _currentValue = [];
    List<TextEditingController> _editControllers = [];

    final ScrollController _scrollController = ScrollController();

    @override
    void initState() {
        super.initState();
        _currentValue = List.from(widget.defaultValue); //attempt at making list changable
        Future.delayed(const Duration(milliseconds: 1), _updateList);
    }

    void _updateList() {
        for (final (index, textController) in _editControllers.indexed) {
            textController.text = _currentValue[index];
        }
        widget.onChanged(_currentValue);
    }

    @override
    Widget build(BuildContext context) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: Scrollbar(
                        thumbVisibility: true,
                        controller: _scrollController,
                        child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _currentValue.length,
                            controller: _scrollController,
                            itemBuilder: (BuildContext context, index) {
                                if((_editControllers.length - 1) < index) _editControllers.add(TextEditingController());

                                final controller = _editControllers[index];

                                return TextFormField(
                                    controller: controller,
                                    decoration: (widget.canBeEmpty || index != 0) ? InputDecoration(suffixIcon: IconButton(onPressed: () => setState(() {
                                        controller.dispose();
                                        _currentValue.removeAt(index);
                                        _editControllers.removeAt(index);
                                        _updateList();
                                    }), icon: const Icon(Icons.remove))) : null,
                                    validator: widget.formValidator,
                                    onChanged: (value) {
                                        setState(() => _currentValue[index] = value);
                                        _updateList();
                                    },
                                    
                                );
                            }
                        ),
                    )
                ),
                const SizedBox(height: 16),
                ListTile(
                    title: widget.addButton,
                    leading: const Icon(Icons.add),
                    onTap: () async {
                        setState(() => _currentValue.add(""));
                        _updateList();
                        Future.delayed(const Duration(milliseconds: 10), () => _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.fastOutSlowIn,
                        ));
                    }, 
                )
            ],
        );
    }
}