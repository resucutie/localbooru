import 'package:localbooru/utils/download_image.dart';
import 'package:localbooru/utils/listeners.dart';

class MultiCompletionist {
    MultiCompletionist(this.amount);
    final int amount;
    final Map<dynamic, _Operation> _operations = {};

    HandleChunk chunkHandler(dynamic id) {
        return (chunk, res) {
            if(res.contentLength == null) return;
            if(!_operations.containsKey(id)) {
                _operations[id] = _Operation(
                    downloaded: 0,
                    sizeOfContent: res.contentLength!
                );
            }
            _operations[id]!.downloaded += chunk.length;
            _updateProgress();
        };
    }

    _updateProgress() {
        final operations = _operations.values;
        double finalVal = 0;
        for(final operation in operations) {
            finalVal += operation.downloaded / operation.sizeOfContent;
        }
        importListener.updateImportStatus(progress: finalVal / amount);
    }
}

class _Operation {
    _Operation({required this.downloaded, required this.sizeOfContent});
    int downloaded;
    int sizeOfContent;
}