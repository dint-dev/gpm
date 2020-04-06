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

class _TestCommand extends Command {
  _TestCommand() {
    argParser.addOption(
      'platform',
      abbr: 'p',
      help: 'Test only on the platform(s).',
    );
    argParser.addOption(
      'tags',
      abbr: 't',
      help: 'Include only tests with the tags. Ignored by Flutter packages.',
    );
    argParser.addOption(
      'exclude-tags',
      abbr: 'x',
      help: 'Exclude tests with the tags. Ignored by Flutter packages.',
    );
    argParser.addOption(
      'timeout',
      help:
          'Default timeout. Examples: 10s, 2x, none. Ignored by Flutter packages.',
    );
    argParser.addFlag(
      'debug',
      defaultsTo: false,
      help: 'Run in debug mode. Ignored by Flutter packages.',
    );
  }

  @override
  String get description => 'Run tests (in each package)';

  @override
  String get name => 'test';

  @override
  bool get takesArguments => false;

  @override
  Future<void> run() async {
    final pubArgs = ['run', 'test'];
    final flutterArgs = ['--no-version-check', 'test'];

    final platform = argResults['platform'];
    if (platform != null) {
      pubArgs.addAll(['--platform', platform]);
      flutterArgs.addAll(['--platform', platform]);
    }

    final tags = argResults['tags'];
    if (tags != null) {
      pubArgs.addAll(['--tags', tags]);
    }

    final excludeTags = argResults['exclude-tags'];
    if (excludeTags != null) {
      pubArgs.addAll(['--exclude-tags', excludeTags]);
    }

    final timeout = argResults['timeout'];
    if (timeout != null) {
      pubArgs.addAll(['--timeout', timeout]);
    }

    final debug = argResults['debug'];
    if (debug) {
      pubArgs.add('debug');
    }

    pubArgs.addAll(argResults.rest);

    for (var package in GpmConfig.get().packages) {
      if (package.isTestedWithFlutter) {
        if (platform == null) {
          await runCommand(
            'flutter',
            flutterArgs,
            workingDirectory: package.directory.path,
          );
        } else {
          final dashes = ''.padLeft(80, '-');
          commandStdout?.writeln(dashes);
          commandStdout?.writeln(
            '| Skipping "${_toRelativePath(package.path)}" because of --platform'
                    .padRight(79, ' ') +
                '|',
          );
          commandStdout?.writeln(dashes);
        }
      } else {
        await package.runPub(pubArgs);
      }
    }
  }
}
