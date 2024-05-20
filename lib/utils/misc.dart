import 'dart:math' as m;

String formatSize(int bytes) {
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (m.log(bytes) / m.log(1000)).floor();
    return '${(bytes / m.pow(1000, i)).toStringAsFixed(2)} ${suffixes[i]}';
}

bool wildcardMatch(String text, String pattern) {
    String regexPattern = RegExp.escape(pattern)
        .replaceAll('\\*', '.*') // Replace * with .*
        .replaceAll('\\?', '.'); // Replace ? with .

    // Match the entire string from start to end
    regexPattern = '^$regexPattern\$';

    // Perform regex match
    return RegExp(regexPattern).hasMatch(text);
}

bool rangeMatch(double num, String pattern) {
    if(pattern.contains("..")) {
        final split = pattern.split("..");
        if(split.any((e) => double.tryParse(e) == null)) return false;
        final [double from, double to] = split.map((e) => double.parse(e)).toList();
        return from <= num && to >= num;
    } else if(pattern[0] == ">") {
        final min = pattern.substring(1);
        print("${double.tryParse(min) == null && double.tryParse(min.substring(1)) == null}");
        if(double.tryParse(min) == null && double.tryParse(min.substring(1)) == null) return false;
        if(min[0] == "=") return double.parse(min.substring(1)) >= num;
        return double.parse(min) > num;
    } else if(pattern[0] == "<") {
        final min = pattern.substring(1);
        if(double.tryParse(min) == null && double.tryParse(min.substring(1)) == null) return false;
        if(min[0] == "=") return double.parse(min.substring(1)) <= num;
        return double.parse(min) < num;
    } else {
        return false;
    }
}

class Throttler {
    final Duration duration;

    bool canRun = true;

    Throttler(this.duration);

    void run(void Function() action) {
        canRun = false;
        Future.delayed(duration).then((_) {
            if(!canRun) action();
            canRun = true;
        });
    }
}