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

part of gpm;

/// A script node in [GpmConfig].
class GpmStep {
  /// Description.
  String description;

  /// Platform selector.
  String platform;

  /// Working directory.
  String directory;

  /// Environmental variables.
  Map<String, String> environment;

  /// Command that will be executed.
  String run;

  /// Error message that will be thrown.
  String fail;

  /// Steps that make this step.
  ///
  /// If [platform] does not match, the steps are ignored.
  /// Possible [environment] or [directory] of the parent step is inherited by
  /// every child step.
  List<GpmStep> steps;

  GpmStep();

  /// Decodes YAML.
  factory GpmStep.fromYaml(Object yaml, {@required List<String> path}) {
    path ??= const <String>[];
    if (yaml is Map) {
      final result = GpmStep();
      for (var entry in yaml.entries) {
        final key = entry.key as String;
        switch (key) {
          case 'description':
            result.description = entry.value as String;
            break;
          case 'directory':
            result.directory = entry.value as String;
            break;
          case 'environment':
            final environment = <String, String>{};
            for (var entry in (entry.value as Map).entries) {
              environment[entry.key as String] = entry.value as String;
            }
            result.environment = environment;
            break;
          case 'fail':
            result.fail = entry.value as String;
            break;
          case 'platform':
            result.platform = entry.value as String;
            break;
          case 'run':
            result.run = entry.value as String;
            break;
          case 'steps':
            final steps = <GpmStep>[];
            var index = 0;
            for (var yaml in entry.value as List) {
              steps.add(GpmStep.fromYaml(yaml, path: [...path, '$index']));
              index++;
            }
            result.steps = steps;
            break;
          default:
            throw StateError('Unsupported key "$key" in /${path.join("/")}');
        }
      }
      return result;
    } else {
      throw ArgumentError.value(yaml);
    }
  }

  bool get isPlatformTrue {
    final platform = this.platform;
    if (platform == null || platform.trim().isEmpty) {
      return true;
    }
    final selector = BooleanSelector.parse(platform);
    return selector.evaluate((variable) {
      switch (variable) {
        case 'linux':
          return Platform.isLinux;
        case 'mac-os':
          return Platform.isMacOS;
        case 'posix':
          return !Platform.isWindows;
        case 'windows':
          return Platform.isWindows;
        default:
          throw ArgumentError.value(variable);
      }
    });
  }

  Future<void> execute(
    List<String> args, {
    Map<String, String> environment,
    String workingDirectory,
  }) async {
    if (!isPlatformTrue) {
      return;
    }

    final fail = this.fail;
    if (fail != null) {
      commandStdout?.writeln('ERROR: $fail');
      if (Platform.isWindows) {
        throw CommandFailedException(50);
      } else {
        throw CommandFailedException(1);
      }
    }

    environment ??= Platform.environment;
    if (this.environment != null) {
      environment = Map<String, String>.from(environment);
      environment.addAll(this.environment);
    }
    workingDirectory = directory ?? workingDirectory;

    final run = this.run;
    if (run != null) {
      final parts = evaluateTemplate(run, environment: environment);
      final executable = parts.first;
      final runArgs = <String>[];
      for (var arg in parts.skip(1)) {
        if (arg.startsWith(r'$')) {
          final name = arg.substring(1);
          switch (name) {
            case r'ARGS':
              runArgs.addAll(args);
              break;
            default:
              runArgs.add(environment[name].toString());
              break;
          }
        } else {
          runArgs.add(arg);
        }
      }
      await runCommand(
        executable,
        runArgs,
        environment: environment,
        workingDirectory: workingDirectory,
      );
    }

    final steps = this.steps;
    if (steps != null) {
      for (var step in steps) {
        await step.execute(
          args,
          environment: environment,
          workingDirectory: workingDirectory,
        );
      }
    }
  }

  Map<String, Object> toYaml() {
    final yaml = <String, Object>{};
    if (description != null) {
      yaml['description'] = description;
    }
    if (platform != null) {
      yaml['platform'] = platform;
    }
    if (directory != null) {
      yaml['directory'] = directory;
    }
    if (environment != null) {
      yaml['environment'] = environment;
    }
    if (run != null) {
      yaml['run'] = run;
    }
    if (fail != null) {
      yaml['fail'] = fail;
    }
    if (steps != null) {
      yaml['steps'] = steps.map((e) => e.toYaml()).toList();
    }
    return yaml;
  }

  static List<String> evaluateTemplate(
    String s, {
    @required Map<String, String> environment,
    String pathSeparator,
  }) {
    pathSeparator ??= Platform.pathSeparator;
    s = s.trim();
    final result = <String>[];
    final sb = StringBuffer();
    var isQuoted = false;
    var isArgument = false;
    for (var i = 0; i < s.length; i++) {
      if (!isQuoted && s.startsWith(' ', i)) {
        if (isArgument) {
          // End of argument
          result.add(sb.toString());
          sb.clear();
          isArgument = false;
        }
      } else {
        isArgument = true;
        if (s.startsWith('"', i)) {
          // Possibly start/end of quoted argument
          isQuoted = !isQuoted;
        } else if (isQuoted && s.startsWith(r'\', i)) {
          // Escaped character
          sb.write(s.substring(i + 1, i + 2));
          i++;
        } else if (s.startsWith('@(', i)) {
          // File path where '/' is replaced with path separator
          final end = s.indexOf(')', i + 2);
          final path = s.substring(i + 2, end);
          sb.write(path.replaceAll('/', pathSeparator));
          i = end;
        } else if (s.startsWith(r'$(', i)) {
          // Environmental variable
          final end = s.indexOf(')', i + 2);
          final name = s.substring(i + 2, end);
          final value = environment[name];
          if (value == null) {
            throw StateError('Environmental variable "$name" is undefined');
          }
          sb.write(value);
          i = end;
        } else {
          // Ordinary character
          sb.write(s.substring(i, i + 1));
        }
      }
    }

    // Last argument
    if (isArgument) {
      result.add(sb.toString());
    }

    return result;
  }
}
