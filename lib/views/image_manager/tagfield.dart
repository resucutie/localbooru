import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localbooru/api/index.dart';

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