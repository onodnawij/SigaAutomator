import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:logger/logger.dart";

final logProvider = Provider((ref) => Logger(
  level: Level.info,
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
  ),
));