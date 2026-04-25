import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/api/tags/index.dart';

class TagField extends StatefulWidget {
    const TagField({super.key, this.controller,  this.decoration, this.validator, this.style, this.type = "generic", this.onChanged});

    final TextEditingController? controller;
    final InputDecoration? decoration;
    final FormFieldValidator<String>? validator;
    final void Function(String)? onChanged;
    final TextStyle? style;
    final String type;

    @override
    State<TagField> createState() => _TagFieldState();
}
class _TagFieldState extends State<TagField> {
    final FocusNode _focusNode = FocusNode();
    late TextEditingController controller;
    GlobalKey textboxKey = GlobalKey();
    String _lastTypedText = "";

    List<BooruTagCounterDisplay<NormalTag>> allTags = [];

    @override
    void initState() {
        super.initState();
        controller = widget.controller ?? TextEditingController();
        _lastTypedText = controller.text;
        cacheTags();
    }

    @override
    void dispose() {
        _focusNode.dispose();
        if(widget.controller == null) controller.dispose();
        super.dispose();
    }

    Future<void> cacheTags() async {
        Booru currentBooru = await getCurrentBooru();
        //todo: change behavior to support BooruTagCounterDisplay
        allTags = await currentBooru.getAllSavedTagsFromType(widget.type);
    }

    bool spawnAtBottom() {
        if(textboxKey.currentContext == null) return true;
        RenderBox textboxRenderBox = textboxKey.currentContext!.findRenderObject() as RenderBox;
        double textboxPosY = textboxRenderBox.localToGlobal(Offset.zero).dy;
        return textboxPosY <= (MediaQuery.of(context).size.height / 2);
    }

    String _buildCompletedText(String selectedTag, [String? sourceText]) {
        final currentText = sourceText ?? controller.text;
        final tagList = currentText.split(" ");
        if(tagList.isEmpty) return "$selectedTag ";

        final restOfList = List<String>.from(tagList)..removeLast();
        final completedTags = [
            ...restOfList.where((tag) => tag.isNotEmpty),
            selectedTag,
        ];
        return "${completedTags.join(" ")} ";
    }

    void _applyAutocompleteOption(BooruTagCounterDisplay<NormalTag> option) {
        final completedText = _buildCompletedText(option.tag.text, _lastTypedText);
        controller.value = TextEditingValue(
            text: completedText,
            selection: TextSelection.collapsed(offset: completedText.length),
        );
        _lastTypedText = completedText;
        widget.onChanged?.call(completedText);
    }

    @override
    Widget build(context) {
        return LayoutBuilder(
            builder: (context, constrains) {
                return RawAutocomplete<BooruTagCounterDisplay<NormalTag>>(
                    textEditingController: controller,
                    focusNode: _focusNode,
                    optionsBuilder: (textEditingValue) async {
                        _lastTypedText = textEditingValue.text;
                        if (textEditingValue.text == '') {
                            return const Iterable<BooruTagCounterDisplay<NormalTag>>.empty();
                        } else {
                            List<String> tagList = textEditingValue.text.split(" ");
                            List<String> restOfList = List.from(tagList);
                            restOfList.removeLast();
                            String tagToSearch = tagList.last;
                
                            if(allTags.isEmpty) await cacheTags();
                
                            List<BooruTagCounterDisplay<NormalTag>> matches = List<BooruTagCounterDisplay<NormalTag>>.from(allTags);
                
                            matches.retainWhere((s){
                                return s.tag.text.contains(tagToSearch) && !restOfList.contains(s.tag.text) && s.tag.text != tagToSearch;
                            });
                            return matches;
                        }
                    },
                    onSelected: _applyAutocompleteOption,
                    optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                            alignment: spawnAtBottom() ? Alignment.topLeft : Alignment.bottomLeft,
                            child: Material(
                                elevation: 4.0,
                                child: ConstrainedBox(
                                    constraints: BoxConstraints(maxHeight: 300, maxWidth: constrains.maxWidth),
                                    child: ListView.builder(
                                        itemCount: options.length,
                                        shrinkWrap: true,
                                        padding: EdgeInsets.zero,
                                        itemBuilder: (context, index) => Builder(
                                            builder: (context) {
                                                final shouldHighlight = AutocompleteHighlightedOption.of(context) == index;
                                                if (shouldHighlight) {
                                                    SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
                                                        Scrollable.ensureVisible(context, alignment: 0.5, duration: Duration(milliseconds: 100));
                                                    });
                                                }
                                                final currentOption = options.elementAt(index);
                                                return ListTile(
                                                    title: Text(currentOption.tag.text),
                                                    onTap: () => onSelected(currentOption),
                                                    selected: shouldHighlight,
                                                    selectedColor: widget.style?.color,
                                                    selectedTileColor: widget.style?.color?.withValues(alpha: 0.1),
                    
                                                    trailing: Text("${currentOption.callQuantity}"),
                                                );
                                            },
                                        ),
                                    ),
                                )
                            ),
                        );
                    },
                    displayStringForOption: (option) => "${option.tag.text} ",
                    optionsViewOpenDirection: spawnAtBottom() ? OptionsViewOpenDirection.down : OptionsViewOpenDirection.up,
                    fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                        return Shortcuts(
                            shortcuts: const <ShortcutActivator, Intent>{
                                SingleActivator(LogicalKeyboardKey.keyC, control: true): CopySelectionTextIntent.copy,
                                SingleActivator(LogicalKeyboardKey.keyV, control: true): PasteTextIntent(SelectionChangedCause.keyboard),
                            },
                            child: TextFormField(
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
                                onChanged: (value) {
                                    _lastTypedText = value;
                                    widget.onChanged?.call(value);
                                },
                            ),
                        );
                    },
                );
            }
        );
    }
}
