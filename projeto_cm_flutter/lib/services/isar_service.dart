import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:projeto_cm_flutter/isar/models.dart' as models;

class IsarService {
  static Isar? _isar;

  static Future<Isar> getInstance() async {
    if (_isar == null) {
      final dir = await getApplicationDocumentsDirectory();
      _isar = await Isar.open(
        [
          models.StopSchema,
          models.RouteSchema,
          models.BusSchema,
          models.BusStopSchema,
        ],
        directory: dir.path,
      );
    }
    return _isar!;
  }
}
