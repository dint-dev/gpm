[![Pub Package](https://img.shields.io/pub/v/gpm.svg)](https://pub.dartlang.org/packages/gpm)
[![Github Actions CI](https://github.com/dint-dev/gpm/workflows/Dart%20CI/badge.svg)](https://github.com/dint-dev/gpm/actions?query=workflow%3A%22Dart+CI%22)

# Overview

GPM ("General Package Manager") is a command-line tool for working with Dart/Flutter repositories.

By default, GPM assumes that every package found in the directory tree is part of the project. You
can optionally write `.gpm.yaml` configuration file.

## Alternatives
  * Writing shell scripts (or Dart scripts).
    * GPM is faster to set up.
  * Setting up a CI tool.
    * GPM is a lightweight tool that doesn't replace a CI server.
  * [pub.dev/packages/mono_repo](https://pub.dev/packages/mono_repo)
    * _mono_repo_ is focused on running Travis CI locally.

## Links
  * [Pub package](https://pub.dev/packages/gpm)
  * [Issue tracker](https://github.com/dint-dev/gpm/issues)

# Installing
Then run:
```
pub global activate gpm
```

Alternatively, if you have only Flutter SDK installed, you can run:
`flutter pub global activate gpm`

Test installation by running `gpm`. If you haven't configured your PATH environmental variable
properly (see Dart SDK / Flutter SDK instructions), attempting to run GPM will give you a "command
not found" error message. In this case, you can still use GPM by running `pub global run gpm` (or
`flutter pub global run gpm`).

# Examples
## Show packages in the directory tree
```
gpm info
```

The command will show debug information.

## Get dependencies
```
gpm get
```

The above command will run:
  * `flutter pub get` (for each Flutter SDK package)
  * `pub get` (for each Dart SDK package)

## Test
```
gpm test
```

The above command will run:
  * `flutter test` (for each Flutter SDK package, when `flutter_test` dependency is found)
  * `flutter pub run test` (for each Flutter SDK package, when `flutter_test` dependency is not found)
  * `pub run test` (for each Dart SDK package)

## Build
```
gpm build
```

The above command will run:
  * `flutter build apk` (for each Flutter SDK package that has `android` directory)
  * `flutter build ios` (for each Flutter SDK package that has `ios` directory)
  * `flutter build web` (for each Flutter SDK package that has `web` directory)
  * `pub global run webdev build` (for each Dart SDK package that has `web` directory)
    * If `webdev` is not activated, it activates it.

## Initialize CI configuration
### Azure Pipelines
```
gpm ci init azure
```

This will generate ".ci/.azure-pipelines.yml".

### Github Actions
```
gpm ci init github
```

This will generate ".github/workflows/dart.yml".

### Gitlab CI
```
gpm ci init gitlab
```

This will generate ".gitlab-ci.yml".

### Travis
```
gpm ci init travis
```

This will generate ".travis-ci.yml".

## Upgrade GPM to the latest version
```
gpm upgrade
```

This is just a shorthand for `pub global activate gpm`.


## Choosing packages manually
By default, GPM assumes that every directory that contains _pubspec.yaml_ is a package.
Packages are currently handled in alphabetical order.

You can customize this in `gpm.yaml`:
```yaml
packages:
  - path: some/package
  - path: some/other/package
```

## Running scripts
In `gpm.yaml`:
```yaml
scripts:
  protos:
    description: Generates Dart files from Protocol Buffers definitions.
    steps:
        # Define working directory
      - directory: some/directory

        # Run 'protoc' command.
        # @(X) causes every "/" in X to be replaced with "\" when running in Windows.
        run: protoc --dart-out @(lib/generated/) definition.proto

        # You could optionally define platform:
        # platform: "posix || windows"


        # Another step
      - directory: some/directory
        run: protoc --dart-out @(lib/generated/) another_definition.proto
```

Then run:
```
gpm run protos
```

Syntax rules for _run_ are:
  * `cmd "a b c" arg1 arg2` (quoted arguments)
  * `cmd "\@\(\)" arg1 arg2` (escape character "\" works inside quoted arguments)
  * `cmd $(ENV_VAR) arg1 arg2` (environmental variables)
  * `cmd @(a/b/c) arg1 arg2` (slash replacement for supporting Windows)