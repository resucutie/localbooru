import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesBuilder extends StatelessWidget {
    const SharedPreferencesBuilder({super.key, required this.builder, this.loading});
    
    final Widget Function(BuildContext context, SharedPreferences prefs) builder;
    final Widget? loading;

    @override
    Widget build(BuildContext context) {
        return FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
                if(snapshot.hasData) {
                    return builder(context, snapshot.data!);
                } else if(snapshot.hasError) {
                    throw snapshot.error!;
                }
                return loading ?? const Center(child: CircularProgressIndicator());
            },
        );
    }
}