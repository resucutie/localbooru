part of tag_manager;

/// Model:
/// {"tagName": accuracy}
typedef AccuracyTagList = Map<String, double>;
mixin TagFilter on ModelInterface {
    double filterPercentage = 0.3;

    @protected
    AccuracyTagList flterAccurateResults(AccuracyTagList tags) {
        return AccuracyTagList.from(tags)..removeWhere((tag, accuracy) => accuracy < filterPercentage);
    }
}

abstract class ModelInterface {
    ModelInterface(this.file);

    File file;
    Future<AccuracyTagList> execute();
}