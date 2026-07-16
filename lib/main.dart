import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';

// Initialization order matters: WidgetsFlutterBinding must be
// initialized before any async plugins (Hive). ProviderScope wraps
// the app so Riverpod providers are available throughout the tree.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const ProviderScope(child: App()));
}
