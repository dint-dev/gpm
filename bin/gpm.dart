import 'package:args/command_runner.dart';
import 'package:gpm/gpm.dart' as gpm;

Future<void> main(List<String> args) async {
  try {
    await gpm.main(args);
  } on UsageException catch (e) {
    print(e.message);
  }
}
