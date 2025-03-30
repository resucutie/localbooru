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

mixin CanCustomTaggingServer on ModelInterface {
    Uri get DEFAULT_SERVER_HOST;

    Uri? _host;

    set host(Uri newHost) {
        _host = newHost;
    }

    Uri get host {
        if(_host == null) return DEFAULT_SERVER_HOST;
        return _host!;
    }
}

abstract class ModelInterface {
    ModelInterface(this.file);

    File file;
    Future<AccuracyTagList> execute();
}