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

class _CIInitGithubCommand extends Command {
  static const _path = '.github/workflows/dart.yml';

  @override
  String get description => 'Configure Github Actions CI ("$_path").';

  @override
  String get name => 'github';

  @override
  bool get takesArguments => false;

  @override
  Future<void> run() async {
    final file = File.fromUri(Uri.parse(_path));
    print('Writing to: ${file.path}');
    file.writeAsStringSync('''name: Dart CI

on: [push]

jobs:
  build:

    runs-on: ubuntu-latest

    container:
      image:  google/dart:latest

    steps:
      - uses: actions/checkout@v1

      - name: Install GPM
        run: pub global activate gpm $_versionConstraint
        
      - name: Get dependencies (gpm get)
        run: pub global run gpm get

      - name: Run tests (gpm test --platform=vm)
        run: pub global run gpm test --platform=vm
''');
  }
}
