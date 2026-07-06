// ignore_for_file: subtype_of_sealed_class, unnecessary_non_null_assertion

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart' hide TransactionHandler;
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_field_value.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> data = {};
  final List<VoidCallback> _listeners = [];
  List<VoidCallback> get listeners => _listeners;

  void _notifyListeners() {
    for (final listener in List.from(_listeners)) {
      listener();
    }
  }

  void setDoc(String path, Map<String, dynamic> docData, [SetOptions? options]) {
    _setDoc(path, docData, options);
    _notifyListeners();
  }

  void updateDoc(String path, Map<String, dynamic> docData) {
    _updateDoc(path, docData);
    _notifyListeners();
  }

  void deleteDoc(String path) {
    _deleteDoc(path);
    _notifyListeners();
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return FakeCollectionReference<Map<String, dynamic>>(collectionPath, this);
  }

  @override
  DocumentReference<Map<String, dynamic>> doc(String documentPath) {
    return FakeDocumentReference<Map<String, dynamic>>(documentPath, this);
  }

  @override
  WriteBatch batch() => FakeWriteBatch(this);

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    final tx = FakeTransaction(this);
    final result = await transactionHandler(tx);
    for (final write in tx._pendingWrites) {
      write();
    }
    _notifyListeners();
    return result;
  }

  void _setDoc(String path, Map<String, dynamic> docData, [SetOptions? options]) {
    final bool merge = options?.merge ?? false;
    final existing = data[path] ?? <String, dynamic>{};
    final Map<String, dynamic> target = merge ? Map<String, dynamic>.from(existing) : <String, dynamic>{};
    _mergeMaps(target, docData);
    data[path] = target;
  }

  void _updateDoc(String path, Map<String, dynamic> docData) {
    final existing = data[path];
    if (existing == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-found',
        message: 'Some requested document was not found.',
      );
    }
    final target = Map<String, dynamic>.from(existing);
    _mergeMaps(target, docData);
    data[path] = target;
  }

  void _deleteDoc(String path) {
    data.remove(path);
  }

  void _mergeMaps(Map<String, dynamic> target, Map<String, dynamic> source) {
    source.forEach((key, value) {
      if (value is FieldValue) {
        final delegate = FieldValuePlatform.getDelegate(value);
        if (delegate is MethodChannelFieldValue) {
          if (delegate.type == FieldValueType.serverTimestamp) {
            target[key] = Timestamp.now();
          } else if (delegate.type == FieldValueType.arrayUnion) {
            final List<dynamic> currentList = List.from(target[key] ?? []);
            for (final item in (delegate.value as List)) {
              if (!currentList.contains(item)) {
                currentList.add(item);
              }
            }
            target[key] = currentList;
          } else if (delegate.type == FieldValueType.arrayRemove) {
            final List<dynamic> currentList = List.from(target[key] ?? []);
            for (final item in (delegate.value as List)) {
              currentList.remove(item);
            }
            target[key] = currentList;
          } else if (delegate.type == FieldValueType.delete) {
            target.remove(key);
          } else if (delegate.type == FieldValueType.incrementInteger ||
                     delegate.type == FieldValueType.incrementDouble) {
            final num currentVal = target[key] ?? 0;
            target[key] = currentVal + (delegate.value as num);
          }
        }
      } else if (value is Map<String, dynamic>) {
        final existingVal = target[key];
        if (existingVal is Map<String, dynamic>) {
          final mergedVal = Map<String, dynamic>.from(existingVal);
          _mergeMaps(mergedVal, value);
          target[key] = mergedVal;
        } else {
          target[key] = value;
        }
      } else {
        target[key] = value;
      }
    });
  }
}

class FakeTransaction extends Fake implements Transaction {
  final FakeFirebaseFirestore _firestore;
  final List<VoidCallback> _pendingWrites = [];

  FakeTransaction(this._firestore);

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> documentReference,
  ) async {
    final snap = await _firestore.doc(documentReference.path).get();
    return snap as DocumentSnapshot<T>;
  }

  @override
  Transaction set<T>(DocumentReference<T> documentReference, T data, [SetOptions? options]) {
    _pendingWrites.add(() {
      _firestore._setDoc(documentReference.path, data as Map<String, dynamic>, options);
    });
    return this;
  }

  @override
  Transaction update(DocumentReference documentReference, Map<Object, Object?> data) {
    _pendingWrites.add(() {
      _firestore._updateDoc(documentReference.path, data.cast<String, dynamic>());
    });
    return this;
  }

  @override
  Transaction delete(DocumentReference documentReference) {
    _pendingWrites.add(() {
      _firestore._deleteDoc(documentReference.path);
    });
    return this;
  }
}

class FakeWriteBatch extends Fake implements WriteBatch {
  final FakeFirebaseFirestore _firestore;
  final List<VoidCallback> _pendingWrites = [];

