@Timeout(Duration(seconds: 60))
library gpm_test;

import 'dart:io';

import 'package:test/test.dart';
import 'package:gpm/gpm.dart' as gpm;
import 'package:yaml/yaml.dart';

Future<void> _gpm(List<String> args) {
  return gpm.main(args, noExit: true);
}

void main() {
  group('GpmConfig:', () {
    test('example #1', () {
      final config = gpm.GpmConfig.fromYaml(loadYaml('''
packages:
- path: path0
- path: path1

scripts:
  example0:
    description: some script
    environment:
      k0: v0
      k1: v1
    run: ["echo", "hello"]
  example1:
    platform: windows
    fail: Failure message
'''));
      expect(config.packages, hasLength(2));
      expect(config.packages[0].path, 'path0');
      expect(config.packages[1].path, 'path1');

      expect(config.scripts, hasLength(2));
      {
        final example = config.scripts['example0'];
        expect(example.platform, isNull);
        expect(example.description, 'some script');
        expect(example.environment, {'k0': 'v0', 'k1': 'v1'});
        expect(example.run, ['echo', 'hello']);
        expect(example.fail, isNull);
      }
      {
        final example = config.scripts['example1'];
        expect(example.platform, 'windows');
        expect(example.description, isNull);
        expect(example.environment, isNull);
        expect(example.run, isNull);
        expect(example.fail, 'Failure message');
      }
    });
  });
  group('main(...):', () {
    final oldWorkingDirectory = Directory.current;
    setUp(() {
      Directory.current = oldWorkingDirectory;
      _deleteTemporyFiles();
    });
    tearDown(() {
      Directory.current = oldWorkingDirectory;
      _deleteTemporyFiles();
    });

    test('gpm list', () {
      final process = Process.runSync('pub', ['run', 'gpm', 'list']);
      final out = process.stdout as String;
      final lines = out
          .trim()
          .split('\n')
          .where((e) => !e.startsWith('Observatory server failed'))
          .toList();
      expect(lines, hasLength(5));
      expect(
        lines[0],
        '.'.padRight(60) + '(Dart SDK)',
      );
      expect(
        lines[1],
        'test/example1/dart_package'.padRight(60) + '(Dart SDK)',
      );
    });

    group('gpm get:', () {
      test('example #1', () async {
        Directory.current = 'test/example1';
        expect(_exists('dart_package/.packages'), isFalse);
        expect(_exists('flutter_package/.packages'), isFalse);
        await _gpm(['get', '--offline']);
        expect(_exists('dart_package/.packages'), isTrue);
        expect(_exists('flutter_package/.packages'), isTrue);
      });

      test('example #2', () async {
        Directory.current = 'test/example2';
        expect(_exists('dart_package/.packages'), isFalse);
        expect(_exists('flutter_package/.packages'), isFalse);
        await _gpm(['get', '--offline']);
        expect(_exists('dart_package/.packages'), isTrue);
        expect(_exists('flutter_package/.packages'), isFalse);
      });

      test('example #3', () async {
        Directory.current = 'test/example3';
        expect(_exists('dart_package/.packages'), isFalse);
        expect(_exists('flutter_package/.packages'), isFalse);
        await _gpm(['get', '--offline']);
        expect(_exists('dart_package/.packages'), isFalse);
        expect(_exists('flutter_package/.packages'), isTrue);
      });
    });

    group('gpm test:', () {
      test('example #1', () async {
        Directory.current = 'test/example1';
        await _gpm(['get', '--offline']);
        await _gpm(['test']);
      });
    });

    group('gpm run example:', () {
      test('example #2', () async {
        addTearDown(() {
          final file = File('x');
          if (file.existsSync()) {
            file.deleteSync();
          }
        });
        Directory.current = 'test/example2';
        expect(File('x').existsSync(), isFalse);
        await _gpm(['run', 'example', 'x']);
        expect(File('x').existsSync(), isTrue);
      });
    }, testOn: 'mac-os || linux');
  });
}

bool _exists(String path) {
  return File.fromUri(Directory.current.uri.resolve(path)).existsSync();
}

void _deleteTemporyFiles() {
  for (var entity in Directory('test').listSync(recursive: true)) {
    final packages = entity.path.split(Platform.pathSeparator);
    final name = packages.last;
    if (name == '.packages' || name == 'pubspec.lock' || name == '.dart_tool') {
      if (entity.existsSync()) {
        entity.deleteSync(recursive: true);
      }
    }
  }
}
