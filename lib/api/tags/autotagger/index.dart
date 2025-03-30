part of tag_manager;

Future<AccuracyTagList> autoTag(File file) async {
    final prefs = await SharedPreferences.getInstance();
    final String modelSetting = prefs.getString("autotag_model") ?? settingsDefaults["autotag_model"];
    final String? modelCustomUrl = prefs.getString("autotag_custom_url") ?? settingsDefaults["autotag_custom_url"];
    final ModelInterface model = switch(modelSetting) {
        "joint_tagger_project" => JointTaggerProjectAutotagger(file),
        "z3d_e621_convnext" => Z3DE621ConvnextAutotagger(file),
        "danbooru" || _ => DanbooruAutotagger(file)
    };
    if(model is TagFilter) model.filterPercentage = prefs.getDouble("autotag_accuracy") ?? settingsDefaults["autotag_accuracy"];
    if(model is CanCustomTaggingServer && modelCustomUrl != null) model.host = Uri.parse(modelCustomUrl);
    return model.execute();
}

