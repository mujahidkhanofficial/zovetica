import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Import table definitions
part 'database.g.dart';

// ============================================
// TABLE DEFINITIONS
// ============================================

/// Local cache of chats
class LocalChats extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text().nullable()();
  TextColumn get type => text().withDefault(const Constant('direct'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  
  // Joined/cached data for display
  TextColumn get otherUserName => text().nullable()();
  TextColumn get otherUserImage => text().nullable()();
  TextColumn get otherUserId => text().nullable()();
  TextColumn get lastMessage => text().nullable()();
  DateTimeColumn get lastMessageAt => dateTime().nullable()();
  
  // Sync metadata
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();
  DateTimeColumn get localUpdatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of messages
class LocalMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get remoteId => integer().nullable()();  // NULL = pending sync
  IntColumn get chatId => integer()();
  TextColumn get senderId => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get editedAt => dateTime().nullable()();
  
  // Idempotency key for preventing duplicate sends
  TextColumn get clientMessageId => text().nullable()();
  
  // Sync metadata
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  // Values: 'pending', 'syncing', 'synced', 'failed'
  DateTimeColumn get syncedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (chat_id) REFERENCES local_chats(id) ON DELETE CASCADE'
  ];
}

/// Local cache of posts (community feed)
class LocalPosts extends Table {
  IntColumn get id => integer()();
  TextColumn get userId => text()();
  TextColumn get content => text()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get authorName => text()();
  TextColumn get authorImage => text().nullable()();
  TextColumn get location => text().nullable()();
  IntColumn get likesCount => integer().withDefault(const Constant(0))();
  IntColumn get commentsCount => integer().withDefault(const Constant(0))();
  BoolColumn get isLikedByMe => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  
  // Sync metadata
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of appointments
class LocalAppointments extends Table {
  TextColumn get id => text()();  // UUID
  TextColumn get userId => text()();
  TextColumn get doctorId => text()();
  TextColumn get petId => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get time => text()();
  TextColumn get type => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime()();
  
  // Cached doctor info for display
  TextColumn get doctorName => text().nullable()();
  TextColumn get doctorImage => text().nullable()();
  TextColumn get doctorSpecialty => text().nullable()();
  TextColumn get clinicName => text().nullable()();
  
  // Cached pet info
  TextColumn get petName => text().nullable()();
  TextColumn get petEmoji => text().nullable()();
  
  // Sync metadata
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of pets
class LocalPets extends Table {
  TextColumn get id => text()();  // UUID
  TextColumn get ownerId => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get breed => text().nullable()();
  TextColumn get gender => text().nullable()();
  TextColumn get age => text().nullable()();
  TextColumn get weight => text().nullable()();
  TextColumn get height => text().nullable()();
  TextColumn get health => text().nullable()();
  TextColumn get emoji => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  DateTimeColumn get nextCheckup => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  
  // Sync metadata
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of users/doctors for profile display
class LocalUsers extends Table {
  TextColumn get id => text()();  // UUID
  TextColumn get email => text()();
  TextColumn get name => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get role => text().withDefault(const Constant('pet_owner'))();
  TextColumn get profileImage => text().nullable()();
  TextColumn get specialty => text().nullable()();  // For doctors
  TextColumn get clinic => text().nullable()();     // For doctors
  TextColumn get bio => text().nullable()();
  TextColumn get username => text().nullable()();
  RealColumn get rating => real().nullable()();     // For doctors
  IntColumn get reviewsCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  
  // Sync metadata
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();
  DateTimeColumn get localUpdatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of doctors for find doctor screen
class LocalDoctors extends Table {
  TextColumn get id => text()();  // UUID
  TextColumn get userId => text()();  // Reference to users table
  TextColumn get name => text()();
  TextColumn get specialty => text().nullable()();
  TextColumn get clinic => text().nullable()();
  RealColumn get rating => real().withDefault(const Constant(0.0))();
  IntColumn get reviewsCount => integer().withDefault(const Constant(0))();
  TextColumn get profileImage => text().nullable()();
  TextColumn get nextAvailable => text().nullable()();
  BoolColumn get available => boolean().withDefault(const Constant(true))();
  BoolColumn get verified => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  
  // Sync metadata
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of notifications
class LocalNotifications extends Table {
  IntColumn get id => integer()();
  TextColumn get userId => text()();
  TextColumn get actorId => text().nullable()();
  TextColumn get type => text()();  // 'like', 'comment', 'message'
  TextColumn get title => text()();
  TextColumn get body => text()();
  IntColumn get relatedId => integer().nullable()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  
  // Actor info for display
  TextColumn get actorName => text().nullable()();
  TextColumn get actorImage => text().nullable()();
  
