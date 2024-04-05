import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localbooru/components/headers.dart';
import 'package:localbooru/utils/constants.dart';
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

    late double _gridSizeSliderValue;
    late double _autotagAccuracy;
    late double _thumbnailQuality;
    late bool _monetTheme;
    late bool _update;
    late bool _gif_video;
    late String _theme;

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
        _autotagAccuracy = widget.prefs.getDouble("autotag_accuracy") ?? settingsDefaults["autotag_accuracy"];
        _thumbnailQuality = widget.prefs.getDouble("thumbnail_quality") ?? settingsDefaults["thumbnail_quality"];
        _pageSizeController.text = (widget.prefs.getInt("page_size") ?? settingsDefaults["page_size"]).toString();
        _monetTheme = widget.prefs.getBool("monet") ?? settingsDefaults["monet"];
        _update = widget.prefs.getBool("update") ?? settingsDefaults["update"];
        _gif_video = widget.prefs.getBool("gif_video") ?? settingsDefaults["gif_video"];
        _theme = widget.prefs.getString("theme") ?? settingsDefaults["theme"];
    }

    Future<void> onChangeTheme() async {
        final choosenTheme = await showDialog<String>(
            context: context,
            builder: (_) => ThemeChangerDialog(theme: widget.prefs.getString("theme") ?? settingsDefaults["theme"])
        );
        if(choosenTheme == null) return;
        widget.prefs.setString("theme", choosenTheme);
        themeListener.update();
        setState(() => _theme = choosenTheme);
    }

    @override
    Widget build(BuildContext context) {
        return ListView(
            children: [
                const SmallHeader("Browsing"),
                SliderListTile(
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
                    subtitle: const Text("Set how many columns should be displayed dynamically"),
                    extremeTips: const [Text("Less elements"), Text("More elements")],
                    value: _gridSizeSliderValue,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (value) async {
                        setState(() => _gridSizeSliderValue = value);
                        widget.prefs.setInt("grid_size", value.ceil());
                    },
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
                SliderListTile(
                    title: Row(
                        children: [
                            const Text("Thumbnail quality"),
                            if(isSettingModified("thumbnail_quality")) IconButton(
                                onPressed: () => resetProp("thumbnail_quality", modifier: (v) => _thumbnailQuality = v),
                                icon: const Icon(Icons.restart_alt)
                            )
                        ],
                    ),
                    leading: const Icon(Icons.image_aspect_ratio),
                    subtitle: const Text("Set how high quality should the thumbnails be on the browse screen. The less, the less ram will be used, but the preview will be lower quality"),
                    extremeTips: const [Text("0.5x displayed"), Text("3x displayed")],
                    value: _thumbnailQuality,
                    min: 0.5,
                    max: 3,
                    divisions: 5,
                    label: "$_thumbnailQuality",
                    onChanged: (value) async {
                        setState(() => _thumbnailQuality = value);
                        widget.prefs.setDouble("thumbnail_quality", value);
                    },
                ),
                
                const SmallHeader("Tags"),
                SliderListTile(
                    title: Row(
                        children: [
                            const Text("Autotag accuracy"),
                            if(isSettingModified("autotag_accuracy")) IconButton(
                                onPressed: () => resetProp("autotag_accuracy", modifier: (v) => _autotagAccuracy = v),
                                icon: const Icon(Icons.restart_alt)
                            )
                        ],
                    ),
                    leading: const Icon(CupertinoIcons.sparkles),
                    subtitle: const Text("How accurate should be the results of the autotagger"),
                    extremeTips: const [Text("Less accurate"), Text("More accurate")],
                    //TODO: Make this slider go in an exponential curve
                    value: _autotagAccuracy,
                    min: 0,
                    max: 1,
                    label: "${(_autotagAccuracy*100).round()}%",
                    onChanged: (value) async {
                        setState(() => _autotagAccuracy = value);
                        widget.prefs.setDouble("autotag_accuracy", value);
                    },
                ),
                
                const SmallHeader("Appearence"),
                ListTile(
                    title: const Text("Theme"),
                    subtitle: Text(_theme.replaceFirstMapped(_theme[0], (match) => _theme[0].toUpperCase())),
                    leading: const Icon(Icons.dark_mode),
                    onTap: onChangeTheme,
                ),
                SwitchListTile(
                    title: const Text("Dynamic colors"),
                    secondary: const Icon(Icons.palette),
                    subtitle: const Text("For desktop devices: It will apply the current accent color as the dynamic colors"),
                    value: _monetTheme,
                    onChanged: (value) {
                        widget.prefs.setBool("monet", value);
                        themeListener.update();
                        setState(() => _monetTheme = value);
                    }
                ),

                const SmallHeader("Behavior"),
                SwitchListTile(
                    title: const Text("Display GIFs as videos"),
                    secondary: const Icon(Icons.gif),
                    subtitle: const Text("It will add video controllers to GIFs"),
                    value: _gif_video,
                    onChanged: (value) {
                        widget.prefs.setBool("gif_video", value);
                        setState(() => _gif_video = value);
                    }
                ),
                const SmallHeader("Other"),
                SwitchListTile(
                    title: const Text("Prompt for updates"),
                    secondary: const Icon(Icons.cached),
                    subtitle: const Text("If the program it outdated, it'll prompt for an update"),
                    value: _update,
                    onChanged: (value) {
                        widget.prefs.setBool("update", value);
                        setState(() => _update = value);
                    }
                ),
            ],
        );
    }
}

class SliderListTile extends StatelessWidget {
    const SliderListTile({super.key, this.title, this.leading, required this.value, this.min = 0, this.max = 1, this.label, this.onChanged, this.subtitle, this.extremeTips, this.divisions});
    
    final Widget? title;
    final Widget? subtitle;
    final List<Widget>? extremeTips;
    final Widget? leading;
    final double value;
    final double min;
    final double max;
    final int? divisions;
    final String? label;
    final Function(double)? onChanged;


    @override
    Widget build(BuildContext context) {
        return ListTile(
            title: title,
            leading: leading,
            subtitle: Wrap(
                children: [
                    if(subtitle != null) subtitle!,
                    if(extremeTips != null) Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: extremeTips!
                    ),
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: SliderTheme(
                            data: SliderThemeData(overlayShape: SliderComponentShape.noOverlay, showValueIndicator: ShowValueIndicator.always),
                            child: Slider(
                                value: value,
                                min: min,
                                max: max,
                                label: label,
                                divisions: divisions,
                                onChanged: onChanged,
                            ),
                        ),
                    )
                ],
            )
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