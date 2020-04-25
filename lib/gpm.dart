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
library gpm;

import 'dart:convert';
import 'dart:io';

import 'package:boolean_selector/boolean_selector.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:yaml/yaml.dart' show loadYaml;

part 'src/gpm/gpm_config.dart';
part 'src/gpm/gpm_package.dart';
part 'src/gpm/gpm_step.dart';
part 'src/gpm/run_command.dart';
