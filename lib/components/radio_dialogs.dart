import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';

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
                        title: Text(rating == null ? "None" : rating.name.replaceFirstMapped(rating.name[0], (match) => rating.name[0].toUpperCase())),
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