part of tag_manager;

Future<AccuracyTagList> autoTag(File file) async {
    final prefs = await SharedPreferences.getInstance();
    final String modelSetting = prefs.getString("autotag_model") ?? settingsDefaults["autotag_model"];
    final TagFilter model = switch(modelSetting) {
        "joint_tagger_project" => JointTaggerProjectAutotagger(file),
        "danbooru" || _ => DanbooruAutotagger(file)
    };
    model.filterPercentage = prefs.getDouble("autotag_accuracy") ?? settingsDefaults["autotag_accuracy"];
    return model.execute();
}

