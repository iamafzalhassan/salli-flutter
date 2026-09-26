import 'dart:convert';

import 'package:hive_ce/hive_ce.dart';

class MockStore {
  final Map<String, Future<void>> _pending = {};

  final Map<String, Map<String, Map<String, dynamic>>> _collections = {};

  final Box<String> _box;

  MockStore(this._box);

  List<Map<String, dynamic>> all(String collection) => _collection(collection).values.toList();

  List<MapEntry<String, Map<String, dynamic>>> entries(String collection) => _collection(collection).entries.toList();

  Map<String, dynamic>? find(String collection, String id) => _collection(collection)[id];

  Future<void> put(String collection, String id, Map<String, dynamic> document) async {
    _collection(collection)[id] = document;
    await _persist(collection);
  }

  Future<void> remove(String collection, String id) async {
    _collection(collection).remove(id);
    await _persist(collection);
  }

  Future<void> reset() async {
    _collections.clear();
    await _box.clear();
  }

  Map<String, Map<String, dynamic>> _collection(String name) => _collections.putIfAbsent(name, () => _decode(_box.get(name)));

  Map<String, Map<String, dynamic>> _decode(String? raw) => raw == null ? {} : {for (final entry in (jsonDecode(raw) as Map<String, dynamic>).entries) entry.key: entry.value as Map<String, dynamic>};

  Future<void> _persist(String collection) => _pending[collection] ??= Future(() {
    _pending.remove(collection);
    return _box.put(collection, jsonEncode(_collections[collection]));
  });
}