  // Sync metadata
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of availability slots for doctors
class LocalSlots extends Table {
  TextColumn get id => text()();  // UUID or string ID
  TextColumn get doctorId => text()();
  TextColumn get day => text()(); // Monday, Tuesday, etc.
  TextColumn get startTime => text()(); // 09:00 AM
  TextColumn get endTime => text()();   // 05:00 PM
  
  // Sync metadata
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of daily care tasks
class LocalCareTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get petId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get frequency => text().withDefault(const Constant('daily'))();
  DateTimeColumn get lastCompletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  
  // Sync metadata (local only for now, but keeping consistency)
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

/// Local cache of pet health events (Vaccines, Surgery, etc.)
class LocalHealthEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get petId => text()();
  TextColumn get title => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get type => text()(); // Vaccine, Checkup, etc.
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  
  // Sync metadata
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

/// Sync metadata tracking for delta sync
class SyncMetadata extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get syncTableName => text().named('table_name')();  // Renamed to avoid override
  TextColumn get entityId => text().withDefault(const Constant(''))();  // Empty string for global
  DateTimeColumn get lastSyncAt => dateTime()();
  IntColumn get syncCount => integer().withDefault(const Constant(0))();

  @override
  List<String> get customConstraints => [
    'UNIQUE (table_name, entity_id)'
  ];
}

// ============================================
// DATABASE CLASS
// ============================================

@DriftDatabase(tables: [
  LocalChats,
  LocalMessages,
  LocalPosts,
  LocalAppointments,
  LocalPets,
  LocalUsers,
  LocalDoctors,
  LocalNotifications,
  LocalSlots,
  LocalCareTasks,
  LocalHealthEvents,
  SyncMetadata,
])
class AppDatabase extends _$AppDatabase {
  // Singleton instance
  static AppDatabase? _instance;
  
  AppDatabase._() : super(_openConnection());
  
  /// Get the singleton database instance
  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Add local_users table for version 2
          await m.createTable(localUsers);
        }
        if (from < 3) {
          // Add local_doctors and local_notifications tables for version 3
          await m.createTable(localDoctors);
          await m.createTable(localNotifications);
        }
        if (from < 4) {
          // Add local_slots table for version 4
          await m.createTable(localSlots);
        }
        if (from < 5) {
          // Add local_care_tasks table for version 5
          await m.createTable(localCareTasks);
        }
        if (from < 6) {
          // Add local_health_events table for version 6
          await m.createTable(localHealthEvents);
        }
        if (from < 7) {
          // Add client_message_id column for idempotency
          await m.addColumn(localMessages, localMessages.clientMessageId);
        }
      },
    );
  }

  // ============================================
  // SYNC METADATA OPERATIONS
  // ============================================

  /// Get last sync time for a table (optionally scoped to an entity)
  Future<DateTime?> getLastSyncTime(String table, {String? entityId}) async {
    final effectiveEntityId = entityId ?? '';  // Use empty string for global
    final query = select(syncMetadata)
      ..where((t) => t.syncTableName.equals(table))
      ..where((t) => t.entityId.equals(effectiveEntityId));
    
    final result = await query.getSingleOrNull();
    return result?.lastSyncAt;
  }

  /// Update sync time for a table
  Future<void> updateSyncTime(String table, DateTime time, {String? entityId}) async {
    final effectiveEntityId = entityId ?? '';  // Use empty string for global
    
    // First try to update existing
    final existing = await (select(syncMetadata)
          ..where((t) => t.syncTableName.equals(table))
          ..where((t) => t.entityId.equals(effectiveEntityId)))
        .getSingleOrNull();
    
    if (existing != null) {
      await (update(syncMetadata)..where((t) => t.id.equals(existing.id))).write(
        SyncMetadataCompanion(
          lastSyncAt: Value(time),
          syncCount: Value(existing.syncCount + 1),
        ),
      );
    } else {
      await into(syncMetadata).insert(
        SyncMetadataCompanion(
          syncTableName: Value(table),
          entityId: Value(effectiveEntityId),
          lastSyncAt: Value(time),
          syncCount: const Value(1),
        ),
      );
    }
  }

