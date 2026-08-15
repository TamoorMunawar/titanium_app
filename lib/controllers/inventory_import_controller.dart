import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/inventory_import_repository.dart';
import 'auth_controller.dart';

final inventoryImportRepositoryProvider = Provider<InventoryImportRepository>((ref) {
  return InventoryImportRepository(ref.watch(dioProvider));
});
