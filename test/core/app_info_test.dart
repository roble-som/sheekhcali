import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/core/app_info.dart';

void main() {
  test('About shows the pubspec version', () {
    final line = File('pubspec.yaml')
        .readAsLinesSync()
        .firstWhere((l) => l.startsWith('version:'));
    final version = line.split(':')[1].trim().split('+').first;
    expect(appVersion, version);
  });
}