  FakeWriteBatch(this._firestore);

  @override
  void set<T>(DocumentReference<T> documentReference, T data, [SetOptions? options]) {
    _pendingWrites.add(() {
      _firestore._setDoc(documentReference.path, data as Map<String, dynamic>, options);
    });
  }

  @override
  void update(DocumentReference documentReference, Map<Object, Object?> data) {
    _pendingWrites.add(() {
      _firestore._updateDoc(documentReference.path, data.cast<String, dynamic>());
    });
  }

  @override
  void delete(DocumentReference documentReference) {
    _pendingWrites.add(() {
      _firestore._deleteDoc(documentReference.path);
    });
  }

  @override
  Future<void> commit() async {
    for (final write in _pendingWrites) {
      write();
    }
    _firestore._notifyListeners();
  }
}

class FakeDocumentReference<T extends Object?> extends Fake implements DocumentReference<T> {
  @override
  final String path;
  final FakeFirebaseFirestore _firestore;

  FakeDocumentReference(this.path, this._firestore);

  @override
  String get id => path.split('/').last;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return FakeCollectionReference<Map<String, dynamic>>('$path/$collectionPath', _firestore);
  }

  @override
  Future<DocumentSnapshot<T>> get([GetOptions? options]) async {
    final docData = _firestore.data[path];
    return FakeDocumentSnapshot<T>(path, docData != null ? Map<String, dynamic>.from(docData) : null, this);
  }

  @override
  Future<void> set(T data, [SetOptions? options]) async {
    _firestore._setDoc(path, data as Map<String, dynamic>, options);
    _firestore._notifyListeners();
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    _firestore._updateDoc(path, data.cast<String, dynamic>());
    _firestore._notifyListeners();
  }

  @override
  Future<void> delete() async {
    _firestore._deleteDoc(path);
    _firestore._notifyListeners();
  }

  @override
  Stream<DocumentSnapshot<T>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    late StreamController<DocumentSnapshot<T>> controller;
    void listener() {
      if (controller.isClosed) return;
      final docData = _firestore.data[path];
      controller.add(FakeDocumentSnapshot<T>(path, docData != null ? Map<String, dynamic>.from(docData) : null, this));
    }

    controller = StreamController<DocumentSnapshot<T>>.broadcast(
      onListen: () {
        _firestore._listeners.add(listener);
        listener();
      },
      onCancel: () {
        _firestore._listeners.remove(listener);
      },
    );
    return controller.stream;
  }
}

class FakeDocumentSnapshot<T extends Object?> extends Fake implements DocumentSnapshot<T> {
  final String _path;
  final Map<String, dynamic>? _data;
  final DocumentReference<T> _ref;

  FakeDocumentSnapshot(this._path, this._data, this._ref);

  @override
  String get id => _path.split('/').last;

  @override
  bool get exists => _data != null;

  @override
  T? data() => _data as T?;

  @override
  DocumentReference<T> get reference => _ref;

  @override
  dynamic operator [](Object field) {
    if (_data == null) return null;
    return _data![field];
  }
}

class FakeCollectionReference<T extends Object?> extends FakeQuery<T> implements CollectionReference<T> {
  FakeCollectionReference(super.path, super.firestore);

  @override
  String get id => path.split('/').last;

  @override
  DocumentReference<T> doc([String? path]) {
    final docId = path ?? _uuid.v4();
    final docPath = '${this.path}/$docId';
    return FakeDocumentReference<T>(docPath, firestore);
  }

  @override
  Future<DocumentReference<T>> add(T data) async {
    final d = doc();
    await d.set(data);
    return d;
  }
}

class FakeQuery<T extends Object?> extends Fake implements Query<T> {
  final String path;
  final FakeFirebaseFirestore firestore;
  final List<bool Function(String id, Map<String, dynamic> data)> _filters;
  final List<int Function(Map<String, dynamic> a, Map<String, dynamic> b)> _sorts;
  final int? _limit;

  FakeQuery(this.path, this.firestore, [this._filters = const [], this._sorts = const [], this._limit]);

  @override
  Query<T> where(Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    final filters = List<bool Function(String id, Map<String, dynamic> data)>.from(_filters);
    filters.add((id, data) {
      dynamic val;
      if (field == FieldPath.documentId) {
        val = id;
      } else if (field is FieldPath) {
        if (field.toString() == 'FieldPath([__name__])') {
          val = id;
        } else {
          val = _getValueForFieldPath(data, field);
        }
      } else if (field is String) {
        val = _getValueForFieldPath(data, FieldPath([field]));
      } else {
        val = data[field.toString()];
      }

      if (isEqualTo != null) {
        return val == isEqualTo;
      }
      if (isNotEqualTo != null) {
        return val != isNotEqualTo;
      }
      if (isLessThan != null) {
        if (val == null) return false;
        return (val as Comparable).compareTo(isLessThan) < 0;
      }
      if (isLessThanOrEqualTo != null) {
        if (val == null) return false;
        return (val as Comparable).compareTo(isLessThanOrEqualTo) <= 0;
      }
      if (isGreaterThan != null) {
        if (val == null) return false;
        return (val as Comparable).compareTo(isGreaterThan) > 0;
      }
      if (isGreaterThanOrEqualTo != null) {
        if (val == null) return false;
        return (val as Comparable).compareTo(isGreaterThanOrEqualTo) >= 0;
      }
      if (arrayContains != null) {
        if (val is! List) return false;
        return val.contains(arrayContains);
      }
      if (isNull != null) {
        return (val == null) == isNull;
      }
      return true;
    });

    return FakeQuery<T>(path, firestore, filters, _sorts, _limit);
  }

