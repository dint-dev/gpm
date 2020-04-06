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

/// A command-line tool for working with monorepos.
library gpm.cli;

import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import 'gpm.dart';

part 'src/cli/build.dart';
part 'src/cli/ci.dart';
part 'src/cli/ci_init_azure.dart';
part 'src/cli/ci_init_github.dart';
part 'src/cli/ci_init_gitlab.dart';
part 'src/cli/ci_init_travis.dart';
part 'src/cli/get.dart';
part 'src/cli/info.dart';
part 'src/cli/main.dart';
part 'src/cli/run.dart';
part 'src/cli/test.dart';
part 'src/cli/version.dart';
