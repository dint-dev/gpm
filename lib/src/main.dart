part of gpm;

/// Run GPM.
Future<int> main(List<String> args, {bool noExit = false}) async {
  final cmd = CommandRunner(
    'gpm',
    'A package management tool for multi-package projects.',
  );
  cmd.addCommand(_BuildCommand());
  cmd.addCommand(_GetCommand());
  cmd.addCommand(_ListCommand());
  cmd.addCommand(_PubCommand());
  cmd.addCommand(_RunCommand());
  cmd.addCommand(_TestCommand());
  cmd.addCommand(_UpgradeCommand());
  var exitCode = 0;
  try {
    await cmd.run(args);
  } on _ExitException catch (e) {
    exitCode = e.exitCode;
  }
  if (noExit) {
    return exitCode;
  }
  exit(exitCode);
  return 1;
}

final _dashes = ''.padLeft(80, '-');

String _fileName(String path) {
  final packages = path.split(Platform.pathSeparator);
  return packages.last;
}

Future<void> _runCommand(String executable, List<String> args,
    {String workingDirectory, Map<String, String> environment}) async {
  if (workingDirectory == null) {
    if (!Platform.isWindows) {
      workingDirectory = '.';
    } else {
      workingDirectory ??= Directory.current.path;
    }
  }

  final relativePath = _toRelativePath(workingDirectory);
  print(_dashes);
  print('| Running: $executable ${args.join(" ")}'.padRight(79, ' ') + '|');
  print('|      in: $relativePath'.padRight(79, ' ') + '|');
  print(_dashes);

  final process = await Process.start(
    executable,
    args,
    workingDirectory: workingDirectory,
    environment: environment,
  );

  process.stdout.listen((data) {
    stdout.add(data);
  });
  process.stderr.listen((data) {
    stderr.add(data);
  });

  final exitCode = await process.exitCode;
  print('');
  if (exitCode != 0) {
    print('Error code $exitCode');
    throw _ExitException(exitCode);
  }
}

String _toRelativePath(String path) {
  if (path == Directory.current.path && !Platform.isWindows) {
    return '.';
  }
  final workingPath = Directory.current.path + Platform.pathSeparator;
  if (path.startsWith(workingPath)) {
    return path.substring(workingPath.length);
  }
  return path;
}

class _BuildCommand extends Command {
  @override
  String get description => 'Builds each package';

  @override
  String get name => 'build';

  @override
  Future<void> run() async {
    for (var package in GpmConfig.get().packages) {
      if (package.isFlutter) {
        await _runCommand(
          'flutter',
          ['generate'],
          workingDirectory: package.directory.path,
        );
        if (Directory.fromUri(package.directory.uri.resolve('android'))
            .existsSync()) {
          await _runCommand(
            'flutter',
            ['build', 'apk'],
            workingDirectory: package.directory.path,
          );
        }
        if (Platform.isMacOS &&
            Directory.fromUri(package.directory.uri.resolve('ios'))
                .existsSync()) {
          await _runCommand(
            'flutter',
            ['build', 'ios'],
            workingDirectory: package.directory.path,
          );
        }
        if (Directory.fromUri(package.directory.uri.resolve('web'))
            .existsSync()) {
          await _runCommand(
            'flutter',
            ['build', 'web'],
            workingDirectory: package.directory.path,
          );
        }
      } else if (package.isWebDev) {
        await package.runPub(['run', 'webdev', 'build']);
      } else {
        print(_dashes);
        print('Skipping ${_toRelativePath(package.path)}');
        print(_dashes);
      }
    }
  }
}

class _ExitException implements Exception {
  final int exitCode;

  _ExitException(this.exitCode);

  @override
  String toString() => 'ExitException($exitCode)';
}

class _GetCommand extends Command {
  _GetCommand() {
    argParser.addFlag('offline');
  }

  @override
  String get description => 'Get dependencies (in each package)';

  @override
  String get name => 'get';

  @override
  Future<void> run() async {
    final args = ['get'];
    final offline = argResults['offline'];
    if (offline) {
      args.add('--offline');
    }
    args.addAll(argResults.rest);
    for (var package in GpmConfig.get().packages) {
      await package.runPub(args);
    }
  }
}

class _ListCommand extends Command {
  @override
  String get description => 'List all packages in the directory tree';

  @override
  String get name => 'list';

  @override
  Future<void> run() async {
    for (var package in GpmConfig.get().packages) {
      final line = _toRelativePath(package.path).padRight(60);
      print('$line(${package.isFlutter ? "Flutter SDK" : "Dart SDK"})');
    }
  }
}

class _PubCommand extends Command {
  final _argParser = ArgParser.allowAnything();

  @override
  ArgParser get argParser => _argParser;

  @override
  String get description => 'Runs "pub" (in each package)';

  @override
  String get invocation => 'gpm pub [command]';
  @override
  String get name => 'pub';

  @override
  Future<void> run() async {
    final args = argResults.rest;
    if (args.isEmpty) {
      print('Missing subcommand');
      return;
    }
    for (var package in GpmConfig.get().packages) {
      await package.runPub(args);
    }
  }
}

class _RunCommand extends Command {
  final _argParser = ArgParser.allowAnything();

  @override
  ArgParser get argParser => _argParser;

  _RunCommand();

  @override
  String get description => 'Run a command';

  @override
  String get name => 'run';

  @override
  Future<void> run() async {
    final config = GpmConfig.get();
    final rest = argResults.rest;
    if (rest.isEmpty) {
      print('Missing command');
      return;
    }
    final executable = rest.first;
    final step = config.scripts[executable];
    if (step != null) {
      await step.execute(rest.skip(1).toList());
      return;
    }
    if (File('pubspec.yaml').existsSync()) {
      final isFlutter =
          File('pubspec.yaml').readAsStringSync().contains('sdk: flutter');
      if (isFlutter) {
        await _runCommand('flutter', ['pub', 'run', ...rest]);
      } else {
        await _runCommand('pub', ['run', ...rest]);
      }
    }
    await _runCommand('pub', ['global', 'run', ...rest]);
  }
}

class _TestCommand extends Command {
  _TestCommand() {
    argParser.addOption('platform', help: 'Platforms where the tests are run');
  }

  @override
  String get description => 'Run tests (in each package)';

  @override
  String get name => 'test';

  @override
  Future<void> run() async {
    final args = ['run', 'test'];
    final platform = argResults['platform'];
    if (platform != null) {
      args.addAll(['--platform', platform]);
    }
    args.addAll(argResults.rest);

    for (var package in GpmConfig.get().packages) {
      await package.runPub(args);
    }
  }
}

class _UpgradeCommand extends Command {
  @override
  String get description => 'Upgrades GPM';

  @override
  String get name => 'upgrade';

  @override
  Future<void> run() async {
    await _runCommand('pub', ['global', 'activate', 'gpm']);
  }
}
