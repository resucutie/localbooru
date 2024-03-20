import 'dart:math' as m;

String formatSize(int bytes) {
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (m.log(bytes) / m.log(1000)).floor();
    return '${(bytes / m.pow(1000, i)).toStringAsFixed(2)} ${suffixes[i]}';
}