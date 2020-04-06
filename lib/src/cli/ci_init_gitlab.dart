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

class _CIInitGitlabCommand extends Command {
  static const _path = '.gitlab-ci.yml';

  @override
  String get description => 'Configure Gitlab CI ("$_path").';

  @override
  String get name => 'gitlab';

  @override
  bool get takesArguments => false;

  @override
  Future<void> run() async {
    final file = File.fromUri(Uri.parse(_path));
    print('Writing to: ${file.path}');
    file.writeAsStringSync('''image: google/dart:latest

stages:
  - build
  - test

before_script:
  - pub global activate gpm $_versionConstraint
  - pub global run gpm get

build:
  stage: build

  script:
    - pub global run gpm build

unit_test:
  stage: test

  script:
    - pub global run gpm test --platform=vm
''');
  }
}
