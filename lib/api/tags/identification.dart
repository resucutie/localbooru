part of tag_manager;

final List<String> selectors = ["+", "-"];

class TagText {
    const TagText(this.rawText);

    final String rawText;

    String get text {
        if(obtainSelector() != null) {
            return rawText.substring(1);
        } else {
            return rawText;
        }
    }

    String? obtainSelector(){
        final String firstElement = rawText[0];
        if(selectors.contains(firstElement)) return firstElement;
        return null;
    }

    bool isMetatag() {
        final split = text.split(":");
        return split.length == 2 && split.first.isNotEmpty && split.last.isNotEmpty;
    }
}

class Metatag {
    Metatag(this.rawTag) {
        if(!rawTag.isMetatag()) throw "${rawTag.text} is not a metatag";

        final List<String> split = rawTag.text.split(":");
        selector = split[0];
        value = split[1];
    }
    
    final TagText rawTag;

    late String selector;
    late String value;
}