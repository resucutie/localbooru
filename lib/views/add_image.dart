import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/header.dart';
import 'package:localbooru/components/window_frame.dart';

class AddImageView extends StatefulWidget {
    const AddImageView({super.key});

    @override
    State<AddImageView> createState() => _AddImageViewState();
}

class _AddImageViewState extends State<AddImageView> {
    final _formKey = GlobalKey<FormState>();

    final tagController = TextEditingController();

    List<String> urlList = [];
    String image = "";

    void _submit() {
        debugPrint("$urlList");
        addImage(
            imageFile: File(image),
            tags: tagController.text,
            sources: urlList
        );
        context.pop();
        context.push("/recent");
    }

    @override
    void dispose() {
        super.dispose();
        tagController.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: WindowFrameAppBar(
                title: "Add image",
                appBar: AppBar(
                    title: const Text("Add an image"),
                    actions: [
                        IconButton(
                            icon: const Icon(Icons.done),
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
                            onChanged: (value) => setState(() => image = value),
                            validator: (value) {
                                if (value == null || value.isEmpty) return 'Please select an image';
                                return null;
                            },
                        ),
                        TextFormField(
                            controller: tagController,
                            decoration: const InputDecoration(
                                labelText: "Tags (very lame way of putting tags yea)"
                            ),
                            validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter tags';
                                return null;
                            },
                        ),
                        const Header("Sources"),
                        ListStringTextInput(
                            onChanged: (list) => setState(() => urlList = list),
                            canBeEmpty: true,
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
    ImageUploadForm({super.key, required this.onChanged, required this.validator, this.currentValue = ""});
    
    ValueChanged<String> onChanged;
    FormFieldValidator<String> validator;
    String currentValue = "";
    
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
                                color: Theme.of(context).colorScheme.primary,
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
                                            };
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
                        if(!state.value.isEmpty) Text(state.value),
                        if(state.hasError) Text(state.errorText!)
                    ],
                );
            },
        );
    }
}

class ListStringTextInput extends StatefulWidget {
    ListStringTextInput({super.key, required this.onChanged, this.defaultValue = const [], this.canBeEmpty = false, this.formValidator});

    Function(List<String>) onChanged;
    List<String> defaultValue;
    FormFieldValidator<String>? formValidator;
    bool canBeEmpty;

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
            // mainAxisAlignment: MainAxisAlignment.start,
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
                FilledButton(onPressed: () async {
                    setState(() => _currentValue.add(""));
                    _updateList();
                    Future.delayed(const Duration(milliseconds: 10), () => _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.fastOutSlowIn,
                    ));
                }, child: const Text("Add"))
            ],
        );
    }
}