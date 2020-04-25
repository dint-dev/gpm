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

class _GetCommand extends Command {
  _GetCommand() {
    argParser.addFlag('offline');
    argParser.addFlag('link');
  }

  @override
  String get description => 'Get dependencies for each package.';

  @override
  String get name => 'get';

  @override
  bool get takesArguments => false;

  @override
  Future<void> run() async {
    final args = ['get'];
    final offline = argResults['offline'];
    if (offline) {
      args.add('--offline');
    }
    final link = argResults['link'];
    args.addAll(argResults.rest);
    final packages = GpmConfig.get().packages;
    for (var package in packages) {
      await package.runPub(args);

      if (link) {
        await package.link(packages);
      }
    }
  }
}
