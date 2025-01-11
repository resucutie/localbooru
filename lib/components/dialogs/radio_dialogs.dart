import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/counter.dart';
import 'package:localbooru/utils/constants.dart';

class RatingChooserDialog extends StatelessWidget {
    const RatingChooserDialog({super.key, this.selected, this.hasNull = false, this.title = const Text("Rating")});

    final Rating? selected;
    final bool hasNull;
    final Widget title;

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: title,
            contentPadding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    for (final rating in [if(hasNull) null, Rating.safe, Rating.questionable, Rating.explicit, Rating.illegal]) RadioListTile(
                        groupValue: selected,
                        value: rating,
                        title: Wrap(
                            spacing: 8,
                            children: [
                                Icon(getRatingIcon(rating)),
                                Text(getRatingText(rating)),
                            ],
                        ),
                        onChanged: (value) => Navigator.of(context).pop(value ?? "None"),
                    ),
                ],
            ),
            actions: [
                TextButton(onPressed: Navigator.of(context).pop, child: const Text("Close"))
            ],
        );
    }
}

class ThemeChangerDialog extends StatelessWidget {
    const ThemeChangerDialog({super.key, required this.theme});

    final String theme;

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Text("Theme"),
            contentPadding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    for (final themeMode in ["system", "dark", "light"]) RadioListTile(
                        groupValue: theme,
                        value: themeMode,
                        title: Text(themeMode.replaceFirstMapped(themeMode[0], (match) => themeMode[0].toUpperCase())),
                        onChanged: (value) => Navigator.of(context).pop(value),
                    ),
                ],
            ),
            actions: [
                TextButton(onPressed: Navigator.of(context).pop, child: const Text("Close"))
            ],
        );
    }
}

final Map<String, String> avaiableCounters = {
    "squares": "resucutie",
    "baba": "resucutie",
    "image-goobers": "endercatcore",
    "signs": "themtipguy, resucutie",
};
class CounterChangerDialog extends StatelessWidget {
    const CounterChangerDialog({super.key, required this.counter});

    final String counter;

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Text("Counter"),
            contentPadding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
            content: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 460),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: avaiableCounters.entries.map((counterType) => RadioListTile(
                        groupValue: counter,
                        value: counterType.key,
                        title: Wrap(
                            // crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                                Text(counterType.key),
                                Text("- ${counterType.value}", style: TextStyle(color: Theme.of(context).disabledColor),),
                            ],
                        ),
                        subtitle: Wrap(children: [StyleCounter(number: 1234567890, height: 30, display: counterType.key)]),
                
                        onChanged: (value) => Navigator.of(context).pop(value),
                    )).toList(),
                ),
            ),
            actions: [
                TextButton(onPressed: Navigator.of(context).pop, child: const Text("Close"))
            ],
        );
    }
}