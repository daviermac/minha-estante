// Testes das Firestore Security Rules com o Firebase Emulator.
// Executar: cd test/firestore_rules && npm install && npm test
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

let env;
const book = (extra = {}) => ({
  title: 'Dom Casmurro',
  author: 'Machado de Assis',
  genre: 'Romance',
  status: 'lendo',
  rating: 4,
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  ...extra,
});

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-minha-estante',
    firestore: { rules: readFileSync('../../firestore.rules', 'utf8') },
  });
});
after(() => env.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  // Livro da conta A criado sem passar pelas regras.
  await env.withSecurityRulesDisabled((ctx) =>
    setDoc(doc(ctx.firestore(), 'users/contaA/books/livroA'), {
      ...book(),
      createdAt: new Date(),
      updatedAt: new Date(),
    }),
  );
});

const dbA = () => env.authenticatedContext('contaA').firestore();
const dbB = () => env.authenticatedContext('contaB').firestore();
const dbAnon = () => env.unauthenticatedContext().firestore();

test('Conta A lê, cria, edita e exclui os próprios livros', async () => {
  await assertSucceeds(getDocs(collection(dbA(), 'users/contaA/books')));
  await assertSucceeds(setDoc(doc(dbA(), 'users/contaA/books/novo'), book()));
  await assertSucceeds(
    updateDoc(doc(dbA(), 'users/contaA/books/livroA'), {
      title: 'Quincas Borba',
      updatedAt: serverTimestamp(),
    }),
  );
  await assertSucceeds(deleteDoc(doc(dbA(), 'users/contaA/books/livroA')));
});

test('Conta B não lê a lista nem o documento da conta A', async () => {
  await assertFails(getDocs(collection(dbB(), 'users/contaA/books')));
  await assertFails(getDoc(doc(dbB(), 'users/contaA/books/livroA')));
});

test('Conta B não cria, edita nem exclui livros da conta A', async () => {
  await assertFails(setDoc(doc(dbB(), 'users/contaA/books/invasao'), book()));
  await assertFails(
    updateDoc(doc(dbB(), 'users/contaA/books/livroA'), {
      title: 'Alterado por B',
      updatedAt: serverTimestamp(),
    }),
  );
  await assertFails(deleteDoc(doc(dbB(), 'users/contaA/books/livroA')));
});

test('Sem autenticação nada é acessível', async () => {
  await assertFails(getDocs(collection(dbAnon(), 'users/contaA/books')));
  await assertFails(setDoc(doc(dbAnon(), 'users/contaA/books/x'), book()));
});

test('Dados inválidos e campos extras são recusados', async () => {
  await assertFails(
    setDoc(doc(dbA(), 'users/contaA/books/x'), book({ rating: 9 })),
  );
  await assertFails(
    setDoc(doc(dbA(), 'users/contaA/books/x'), book({ status: 'outro' })),
  );
  await assertFails(
    setDoc(doc(dbA(), 'users/contaA/books/x'), book({ title: '' })),
  );
  await assertFails(
    setDoc(doc(dbA(), 'users/contaA/books/x'), book({ ownerUid: 'contaB' })),
  );
});

test('Outros caminhos do banco são negados', async () => {
  await assertFails(getDoc(doc(dbA(), 'users/contaA')));
  await assertFails(setDoc(doc(dbA(), 'qualquer/coisa'), { a: 1 }));
});