  // ============================================
  // MESSAGE OPERATIONS
  // ============================================

  /// Watch all messages for a chat (reactive stream)
  Stream<List<LocalMessage>> watchMessages(int chatId) {
    return (select(localMessages)
          ..where((m) => m.chatId.equals(chatId))
          ..where((m) => m.isDeleted.equals(false))
          ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
        .watch();
  }

  /// Insert a pending message (optimistic write)
  /// Uses clientMessageId as idempotency key to prevent duplicate sends
  Future<int> insertPendingMessage({
    required int chatId,
    required String senderId,
    required String content,
    required String clientMessageId,
  }) async {
    return into(localMessages).insert(
      LocalMessagesCompanion(
        chatId: Value(chatId),
        senderId: Value(senderId),
        content: Value(content),
        clientMessageId: Value(clientMessageId),
        createdAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
    );
  }

  /// Mark a message as synced with remote ID
  Future<void> markMessageSynced(int localId, int remoteId) async {
    await (update(localMessages)..where((m) => m.id.equals(localId))).write(
      LocalMessagesCompanion(
        remoteId: Value(remoteId),
        syncStatus: const Value('synced'),
        syncedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Upsert messages from remote (delta sync)
  Future<void> upsertMessages(List<LocalMessagesCompanion> messages) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(localMessages, messages);
    });
  }

  // ============================================
  // CHAT OPERATIONS
  // ============================================

  /// Watch all chats for current user (reactive stream)
  Stream<List<LocalChat>> watchChats() {
    return (select(localChats)
          ..orderBy([(c) => OrderingTerm.desc(c.lastMessageAt)]))
        .watch();
  }

  /// Upsert chats from remote
  Future<void> upsertChats(List<LocalChatsCompanion> chats) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(localChats, chats);
    });
  }

  /// Get pending messages that need sync
  Future<List<LocalMessage>> getPendingMessages() async {
    return (select(localMessages)
          ..where((m) => m.syncStatus.equals('pending')))
        .get();
  }

  // ============================================
  // USER OPERATIONS
  // ============================================

  /// Watch a specific user by ID
  Stream<LocalUser?> watchUser(String userId) {
    return (select(localUsers)..where((u) => u.id.equals(userId)))
        .watchSingleOrNull();
  }

  /// Get user by ID
  Future<LocalUser?> getUser(String userId) {
    return (select(localUsers)..where((u) => u.id.equals(userId)))
        .getSingleOrNull();
  }

  /// Upsert user from remote
  Future<void> upsertUser(LocalUsersCompanion user) async {
    await into(localUsers).insertOnConflictUpdate(user);
  }

