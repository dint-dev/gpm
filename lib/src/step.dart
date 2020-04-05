part of gpm;

class GpmStep {
  String description;
  String platform;
  String directory;
  Map<String, String> environment;
  List<String> run;
  String fail;
  List<GpmStep> steps;

  GpmStep();

  factory GpmStep.fromYaml(Object yaml, {List<String> path}) {
    path ??= const <String>[];
    if (yaml is Map) {
      final result = GpmStep();
      for (var entry in yaml.entries) {
        final key = entry.key as String;
        switch (key) {
          case 'description':
            result.description = entry.value as String;
            break;
          case 'platform':
            result.platform = entry.value as String;
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
          case 'run':
            result.run =
                (entry.value as List).map<String>((e) => e as String).toList();
            break;
          case 'fail':
            result.fail = entry.value as String;
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
      print('ERROR: $fail');
      if (Platform.isWindows) {
        throw _ExitException(50);
      } else {
        throw _ExitException(1);
      }
    }

    environment ??= const <String, String>{};
    if (this.environment != null) {
      environment = Map<String, String>.from(environment);
      environment.addAll(this.environment);
    }
    workingDirectory = directory ?? workingDirectory;

    final run = this.run;
    if (run != null) {
      final executable = run.first;
      final runArgs = <String>[];
      for (var arg in run.skip(1)) {
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
      await _runCommand(
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
}
