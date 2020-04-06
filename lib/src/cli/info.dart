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

class _InfoCommand extends Command {
  @override
  String get description => 'Show all packages in the directory tree.';

  @override
  String get name => 'info';

  @override
  bool get takesArguments => false;

  @override
  Future<void> run() async {
    for (var package in GpmConfig.get().packages) {
      final line = _toRelativePath(package.path).padRight(60);
      print('$line(${package.isFlutter ? "Flutter SDK" : "Dart SDK"})');
    }
  }
}
