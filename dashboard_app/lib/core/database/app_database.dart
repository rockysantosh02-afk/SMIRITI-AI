import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// GameSessions table - stores completed game session records
class GameSessions extends Table {
  TextColumn get id => text()();
  TextColumn get gameId => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get difficultyLevel => integer()();
  IntColumn get roundsPlayed => integer()();
  RealColumn get accuracy => real()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Attempts table - stores individual game round attempts
class Attempts extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  TextColumn get gameId => text()();
  IntColumn get roundNumber => integer()();
  BoolColumn get correct => boolean()();
  IntColumn get responseTimeMs => integer()();
  IntColumn get difficultyLevel => integer()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// CognitiveScores table - stores aggregated cognitive domain scores
class CognitiveScores extends Table {
  TextColumn get id => text()();
  TextColumn get domain => text()();
  RealColumn get score => real()();
  RealColumn get trend => real()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// JournalEntries table - stores user journal entries
class JournalEntries extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get mood => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get generatedStory => text().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Reminders table - stores user reminders
class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get timeOfDay => text()();
  TextColumn get daysOfWeek => text()();
  BoolColumn get enabled => boolean()();
  DateTimeColumn get lastFiredAt => dateTime().nullable()();
  IntColumn get followUpCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Outbox table - stores pending sync operations
class Outbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}

/// FamilyMembers table - stores family member memories
class FamilyMembers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get relation => text()();
  TextColumn get photoPath => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  GameSessions,
  Attempts,
  CognitiveScores,
  JournalEntries,
  Reminders,
  Outbox,
  FamilyMembers,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For testing only
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(journalEntries, journalEntries.generatedStory);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'smriti_database',
    );
  }

  // ============ GameSessions CRUD ============

  Future<List<GameSession>> getAllGameSessions() =>
      select(gameSessions).get();

  Stream<List<GameSession>> watchAllGameSessions() =>
      select(gameSessions).watch();

  Future<GameSession?> getGameSessionById(String id) =>
      (select(gameSessions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertGameSession(GameSessionsCompanion session) =>
      into(gameSessions).insert(session);

  Future<bool> updateGameSession(GameSessionsCompanion session) =>
      update(gameSessions).replace(GameSession(
        id: session.id.value,
        gameId: session.gameId.value,
        startedAt: session.startedAt.value,
        completedAt: session.completedAt.value,
        difficultyLevel: session.difficultyLevel.value,
        roundsPlayed: session.roundsPlayed.value,
        accuracy: session.accuracy.value,
        synced: session.synced.value,
      ));

  Future<int> deleteGameSession(String id) =>
      (delete(gameSessions)..where((t) => t.id.equals(id))).go();

  Future<List<GameSession>> getUnsyncedGameSessions() =>
      (select(gameSessions)..where((t) => t.synced.equals(false))).get();

  // ============ Attempts CRUD ============

  Future<List<Attempt>> getAllAttempts() => select(attempts).get();

  Future<List<Attempt>> getAttemptsBySessionId(String sessionId) =>
      (select(attempts)..where((t) => t.sessionId.equals(sessionId))).get();

  Future<int> insertAttempt(AttemptsCompanion attempt) =>
      into(attempts).insert(attempt);

  Future<int> deleteAttempt(String id) =>
      (delete(attempts)..where((t) => t.id.equals(id))).go();

  Future<List<Attempt>> getUnsyncedAttempts() =>
      (select(attempts)..where((t) => t.synced.equals(false))).get();

  // ============ CognitiveScores CRUD ============

  Future<List<CognitiveScore>> getAllCognitiveScores() =>
      select(cognitiveScores).get();

  Future<CognitiveScore?> getCognitiveScoreByDomain(String domain) =>
      (select(cognitiveScores)..where((t) => t.domain.equals(domain)))
          .getSingleOrNull();

  Future<int> insertOrUpdateCognitiveScore(CognitiveScoresCompanion score) =>
      into(cognitiveScores).insertOnConflictUpdate(score);

  // ============ JournalEntries CRUD ============

  Future<List<JournalEntry>> getAllJournalEntries() =>
      (select(journalEntries)..where((t) => t.deleted.equals(false))).get();

  Stream<List<JournalEntry>> watchAllJournalEntries() =>
      (select(journalEntries)..where((t) => t.deleted.equals(false))).watch();

  Future<JournalEntry?> getJournalEntryById(String id) =>
      (select(journalEntries)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertJournalEntry(JournalEntriesCompanion entry) =>
      into(journalEntries).insert(entry);

  Future<bool> updateJournalEntry(JournalEntriesCompanion entry) =>
      update(journalEntries).replace(JournalEntry(
        id: entry.id.value,
        title: entry.title.value,
        body: entry.body.value,
        mood: entry.mood.value,
        photoPath: entry.photoPath.value,
        generatedStory: entry.generatedStory.value,
        createdAt: entry.createdAt.value,
        updatedAt: entry.updatedAt.value,
        synced: entry.synced.value,
        deleted: entry.deleted.value,
      ));

  Future<int> softDeleteJournalEntry(String id) =>
      (update(journalEntries)..where((t) => t.id.equals(id)))
          .write(const JournalEntriesCompanion(deleted: Value(true)));

  Future<List<JournalEntry>> getUnsyncedJournalEntries() =>
      (select(journalEntries)
            ..where((t) => t.synced.equals(false) & t.deleted.equals(false)))
          .get();

  // ============ Reminders CRUD ============

  Future<List<Reminder>> getAllReminders() => select(reminders).get();

  Stream<List<Reminder>> watchAllReminders() => select(reminders).watch();

  Future<Reminder?> getReminderById(String id) =>
      (select(reminders)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertReminder(RemindersCompanion reminder) =>
      into(reminders).insert(reminder);

  Future<bool> updateReminder(RemindersCompanion reminder) =>
      update(reminders).replace(Reminder(
        id: reminder.id.value,
        title: reminder.title.value,
        timeOfDay: reminder.timeOfDay.value,
        daysOfWeek: reminder.daysOfWeek.value,
        enabled: reminder.enabled.value,
        lastFiredAt: reminder.lastFiredAt.value,
        followUpCount: reminder.followUpCount.value,
        createdAt: reminder.createdAt.value,
        synced: reminder.synced.value,
      ));

  Future<int> deleteReminder(String id) =>
      (delete(reminders)..where((t) => t.id.equals(id))).go();

  Future<List<Reminder>> getEnabledReminders() =>
      (select(reminders)..where((t) => t.enabled.equals(true))).get();

  // ============ Outbox CRUD ============

  Future<List<OutboxData>> getAllOutboxItems() => select(outbox).get();

  Future<int> insertOutboxItem(OutboxCompanion item) =>
      into(outbox).insert(item);

  Future<int> deleteOutboxItem(int id) =>
      (delete(outbox)..where((t) => t.id.equals(id))).go();

  Future<int> incrementOutboxRetry(int id, String error) async {
    final item = await (select(outbox)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (item == null) return 0;
    return (update(outbox)..where((t) => t.id.equals(id))).write(
      OutboxCompanion(
        retryCount: Value(item.retryCount + 1),
        lastError: Value(error),
      ),
    );
  }

  Future<int> getOutboxCount() async {
    final count = countAll();
    final query = selectOnly(outbox)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ============ FamilyMembers CRUD ============

  Future<List<FamilyMember>> getAllFamilyMembers() => select(familyMembers).get();

  Stream<List<FamilyMember>> watchAllFamilyMembers() => select(familyMembers).watch();

  Future<FamilyMember?> getFamilyMemberById(String id) =>
      (select(familyMembers)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertFamilyMember(FamilyMembersCompanion member) =>
      into(familyMembers).insert(member);

  Future<bool> updateFamilyMember(FamilyMembersCompanion member) =>
      update(familyMembers).replace(FamilyMember(
        id: member.id.value,
        name: member.name.value,
        relation: member.relation.value,
        photoPath: member.photoPath.value,
        notes: member.notes.value,
        createdAt: member.createdAt.value,
        synced: member.synced.value,
      ));

  Future<int> deleteFamilyMember(String id) =>
      (delete(familyMembers)..where((t) => t.id.equals(id))).go();
}

/// The database provider singleton
class DatabaseProvider {
  static AppDatabase? _instance;

  static AppDatabase get instance {
    _instance ??= AppDatabase();
    return _instance!;
  }

  /// For testing - allows injecting a custom database
  static void setInstance(AppDatabase db) {
    _instance = db;
  }

  /// For testing - reset the singleton
  static void resetInstance() {
    _instance?.close();
    _instance = null;
  }
}
