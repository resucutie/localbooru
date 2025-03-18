import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/api/tags/index.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/listeners.dart';

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

    Map<String, List<BooruTagCounterDisplay<Tag>>> tagsAndTypes = {};

    @override
    void initState() {
        super.initState();

        if(widget.controller != null) _controller = widget.controller!;

        booruUpdateListener.addListener(cacheTags);
    }

    Future<void> cacheTags() async {
        Booru booru = await getCurrentBooru();
        final Map<String, BooruTagCounterDisplay<Tag>> tags = {}; //transform it in tag for better matching, so we can avoid spamming firstWhere 
        for(final tag in await booru.getAllTags()) {
            tags[tag.tag.text] = tag;
        }


        final categorizedTags = await booru.separateTagsByType(tags.values.map((e) => e.tag.getText(),).toList());
        for(final type in categorizedTags.entries) {
            if(tagsAndTypes[type.key] == null) tagsAndTypes[type.key] = [];
            for(final tagString in type.value) {
                tagsAndTypes[type.key]!.add(tags[tagString]!);
            }
            tagsAndTypes[type.key]!.sort((a, b) => b.callQuantity.compareTo(a.callQuantity),);
        }
        tagsAndTypes["metatag"] = tagsToAddToSearch;
        refreshSuggestions();
    }

    void refreshSuggestions() {
        final previousText = _controller.text;
        _controller.text = '\u200B$previousText'; // no good way to update the search
        _controller.text = previousText;
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
                if(tagsAndTypes.isEmpty) await cacheTags();
                final tagsOnSearch = List<String>.from(controller.text.split(" "));

                // final filteredTags = Map<String, List<String>>.from(tagsAndTypes!)..retainWhere((s){
                //     return tagsOnSearch.last.isEmpty || s.contains(TagText(tagsOnSearch.last).text);
                // });

                final filteredTags = tagsAndTypes.map((type, tags) {
                    return MapEntry(type, tags.where((display) {
                        return tagsOnSearch.last.isEmpty
                               || display.tag.getText().contains(SearchTag.fromText(tagsOnSearch.last).tag.getText());
                    },));
                },);

                return filteredTags.entries.map((type) => type.value.map((display) {
                    final isMetatag = display.tag is Metatag;
                    final color = !isMetatag ? SpecificTagsColors.getColor(type.key) : null;
                    return ListTile(
                        leading: Icon(!isMetatag ? SpecificTagsIcons.getIcon(type.key) : Icons.lightbulb, color: color,),
                        title: Text(display.tag.getText(),
                            style: TextStyle(
                                color: color,
                                fontWeight: isMetatag ? FontWeight.bold : null
                            ),
                        ),
                        trailing: display.callQuantity > 0 ? Text("${display.callQuantity}") : null,
                        onTap: () {
                            final endResult = List<String>.from(tagsOnSearch)..removeLast()..add(display.tag.getText());
                            setState(() {
                                if(isMetatag && (display.tag as Metatag).value.isEmpty) controller.text = endResult.join(" ");
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
final List<BooruTagCounterDisplay<Tag>> tagsToAddToSearch = [
    BooruTagCounterDisplay(tag: Metatag("rating", "none"), callQuantity: 0),
    BooruTagCounterDisplay(tag: Metatag("rating", "safe"), callQuantity: 0),
    BooruTagCounterDisplay(tag: Metatag("rating", "questionable"), callQuantity: 0),
    BooruTagCounterDisplay(tag: Metatag("rating", "explicit"), callQuantity: 0),
    BooruTagCounterDisplay(tag: Metatag("rating", "borderline"), callQuantity: 0),
    BooruTagCounterDisplay(tag: Metatag("id", ""), callQuantity: 0),
    BooruTagCounterDisplay(tag: Metatag("file", ""), callQuantity: 0),
    BooruTagCounterDisplay(tag: Metatag("type", "static"), callQuantity: 0),
    BooruTagCounterDisplay(tag: Metatag("type", "animated"), callQuantity: 0),
    BooruTagCounterDisplay(tag: Metatag("source", ""), callQuantity: 0),
    BooruTagCounterDisplay(tag: Metatag("source", "none"), callQuantity: 0),
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
            final text = e.getText();

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