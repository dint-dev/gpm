[![Pub Package](https://img.shields.io/pub/v/gpm.svg)](https://pub.dartlang.org/packages/gpm)
[![Github Actions CI](https://github.com/dint-dev/gpm/workflows/Dart%20CI/badge.svg)](https://github.com/dint-dev/gpm/actions?query=workflow%3A%22Dart+CI%22)

# Overview

GPM ("General Package Manager") is a programming tool designed for monorepos (multi-package
repositories). GPM automatically discovers packages and infers how to test/build them.
You can optionally write `.gpm.yaml` configuration files.

## Links
  * [Pub package](https://pub.dev/packages/gpm)
  * [Issue tracker](https://github.com/dint-dev/gpm/issues)

## Alternatives
  * Custom test/build scripts (Bash, Dart, etc.).
    * GPM saves time and is less error-prone.
  * CI tools
    * GPM is just a simple command-line tool that developers can use in their local development
      machine. It doesn't replace CI tools. GPM can be used to generate configurations for CI tools.
  * [mono_repo](https://pub.dev/packages/mono_repo)
    * _mono_repo_ appears to be focused on running Travis CI tests locally.

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

## Link packages
```
gpm get --link
```

The above command will do `gpm get` and link all local packages together.

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


# Optional configuration file
## Filename
The following filenames are supported:
  * _.gpm.yaml_
  * _gpm.yaml_

## Defining packages
By default, GPM assumes that every directory that contains _pubspec.yaml_ is a package.
Packages are currently handled in alphabetical order.

You can customize this in `gpm.yaml`:
```yaml
packages:
  - path: some/package
    # Override default test step(s)
    test:
      run: flutter test
    # Override default build step(s)
    build:
      steps:
        - run: flutter build apk
        - run: flutter build ios
        - run: flutter build web

  - path: some/other/package
```

## Defining scripts
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
  * `"a b c"` (a quoted argument)
  * `"\@\(\)"` (escape character "\\" works inside a quoted argument)
  * `$(ENV_VAR)` (an environmental variable)
  * `@(a/b/c)` (replaces "/" with "\" in Windows)
