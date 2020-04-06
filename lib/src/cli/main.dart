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

part of gpm.cli;

/// Run GPM.
Future<void> main(
  List<String> args, {
  bool noExit = false,
}) async {
  final cmd = CommandRunner(
    'gpm',
    'A package management tool for multi-package projects.',
  );
  cmd.addCommand(_BuildCommand());
  cmd.addCommand(_CICommand());
  cmd.addCommand(_GetCommand());
  cmd.addCommand(_InfoCommand());
  cmd.addCommand(_PubCommand());
  cmd.addCommand(_RunCommand());
  cmd.addCommand(_TestCommand());
  cmd.addCommand(_UpgradeCommand());

  if (noExit) {
    await cmd.run(args);
    return;
  }

  try {
    await cmd.run(args);
    exit(0);
  } on CommandFailedException catch (e) {
    exit(e.exitCode);
  } on UsageException catch (e) {
    print(e.message);
    exit(1);
  }
}

String _toRelativePath(String path) {
  var wd = Directory.current.path;
  if (path == wd || path == wd.replaceAll(Platform.pathSeparator, '/')) {
    return '.';
  }
  wd += Platform.pathSeparator;
  if (path.startsWith(wd) ||
      path.startsWith(wd.replaceAll(Platform.pathSeparator, '/'))) {
    return path.substring(wd.length);
  }
  return path;
}

class _PubCommand extends Command {
  @override
  ArgParser argParser = ArgParser.allowAnything();

  @override
  String get description => 'Runs "pub" in each package.';

  @override
  String get invocation => 'gpm pub [command]';

  @override
  String get name => 'pub';

  @override
  Future<void> run() async {
    final args = argResults.rest;
    if (args.isEmpty) {
      commandStdout?.writeln('Missing subcommand');
      return;
    }
    for (var package in GpmConfig.get().packages) {
      await package.runPub(args);
    }
  }
}

class _UpgradeCommand extends Command {
  @override
  String get description => 'Upgrades GPM.';

  @override
  String get name => 'upgrade';

  @override
  bool get takesArguments => false;

  @override
  Future<void> run() async {
    await runCommand('pub', ['global', 'activate', 'gpm']);
  }
}
