const assert = require('node:assert/strict');
const fs = require('node:fs');
const test = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, Timestamp } = require('firebase/firestore');

let environment;

test.before(async () => {
  environment = await initializeTestEnvironment({
    projectId: 'demo-lume',
    firestore: {
      rules: fs.readFileSync('../firestore.rules', 'utf8'),
    },
  });
});

test.after(async () => {
  await environment.cleanup();
});

test('owner can write a named shopping list and item', async () => {
  const db = environment.authenticatedContext('user-1').firestore();
  const now = Timestamp.fromDate(new Date('2026-08-24T12:00:00.000Z'));
  await assertSucceeds(setDoc(doc(db, 'users/user-1/shopping_lists/work'), {
    name: 'Trabalho',
    createdAt: now,
    updatedAt: now,
    schemaVersion: 1,
  }));
  await assertSucceeds(setDoc(doc(db, 'users/user-1/shopping_lists/work/items/item-1'), {
    listId: 'work',
    name: 'Caderno',
    quantity: '1',
    isChecked: false,
    position: 0,
    createdAt: now,
    updatedAt: now,
    schemaVersion: 1,
  }));
});

test('another UID cannot read the owner list', async () => {
  const db = environment.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(db, 'users/user-1/shopping_lists/work')));
  const other = environment.authenticatedContext('user-2').firestore();
  await assertFails(getDoc(doc(other, 'users/user-1/shopping_lists/work')));
});

test('unknown fields and mismatched item list are rejected', async () => {
  const db = environment.authenticatedContext('user-1').firestore();
  const now = Timestamp.fromDate(new Date('2026-08-24T12:00:00.000Z'));
  await assertFails(setDoc(doc(db, 'users/user-1/shopping_lists/work'), {
    name: 'Trabalho',
    unexpected: true,
    createdAt: now,
    updatedAt: now,
    schemaVersion: 1,
  }));
  await assertFails(setDoc(doc(db, 'users/user-1/shopping_lists/work/items/bad'), {
    listId: 'other',
    name: 'Item',
    quantity: '1',
    isChecked: false,
    position: 0,
    createdAt: now,
    updatedAt: now,
    schemaVersion: 1,
  }));
});
