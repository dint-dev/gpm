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

part of gpm;

String _fileName(String path) {
  final packages = path.split(Platform.pathSeparator);
  return packages.last;
}

/// A package node in [GpmConfig].
class GpmPackage {
  String path;

  bool _isFlutter;
  bool _isWebDev;
  String _pubspec;
  String _pubspecLock;

  GpmPackage();

  factory GpmPackage.fromYaml(Object yaml, {@required List<String> path}) {
    if (yaml is Map) {
      final result = GpmPackage();
      for (var entry in yaml.entries) {
        final key = entry.key as String;
        switch (key) {
          case 'path':
            result.path = entry.value as String;
            break;
          case 'flutter':
            result.path = entry.value as String;
            break;
          default:
            throw StateError('Unsupported key "$key" in /${path.join("/")}');
        }
      }
      return result;
    } else {
      throw ArgumentError.value(yaml);
    }
  }

  Directory get directory => Directory(
        path.replaceAll('/', Platform.pathSeparator),
      );

  /// Tells whether this is a Flutter package.
  bool get isFlutter {
    _isFlutter ??= (pubspecLock?.contains(' flutter:') ??
            pubspec.contains('sdk: flutter')) ||
        Directory.fromUri(directory.uri.resolve('android')).existsSync() ||
        Directory.fromUri(directory.uri.resolve('ios')).existsSync();
    return _isFlutter;
  }

  /// Tells whether this is a Flutter that must be tested with "flutter test"
  /// instead of "flutter pub run test".
  bool get isTestedWithFlutter {
    return isFlutter && (pubspecLock?.contains(' flutter_test:') ?? false);
  }

  /// Tells whether this is a "webdev" package.
  bool get isBuiltWithWebDev {
    _isWebDev ??= !isFlutter &&
        Directory.fromUri(directory.uri.resolve('web')).existsSync();
    return _isWebDev;
  }

  String get pubspec {
    _pubspec ??=
        File.fromUri(directory.uri.resolve('pubspec.yaml')).readAsStringSync();
    return _pubspec;
  }

  String get pubspecLock {
    if (_pubspecLock == null) {
      final file = File.fromUri(directory.uri.resolve('.pubspec.lock'));
      if (!file.existsSync()) {
        return null;
      }
      _pubspecLock = file.readAsStringSync();
    }
    return _pubspecLock;
  }

  /// Runs _pub_ or _flutter pub_.
  Future<void> runPub(
    List<String> args, {
    Map<String, String> environment,
    bool silent = false,
  }) async {
    var executable = 'pub';

    // If:
    // * This is a Flutter package
    // * OR 'pub' is not installed
    final useFlutter = isFlutter || !(await isPubCommandAvailable);

    if (useFlutter) {
      final isFlutterPossible = await isFlutterCommandAvailable;
      if (!isFlutterPossible) {
        if (!(await isPubCommandAvailable)) {
          commandStdout?.writeln(
            'Commands "flutter" and "pub" are unavailable. A possible solution: install Flutter SDK.',
          );
          throw CommandFailedException(1);
        }
        commandStdout?.writeln(
          'Command "flutter" is unavailable. A possible solution: install Flutter SDK.',
        );
        throw CommandFailedException(1);
      }
      executable = 'flutter';
      args = ['--no-version-check', 'pub', ...args];
    }

    return runCommand(
      executable,
      args,
      workingDirectory: directory.path,
      environment: environment,
      silent: silent,
    );
  }

  Map<String, Object> toYaml() {
    final result = <String, Object>{};
    result['path'] = path;
    return result;
  }
}
