// Copyright 2020 terrier989@gmail.com.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

@Timeout(Duration(minutes: 2))
library gpm_test;

import 'dart:io';

import 'package:gpm/cli.dart' as gpm;
import 'package:gpm/gpm.dart' as gpm;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';
import 'dart:async';

void main() {
  group('GpmStep:', () {
    group('evaluateTemplate:', () {
      test('lots of whitespace', () {
        expect(
          gpm.GpmStep.evaluateTemplate(
            r'  a  b  c  ',
            environment: {},
          ),
          ['a', 'b', 'c'],
        );
      });
      test('quotes #1', () {
        expect(
          gpm.GpmStep.evaluateTemplate(
            r'arg0 "a b c"',
            environment: {},
          ),
          ['arg0', 'a b c'],
        );
      });
      test('quotes #2', () {
        expect(
          gpm.GpmStep.evaluateTemplate(
            r'arg0 "a b c" arg2',
            environment: {},
          ),
          ['arg0', 'a b c', 'arg2'],
        );
      });
      test('environmental variable', () {
        expect(
          gpm.GpmStep.evaluateTemplate(
            r'arg0 prefix-$(ABC)-suffix arg2',
            environment: {
              'ABC': 'value',
            },
          ),
          ['arg0', 'prefix-value-suffix', 'arg2'],
        );
      });
      test('environmental variable is missing', () {
        expect(
          () => gpm.GpmStep.evaluateTemplate(
            r'$(ABC)',
            environment: {},
          ),
          throwsStateError,
        );
      });
      test('paths in non-Windows systems', () {
        expect(
          gpm.GpmStep.evaluateTemplate(
            'arg0 @(a/b/c) arg2',
            environment: {},
          ),
          ['arg0', 'a/b/c', 'arg2'],
        );
      });
      test('paths in Windows systems', () {
        expect(
          gpm.GpmStep.evaluateTemplate(
            'arg0 @(a/b/c) arg2',
            environment: {},
            pathSeparator: r'\',
          ),
          ['arg0', r'a\b\c', 'arg2'],
        );
      });
    });
  });
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
    run: echo "hello"
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
        expect(example.run, 'echo "hello"');
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
    setUpAll(() async {
      if (Platform.environment['SILENT'] == 'true') {
        gpm.commandStdout = null;
        gpm.commandStderr = null;
      }

      // Ensure that we have dependencies cached so we can use 'pub get --offline'
      // in actual tests.
      try {
        await gpm.runCommand(
          'pub',
          ['get', '--offline'],
          workingDirectory: 'test_projects/example2_gpm_config/dart_package',
        );
      } on gpm.CommandFailedException {
        // Cache dependencies so we can use "run pub get --offline" later
        await gpm.runCommand(
          'pub',
          ['get'],
          workingDirectory: 'test_projects/example2_gpm_config/dart_package',
        );
      }
    });

    setUp(() {
      _deleteTemporyFiles();
    });

    final oldWorkingDirectory = Directory.current;
    tearDown(() {
      Directory.current = oldWorkingDirectory;
      _deleteTemporyFiles();
    });

    test('gpm info', () {
      final process = Process.runSync('pub', ['run', 'gpm', 'info']);
      final out = process.stdout as String;
      final lines = out
          .trim()
          .split('\n')
          .where((e) => !e.startsWith('Observatory server failed'))
          .toList();
      expect(lines, hasLength(6));
      expect(
        lines[0],
        '.'.padRight(60) + '(Dart SDK)',
      );
      expect(
        lines[1],
        'test_projects/example1_two_packages/dart_package'.padRight(60) +
            '(Dart SDK)',
      );
    });

    group('gpm get:', () {
      test('example #1', () async {
        if (!(await gpm.isFlutterCommandAvailable)) {
          return;
        }
        Directory.current = 'test_projects/example1_two_packages';
        expect(_exists('dart_package/.packages'), isFalse);
        expect(_exists('flutter_package/.packages'), isFalse);
        await _gpm(['get', '--offline']);
        expect(_exists('dart_package/.packages'), isTrue);
        expect(_exists('flutter_package/.packages'), isTrue);
      });

      test('example #2', () async {
        Directory.current = 'test_projects/example2_gpm_config';
        expect(_exists('dart_package/.packages'), isFalse);
        expect(_exists('flutter_package/.packages'), isFalse);
        await _gpm(['get', '--offline']);
        expect(_exists('dart_package/.packages'), isTrue);
        expect(_exists('flutter_package/.packages'), isFalse);
      });

      test('example #3', () async {
        if (!(await gpm.isFlutterCommandAvailable)) {
          return;
        }
        Directory.current = 'test_projects/example3_flutter_package';
        expect(_exists('dart_package/.packages'), isFalse);
        expect(_exists('flutter_package/.packages'), isFalse);
        await _gpm(['get', '--offline']);
        expect(_exists('dart_package/.packages'), isFalse);
        expect(_exists('flutter_package/.packages'), isTrue);
      });
    });

    group('gpm test:', () {
      test('example #1', () async {
        if (!(await gpm.isFlutterCommandAvailable)) {
          return;
        }
        Directory.current = 'test_projects/example1_two_packages';
        await _gpm(['get', '--offline']);
        await _gpm(['test']);
      });

      test('example #2', () async {
        Directory.current = 'test_projects/example2_gpm_config';
        final file = File('dart_package/tested.txt');
        addTearDown(() {
          if (file.existsSync()) {
            file.deleteSync();
          }
        });
        expect(file.existsSync(), isFalse);
        await _gpm(['get', '--offline']);
        await _gpm(['test']); // Will create 'tested.txt'
        expect(file.existsSync(), isTrue);
      });

      test('example4_failing_test', () async {
        Directory.current = 'test_projects/example4_failing_test';
        await _gpm(['get', '--offline']);

        try {
          await _gpm(['test']);
          fail('Should have thrown');
        } on gpm.CommandFailedException catch (e) {
          expect(e.stdout, contains('Test failed'));
          expect(e.stdout, contains('Some tests failed'));
          expect(e.stderr, '');
          expect(e.exitCode, isNot(0));
        }
      });
    });

    group('gpm build:', () {
      test('example #2', () async {
        Directory.current = 'test_projects/example2_gpm_config';
        final file = File('dart_package/built.txt');
        addTearDown(() {
          if (file.existsSync()) {
            file.deleteSync();
          }
        });
        expect(file.existsSync(), isFalse);
        await _gpm(['get', '--offline']);
        await _gpm(['build']); // Will create 'built.txt'
        expect(file.existsSync(), isTrue);
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
        Directory.current = 'test_projects/example2_gpm_config';
        expect(File('x').existsSync(), isFalse);
        await _gpm(['run', 'example', 'x']);
        expect(File('x').existsSync(), isTrue);
      });
    }, testOn: 'mac-os || linux');
  });
}

void _deleteTemporyFiles() {
  for (var entity in Directory('test_projects').listSync(recursive: true)) {
    final packages = entity.path.split(Platform.pathSeparator);
    final name = packages.last;
    if (name == '.packages' || name == 'pubspec.lock' || name == '.dart_tool') {
      if (entity.existsSync()) {
        entity.deleteSync(recursive: true);
      }
    }
  }
}

bool _exists(String path) {
  return File.fromUri(Directory.current.uri.resolve(path)).existsSync();
}

Future<void> _gpm(List<String> args) async {
  await gpm.main(args, noExit: true);
}
