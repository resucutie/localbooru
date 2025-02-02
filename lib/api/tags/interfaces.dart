part of tag_manager;


abstract class Tag {
    const Tag();
}

class NormalTag extends Tag {
    const NormalTag(this.text);

    final String text;
}

class Metatag extends Tag {
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
}

class SearchTag {
    const SearchTag({required Tag tag, required this.modifier}):
        _tag = tag;
    
    factory SearchTag.fromText(String rawText) {
        final modifier = obtainModifier(rawText);
        final nonModifierText = modifier == Modifier.filterModifier ? rawText : rawText.substring(1);
        return SearchTag(
            tag: !Metatag.isMetatag(nonModifierText) ? NormalTag(nonModifierText) : Metatag.fromText(nonModifierText),
            modifier: modifier
        );
    }
    final Tag _tag;
    final Modifier modifier;

    Tag get tag => _tag;

    static Modifier obtainModifier(String rawText){
        final String firstElement = rawText[0];
        final Modifier? foundModifier = modifierSelectors.entries.firstWhereOrNull((mapEntry) => mapEntry.value == firstElement,)?.key;
        if(foundModifier == null) return Modifier.filterModifier;
        else return foundModifier;
    }

    static Map<Modifier, String?> get modifierSelectors => _modifierSelectors;
}

enum Modifier {additionModifier, exclusionModifier, filterModifier}
final Map<Modifier, String?> _modifierSelectors = {
    Modifier.additionModifier: "+",
    Modifier.exclusionModifier: "-",
    Modifier.filterModifier: null,
};