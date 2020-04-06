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

IOSink commandStderr = stderr;

IOSink commandStdout = stdout;

/// Determines whether command 'pub' is available. In other words, the method
/// checks whether Dart SDK has been installed and properly configured.
final Future<bool> isFlutterCommandAvailable = () async {
  try {
    final process = await Process.start(
      'flutter',
      ['--no-version-check', ' --suppress-analytics', 'help'],
    );
    process.kill();
    return true;
  } on Object {
    return false;
  }
}();

/// Determines whether command 'pub' is available. In other words, the method
/// checks whether Dart SDK has been installed and properly configured.
final Future<bool> isPubCommandAvailable = () async {
  try {
    final process = await Process.start('pub', []);
    process.kill();
    return true;
  } on Object {
    return false;
  }
}();

Future<void> runCommand(
  String executable,
  List<String> args, {
  String workingDirectory,
  Map<String, String> environment,
  bool silent = false,
}) async {
  final stdoutBuffer = <int>[];
  final stderrBuffer = <int>[];
  if (workingDirectory == null) {
    if (!Platform.isWindows) {
      workingDirectory = '.';
    } else {
      workingDirectory ??= Directory.current.path;
    }
  } else if (workingDirectory == '') {
    workingDirectory = '.';
  }

  final relativePath = _toRelativePath(workingDirectory);

  if (!silent) {
    final dashes = ''.padLeft(80, '-');
    commandStdout?.writeln(dashes);
    commandStdout?.writeln(
        '| Running: $executable ${args.join(" ")}'.padRight(79, ' ') + '|');
    commandStdout?.writeln('|      in: $relativePath'.padRight(79, ' ') + '|');
    commandStdout?.writeln(dashes);
  }

  final process = await Process.start(
    executable,
    args,
    workingDirectory: workingDirectory,
    environment: environment,
  );

  process.stdout.listen((data) {
    if (!silent) {
      commandStdout?.add(data);
    }
    stdoutBuffer.addAll(data);
  });

  process.stderr.listen((data) {
    if (!silent) {
      commandStderr?.add(data);
    }
    stderrBuffer.addAll(data);
  });

  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw CommandFailedException(
      exitCode,
      stdout: utf8.decode(stdoutBuffer),
      stderr: utf8.decode(stderrBuffer),
    );
  }
}

String _toRelativePath(String path) {
  var wd = Directory.current.path;
  if (path == wd || path == wd.replaceAll(Platform.pathSeparator, '/')) {
    return '.';
  }
  wd += Platform.pathSeparator;
  if (path.startsWith(wd) ||
      path.startsWith(wd.replaceAll(Platform.pathSeparator, '/'))) {
    return path.substring(wd.length);
  }
  return path;
}

class CommandFailedException implements Exception {
  final int exitCode;
  final String stdout;
  final String stderr;

  CommandFailedException(
    this.exitCode, {
    this.stdout = '',
    this.stderr = '',
  });

  @override
  String toString() => 'CommandFailedException($exitCode, ...)';
}
