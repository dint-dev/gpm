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

class _BuildCommand extends Command {
  @override
  String get description => 'Build each package.';

  @override
  String get name => 'build';

  @override
  bool get takesArguments => false;

  @override
  Future<void> run() async {
    for (var package in GpmConfig.get().packages) {
      final step = package.build;
      if (step != null) {
        await step.execute(workingDirectory: package.directory.path);
        continue;
      }
      if (package.isFlutter) {
        await runCommand(
          'flutter',
          ['--no-version-check', 'generate'],
          workingDirectory: package.directory.path,
        );
        if (Directory.fromUri(package.directory.uri.resolve('android'))
            .existsSync()) {
          await runCommand(
            'flutter',
            ['--no-version-check', 'build', 'apk'],
            workingDirectory: package.directory.path,
          );
        }
        if (Platform.isMacOS &&
            Directory.fromUri(package.directory.uri.resolve('ios'))
                .existsSync()) {
          await runCommand(
            'flutter',
            ['--no-version-check', 'build', 'ios'],
            workingDirectory: package.directory.path,
          );
        }
        if (Directory.fromUri(package.directory.uri.resolve('web'))
            .existsSync()) {
          await runCommand(
            'flutter',
            ['--no-version-check', 'build', 'web'],
            workingDirectory: package.directory.path,
          );
        }
      } else if (package.isBuiltWithWebDev) {
        // See whether 'webdev' is activated
        try {
          await package.runPub(
            ['global', 'run', 'webdev', '-h'],
            silent: true,
          );
        } on CommandFailedException {
          // Activate 'webdev'
          await package.runPub(
            ['global', 'activate', 'webdev'],
          );
        }
        // Run 'webdev build'
        await package.runPub(
          ['global', 'run', 'webdev', 'build'],
        );
      } else {
        final dashes = ''.padLeft(80, '-');
        commandStdout?.writeln(dashes);
        commandStdout?.writeln(
          '| Skipping "${_toRelativePath(package.path)}"'.padRight(79, ' ') +
              '|',
        );
        commandStdout?.writeln(dashes);
      }
    }
  }
}