  dynamic _getValueForFieldPath(Map<String, dynamic> data, FieldPath path) {
    final str = path.toString();
    final match = RegExp(r'FieldPath\(\[(.*)\]\)').firstMatch(str);
    if (match != null) {
      final partsStr = match.group(1)!;
      final parts = partsStr.split(',').map((p) => p.trim()).toList();
      dynamic current = data;
      for (final part in parts) {
        if (current is Map) {
          current = current[part];
        } else {
          return null;
        }
      }
      return current;
    }
    return data[str];
  }

  @override
  Query<T> orderBy(Object field, {bool descending = false}) {
    final sorts = List<int Function(Map<String, dynamic> a, Map<String, dynamic> b)>.from(_sorts);
    sorts.add((a, b) {
      final fieldName = field is FieldPath ? field.toString() : field.toString();
      final valA = a[fieldName] as Comparable?;
      final valB = b[fieldName] as Comparable?;
      if (valA == null && valB == null) return 0;
      if (valA == null) return descending ? 1 : -1;
      if (valB == null) return descending ? -1 : 1;
      final cmp = valA.compareTo(valB);
      return descending ? -cmp : cmp;
    });
    return FakeQuery<T>(path, firestore, _filters, sorts, _limit);
  }

  @override
  Query<T> limit(int value) {
    return FakeQuery<T>(path, firestore, _filters, _sorts, value);
  }

  List<QueryDocumentSnapshot<T>> _getDocs() {
    final List<QueryDocumentSnapshot<T>> results = [];
    final prefix = '$path/';
    firestore.data.forEach((docPath, docData) {
      if (docPath.startsWith(prefix)) {
        final subPath = docPath.substring(prefix.length);
        if (!subPath.contains('/')) {
          final id = subPath;
          bool matches = true;
          for (final filter in _filters) {
            if (!filter(id, docData)) {
              matches = false;
              break;
            }
          }
          if (matches) {
            results.add(
              FakeQueryDocumentSnapshot<T>(
                docPath,
                Map<String, dynamic>.from(docData),
                FakeDocumentReference<T>(docPath, firestore),
              ),
            );
          }
        }
      }
    });

    if (_sorts.isNotEmpty) {
      results.sort((a, b) {
        final dataA = a.data() as Map<String, dynamic>;
        final dataB = b.data() as Map<String, dynamic>;
        for (final sort in _sorts) {
          final res = sort(dataA, dataB);
          if (res != 0) return res;
        }
        return 0;
      });
    }

    if (_limit != null && results.length > _limit) {
      return results.sublist(0, _limit);
    }

    return results;
  }

  @override
  Future<QuerySnapshot<T>> get([GetOptions? options]) async {
    return FakeQuerySnapshot<T>(_getDocs());
  }

  @override
  Stream<QuerySnapshot<T>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    late StreamController<QuerySnapshot<T>> controller;
    void listener() {
      if (controller.isClosed) return;
      controller.add(FakeQuerySnapshot<T>(_getDocs()));
    }

    controller = StreamController<QuerySnapshot<T>>.broadcast(
      onListen: () {
        firestore._listeners.add(listener);
        listener();
      },
      onCancel: () {
        firestore._listeners.remove(listener);
      },
    );
    return controller.stream;
  }
}

class FakeQuerySnapshot<T extends Object?> extends Fake implements QuerySnapshot<T> {
  @override
  final List<QueryDocumentSnapshot<T>> docs;

  FakeQuerySnapshot(this.docs);

  @override
  List<DocumentChange<T>> get docChanges => [];
}

class FakeQueryDocumentSnapshot<T extends Object?> extends Fake implements QueryDocumentSnapshot<T> {
  final String _path;
  final Map<String, dynamic> _data;
  final DocumentReference<T> _ref;

  FakeQueryDocumentSnapshot(this._path, this._data, this._ref);

  @override
  String get id => _path.split('/').last;

  @override
  bool get exists => true;

  @override
  T data() => _data as T;

  @override
  DocumentReference<T> get reference => _ref;

  @override
  dynamic operator [](Object field) => _data[field];
}
