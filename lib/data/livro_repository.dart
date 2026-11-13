import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/livro.dart';

class LivroFailure implements Exception {
  const LivroFailure(this.message);
  final String message;
}

/// Acesso aos livros de um usuário. O UID sempre vem da sessão autenticada.
abstract class LivroRepository {
  Stream<List<Livro>> watch(String uid);
  Future<void> create(String uid, Livro livro);
  Future<void> update(String uid, Livro livro);
  Future<void> delete(String uid, String livroId);
}

/// Estrutura: users/{uid}/books/{bookId}
class FirestoreLivroRepository implements LivroRepository {
  FirestoreLivroRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _books(String uid) =>
      _db.collection('users').doc(uid).collection('books');

  @override
  Stream<List<Livro>> watch(String uid) => _books(uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((doc) => Livro.fromMap(doc.id, doc.data())).toList())
      .handleError((Object error) => throw _failure(error));

  @override
  Future<void> create(String uid, Livro livro) =>
      _execute(() => _books(uid).add({
            ...livro.toMap(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }));

  @override
  Future<void> update(String uid, Livro livro) =>
      _execute(() => _books(uid).doc(livro.id).update({
            ...livro.toMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          }));

  @override
  Future<void> delete(String uid, String livroId) =>
      _execute(() => _books(uid).doc(livroId).delete());

  Future<void> _execute(Future<void> Function() action) async {
    try {
      await action().timeout(const Duration(seconds: 20));
    } catch (error) {
      throw _failure(error);
    }
  }

  static LivroFailure _failure(Object error) {
    if (error is LivroFailure) return error;
    if (error is FirebaseException) {
      return LivroFailure(messageForFirestoreCode(error.code));
    }
    return LivroFailure(messageForFirestoreCode('timeout'));
  }
}

String messageForFirestoreCode(String code) => switch (code) {
      'permission-denied' ||
      'unauthenticated' =>
        'Você não tem permissão para acessar estes dados. Entre novamente.',
      'unavailable' ||
      'deadline-exceeded' ||
      'timeout' =>
        'Sem conexão com o servidor. Verifique sua internet e tente novamente.',
      'not-found' => 'Este livro não existe mais na sua estante.',
      'invalid-argument' ||
      'failed-precondition' =>
        'Os dados do livro são inválidos. Revise os campos.',
      'resource-exhausted' =>
        'Muitas operações em pouco tempo. Aguarde e tente novamente.',
      _ => 'Não foi possível concluir a operação. Tente novamente.',
    };
