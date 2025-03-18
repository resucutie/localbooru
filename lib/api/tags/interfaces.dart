part of tag_manager;

abstract interface class WorksWithTags {
    String getText();
}

abstract class Tag implements WorksWithTags {
    const Tag();
}

class NormalTag extends Tag {
    const NormalTag(this.text);

    final String text;

    @override
    String getText() {
        return text;
    }
}

class Metatag extends Tag implements WorksWithTags {
    const Metatag(this.selector, this.value);

    factory Metatag.fromText(String rawText) {
        if(!isMetatag(rawText)) throw "$rawText is not a metatag";
        final List<String> split = rawText.split(":");
        return Metatag(split[0], split[1]);
    }

    final String selector;
    final String value;
    
    static bool isMetatag(String text) {
        final split = text.split(":");
        return split.length == 2 && split.first.isNotEmpty && split.last.isNotEmpty;
    }

    @override
    String getText() {
        return "$selector:$value";
    }
}

class SearchTag implements WorksWithTags {
    const SearchTag({required Tag tag, required this.modifier}):
        _tag = tag;
    
    factory SearchTag.fromText(String rawText) {
        final modifier = SearchTag.obtainModifier(rawText);
        final nonModifierText = modifier == Modifier.filterModifier ? rawText : rawText.substring(1);
        return SearchTag(
            tag: !Metatag.isMetatag(nonModifierText) ? NormalTag(nonModifierText) : Metatag.fromText(nonModifierText),
            modifier: modifier
        );
    }
    final Tag _tag;
    final Modifier modifier;

    Tag get tag => _tag;

    @override
    String getText() {
        return "${modifierSelectors[modifier] ?? ""}${tag.getText()}";
    }

    static Modifier obtainModifier(String rawText){
        if(rawText.isEmpty) return Modifier.filterModifier;
        final String firstElement = rawText[0];
        final Modifier? foundModifier = modifierSelectors.entries.firstWhereOrNull((mapEntry) => mapEntry.value == firstElement,)?.key;
        if(foundModifier == null) return Modifier.filterModifier;
        else return foundModifier;
    }

    static Map<Modifier, String?> get modifierSelectors => _modifierSelectors;
    static Map<Modifier, Color?> get modifierColors => _modifierColors;
}

enum Modifier {additionModifier, exclusionModifier, filterModifier}
const Map<Modifier, String?> _modifierSelectors = {
    Modifier.additionModifier: "+",
    Modifier.exclusionModifier: "-",
    Modifier.filterModifier: null,
};
const Map<Modifier, Color?> _modifierColors = {
    Modifier.filterModifier: null,
    Modifier.additionModifier: Colors.green,
    Modifier.exclusionModifier: Colors.red,
};