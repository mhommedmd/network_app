import 'package:flutter/foundation.dart';

@immutable
class StoredCode {
  const StoredCode({
    required this.packageCode,
    required this.packageName,
    required this.codeNumber,
  });
  final String packageCode;
  final String packageName;
  final String codeNumber;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StoredCode &&
        other.packageCode == packageCode &&
        other.packageName == packageName &&
        other.codeNumber == codeNumber;
  }

  @override
  int get hashCode => Object.hash(packageCode, packageName, codeNumber);
}

class InventoryRepository extends ChangeNotifier {
  InventoryRepository._();
  static final InventoryRepository instance = InventoryRepository._();

  final List<StoredCode> _ownerCodes = [
    const StoredCode(
      packageCode: 'PCK-001',
      packageName: 'باقــة أساسية',
      codeNumber: '1234-5678-9012',
    ),
    const StoredCode(
      packageCode: 'PCK-002',
      packageName: 'باقــة مميزة',
      codeNumber: '2234-6678-0012',
    ),
    const StoredCode(
      packageCode: 'PCK-003',
      packageName: 'باقــة بريميوم',
      codeNumber: '3234-7678-1012',
    ),
  ];

  final List<StoredCode> _posCodes = [];

  List<StoredCode> get ownerCodes => List.unmodifiable(_ownerCodes);
  List<StoredCode> get posCodes => List.unmodifiable(_posCodes);

  void importCodes(List<StoredCode> codes) {
    _ownerCodes.addAll(codes);
    notifyListeners();
  }

  void deleteCode(StoredCode code) {
    _ownerCodes.removeWhere((c) => c == code);
    notifyListeners();
  }

  void deleteAllForPackage(String packageName) {
    _ownerCodes.removeWhere((c) => c.packageName == packageName);
    notifyListeners();
  }

  /// Moves up to [count] codes of [packageName] from owner to POS inventory.
  /// Returns how many were actually moved.
  int moveCodesToPos({required String packageName, required int count}) {
    if (count <= 0) return 0;
    final moved = <StoredCode>[];
    for (var i = _ownerCodes.length - 1; i >= 0 && moved.length < count; i--) {
      final c = _ownerCodes[i];
      if (c.packageName == packageName) {
        moved.add(c);
        _ownerCodes.removeAt(i);
      }
    }
    if (moved.isNotEmpty) {
      _posCodes.addAll(moved);
      notifyListeners();
    }
    return moved.length;
  }
}
