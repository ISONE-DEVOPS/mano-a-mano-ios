// Stub para plataformas não-Web: não deve ser chamado fora do Web.
Future<T> promiseToFuture<T>(Object? _) async {
  throw UnsupportedError('promiseToFuture is only available on Web builds.');
}
