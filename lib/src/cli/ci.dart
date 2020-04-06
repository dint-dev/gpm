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

class _CICommand extends Command {
  _CICommand() {
    addSubcommand(_CIInitCommand());
  }

  @override
  String get description => 'Manage CI configurations.';

  @override
  String get name => 'ci';
}

class _CIInitCommand extends Command {
  _CIInitCommand() {
    addSubcommand(_CIInitAzureCommand());
    addSubcommand(_CIInitGithubCommand());
    addSubcommand(_CIInitGitlabCommand());
    addSubcommand(_CIInitTravisCommand());
  }

  @override
  String get description => 'Initialize CI configuration.';

  @override
  String get name => 'init';
}
