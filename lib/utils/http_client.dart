import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class LocalBooruHttpClient extends http.BaseClient {
    LocalBooruHttpClient(this._inner, {
        this.withCustomUserAgent = true,
        this.manipulateRequest
    });
    
    final http.Client _inner;
    final bool withCustomUserAgent;
    final FutureOr<http.BaseRequest> Function(http.BaseRequest request)? manipulateRequest;

    @override
    Future<http.StreamedResponse> send(http.BaseRequest request) async {
        if(withCustomUserAgent) {
            if(!Platform.environment.containsKey('FLUTTER_TEST')) {
                final package = await PackageInfo.fromPlatform();
                request.headers['user-agent'] = "LocalBooru/${package.version}"; //didn't even test, dont know how i'll be sure it is sending headers
            } else {
                request.headers['user-agent'] = "LocalBooru/TEST_ENV";
            }
        }
        if(manipulateRequest != null) request = await manipulateRequest!(request);
        return await _inner.send(request);
    }
}

class LoggedHttpClients {
    static LocalBooruHttpClient e621Cleint = LocalBooruHttpClient(http.Client());
}

final lbHttp = LocalBooruHttpClient(http.Client());
// final e6lbHttp = LocalBooruHttpClient(http.Client(), manipulateRequest: (request) {
  
// },);