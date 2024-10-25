import 'dart:developer';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:projeto_cm_flutter/isar/models.dart' as models;

class IsarService {
  static final IsarService _instance = IsarService._internal();
  late final Isar _isar;

  IsarService._internal();

  factory IsarService() => _instance;

  Future<void> initIsar() async {
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

  Isar get isar => _isar;
}
