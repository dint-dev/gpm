part of gpm;

class GpmPackage {
  String path;

  bool _isFlutter;
  bool _isWebDev;

  GpmPackage();

  factory GpmPackage.fromYaml(Object yaml, {List<String> path}) {
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

  bool get isFlutter {
    if (_isFlutter == null) {
      final pubspecFile = File.fromUri(directory.uri.resolve('pubspec.yaml'));
      _isFlutter = pubspecFile.readAsStringSync().contains('sdk: flutter');
    }
    return _isFlutter;
  }

  bool get isWebDev {
    _isWebDev ??= !isFlutter &&
        Directory.fromUri(directory.uri.resolve('web')).existsSync();
    return _isWebDev;
  }

  Future<void> runPub(List<String> args,
      {Map<String, String> environment}) async {
    var executable = 'pub';
    if (isFlutter) {
      executable = 'flutter';
      args = ['pub', ...args];
    }

    await _runCommand(
      executable,
      args,
      workingDirectory: directory.path,
      environment: environment,
    );
  }

  Map<String, Object> toYaml() {
    final result = <String, Object>{};
    result['path'] = path;
    return result;
  }
}
