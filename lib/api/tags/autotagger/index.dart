part of tag_manager;

Future<AccuracyTagList> autoTag(File file) async {
    final prefs = await SharedPreferences.getInstance();
    final danbooruAutotagger = DanbooruAutotagger(file);
    danbooruAutotagger.filterPercentage = prefs.getDouble("autotag_accuracy") ?? settingsDefaults["autotag_accuracy"];
    return danbooruAutotagger.execute();
}

