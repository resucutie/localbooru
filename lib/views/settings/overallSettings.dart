import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localbooru/utils/defaults.dart';
import 'package:localbooru/utils/listeners.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OverallSettings extends StatefulWidget {
    const OverallSettings({super.key, required this.prefs});

    final SharedPreferences prefs;

    @override
    State<OverallSettings> createState() => _OverallSettingsState();
}

class _OverallSettingsState extends State<OverallSettings> {
    final _pageSizeValidator = GlobalKey<FormState>();
    final _pageSizeController = TextEditingController();

    double _gridSizeSliderValue = settingsDefaults["grid_size"].toDouble();
    bool _monetTheme = settingsDefaults["monet"];

    bool isSettingModified(String setting) {
        return widget.prefs.get(setting) != null && widget.prefs.get(setting) != settingsDefaults[setting];
    }

    void resetProp(String setting, {Function(dynamic)? modifier}) {
        widget.prefs.remove(setting);
        setState(() {
            if(modifier != null) modifier(settingsDefaults[setting]);
        });
    }

    @override
    void initState() {
        super.initState();
        _gridSizeSliderValue = (widget.prefs.getInt("grid_size") ?? settingsDefaults["grid_size"]).toDouble();
        _pageSizeController.text = (widget.prefs.getInt("page_size") ?? settingsDefaults["page_size"]).toString();
        _monetTheme = widget.prefs.getBool("monet") ?? settingsDefaults["monet"];
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
                                onPressed: () => resetProp("grid_size", modifier: (v) => _gridSizeSliderValue = v.toDouble()),
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
                                onPressed: () => resetProp("page_size", modifier: (v) => _pageSizeController.text = v.toString()),
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
                                    controller: _pageSizeController,
                                    validator: (value) {
                                        if(value == null || value.isEmpty) return "Cannot be empty";
                                        if(int.parse(value) > 100) return "Isn't it too big?";
                                        return null;
                                    },
                                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9]+')),],
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
                ),
                SwitchListTile(
                    title: Row(
                        children: [
                            const Text("Dynamic colors"),
                            if(isSettingModified("monet")) IconButton(
                                onPressed: () {resetProp("monet", modifier: (v) => _monetTheme = v); themeListener.update();},
                                icon: const Icon(Icons.restart_alt)
                            )
                        ],
                    ),
                    secondary: const Icon(Icons.palette),
                    subtitle: const Text("For desktop devices: It will apply the current accent color as the dynamic colors"),
                    value: _monetTheme,
                    onChanged: (value) {
                        widget.prefs.setBool("monet", value);
                        themeListener.update();
                        setState(() => _monetTheme = value);
                    }
                )
            ],
        );
    }
}