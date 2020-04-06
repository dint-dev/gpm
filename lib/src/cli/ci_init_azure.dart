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

class _CIInitAzureCommand extends Command {
  static const _path = '.azure-pipelines.yml';

  @override
  String get description => 'Configure Azure Pipelines CI ("$_path").';

  @override
  String get name => 'azure';

  @override
  bool get takesArguments => false;

  @override
  Future<void> run() async {
    final file = File.fromUri(Uri.parse(_path));
    print('Writing to: ${file.path}');
    file.writeAsStringSync('''stages:
- stage: Run tests
  jobs:
    - job: Test with Dart SDK
      timeoutInMinutes: 5
      container: google/dart:latest
      steps:
      - displayName: Install GPM
        script: pub global activate gpm $_versionConstraint
      - displayName: Get dependencies (gpm get)
        script: pub global run gpm get
      - displayName: Test (gpm test --platform=vm)
        script: pub global run gpm test --platform=vm
''');
  }
}
