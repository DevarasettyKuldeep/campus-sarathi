import '../../repositories/academic_store.dart';

/// Serialises account activation and cleanup. Only one account workspace is
/// active, and in-flight local writes finish before its connection is closed.
class AccountWorkspaces {
  AccountWorkspaces({
    required AcademicStore Function(String accountId) createStore,
  }) : _createStore = createStore;
  final AcademicStore Function(String) _createStore;
  Future<void> _tail = Future<void>.value();
  AcademicStore? _active;
  String? _accountId;
  bool _closed = false;
  Future<void>? _closeFuture;

  Future<T> _serial<T>(Future<T> Function() task) {
    final result = _tail.then((_) => task());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<AcademicStore> open(String accountId) => _serial(() async {
    if (_closed) throw StateError('Account storage is closed.');
    if (_accountId == accountId && _active != null) return _active!;
    await _closeActive();
    final store = _createStore(accountId);
    try {
      await store.initialize();
    } catch (_) {
      await store.close();
      store.dispose();
      rethrow;
    }
    _active = store;
    _accountId = accountId;
    return store;
  });

  Future<void> erase(String accountId) => _serial(() async {
    if (_closed) throw StateError('Account storage is closed.');
    if (_accountId != null && _accountId != accountId) {
      throw StateError('An account cannot erase another active workspace.');
    }
    await _closeActive();
    final store = _createStore(accountId);
    try {
      await store.initialize();
      await store.eraseLocalData();
    } finally {
      await store.close();
      store.dispose();
    }
  });

  Future<void> _closeActive() async {
    final previous = _active;
    if (previous == null) return;
    await previous.close();
    previous.dispose();
    _active = null;
    _accountId = null;
  }

  Future<void> close() {
    _closed = true;
    return _closeFuture ??= _serial(_closeActive);
  }
}
