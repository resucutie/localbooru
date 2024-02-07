import 'package:flutter/material.dart';
import 'package:localbooru/utils/defaults.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OverallSettings extends StatefulWidget {
    const OverallSettings({super.key, required this.prefs});

    final SharedPreferences prefs;

    @override
    State<OverallSettings> createState() => _OverallSettingsState();
}

class _OverallSettingsState extends State<OverallSettings> {
    double _gridSizeSliderValue = settingsDefaults["grid_size"].toDouble();

    @override
    void initState() {
        super.initState();
        _gridSizeSliderValue = (widget.prefs.getInt("grid_size") ?? settingsDefaults["grid_size"]).toDouble();
    }
    

    @override
    Widget build(BuildContext context) {
        return ListView(
            children: [
                ListTile(
                    title: const Text("Grid size"),
                    subtitle: Wrap(
                        children: [
                            const Text("Set how many columns should be displayed dynamically"),
                            const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [Text("Less elements"), Text("More elements")]
                            ),
                            Slider(
                                value: _gridSizeSliderValue,
                                min: 1,
                                max: 10,
                                divisions: 9,
                                onChanged: (value) async {
                                    setState(() => _gridSizeSliderValue = value);
                                    widget.prefs.setInt("grid_size", _gridSizeSliderValue.ceil());
                                },
                            ),
                        ],
                    )
                )
            ],
        );
    }
}