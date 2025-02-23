import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/api/tags/index.dart';
import 'package:localbooru/utils/constants.dart';

class SearchTagBox extends StatefulWidget {
    const SearchTagBox({super.key, this.hint, required this.onSearch, this.controller, this.isFullScreen, this.actions, this.showShadow = false, this.leading = const Icon(Icons.search), this.padding = const EdgeInsets.only(left: 16.0, right: 10.0), this.backgroundColor, this.elevation});

    final String? hint;
    final Function(String value) onSearch;
    final SearchTagController? controller;
    final bool? isFullScreen;
    final List<Widget>? actions;
    final bool showShadow;
    final Widget? leading;
    final EdgeInsetsGeometry? padding;
    final Color? backgroundColor;
    final double? elevation;

    @override
    State<SearchTagBox> createState() => _SearchTagBoxState();
}

class _SearchTagBoxState extends State<SearchTagBox> {
    SearchTagController _controller = SearchTagController();

    @override
    void initState() {
        super.initState();

        if(widget.controller != null) _controller = widget.controller!;
    }

    @override
    Widget build(BuildContext context) {
        return SearchAnchor(
            searchController: _controller,
            builder: (context, controller) => SearchBar(
                controller: controller,
                hintText: widget.hint,
                padding: WidgetStatePropertyAll(widget.padding),
                onSubmitted: widget.onSearch,
                onTap: controller.openView,
                onChanged: (_) => controller.openView(),
                leading: widget.leading,
                trailing: [
                    // if(controller.text.isNotEmpty) IconButton(onPressed: _controller.clear, icon: const Icon(Icons.close)),
                    if(widget.actions == null) SearchButton(controller: controller, onSearch: widget.onSearch, icon: const Icon(Icons.arrow_forward),)
                    else ...widget.actions!
                ],
                elevation: WidgetStatePropertyAll(widget.elevation),
                shadowColor: widget.showShadow ? null : const WidgetStatePropertyAll(Colors.transparent),
                backgroundColor: WidgetStatePropertyAll<Color?>(widget.backgroundColor),
            ),
            suggestionsBuilder: (context, controller) async {
                Booru booru = await getCurrentBooru();
                List<String> tags = await booru.getAllTags();
                final currentTags = List<String>.from(controller.text.split(" "));

                final filteredTags = List<String>.from(tags)..addAll(tagsToAddToSearch)..retainWhere((s){
                    if((List<String>.from(currentTags)..removeLast()).contains(s)) return false;
                    if(currentTags.last.isEmpty) return true;
                    final nomModifierLastTagInserted = SearchTag.obtainModifier(currentTags.last) == Modifier.filterModifier ? currentTags.last : currentTags.last.substring(1);
                    return s.contains(nomModifierLastTagInserted);
                });

                final specialTags = await booru.separateTagsByType(filteredTags);

                return specialTags.entries.map((type) => type.value.map((tag) {
                    final isMetatag = tag.contains(":") && tag.split(":").first.isNotEmpty;
                    final color = !isMetatag ? SpecificTagsColors.getColor(type.key) : null;
                    return ListTile(
                        leading: Icon(!isMetatag ? SpecificTagsIcons.getIcon(type.key) : Icons.lightbulb, color: color,),
                        title: Text(tag,
                            style: TextStyle(
                                color: color,
                                fontWeight: isMetatag ? FontWeight.bold : null
                            ),
                        ),
                        onTap: () {
                            List endResult = List.from(currentTags);
                            endResult.removeLast();
                            endResult.add(tag);
                            setState(() {
                                if(isMetatag) controller.text = endResult.join(" ");
                                else controller.text = "${endResult.join(" ")} ";
                            });
                        },
                    );
                })).expand((i) => i);
            },
            viewTrailing: [
                IconButton(onPressed: _controller.clear, icon: const Icon(Icons.close)),
                SearchButton(controller: _controller, onSearch: widget.onSearch)
            ],
            isFullScreen: widget.isFullScreen,
        );
    }
}
final List<String> tagsToAddToSearch = [
    "rating:none",
    "rating:safe",
    "rating:questionable",
    "rating:explicit",
    "rating:borderline",
    "id:",
    "file:",
    "type:",
    "type:static",
    "type:animated",
    "source:",
    "source:none",
];

class SearchButton extends StatelessWidget {
    const SearchButton({super.key, required this.controller, this.onSearch, this.icon = const Icon(Icons.search)});

    final SearchController controller;
    final Widget icon;
    final Function(String)? onSearch;
    
    @override
    Widget build(context) {
        return IconButton(
            icon: icon,
            onPressed: onSearch != null ? () => onSearch!(controller.text) : null,
        );
    }
}

class SearchTagController extends SearchController {
    // I copied some of the code straight from Flutter's implementation of buildTextSpan due to composing
    @override
    TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
        assert(!value.composing.isValid || !withComposing || value.isComposingRangeValid);
        final bool composingRegionOutOfRange = !value.isComposingRangeValid || !withComposing;

        final searchTags = text.split(" ").map((e) => SearchTag.fromText(e),).toList();

        int wordIndex = 0;
        final textSpans = searchTags.map((e) {
            final TextStyle? styleWithModifier = style?.merge(TextStyle(color: SearchTag.modifierColors[e.modifier]));
            final text = e.getTextRepresentation();

            final bool isWordWithinComposingRange = !composingRegionOutOfRange
                && (wordIndex + text.length) > value.composing.start
                && wordIndex < value.composing.end;

            if(isWordWithinComposingRange) {
                final composingAdjusted = TextRange(start: value.composing.start - wordIndex, end: value.composing.end - wordIndex);
                wordIndex += text.length + 1;
                return TextSpan(
                    style: styleWithModifier,
                    children: <TextSpan>[
                        TextSpan(text: composingAdjusted.textBefore(text)),
                        TextSpan(
                            style: getComposingStyle(styleWithModifier),
                            text: composingAdjusted.textInside(text),
                        ),
                        TextSpan(text: composingAdjusted.textAfter(text)),
                    ],
                );
            }
            wordIndex += text.length + 1;
            return TextSpan(
                style: styleWithModifier,
                text: text
            );
        },).expandIndexed((index, e) {
            final bool hasSpaceOnLast = value.text.endsWith(" ");
            if(!hasSpaceOnLast && index == searchTags.length) {
                return [e];
            }
            return [e, TextSpan(text: " ")];
        }).toList();

        return TextSpan(style: style, children: textSpans);
    }

    TextStyle getComposingStyle(TextStyle? style) => style?.merge(const TextStyle(decoration: TextDecoration.underline)) ?? const TextStyle(decoration: TextDecoration.underline);
}