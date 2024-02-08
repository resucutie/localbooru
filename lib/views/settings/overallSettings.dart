import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localbooru/utils/defaults.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OverallSettings extends StatefulWidget {
    const OverallSettings({super.key, required this.prefs});

    final SharedPreferences prefs;

    @override
    State<OverallSettings> createState() => _OverallSettingsState();
}

class _OverallSettingsState extends State<OverallSettings> {
    final _pageSizeValidator = GlobalKey<FormState>();

    double _gridSizeSliderValue = settingsDefaults["grid_size"].toDouble();

    bool isSettingModified(String setting) {
        return widget.prefs.getInt(setting) != null && widget.prefs.getInt(setting) != settingsDefaults[setting];
    }

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
                    title: Row(
                        children: [
                            const Text("Grid size"),
                            if(isSettingModified("grid_size")) IconButton(
                                onPressed: () {widget.prefs.remove("grid_size"); setState(() {});},
                                icon: const Icon(Icons.restart_alt)
                            )
                        ],
                    ),
                    leading: const Icon(Icons.grid_3x3),
                    subtitle: Wrap(
                        children: [
                            const Text("Set how many columns should be displayed dynamically"),
                            const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [Text("Less elements"), Text("More elements")]
                            ),
                            Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: SliderTheme(
                                    data: SliderThemeData(overlayShape: SliderComponentShape.noOverlay),
                                    child: Slider(
                                        value: _gridSizeSliderValue,
                                        min: 1,
                                        max: 10,
                                        divisions: 9,
                                        onChanged: (value) async {
                                            setState(() => _gridSizeSliderValue = value);
                                            widget.prefs.setInt("grid_size", _gridSizeSliderValue.ceil());
                                        },
                                    ),
                                ),
                            )
                        ],
                    )
                ),
                ListTile(
                    title: Row(
                        children: [
                            const Text("Page size"),
                            if(isSettingModified("page_size")) IconButton(
                                onPressed: () {widget.prefs.remove("page_size"); setState(() {});},
                                icon: const Icon(Icons.restart_alt)
                            )
                        ],
                    ),
                    leading: const Icon(Icons.visibility),
                    subtitle: Wrap(
                        children: [
                            const Text("How many images per page should be displayed"),
                            Form(
                                key: _pageSizeValidator,
                                child: TextFormField(
                                    validator: (value) {
                                        if(value == null || value.isEmpty) return "Cannot be empty";
                                        if(int.parse(value) > 100) return "Isn't it too big?";
                                        return null;
                                    },
                                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9]+')),],
                                    initialValue: (widget.prefs.getInt("page_size") ?? settingsDefaults["page_size"]).toString(),
                                    onChanged: (value) {
                                        _pageSizeValidator.currentState!.validate();
                                        if(value.isEmpty || int.parse(value) > 100) return;
                                        setState(() {});
                                        widget.prefs.setInt("page_size", int.parse(value));
                                    },
                                ),
                            )
                        ],
                    )
                )
            ],
        );
    }
}