  /// Upsert multiple users
  Future<void> upsertUsers(List<LocalUsersCompanion> users) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(localUsers, users);
    });
  }

  // ============================================
  // PET OPERATIONS
  // ============================================

  /// Watch all pets for a user
  Stream<List<LocalPet>> watchPets(String ownerId) {
    return (select(localPets)
          ..where((p) => p.ownerId.equals(ownerId))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  /// Get all pets for a user
  Future<List<LocalPet>> getPets(String ownerId) {
    return (select(localPets)..where((p) => p.ownerId.equals(ownerId))).get();
  }

  /// Upsert pet
  Future<void> upsertPet(LocalPetsCompanion pet) async {
    await into(localPets).insertOnConflictUpdate(pet);
  }

  /// Upsert multiple pets
  Future<void> upsertPets(List<LocalPetsCompanion> pets) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(localPets, pets);
    });
  }

  /// Insert pending pet (optimistic write)
  Future<void> insertPendingPet(LocalPetsCompanion pet) async {
    await into(localPets).insert(pet);
  }

  /// Get pending pets that need sync
  Future<List<LocalPet>> getPendingPets() async {
    return (select(localPets)..where((p) => p.syncStatus.equals('pending'))).get();
  }

  /// Delete pet locally
  Future<void> deletePet(String petId) async {
    await (delete(localPets)..where((p) => p.id.equals(petId))).go();
  }

  // ============================================
  // APPOINTMENT OPERATIONS
  // ============================================

  /// Watch all appointments for a user
  Stream<List<LocalAppointment>> watchAppointments(String userId) {
    return (select(localAppointments)
          ..where((a) => a.userId.equals(userId))
          ..orderBy([(a) => OrderingTerm.desc(a.date)]))
        .watch();
  }

  /// Get all appointments for a user
  Future<List<LocalAppointment>> getAppointments(String userId) {
    return (select(localAppointments)..where((a) => a.userId.equals(userId))).get();
  }

  /// Upsert appointment
  Future<void> upsertAppointment(LocalAppointmentsCompanion appt) async {
    await into(localAppointments).insertOnConflictUpdate(appt);
  }

  /// Upsert multiple appointments
  Future<void> upsertAppointments(List<LocalAppointmentsCompanion> appts) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(localAppointments, appts);
    });
  }

  /// Insert pending appointment (optimistic write)
  Future<void> insertPendingAppointment(LocalAppointmentsCompanion appt) async {
    await into(localAppointments).insert(appt);
  }

  /// Get pending appointments that need sync
  Future<List<LocalAppointment>> getPendingAppointments() async {
    return (select(localAppointments)..where((a) => a.syncStatus.equals('pending'))).get();
  }

  /// Update appointment status
  Future<void> updateAppointmentStatus(String id, String status) async {
    await (update(localAppointments)..where((a) => a.id.equals(id))).write(
      LocalAppointmentsCompanion(status: Value(status)),
    );
  }

  // ============================================
  // POST OPERATIONS
  // ============================================

  /// Watch all posts (community feed)
  Stream<List<LocalPost>> watchPosts() {
    return (select(localPosts)
          ..where((p) => p.isDeleted.equals(false))
          ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
        .watch();
  }

  /// Get all posts
  Future<List<LocalPost>> getPosts() {
    return (select(localPosts)
          ..where((p) => p.isDeleted.equals(false))
          ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
        .get();
  }

  /// Upsert posts from remote
  Future<void> upsertPosts(List<LocalPostsCompanion> posts) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(localPosts, posts);
    });
  }

  /// Update post like status
  Future<void> updatePostLike(int postId, bool isLiked, int likesCount) async {
    await (update(localPosts)..where((p) => p.id.equals(postId))).write(
      LocalPostsCompanion(
        isLikedByMe: Value(isLiked),
        likesCount: Value(likesCount),
      ),
    );
  }

  // ============================================
  // DOCTOR OPERATIONS
  // ============================================

  /// Watch all available doctors
  Stream<List<LocalDoctor>> watchDoctors() {
    return (select(localDoctors)
          ..orderBy([(d) => OrderingTerm.desc(d.rating)]))
        .watch();
  }

  /// Get all doctors
  Future<List<LocalDoctor>> getDoctors() {
    return (select(localDoctors)
          ..orderBy([(d) => OrderingTerm.desc(d.rating)]))
        .get();
  }

  /// Upsert doctors from remote
  Future<void> upsertDoctors(List<LocalDoctorsCompanion> doctors) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(localDoctors, doctors);
    });
  }

  // ============================================
  // CARE TASK OPERATIONS
  // ============================================

  /// Watch care tasks for a pet
  Stream<List<LocalCareTask>> watchCareTasks(String petId) {
    return (select(localCareTasks)
          ..where((t) => t.petId.equals(petId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  /// Add a care task
  Future<int> addCareTask(LocalCareTasksCompanion task) {
    return into(localCareTasks).insert(task);
  }

  /// Toggle task completion
  Future<void> toggleCareTask(int id, DateTime? completedAt) async {
    await (update(localCareTasks)..where((t) => t.id.equals(id))).write(
      LocalCareTasksCompanion(
        lastCompletedAt: Value(completedAt),
      ),
    );
  }

  /// Delete a care task
  Future<void> deleteCareTask(int id) async {
    await (update(localCareTasks)..where((t) => t.id.equals(id))).write(
      const LocalCareTasksCompanion(
        isDeleted: Value(true),
      ),
    );
  }
  
  // ============================================
  // HEALTH EVENT OPERATIONS
  // ============================================

  /// Watch health events for a pet
  Stream<List<LocalHealthEvent>> watchHealthEvents(String petId) {
    return (select(localHealthEvents)
          ..where((t) => t.petId.equals(petId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  /// Add a health event
  Future<int> addHealthEvent(LocalHealthEventsCompanion event) {
    return into(localHealthEvents).insert(event);
  }

  /// Update a health event
  Future<void> updateHealthEvent(int id, LocalHealthEventsCompanion event) async {
    await (update(localHealthEvents)..where((t) => t.id.equals(id))).write(event);
  }

  /// Delete a health event
  Future<void> deleteHealthEvent(int id) async {
    await (update(localHealthEvents)..where((t) => t.id.equals(id))).write(
      const LocalHealthEventsCompanion(
        isDeleted: Value(true),
      ),
    );
  }
  
  // ============================================
  // NOTIFICATION OPERATIONS
  // ============================================

  /// Watch notifications for a user
  Stream<List<LocalNotification>> watchNotifications(String userId) {
    return (select(localNotifications)
          ..where((n) => n.userId.equals(userId))
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
        .watch();
  }

  /// Get notifications for a user
  Future<List<LocalNotification>> getNotifications(String userId) {
    return (select(localNotifications)
          ..where((n) => n.userId.equals(userId))
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
        .get();
  }

  /// Upsert notifications from remote
  Future<void> upsertNotifications(List<LocalNotificationsCompanion> notifs) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(localNotifications, notifs);
    });
  }

  /// Mark notification as read
  Future<void> markNotificationRead(int id) async {
    await (update(localNotifications)..where((n) => n.id.equals(id))).write(
      const LocalNotificationsCompanion(isRead: Value(true)),
    );
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount(String userId) async {
    final count = await (select(localNotifications)
          ..where((n) => n.userId.equals(userId))
          ..where((n) => n.isRead.equals(false)))
        .get();
    return count.length;
  }

  // ============================================
  // SLOT OPERATIONS
  // ============================================

  /// Watch slots for a doctor
  Stream<List<LocalSlot>> watchSlots(String doctorId) {
    return (select(localSlots)
          ..where((s) => s.doctorId.equals(doctorId))
          ..where((s) => s.isDeleted.equals(false))
          ..orderBy([(s) => OrderingTerm.asc(s.day), (s) => OrderingTerm.asc(s.startTime)]))
        .watch();
  }

  /// Get slots for a doctor
  Future<List<LocalSlot>> getSlots(String doctorId) {
    return (select(localSlots)
          ..where((s) => s.doctorId.equals(doctorId))
          ..where((s) => s.isDeleted.equals(false))
          ..orderBy([(s) => OrderingTerm.asc(s.day), (s) => OrderingTerm.asc(s.startTime)]))
        .get();
  }

  /// Upsert slots
  Future<void> upsertSlots(List<LocalSlotsCompanion> slots) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(localSlots, slots);
    });
  }

  /// Delete slot (soft delete)
  Future<void> deleteSlot(String slotId) async {
    await (update(localSlots)..where((s) => s.id.equals(slotId))).write(
      const LocalSlotsCompanion(isDeleted: Value(true), isSynced: Value(false), syncStatus: Value('pending')),
    );
  }

  /// Insert pending slot
  Future<void> insertPendingSlot(LocalSlotsCompanion slot) async {
    await into(localSlots).insert(slot);
  }

  /// Get pending slots for sync
  Future<List<LocalSlot>> getPendingSlots() async {
    return (select(localSlots)..where((s) => s.syncStatus.equals('pending'))).get();
  }

  /// Delete all pending/temp slots for a doctor (to prevent duplicates after sync)
  Future<void> deletePendingSlots(String doctorId) async {
    await (delete(localSlots)
          ..where((s) => s.doctorId.equals(doctorId))
          ..where((s) => s.syncStatus.equals('pending')))
        .go();
  }

  // ============================================
  // CLEAR DATA (for logout)
  // ============================================

  Future<void> clearAllData() async {
    await delete(localMessages).go();
    await delete(localChats).go();
    await delete(localPosts).go();
    await delete(localAppointments).go();
    await delete(localPets).go();
    await delete(localUsers).go();
    await delete(localDoctors).go();
    await delete(localNotifications).go();
    await delete(syncMetadata).go();
  }
}

// ============================================
// DATABASE CONNECTION
// ============================================

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'pets_and_vets_local.db'));
    return NativeDatabase.createInBackground(file);
  });
}
