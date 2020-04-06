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

class _RunCommand extends Command {
  @override
  ArgParser argParser = ArgParser.allowAnything();

  _RunCommand();

  @override
  String get description => 'Run a command.';

  @override
  String get name => 'run';

  @override
  Future<void> run() async {
    final config = GpmConfig.get();
    final rest = argResults.rest;
    if (rest.isEmpty) {
      commandStdout?.writeln('Missing command');
      return;
    }
    final executable = rest.first;
    final step = config.scripts[executable];
    if (step != null) {
      await step.execute(rest.skip(1).toList());
      return;
    }
    if (File('pubspec.yaml').existsSync()) {
      final package = GpmPackage()..path = '';
      await package.runPub(['run', ...rest]);
      return;
    } else {
      final isPub = await isPubCommandAvailable;
      final isFlutter = await isFlutterCommandAvailable;
      if (isPub) {
        await runCommand(
          'pub',
          ['global', 'run', ...rest],
        );
      } else if (isFlutter) {
        await runCommand(
          'flutter',
          ['--no-version-check', 'pub', 'global', 'run', ...rest],
        );
      } else {
        throw StateError('Neither "flutter" or "pub" is installed.');
      }
    }
  }
}
