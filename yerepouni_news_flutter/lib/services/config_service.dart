import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/config.dart';

class ConfigService {
  static Future<AppConfig> load() async {
    final raw = await rootBundle.loadString('assets/config.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return AppConfig.fromJson(json);
  }
}
