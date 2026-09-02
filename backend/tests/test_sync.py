"""Fast in-memory offline synchronization tests."""

from datetime import datetime, timezone

import pytest

from app.core.outbox_manager import OutboxManager
from app.services.sync_service import SyncService


@pytest.fixture
def sync_pair():
    outbox = OutboxManager()
    return outbox, SyncService(outbox)


def test_offline_writes_go_to_outbox(sync_pair):
    outbox, _ = sync_pair
    outbox.enqueue("games", {"id": "game-1"})
    assert len(outbox.pending()) == 1


def test_outbox_entries_are_persisted(sync_pair):
    outbox, _ = sync_pair
    entry = outbox.enqueue("reminders", {"id": "r-1"})
    assert outbox.all_entries()[0]["id"] == entry


def test_sync_sends_outbox_entries(sync_pair):
    outbox, service = sync_pair
    outbox.enqueue("memory", {"id": "m-1"})
    sent = []
    service.sync(lambda collection, data: sent.append((collection, data)))
    assert sent == [("memory", {"id": "m-1"})]


def test_sync_marks_entries_completed(sync_pair):
    outbox, service = sync_pair
    entry = outbox.enqueue("events", {})
    service.sync(lambda *_: None)
    assert outbox.all_entries()[0]["id"] == entry and not outbox.pending()


def test_duplicate_entries_are_handled(sync_pair):
    outbox, _ = sync_pair
    first = outbox.enqueue("events", {"value": 1}, "same")
    second = outbox.enqueue("events", {"value": 2}, "same")
    assert first == second and len(outbox.all_entries()) == 1


def test_last_write_wins_conflict(sync_pair):
    _, service = sync_pair
    assert service.resolve_last_write_wins({"updated_at": 2}, {"updated_at": 1})["updated_at"] == 2


def test_append_only_logs_merge(sync_pair):
    _, service = sync_pair
    assert len(service.merge_append_only([{"id": "a"}], [{"id": "a"}, {"id": "b"}])) == 2


def test_concurrent_updates_handled(sync_pair):
    _, service = sync_pair
    assert service.resolve_last_write_wins({"updated_at": 3}, {"updated_at": 3})["updated_at"] == 3


def test_sync_after_offline_game_session(sync_pair):
    outbox, service = sync_pair
    outbox.enqueue("game_sessions", {"id": "s"})
    assert service.sync(lambda *_: None)


def test_sync_after_offline_reminders(sync_pair):
    outbox, service = sync_pair
    outbox.enqueue("reminders", {"id": "r"})
    assert service.sync(lambda *_: None)


def test_sync_after_offline_memory_edits(sync_pair):
    outbox, service = sync_pair
    outbox.enqueue("memory_persons", {"id": "p"})
    assert service.sync(lambda *_: None)


def test_sync_with_intermittent_connectivity(sync_pair):
    outbox, service = sync_pair
    outbox.enqueue("events", {"id": "e"})
    with pytest.raises(ConnectionError):
        service.sync(lambda *_: (_ for _ in ()).throw(ConnectionError()))
    assert outbox.pending()
    assert service.sync(lambda *_: None)


def test_no_data_loss_after_sync(sync_pair):
    outbox, service = sync_pair
    outbox.enqueue("x", {"id": "1"})
    sent = []
    service.sync(lambda _, data: sent.append(data))
    assert sent == [{"id": "1"}]


def test_no_duplicates_after_sync(sync_pair):
    outbox, service = sync_pair
    outbox.enqueue("x", {"id": "1"}, "stable")
    outbox.enqueue("x", {"id": "1"}, "stable")
    sent = []
    service.sync(lambda _, data: sent.append(data))
    assert len(sent) == 1


def test_timestamps_preserved(sync_pair):
    outbox, _ = sync_pair
    timestamp = datetime.now(timezone.utc)
    outbox.enqueue("x", {"created_at": timestamp})
    assert outbox.pending()[0]["data"]["created_at"] == timestamp