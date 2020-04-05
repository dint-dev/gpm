# Overview

GPM ("Green Package Manager") is a command-line tool that eases management of multi-package
Dart/Flutter projects.

# Installing
In the command-line, run:
```
pub global activate gpm
```

If you have only Flutter SDK, you can run: `flutter pub global activate gpm`

# Recipes
## List packages
```
gpm list
```

## Get dependencies
To get dependencies for every package, run:
```
gpm get
```

## Test
To test every package, run:
```
gpm test
```

## Build
To build every package, run:
```
gpm build
```

## Upgrade GPM
To upgrade GPM to the latest version, run:
```
gpm upgrade
```

The command just a shorthand for `pub global activate gpm`.

# gpm.yaml
## Packages
By default, _gpm test_ and other commands visit all subdirectories that have _pubspec.yaml_.

You can optionally customize the directories in `gpm.yaml`:
```yaml
packages:
  - path: some/package
  - path: some/other/package
```

## Scripts
You can define cross-platform scripts in `gpm.yaml`:
```yaml
scripts:
  protos:
    steps:
      - run: ["protoc", "--dart-out", "lib/generated/", "example.proto"]
        directory: some/package0
      - run: ["protoc", "--dart-out", "lib/generated/", "example.proto"]
        directory: some/package1
```

Then run:
```
gpm run protos
```