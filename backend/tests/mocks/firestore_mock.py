"""Minimal in-memory Firestore-compatible test double."""

from types import SimpleNamespace
from uuid import uuid4

from firebase_admin import firestore


def _normalise(value):
    if value is firestore.SERVER_TIMESTAMP:
        return None
    if isinstance(value, dict):
        return {key: _normalise(item) for key, item in value.items()}
    if isinstance(value, list):
        return [_normalise(item) for item in value]
    return value


class FakeSnapshot:
    def __init__(self, reference, data):
        self.id = reference.id
        self.reference = reference
        self._data = dict(data) if data is not None else None
        self.exists = data is not None

    def to_dict(self):
        return None if self._data is None else dict(self._data)


class FakeDocument:
    def __init__(self, store, collection, document_id):
        self.store, self.collection_name, self.id = store, collection, document_id

    def set(self, data, merge=False):
        current = self.store.setdefault(self.collection_name, {}).get(self.id, {}) if merge else {}
        current.update(_normalise(data))
        self.store.setdefault(self.collection_name, {})[self.id] = current

    def get(self):
        return FakeSnapshot(self, self.store.get(self.collection_name, {}).get(self.id))

    def update(self, data):
        if self.id not in self.store.get(self.collection_name, {}):
            raise KeyError(self.id)
        self.store[self.collection_name][self.id].update(data)

    def delete(self):
        self.store.get(self.collection_name, {}).pop(self.id, None)

    def collection(self, name):
        return FakeCollection(self.store, f"{self.collection_name}/{self.id}/{name}")


class FakeQuery:
    def __init__(self, store, name, filters=None, limit_count=None):
        self.store, self.name = store, name
        self.filters, self.limit_count = filters or [], limit_count

    def where(self, field, operator, value):
        return FakeQuery(self.store, self.name, self.filters + [(field, operator, value)], self.limit_count)

    def limit(self, count):
        return FakeQuery(self.store, self.name, self.filters, count)

    def stream(self):
        records = []
        for document_id, data in self.store.get(self.name, {}).items():
            if all(operator == "==" and data.get(field) == value for field, operator, value in self.filters):
                records.append(FakeSnapshot(FakeDocument(self.store, self.name, document_id), data))
        return records[:self.limit_count] if self.limit_count is not None else records


class FakeCollection(FakeQuery):
    def document(self, document_id=None):
        return FakeDocument(self.store, self.name, document_id or uuid4().hex)

    def add(self, data):
        reference = self.document()
        reference.set(data)
        return None, reference


class FakeFirestore:
    def __init__(self):
        self.store = {}

    def collection(self, name):
        return FakeCollection(self.store, name)
