// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LocalChatsTable extends LocalChats
    with TableInfo<$LocalChatsTable, LocalChat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalChatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('direct'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _otherUserNameMeta =
      const VerificationMeta('otherUserName');
  @override
  late final GeneratedColumn<String> otherUserName = GeneratedColumn<String>(
      'other_user_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _otherUserImageMeta =
      const VerificationMeta('otherUserImage');
  @override
  late final GeneratedColumn<String> otherUserImage = GeneratedColumn<String>(
      'other_user_image', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _otherUserIdMeta =
      const VerificationMeta('otherUserId');
  @override
  late final GeneratedColumn<String> otherUserId = GeneratedColumn<String>(
      'other_user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastMessageMeta =
      const VerificationMeta('lastMessage');
  @override
  late final GeneratedColumn<String> lastMessage = GeneratedColumn<String>(
      'last_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastMessageAtMeta =
      const VerificationMeta('lastMessageAt');
  @override
  late final GeneratedColumn<DateTime> lastMessageAt =
      GeneratedColumn<DateTime>('last_message_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _localUpdatedAtMeta =
      const VerificationMeta('localUpdatedAt');
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>('local_updated_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        type,
        createdAt,
        updatedAt,
        otherUserName,
        otherUserImage,
        otherUserId,
        lastMessage,
        lastMessageAt,
        isSynced,
        localUpdatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_chats';
  @override
  VerificationContext validateIntegrity(Insertable<LocalChat> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('other_user_name')) {
      context.handle(
          _otherUserNameMeta,
          otherUserName.isAcceptableOrUnknown(
              data['other_user_name']!, _otherUserNameMeta));
    }
    if (data.containsKey('other_user_image')) {
      context.handle(
          _otherUserImageMeta,
          otherUserImage.isAcceptableOrUnknown(
              data['other_user_image']!, _otherUserImageMeta));
    }
    if (data.containsKey('other_user_id')) {
      context.handle(
          _otherUserIdMeta,
          otherUserId.isAcceptableOrUnknown(
              data['other_user_id']!, _otherUserIdMeta));
    }
    if (data.containsKey('last_message')) {
      context.handle(
          _lastMessageMeta,
          lastMessage.isAcceptableOrUnknown(
              data['last_message']!, _lastMessageMeta));
    }
    if (data.containsKey('last_message_at')) {
      context.handle(
          _lastMessageAtMeta,
          lastMessageAt.isAcceptableOrUnknown(
              data['last_message_at']!, _lastMessageAtMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
          _localUpdatedAtMeta,
          localUpdatedAt.isAcceptableOrUnknown(
              data['local_updated_at']!, _localUpdatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalChat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalChat(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      otherUserName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}other_user_name']),
      otherUserImage: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}other_user_image']),
      otherUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}other_user_id']),
      lastMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_message']),
      lastMessageAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_message_at']),
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      localUpdatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}local_updated_at']),
    );
  }

  @override
  $LocalChatsTable createAlias(String alias) {
    return $LocalChatsTable(attachedDatabase, alias);
  }
}

class LocalChat extends DataClass implements Insertable<LocalChat> {
  final int id;
  final String? name;
  final String type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? otherUserName;
  final String? otherUserImage;
  final String? otherUserId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final bool isSynced;
  final DateTime? localUpdatedAt;
  const LocalChat(
      {required this.id,
      this.name,
      required this.type,
      required this.createdAt,
      required this.updatedAt,
      this.otherUserName,
      this.otherUserImage,
      this.otherUserId,
      this.lastMessage,
      this.lastMessageAt,
      required this.isSynced,
      this.localUpdatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['type'] = Variable<String>(type);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || otherUserName != null) {
      map['other_user_name'] = Variable<String>(otherUserName);
    }
    if (!nullToAbsent || otherUserImage != null) {
      map['other_user_image'] = Variable<String>(otherUserImage);
    }
    if (!nullToAbsent || otherUserId != null) {
      map['other_user_id'] = Variable<String>(otherUserId);
    }
    if (!nullToAbsent || lastMessage != null) {
      map['last_message'] = Variable<String>(lastMessage);
    }
    if (!nullToAbsent || lastMessageAt != null) {
      map['last_message_at'] = Variable<DateTime>(lastMessageAt);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || localUpdatedAt != null) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    }
    return map;
  }

  LocalChatsCompanion toCompanion(bool nullToAbsent) {
    return LocalChatsCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      type: Value(type),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      otherUserName: otherUserName == null && nullToAbsent
          ? const Value.absent()
          : Value(otherUserName),
      otherUserImage: otherUserImage == null && nullToAbsent
          ? const Value.absent()
          : Value(otherUserImage),
      otherUserId: otherUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(otherUserId),
      lastMessage: lastMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessage),
      lastMessageAt: lastMessageAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageAt),
      isSynced: Value(isSynced),
      localUpdatedAt: localUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(localUpdatedAt),
    );
  }

  factory LocalChat.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalChat(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      otherUserName: serializer.fromJson<String?>(json['otherUserName']),
      otherUserImage: serializer.fromJson<String?>(json['otherUserImage']),
      otherUserId: serializer.fromJson<String?>(json['otherUserId']),
      lastMessage: serializer.fromJson<String?>(json['lastMessage']),
      lastMessageAt: serializer.fromJson<DateTime?>(json['lastMessageAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      localUpdatedAt: serializer.fromJson<DateTime?>(json['localUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String?>(name),
      'type': serializer.toJson<String>(type),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'otherUserName': serializer.toJson<String?>(otherUserName),
      'otherUserImage': serializer.toJson<String?>(otherUserImage),
      'otherUserId': serializer.toJson<String?>(otherUserId),
      'lastMessage': serializer.toJson<String?>(lastMessage),
      'lastMessageAt': serializer.toJson<DateTime?>(lastMessageAt),
      'isSynced': serializer.toJson<bool>(isSynced),
      'localUpdatedAt': serializer.toJson<DateTime?>(localUpdatedAt),
    };
  }

  LocalChat copyWith(
          {int? id,
          Value<String?> name = const Value.absent(),
          String? type,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<String?> otherUserName = const Value.absent(),
          Value<String?> otherUserImage = const Value.absent(),
          Value<String?> otherUserId = const Value.absent(),
          Value<String?> lastMessage = const Value.absent(),
          Value<DateTime?> lastMessageAt = const Value.absent(),
          bool? isSynced,
          Value<DateTime?> localUpdatedAt = const Value.absent()}) =>
      LocalChat(
        id: id ?? this.id,
        name: name.present ? name.value : this.name,
        type: type ?? this.type,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        otherUserName:
            otherUserName.present ? otherUserName.value : this.otherUserName,
        otherUserImage:
            otherUserImage.present ? otherUserImage.value : this.otherUserImage,
        otherUserId: otherUserId.present ? otherUserId.value : this.otherUserId,
        lastMessage: lastMessage.present ? lastMessage.value : this.lastMessage,
        lastMessageAt:
            lastMessageAt.present ? lastMessageAt.value : this.lastMessageAt,
        isSynced: isSynced ?? this.isSynced,
        localUpdatedAt:
            localUpdatedAt.present ? localUpdatedAt.value : this.localUpdatedAt,
      );
  @override
  String toString() {
    return (StringBuffer('LocalChat(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('otherUserName: $otherUserName, ')
          ..write('otherUserImage: $otherUserImage, ')
          ..write('otherUserId: $otherUserId, ')
          ..write('lastMessage: $lastMessage, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('localUpdatedAt: $localUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      type,
      createdAt,
      updatedAt,
      otherUserName,
      otherUserImage,
      otherUserId,
      lastMessage,
      lastMessageAt,
      isSynced,
      localUpdatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalChat &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.otherUserName == this.otherUserName &&
          other.otherUserImage == this.otherUserImage &&
          other.otherUserId == this.otherUserId &&
          other.lastMessage == this.lastMessage &&
          other.lastMessageAt == this.lastMessageAt &&
          other.isSynced == this.isSynced &&
          other.localUpdatedAt == this.localUpdatedAt);
}

class LocalChatsCompanion extends UpdateCompanion<LocalChat> {
  final Value<int> id;
  final Value<String?> name;
  final Value<String> type;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> otherUserName;
  final Value<String?> otherUserImage;
  final Value<String?> otherUserId;
  final Value<String?> lastMessage;
  final Value<DateTime?> lastMessageAt;
  final Value<bool> isSynced;
  final Value<DateTime?> localUpdatedAt;
  const LocalChatsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.otherUserName = const Value.absent(),
    this.otherUserImage = const Value.absent(),
    this.otherUserId = const Value.absent(),
    this.lastMessage = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
  });
  LocalChatsCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.otherUserName = const Value.absent(),
    this.otherUserImage = const Value.absent(),
    this.otherUserId = const Value.absent(),
    this.lastMessage = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
  })  : createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<LocalChat> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? otherUserName,
    Expression<String>? otherUserImage,
    Expression<String>? otherUserId,
    Expression<String>? lastMessage,
    Expression<DateTime>? lastMessageAt,
    Expression<bool>? isSynced,
    Expression<DateTime>? localUpdatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (otherUserName != null) 'other_user_name': otherUserName,
      if (otherUserImage != null) 'other_user_image': otherUserImage,
      if (otherUserId != null) 'other_user_id': otherUserId,
      if (lastMessage != null) 'last_message': lastMessage,
      if (lastMessageAt != null) 'last_message_at': lastMessageAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
    });
  }

  LocalChatsCompanion copyWith(
      {Value<int>? id,
      Value<String?>? name,
      Value<String>? type,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<String?>? otherUserName,
      Value<String?>? otherUserImage,
      Value<String?>? otherUserId,
      Value<String?>? lastMessage,
      Value<DateTime?>? lastMessageAt,
      Value<bool>? isSynced,
      Value<DateTime?>? localUpdatedAt}) {
    return LocalChatsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserImage: otherUserImage ?? this.otherUserImage,
      otherUserId: otherUserId ?? this.otherUserId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isSynced: isSynced ?? this.isSynced,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (otherUserName.present) {
      map['other_user_name'] = Variable<String>(otherUserName.value);
    }
    if (otherUserImage.present) {
      map['other_user_image'] = Variable<String>(otherUserImage.value);
    }
    if (otherUserId.present) {
      map['other_user_id'] = Variable<String>(otherUserId.value);
    }
    if (lastMessage.present) {
      map['last_message'] = Variable<String>(lastMessage.value);
    }
    if (lastMessageAt.present) {
      map['last_message_at'] = Variable<DateTime>(lastMessageAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalChatsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('otherUserName: $otherUserName, ')
          ..write('otherUserImage: $otherUserImage, ')
          ..write('otherUserId: $otherUserId, ')
          ..write('lastMessage: $lastMessage, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('localUpdatedAt: $localUpdatedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalMessagesTable extends LocalMessages
    with TableInfo<$LocalMessagesTable, LocalMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _remoteIdMeta =
      const VerificationMeta('remoteId');
  @override
  late final GeneratedColumn<int> remoteId = GeneratedColumn<int>(
      'remote_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<int> chatId = GeneratedColumn<int>(
      'chat_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _senderIdMeta =
      const VerificationMeta('senderId');
  @override
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
      'sender_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _editedAtMeta =
      const VerificationMeta('editedAt');
  @override
  late final GeneratedColumn<DateTime> editedAt = GeneratedColumn<DateTime>(
      'edited_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _clientMessageIdMeta =
      const VerificationMeta('clientMessageId');
  @override
  late final GeneratedColumn<String> clientMessageId = GeneratedColumn<String>(
      'client_message_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('synced'));
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        remoteId,
        chatId,
        senderId,
        content,
        createdAt,
        editedAt,
        clientMessageId,
        syncStatus,
        syncedAt,
        isDeleted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_messages';
  @override
  VerificationContext validateIntegrity(Insertable<LocalMessage> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(_remoteIdMeta,
          remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta));
    }
    if (data.containsKey('chat_id')) {
      context.handle(_chatIdMeta,
          chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta));
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(_senderIdMeta,
          senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta));
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('edited_at')) {
      context.handle(_editedAtMeta,
          editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta));
    }
    if (data.containsKey('client_message_id')) {
      context.handle(
          _clientMessageIdMeta,
          clientMessageId.isAcceptableOrUnknown(
              data['client_message_id']!, _clientMessageIdMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMessage(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      remoteId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}remote_id']),
      chatId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}chat_id'])!,
      senderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender_id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      editedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}edited_at']),
      clientMessageId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}client_message_id']),
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $LocalMessagesTable createAlias(String alias) {
    return $LocalMessagesTable(attachedDatabase, alias);
  }
}

class LocalMessage extends DataClass implements Insertable<LocalMessage> {
  final int id;
  final int? remoteId;
  final int chatId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final DateTime? editedAt;
  final String? clientMessageId;
  final String syncStatus;
  final DateTime? syncedAt;
  final bool isDeleted;
  const LocalMessage(
      {required this.id,
      this.remoteId,
      required this.chatId,
      required this.senderId,
      required this.content,
      required this.createdAt,
      this.editedAt,
      this.clientMessageId,
      required this.syncStatus,
      this.syncedAt,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<int>(remoteId);
    }
    map['chat_id'] = Variable<int>(chatId);
    map['sender_id'] = Variable<String>(senderId);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || editedAt != null) {
      map['edited_at'] = Variable<DateTime>(editedAt);
    }
    if (!nullToAbsent || clientMessageId != null) {
      map['client_message_id'] = Variable<String>(clientMessageId);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  LocalMessagesCompanion toCompanion(bool nullToAbsent) {
    return LocalMessagesCompanion(
      id: Value(id),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      chatId: Value(chatId),
      senderId: Value(senderId),
      content: Value(content),
      createdAt: Value(createdAt),
      editedAt: editedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(editedAt),
      clientMessageId: clientMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientMessageId),
      syncStatus: Value(syncStatus),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory LocalMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMessage(
      id: serializer.fromJson<int>(json['id']),
      remoteId: serializer.fromJson<int?>(json['remoteId']),
      chatId: serializer.fromJson<int>(json['chatId']),
      senderId: serializer.fromJson<String>(json['senderId']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      editedAt: serializer.fromJson<DateTime?>(json['editedAt']),
      clientMessageId: serializer.fromJson<String?>(json['clientMessageId']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'remoteId': serializer.toJson<int?>(remoteId),
      'chatId': serializer.toJson<int>(chatId),
      'senderId': serializer.toJson<String>(senderId),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'editedAt': serializer.toJson<DateTime?>(editedAt),
      'clientMessageId': serializer.toJson<String?>(clientMessageId),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  LocalMessage copyWith(
          {int? id,
          Value<int?> remoteId = const Value.absent(),
          int? chatId,
          String? senderId,
          String? content,
          DateTime? createdAt,
          Value<DateTime?> editedAt = const Value.absent(),
          Value<String?> clientMessageId = const Value.absent(),
          String? syncStatus,
          Value<DateTime?> syncedAt = const Value.absent(),
          bool? isDeleted}) =>
      LocalMessage(
        id: id ?? this.id,
        remoteId: remoteId.present ? remoteId.value : this.remoteId,
        chatId: chatId ?? this.chatId,
        senderId: senderId ?? this.senderId,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        editedAt: editedAt.present ? editedAt.value : this.editedAt,
        clientMessageId: clientMessageId.present
            ? clientMessageId.value
            : this.clientMessageId,
        syncStatus: syncStatus ?? this.syncStatus,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  @override
  String toString() {
    return (StringBuffer('LocalMessage(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('chatId: $chatId, ')
          ..write('senderId: $senderId, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('clientMessageId: $clientMessageId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, remoteId, chatId, senderId, content,
      createdAt, editedAt, clientMessageId, syncStatus, syncedAt, isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMessage &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.chatId == this.chatId &&
          other.senderId == this.senderId &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.editedAt == this.editedAt &&
          other.clientMessageId == this.clientMessageId &&
          other.syncStatus == this.syncStatus &&
          other.syncedAt == this.syncedAt &&
          other.isDeleted == this.isDeleted);
}

class LocalMessagesCompanion extends UpdateCompanion<LocalMessage> {
  final Value<int> id;
  final Value<int?> remoteId;
  final Value<int> chatId;
  final Value<String> senderId;
  final Value<String> content;
  final Value<DateTime> createdAt;
  final Value<DateTime?> editedAt;
  final Value<String?> clientMessageId;
  final Value<String> syncStatus;
  final Value<DateTime?> syncedAt;
  final Value<bool> isDeleted;
  const LocalMessagesCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.chatId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.clientMessageId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  LocalMessagesCompanion.insert({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    required int chatId,
    required String senderId,
    required String content,
    required DateTime createdAt,
    this.editedAt = const Value.absent(),
    this.clientMessageId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  })  : chatId = Value(chatId),
        senderId = Value(senderId),
        content = Value(content),
        createdAt = Value(createdAt);
  static Insertable<LocalMessage> custom({
    Expression<int>? id,
    Expression<int>? remoteId,
    Expression<int>? chatId,
    Expression<String>? senderId,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? editedAt,
    Expression<String>? clientMessageId,
    Expression<String>? syncStatus,
    Expression<DateTime>? syncedAt,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (chatId != null) 'chat_id': chatId,
      if (senderId != null) 'sender_id': senderId,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (editedAt != null) 'edited_at': editedAt,
      if (clientMessageId != null) 'client_message_id': clientMessageId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  LocalMessagesCompanion copyWith(
      {Value<int>? id,
      Value<int?>? remoteId,
      Value<int>? chatId,
      Value<String>? senderId,
      Value<String>? content,
      Value<DateTime>? createdAt,
      Value<DateTime?>? editedAt,
      Value<String?>? clientMessageId,
      Value<String>? syncStatus,
      Value<DateTime?>? syncedAt,
      Value<bool>? isDeleted}) {
    return LocalMessagesCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      clientMessageId: clientMessageId ?? this.clientMessageId,
      syncStatus: syncStatus ?? this.syncStatus,
      syncedAt: syncedAt ?? this.syncedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<int>(remoteId.value);
    }
    if (chatId.present) {
      map['chat_id'] = Variable<int>(chatId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<DateTime>(editedAt.value);
    }
    if (clientMessageId.present) {
      map['client_message_id'] = Variable<String>(clientMessageId.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessagesCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('chatId: $chatId, ')
          ..write('senderId: $senderId, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('clientMessageId: $clientMessageId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $LocalPostsTable extends LocalPosts
    with TableInfo<$LocalPostsTable, LocalPost> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPostsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _imageUrlMeta =
      const VerificationMeta('imageUrl');
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
      'image_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _authorNameMeta =
      const VerificationMeta('authorName');
  @override
  late final GeneratedColumn<String> authorName = GeneratedColumn<String>(
      'author_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _authorImageMeta =
      const VerificationMeta('authorImage');
  @override
  late final GeneratedColumn<String> authorImage = GeneratedColumn<String>(
      'author_image', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _locationMeta =
      const VerificationMeta('location');
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
      'location', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _likesCountMeta =
      const VerificationMeta('likesCount');
  @override
  late final GeneratedColumn<int> likesCount = GeneratedColumn<int>(
      'likes_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _commentsCountMeta =
      const VerificationMeta('commentsCount');
  @override
  late final GeneratedColumn<int> commentsCount = GeneratedColumn<int>(
      'comments_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isLikedByMeMeta =
      const VerificationMeta('isLikedByMe');
  @override
  late final GeneratedColumn<bool> isLikedByMe = GeneratedColumn<bool>(
      'is_liked_by_me', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_liked_by_me" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('synced'));
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        content,
        imageUrl,
        authorName,
        authorImage,
        location,
        likesCount,
        commentsCount,
        isLikedByMe,
        createdAt,
        isSynced,
        syncStatus,
        isDeleted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_posts';
  @override
  VerificationContext validateIntegrity(Insertable<LocalPost> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(_imageUrlMeta,
          imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta));
    }
    if (data.containsKey('author_name')) {
      context.handle(
          _authorNameMeta,
          authorName.isAcceptableOrUnknown(
              data['author_name']!, _authorNameMeta));
    } else if (isInserting) {
      context.missing(_authorNameMeta);
    }
    if (data.containsKey('author_image')) {
      context.handle(
          _authorImageMeta,
          authorImage.isAcceptableOrUnknown(
              data['author_image']!, _authorImageMeta));
    }
    if (data.containsKey('location')) {
      context.handle(_locationMeta,
          location.isAcceptableOrUnknown(data['location']!, _locationMeta));
    }
    if (data.containsKey('likes_count')) {
      context.handle(
          _likesCountMeta,
          likesCount.isAcceptableOrUnknown(
              data['likes_count']!, _likesCountMeta));
    }
    if (data.containsKey('comments_count')) {
      context.handle(
          _commentsCountMeta,
          commentsCount.isAcceptableOrUnknown(
              data['comments_count']!, _commentsCountMeta));
    }
    if (data.containsKey('is_liked_by_me')) {
      context.handle(
          _isLikedByMeMeta,
          isLikedByMe.isAcceptableOrUnknown(
              data['is_liked_by_me']!, _isLikedByMeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalPost map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPost(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      imageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_url']),
      authorName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}author_name'])!,
      authorImage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}author_image']),
      location: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location']),
      likesCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}likes_count'])!,
      commentsCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}comments_count'])!,
      isLikedByMe: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_liked_by_me'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $LocalPostsTable createAlias(String alias) {
    return $LocalPostsTable(attachedDatabase, alias);
  }
}

class LocalPost extends DataClass implements Insertable<LocalPost> {
  final int id;
  final String userId;
  final String content;
  final String? imageUrl;
  final String authorName;
  final String? authorImage;
  final String? location;
  final int likesCount;
  final int commentsCount;
  final bool isLikedByMe;
  final DateTime createdAt;
  final bool isSynced;
  final String syncStatus;
  final bool isDeleted;
  const LocalPost(
      {required this.id,
      required this.userId,
      required this.content,
      this.imageUrl,
      required this.authorName,
      this.authorImage,
      this.location,
      required this.likesCount,
      required this.commentsCount,
      required this.isLikedByMe,
      required this.createdAt,
      required this.isSynced,
      required this.syncStatus,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['author_name'] = Variable<String>(authorName);
    if (!nullToAbsent || authorImage != null) {
      map['author_image'] = Variable<String>(authorImage);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    map['likes_count'] = Variable<int>(likesCount);
    map['comments_count'] = Variable<int>(commentsCount);
    map['is_liked_by_me'] = Variable<bool>(isLikedByMe);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced'] = Variable<bool>(isSynced);
    map['sync_status'] = Variable<String>(syncStatus);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  LocalPostsCompanion toCompanion(bool nullToAbsent) {
    return LocalPostsCompanion(
      id: Value(id),
      userId: Value(userId),
      content: Value(content),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      authorName: Value(authorName),
      authorImage: authorImage == null && nullToAbsent
          ? const Value.absent()
          : Value(authorImage),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      likesCount: Value(likesCount),
      commentsCount: Value(commentsCount),
      isLikedByMe: Value(isLikedByMe),
      createdAt: Value(createdAt),
      isSynced: Value(isSynced),
      syncStatus: Value(syncStatus),
      isDeleted: Value(isDeleted),
    );
  }

  factory LocalPost.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPost(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      content: serializer.fromJson<String>(json['content']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      authorName: serializer.fromJson<String>(json['authorName']),
      authorImage: serializer.fromJson<String?>(json['authorImage']),
      location: serializer.fromJson<String?>(json['location']),
      likesCount: serializer.fromJson<int>(json['likesCount']),
      commentsCount: serializer.fromJson<int>(json['commentsCount']),
      isLikedByMe: serializer.fromJson<bool>(json['isLikedByMe']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'content': serializer.toJson<String>(content),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'authorName': serializer.toJson<String>(authorName),
      'authorImage': serializer.toJson<String?>(authorImage),
      'location': serializer.toJson<String?>(location),
      'likesCount': serializer.toJson<int>(likesCount),
      'commentsCount': serializer.toJson<int>(commentsCount),
      'isLikedByMe': serializer.toJson<bool>(isLikedByMe),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSynced': serializer.toJson<bool>(isSynced),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  LocalPost copyWith(
          {int? id,
          String? userId,
          String? content,
          Value<String?> imageUrl = const Value.absent(),
          String? authorName,
          Value<String?> authorImage = const Value.absent(),
          Value<String?> location = const Value.absent(),
          int? likesCount,
          int? commentsCount,
          bool? isLikedByMe,
          DateTime? createdAt,
          bool? isSynced,
          String? syncStatus,
          bool? isDeleted}) =>
      LocalPost(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        content: content ?? this.content,
        imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
        authorName: authorName ?? this.authorName,
        authorImage: authorImage.present ? authorImage.value : this.authorImage,
        location: location.present ? location.value : this.location,
        likesCount: likesCount ?? this.likesCount,
        commentsCount: commentsCount ?? this.commentsCount,
        isLikedByMe: isLikedByMe ?? this.isLikedByMe,
        createdAt: createdAt ?? this.createdAt,
        isSynced: isSynced ?? this.isSynced,
        syncStatus: syncStatus ?? this.syncStatus,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  @override
  String toString() {
    return (StringBuffer('LocalPost(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('content: $content, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('authorName: $authorName, ')
          ..write('authorImage: $authorImage, ')
          ..write('location: $location, ')
          ..write('likesCount: $likesCount, ')
          ..write('commentsCount: $commentsCount, ')
          ..write('isLikedByMe: $isLikedByMe, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      content,
      imageUrl,
      authorName,
      authorImage,
      location,
      likesCount,
      commentsCount,
      isLikedByMe,
      createdAt,
      isSynced,
      syncStatus,
      isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPost &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.content == this.content &&
          other.imageUrl == this.imageUrl &&
          other.authorName == this.authorName &&
          other.authorImage == this.authorImage &&
          other.location == this.location &&
          other.likesCount == this.likesCount &&
          other.commentsCount == this.commentsCount &&
          other.isLikedByMe == this.isLikedByMe &&
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced &&
          other.syncStatus == this.syncStatus &&
          other.isDeleted == this.isDeleted);
}

class LocalPostsCompanion extends UpdateCompanion<LocalPost> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> content;
  final Value<String?> imageUrl;
  final Value<String> authorName;
  final Value<String?> authorImage;
  final Value<String?> location;
  final Value<int> likesCount;
  final Value<int> commentsCount;
  final Value<bool> isLikedByMe;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  final Value<String> syncStatus;
  final Value<bool> isDeleted;
  const LocalPostsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.content = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.authorName = const Value.absent(),
    this.authorImage = const Value.absent(),
    this.location = const Value.absent(),
    this.likesCount = const Value.absent(),
    this.commentsCount = const Value.absent(),
    this.isLikedByMe = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  LocalPostsCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String content,
    this.imageUrl = const Value.absent(),
    required String authorName,
    this.authorImage = const Value.absent(),
    this.location = const Value.absent(),
    this.likesCount = const Value.absent(),
    this.commentsCount = const Value.absent(),
    this.isLikedByMe = const Value.absent(),
    required DateTime createdAt,
    this.isSynced = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.isDeleted = const Value.absent(),
  })  : userId = Value(userId),
        content = Value(content),
        authorName = Value(authorName),
        createdAt = Value(createdAt);
  static Insertable<LocalPost> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? content,
    Expression<String>? imageUrl,
    Expression<String>? authorName,
    Expression<String>? authorImage,
    Expression<String>? location,
    Expression<int>? likesCount,
    Expression<int>? commentsCount,
    Expression<bool>? isLikedByMe,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSynced,
    Expression<String>? syncStatus,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (content != null) 'content': content,
      if (imageUrl != null) 'image_url': imageUrl,
      if (authorName != null) 'author_name': authorName,
      if (authorImage != null) 'author_image': authorImage,
      if (location != null) 'location': location,
      if (likesCount != null) 'likes_count': likesCount,
      if (commentsCount != null) 'comments_count': commentsCount,
      if (isLikedByMe != null) 'is_liked_by_me': isLikedByMe,
      if (createdAt != null) 'created_at': createdAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  LocalPostsCompanion copyWith(
      {Value<int>? id,
      Value<String>? userId,
      Value<String>? content,
      Value<String?>? imageUrl,
      Value<String>? authorName,
      Value<String?>? authorImage,
      Value<String?>? location,
      Value<int>? likesCount,
      Value<int>? commentsCount,
      Value<bool>? isLikedByMe,
      Value<DateTime>? createdAt,
      Value<bool>? isSynced,
      Value<String>? syncStatus,
      Value<bool>? isDeleted}) {
    return LocalPostsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      authorName: authorName ?? this.authorName,
      authorImage: authorImage ?? this.authorImage,
      location: location ?? this.location,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (authorName.present) {
      map['author_name'] = Variable<String>(authorName.value);
    }
    if (authorImage.present) {
      map['author_image'] = Variable<String>(authorImage.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (likesCount.present) {
      map['likes_count'] = Variable<int>(likesCount.value);
    }
    if (commentsCount.present) {
      map['comments_count'] = Variable<int>(commentsCount.value);
    }
    if (isLikedByMe.present) {
      map['is_liked_by_me'] = Variable<bool>(isLikedByMe.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPostsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('content: $content, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('authorName: $authorName, ')
          ..write('authorImage: $authorImage, ')
          ..write('location: $location, ')
          ..write('likesCount: $likesCount, ')
          ..write('commentsCount: $commentsCount, ')
          ..write('isLikedByMe: $isLikedByMe, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $LocalAppointmentsTable extends LocalAppointments
    with TableInfo<$LocalAppointmentsTable, LocalAppointment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAppointmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _doctorIdMeta =
      const VerificationMeta('doctorId');
  @override
  late final GeneratedColumn<String> doctorId = GeneratedColumn<String>(
      'doctor_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _petIdMeta = const VerificationMeta('petId');
  @override
  late final GeneratedColumn<String> petId = GeneratedColumn<String>(
      'pet_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<String> time = GeneratedColumn<String>(
      'time', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _doctorNameMeta =
      const VerificationMeta('doctorName');
  @override
  late final GeneratedColumn<String> doctorName = GeneratedColumn<String>(
      'doctor_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _doctorImageMeta =
      const VerificationMeta('doctorImage');
  @override
  late final GeneratedColumn<String> doctorImage = GeneratedColumn<String>(
      'doctor_image', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _doctorSpecialtyMeta =
      const VerificationMeta('doctorSpecialty');
  @override
  late final GeneratedColumn<String> doctorSpecialty = GeneratedColumn<String>(
      'doctor_specialty', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _clinicNameMeta =
      const VerificationMeta('clinicName');
  @override
  late final GeneratedColumn<String> clinicName = GeneratedColumn<String>(
      'clinic_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _petNameMeta =
      const VerificationMeta('petName');
  @override
  late final GeneratedColumn<String> petName = GeneratedColumn<String>(
      'pet_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _petEmojiMeta =
      const VerificationMeta('petEmoji');
  @override
  late final GeneratedColumn<String> petEmoji = GeneratedColumn<String>(
      'pet_emoji', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('synced'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        doctorId,
        petId,
        date,
        time,
        type,
        status,
        createdAt,
        doctorName,
        doctorImage,
        doctorSpecialty,
        clinicName,
        petName,
        petEmoji,
        isSynced,
        syncStatus
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_appointments';
  @override
  VerificationContext validateIntegrity(Insertable<LocalAppointment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('doctor_id')) {
      context.handle(_doctorIdMeta,
          doctorId.isAcceptableOrUnknown(data['doctor_id']!, _doctorIdMeta));
    } else if (isInserting) {
      context.missing(_doctorIdMeta);
    }
    if (data.containsKey('pet_id')) {
      context.handle(
          _petIdMeta, petId.isAcceptableOrUnknown(data['pet_id']!, _petIdMeta));
    } else if (isInserting) {
      context.missing(_petIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('time')) {
      context.handle(
          _timeMeta, time.isAcceptableOrUnknown(data['time']!, _timeMeta));
    } else if (isInserting) {
      context.missing(_timeMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('doctor_name')) {
      context.handle(
          _doctorNameMeta,
          doctorName.isAcceptableOrUnknown(
              data['doctor_name']!, _doctorNameMeta));
    }
    if (data.containsKey('doctor_image')) {
      context.handle(
          _doctorImageMeta,
          doctorImage.isAcceptableOrUnknown(
              data['doctor_image']!, _doctorImageMeta));
    }
    if (data.containsKey('doctor_specialty')) {
      context.handle(
          _doctorSpecialtyMeta,
          doctorSpecialty.isAcceptableOrUnknown(
              data['doctor_specialty']!, _doctorSpecialtyMeta));
    }
    if (data.containsKey('clinic_name')) {
      context.handle(
          _clinicNameMeta,
          clinicName.isAcceptableOrUnknown(
              data['clinic_name']!, _clinicNameMeta));
    }
    if (data.containsKey('pet_name')) {
      context.handle(_petNameMeta,
          petName.isAcceptableOrUnknown(data['pet_name']!, _petNameMeta));
    }
    if (data.containsKey('pet_emoji')) {
      context.handle(_petEmojiMeta,
          petEmoji.isAcceptableOrUnknown(data['pet_emoji']!, _petEmojiMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalAppointment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAppointment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      doctorId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}doctor_id'])!,
      petId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pet_id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      time: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}time'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      doctorName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}doctor_name']),
      doctorImage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}doctor_image']),
      doctorSpecialty: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}doctor_specialty']),
      clinicName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}clinic_name']),
      petName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pet_name']),
      petEmoji: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pet_emoji']),
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
    );
  }

  @override
  $LocalAppointmentsTable createAlias(String alias) {
    return $LocalAppointmentsTable(attachedDatabase, alias);
  }
}

class LocalAppointment extends DataClass
    implements Insertable<LocalAppointment> {
  final String id;
  final String userId;
  final String doctorId;
  final String petId;
  final DateTime date;
  final String time;
  final String type;
  final String status;
  final DateTime createdAt;
  final String? doctorName;
  final String? doctorImage;
  final String? doctorSpecialty;
  final String? clinicName;
  final String? petName;
  final String? petEmoji;
  final bool isSynced;
  final String syncStatus;
  const LocalAppointment(
      {required this.id,
      required this.userId,
      required this.doctorId,
      required this.petId,
      required this.date,
      required this.time,
      required this.type,
      required this.status,
      required this.createdAt,
      this.doctorName,
      this.doctorImage,
      this.doctorSpecialty,
      this.clinicName,
      this.petName,
      this.petEmoji,
      required this.isSynced,
      required this.syncStatus});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['doctor_id'] = Variable<String>(doctorId);
    map['pet_id'] = Variable<String>(petId);
    map['date'] = Variable<DateTime>(date);
    map['time'] = Variable<String>(time);
    map['type'] = Variable<String>(type);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || doctorName != null) {
      map['doctor_name'] = Variable<String>(doctorName);
    }
    if (!nullToAbsent || doctorImage != null) {
      map['doctor_image'] = Variable<String>(doctorImage);
    }
    if (!nullToAbsent || doctorSpecialty != null) {
      map['doctor_specialty'] = Variable<String>(doctorSpecialty);
    }
    if (!nullToAbsent || clinicName != null) {
      map['clinic_name'] = Variable<String>(clinicName);
    }
    if (!nullToAbsent || petName != null) {
      map['pet_name'] = Variable<String>(petName);
    }
    if (!nullToAbsent || petEmoji != null) {
      map['pet_emoji'] = Variable<String>(petEmoji);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  LocalAppointmentsCompanion toCompanion(bool nullToAbsent) {
    return LocalAppointmentsCompanion(
      id: Value(id),
      userId: Value(userId),
      doctorId: Value(doctorId),
      petId: Value(petId),
      date: Value(date),
      time: Value(time),
      type: Value(type),
      status: Value(status),
      createdAt: Value(createdAt),
      doctorName: doctorName == null && nullToAbsent
          ? const Value.absent()
          : Value(doctorName),
      doctorImage: doctorImage == null && nullToAbsent
          ? const Value.absent()
          : Value(doctorImage),
      doctorSpecialty: doctorSpecialty == null && nullToAbsent
          ? const Value.absent()
          : Value(doctorSpecialty),
      clinicName: clinicName == null && nullToAbsent
          ? const Value.absent()
          : Value(clinicName),
      petName: petName == null && nullToAbsent
          ? const Value.absent()
          : Value(petName),
      petEmoji: petEmoji == null && nullToAbsent
          ? const Value.absent()
          : Value(petEmoji),
      isSynced: Value(isSynced),
      syncStatus: Value(syncStatus),
    );
  }

  factory LocalAppointment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAppointment(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      doctorId: serializer.fromJson<String>(json['doctorId']),
      petId: serializer.fromJson<String>(json['petId']),
      date: serializer.fromJson<DateTime>(json['date']),
      time: serializer.fromJson<String>(json['time']),
      type: serializer.fromJson<String>(json['type']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      doctorName: serializer.fromJson<String?>(json['doctorName']),
      doctorImage: serializer.fromJson<String?>(json['doctorImage']),
      doctorSpecialty: serializer.fromJson<String?>(json['doctorSpecialty']),
      clinicName: serializer.fromJson<String?>(json['clinicName']),
      petName: serializer.fromJson<String?>(json['petName']),
      petEmoji: serializer.fromJson<String?>(json['petEmoji']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'doctorId': serializer.toJson<String>(doctorId),
      'petId': serializer.toJson<String>(petId),
      'date': serializer.toJson<DateTime>(date),
      'time': serializer.toJson<String>(time),
      'type': serializer.toJson<String>(type),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'doctorName': serializer.toJson<String?>(doctorName),
      'doctorImage': serializer.toJson<String?>(doctorImage),
      'doctorSpecialty': serializer.toJson<String?>(doctorSpecialty),
      'clinicName': serializer.toJson<String?>(clinicName),
      'petName': serializer.toJson<String?>(petName),
      'petEmoji': serializer.toJson<String?>(petEmoji),
      'isSynced': serializer.toJson<bool>(isSynced),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  LocalAppointment copyWith(
          {String? id,
          String? userId,
          String? doctorId,
          String? petId,
          DateTime? date,
          String? time,
          String? type,
          String? status,
          DateTime? createdAt,
          Value<String?> doctorName = const Value.absent(),
          Value<String?> doctorImage = const Value.absent(),
          Value<String?> doctorSpecialty = const Value.absent(),
          Value<String?> clinicName = const Value.absent(),
          Value<String?> petName = const Value.absent(),
          Value<String?> petEmoji = const Value.absent(),
          bool? isSynced,
          String? syncStatus}) =>
      LocalAppointment(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        doctorId: doctorId ?? this.doctorId,
        petId: petId ?? this.petId,
        date: date ?? this.date,
        time: time ?? this.time,
        type: type ?? this.type,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        doctorName: doctorName.present ? doctorName.value : this.doctorName,
        doctorImage: doctorImage.present ? doctorImage.value : this.doctorImage,
        doctorSpecialty: doctorSpecialty.present
            ? doctorSpecialty.value
            : this.doctorSpecialty,
        clinicName: clinicName.present ? clinicName.value : this.clinicName,
        petName: petName.present ? petName.value : this.petName,
        petEmoji: petEmoji.present ? petEmoji.value : this.petEmoji,
        isSynced: isSynced ?? this.isSynced,
        syncStatus: syncStatus ?? this.syncStatus,
      );
  @override
  String toString() {
    return (StringBuffer('LocalAppointment(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('doctorId: $doctorId, ')
          ..write('petId: $petId, ')
          ..write('date: $date, ')
          ..write('time: $time, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('doctorName: $doctorName, ')
          ..write('doctorImage: $doctorImage, ')
          ..write('doctorSpecialty: $doctorSpecialty, ')
          ..write('clinicName: $clinicName, ')
          ..write('petName: $petName, ')
          ..write('petEmoji: $petEmoji, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      doctorId,
      petId,
      date,
      time,
      type,
      status,
      createdAt,
      doctorName,
      doctorImage,
      doctorSpecialty,
      clinicName,
      petName,
      petEmoji,
      isSynced,
      syncStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAppointment &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.doctorId == this.doctorId &&
          other.petId == this.petId &&
          other.date == this.date &&
          other.time == this.time &&
          other.type == this.type &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.doctorName == this.doctorName &&
          other.doctorImage == this.doctorImage &&
          other.doctorSpecialty == this.doctorSpecialty &&
          other.clinicName == this.clinicName &&
          other.petName == this.petName &&
          other.petEmoji == this.petEmoji &&
          other.isSynced == this.isSynced &&
          other.syncStatus == this.syncStatus);
}

class LocalAppointmentsCompanion extends UpdateCompanion<LocalAppointment> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> doctorId;
  final Value<String> petId;
  final Value<DateTime> date;
  final Value<String> time;
  final Value<String> type;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<String?> doctorName;
  final Value<String?> doctorImage;
  final Value<String?> doctorSpecialty;
  final Value<String?> clinicName;
  final Value<String?> petName;
  final Value<String?> petEmoji;
  final Value<bool> isSynced;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const LocalAppointmentsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.doctorId = const Value.absent(),
    this.petId = const Value.absent(),
    this.date = const Value.absent(),
    this.time = const Value.absent(),
    this.type = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.doctorName = const Value.absent(),
    this.doctorImage = const Value.absent(),
    this.doctorSpecialty = const Value.absent(),
    this.clinicName = const Value.absent(),
    this.petName = const Value.absent(),
    this.petEmoji = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalAppointmentsCompanion.insert({
    required String id,
    required String userId,
    required String doctorId,
    required String petId,
    required DateTime date,
    required String time,
    required String type,
    this.status = const Value.absent(),
    required DateTime createdAt,
    this.doctorName = const Value.absent(),
    this.doctorImage = const Value.absent(),
    this.doctorSpecialty = const Value.absent(),
    this.clinicName = const Value.absent(),
    this.petName = const Value.absent(),
    this.petEmoji = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        doctorId = Value(doctorId),
        petId = Value(petId),
        date = Value(date),
        time = Value(time),
        type = Value(type),
        createdAt = Value(createdAt);
  static Insertable<LocalAppointment> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? doctorId,
    Expression<String>? petId,
    Expression<DateTime>? date,
    Expression<String>? time,
    Expression<String>? type,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<String>? doctorName,
    Expression<String>? doctorImage,
    Expression<String>? doctorSpecialty,
    Expression<String>? clinicName,
    Expression<String>? petName,
    Expression<String>? petEmoji,
    Expression<bool>? isSynced,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (doctorId != null) 'doctor_id': doctorId,
      if (petId != null) 'pet_id': petId,
      if (date != null) 'date': date,
      if (time != null) 'time': time,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (doctorName != null) 'doctor_name': doctorName,
      if (doctorImage != null) 'doctor_image': doctorImage,
      if (doctorSpecialty != null) 'doctor_specialty': doctorSpecialty,
      if (clinicName != null) 'clinic_name': clinicName,
      if (petName != null) 'pet_name': petName,
      if (petEmoji != null) 'pet_emoji': petEmoji,
      if (isSynced != null) 'is_synced': isSynced,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalAppointmentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? doctorId,
      Value<String>? petId,
      Value<DateTime>? date,
      Value<String>? time,
      Value<String>? type,
      Value<String>? status,
      Value<DateTime>? createdAt,
      Value<String?>? doctorName,
      Value<String?>? doctorImage,
      Value<String?>? doctorSpecialty,
      Value<String?>? clinicName,
      Value<String?>? petName,
      Value<String?>? petEmoji,
      Value<bool>? isSynced,
      Value<String>? syncStatus,
      Value<int>? rowid}) {
    return LocalAppointmentsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      doctorId: doctorId ?? this.doctorId,
      petId: petId ?? this.petId,
      date: date ?? this.date,
      time: time ?? this.time,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      doctorName: doctorName ?? this.doctorName,
      doctorImage: doctorImage ?? this.doctorImage,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      clinicName: clinicName ?? this.clinicName,
      petName: petName ?? this.petName,
      petEmoji: petEmoji ?? this.petEmoji,
      isSynced: isSynced ?? this.isSynced,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (doctorId.present) {
      map['doctor_id'] = Variable<String>(doctorId.value);
    }
    if (petId.present) {
      map['pet_id'] = Variable<String>(petId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (time.present) {
      map['time'] = Variable<String>(time.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (doctorName.present) {
      map['doctor_name'] = Variable<String>(doctorName.value);
    }
    if (doctorImage.present) {
      map['doctor_image'] = Variable<String>(doctorImage.value);
    }
    if (doctorSpecialty.present) {
      map['doctor_specialty'] = Variable<String>(doctorSpecialty.value);
    }
    if (clinicName.present) {
      map['clinic_name'] = Variable<String>(clinicName.value);
    }
    if (petName.present) {
      map['pet_name'] = Variable<String>(petName.value);
    }
    if (petEmoji.present) {
      map['pet_emoji'] = Variable<String>(petEmoji.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAppointmentsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('doctorId: $doctorId, ')
          ..write('petId: $petId, ')
          ..write('date: $date, ')
          ..write('time: $time, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('doctorName: $doctorName, ')
          ..write('doctorImage: $doctorImage, ')
          ..write('doctorSpecialty: $doctorSpecialty, ')
          ..write('clinicName: $clinicName, ')
          ..write('petName: $petName, ')
          ..write('petEmoji: $petEmoji, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPetsTable extends LocalPets
    with TableInfo<$LocalPetsTable, LocalPet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _breedMeta = const VerificationMeta('breed');
  @override
  late final GeneratedColumn<String> breed = GeneratedColumn<String>(
      'breed', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
      'gender', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ageMeta = const VerificationMeta('age');
  @override
  late final GeneratedColumn<String> age = GeneratedColumn<String>(
      'age', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<String> weight = GeneratedColumn<String>(
      'weight', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<String> height = GeneratedColumn<String>(
      'height', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _healthMeta = const VerificationMeta('health');
  @override
  late final GeneratedColumn<String> health = GeneratedColumn<String>(
      'health', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
      'emoji', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imageUrlMeta =
      const VerificationMeta('imageUrl');
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
      'image_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nextCheckupMeta =
      const VerificationMeta('nextCheckup');
  @override
  late final GeneratedColumn<DateTime> nextCheckup = GeneratedColumn<DateTime>(
      'next_checkup', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('synced'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        ownerId,
        name,
        type,
        breed,
        gender,
        age,
        weight,
        height,
        health,
        emoji,
        imageUrl,
        nextCheckup,
        createdAt,
        isSynced,
        syncStatus
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_pets';
  @override
  VerificationContext validateIntegrity(Insertable<LocalPet> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('breed')) {
      context.handle(
          _breedMeta, breed.isAcceptableOrUnknown(data['breed']!, _breedMeta));
    }
    if (data.containsKey('gender')) {
      context.handle(_genderMeta,
          gender.isAcceptableOrUnknown(data['gender']!, _genderMeta));
    }
    if (data.containsKey('age')) {
      context.handle(
          _ageMeta, age.isAcceptableOrUnknown(data['age']!, _ageMeta));
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    }
    if (data.containsKey('health')) {
      context.handle(_healthMeta,
          health.isAcceptableOrUnknown(data['health']!, _healthMeta));
    }
    if (data.containsKey('emoji')) {
      context.handle(
          _emojiMeta, emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta));
    }
    if (data.containsKey('image_url')) {
      context.handle(_imageUrlMeta,
          imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta));
    }
    if (data.containsKey('next_checkup')) {
      context.handle(
          _nextCheckupMeta,
          nextCheckup.isAcceptableOrUnknown(
              data['next_checkup']!, _nextCheckupMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalPet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPet(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      breed: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}breed']),
      gender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gender']),
      age: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}age']),
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}weight']),
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}height']),
      health: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}health']),
      emoji: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}emoji']),
      imageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_url']),
      nextCheckup: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}next_checkup']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
    );
  }

  @override
  $LocalPetsTable createAlias(String alias) {
    return $LocalPetsTable(attachedDatabase, alias);
  }
}

class LocalPet extends DataClass implements Insertable<LocalPet> {
  final String id;
  final String ownerId;
  final String name;
  final String type;
  final String? breed;
  final String? gender;
  final String? age;
  final String? weight;
  final String? height;
  final String? health;
  final String? emoji;
  final String? imageUrl;
  final DateTime? nextCheckup;
  final DateTime createdAt;
  final bool isSynced;
  final String syncStatus;
  const LocalPet(
      {required this.id,
      required this.ownerId,
      required this.name,
      required this.type,
      this.breed,
      this.gender,
      this.age,
      this.weight,
      this.height,
      this.health,
      this.emoji,
      this.imageUrl,
      this.nextCheckup,
      required this.createdAt,
      required this.isSynced,
      required this.syncStatus});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_id'] = Variable<String>(ownerId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || breed != null) {
      map['breed'] = Variable<String>(breed);
    }
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(gender);
    }
    if (!nullToAbsent || age != null) {
      map['age'] = Variable<String>(age);
    }
    if (!nullToAbsent || weight != null) {
      map['weight'] = Variable<String>(weight);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<String>(height);
    }
    if (!nullToAbsent || health != null) {
      map['health'] = Variable<String>(health);
    }
    if (!nullToAbsent || emoji != null) {
      map['emoji'] = Variable<String>(emoji);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || nextCheckup != null) {
      map['next_checkup'] = Variable<DateTime>(nextCheckup);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced'] = Variable<bool>(isSynced);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  LocalPetsCompanion toCompanion(bool nullToAbsent) {
    return LocalPetsCompanion(
      id: Value(id),
      ownerId: Value(ownerId),
      name: Value(name),
      type: Value(type),
      breed:
          breed == null && nullToAbsent ? const Value.absent() : Value(breed),
      gender:
          gender == null && nullToAbsent ? const Value.absent() : Value(gender),
      age: age == null && nullToAbsent ? const Value.absent() : Value(age),
      weight:
          weight == null && nullToAbsent ? const Value.absent() : Value(weight),
      height:
          height == null && nullToAbsent ? const Value.absent() : Value(height),
      health:
          health == null && nullToAbsent ? const Value.absent() : Value(health),
      emoji:
          emoji == null && nullToAbsent ? const Value.absent() : Value(emoji),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      nextCheckup: nextCheckup == null && nullToAbsent
          ? const Value.absent()
          : Value(nextCheckup),
      createdAt: Value(createdAt),
      isSynced: Value(isSynced),
      syncStatus: Value(syncStatus),
    );
  }

  factory LocalPet.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPet(
      id: serializer.fromJson<String>(json['id']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      breed: serializer.fromJson<String?>(json['breed']),
      gender: serializer.fromJson<String?>(json['gender']),
      age: serializer.fromJson<String?>(json['age']),
      weight: serializer.fromJson<String?>(json['weight']),
      height: serializer.fromJson<String?>(json['height']),
      health: serializer.fromJson<String?>(json['health']),
      emoji: serializer.fromJson<String?>(json['emoji']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      nextCheckup: serializer.fromJson<DateTime?>(json['nextCheckup']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerId': serializer.toJson<String>(ownerId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'breed': serializer.toJson<String?>(breed),
      'gender': serializer.toJson<String?>(gender),
      'age': serializer.toJson<String?>(age),
      'weight': serializer.toJson<String?>(weight),
      'height': serializer.toJson<String?>(height),
      'health': serializer.toJson<String?>(health),
      'emoji': serializer.toJson<String?>(emoji),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'nextCheckup': serializer.toJson<DateTime?>(nextCheckup),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSynced': serializer.toJson<bool>(isSynced),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  LocalPet copyWith(
          {String? id,
          String? ownerId,
          String? name,
          String? type,
          Value<String?> breed = const Value.absent(),
          Value<String?> gender = const Value.absent(),
          Value<String?> age = const Value.absent(),
          Value<String?> weight = const Value.absent(),
          Value<String?> height = const Value.absent(),
          Value<String?> health = const Value.absent(),
          Value<String?> emoji = const Value.absent(),
          Value<String?> imageUrl = const Value.absent(),
          Value<DateTime?> nextCheckup = const Value.absent(),
          DateTime? createdAt,
          bool? isSynced,
          String? syncStatus}) =>
      LocalPet(
        id: id ?? this.id,
        ownerId: ownerId ?? this.ownerId,
        name: name ?? this.name,
        type: type ?? this.type,
        breed: breed.present ? breed.value : this.breed,
        gender: gender.present ? gender.value : this.gender,
        age: age.present ? age.value : this.age,
        weight: weight.present ? weight.value : this.weight,
        height: height.present ? height.value : this.height,
        health: health.present ? health.value : this.health,
        emoji: emoji.present ? emoji.value : this.emoji,
        imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
        nextCheckup: nextCheckup.present ? nextCheckup.value : this.nextCheckup,
        createdAt: createdAt ?? this.createdAt,
        isSynced: isSynced ?? this.isSynced,
        syncStatus: syncStatus ?? this.syncStatus,
      );
  @override
  String toString() {
    return (StringBuffer('LocalPet(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('breed: $breed, ')
          ..write('gender: $gender, ')
          ..write('age: $age, ')
          ..write('weight: $weight, ')
          ..write('height: $height, ')
          ..write('health: $health, ')
          ..write('emoji: $emoji, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('nextCheckup: $nextCheckup, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      ownerId,
      name,
      type,
      breed,
      gender,
      age,
      weight,
      height,
      health,
      emoji,
      imageUrl,
      nextCheckup,
      createdAt,
      isSynced,
      syncStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPet &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.name == this.name &&
          other.type == this.type &&
          other.breed == this.breed &&
          other.gender == this.gender &&
          other.age == this.age &&
          other.weight == this.weight &&
          other.height == this.height &&
          other.health == this.health &&
          other.emoji == this.emoji &&
          other.imageUrl == this.imageUrl &&
          other.nextCheckup == this.nextCheckup &&
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced &&
          other.syncStatus == this.syncStatus);
}

class LocalPetsCompanion extends UpdateCompanion<LocalPet> {
  final Value<String> id;
  final Value<String> ownerId;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> breed;
  final Value<String?> gender;
  final Value<String?> age;
  final Value<String?> weight;
  final Value<String?> height;
  final Value<String?> health;
  final Value<String?> emoji;
  final Value<String?> imageUrl;
  final Value<DateTime?> nextCheckup;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const LocalPetsCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.breed = const Value.absent(),
    this.gender = const Value.absent(),
    this.age = const Value.absent(),
    this.weight = const Value.absent(),
    this.height = const Value.absent(),
    this.health = const Value.absent(),
    this.emoji = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.nextCheckup = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPetsCompanion.insert({
    required String id,
    required String ownerId,
    required String name,
    required String type,
    this.breed = const Value.absent(),
    this.gender = const Value.absent(),
    this.age = const Value.absent(),
    this.weight = const Value.absent(),
    this.height = const Value.absent(),
    this.health = const Value.absent(),
    this.emoji = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.nextCheckup = const Value.absent(),
    required DateTime createdAt,
    this.isSynced = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        ownerId = Value(ownerId),
        name = Value(name),
        type = Value(type),
        createdAt = Value(createdAt);
  static Insertable<LocalPet> custom({
    Expression<String>? id,
    Expression<String>? ownerId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? breed,
    Expression<String>? gender,
    Expression<String>? age,
    Expression<String>? weight,
    Expression<String>? height,
    Expression<String>? health,
    Expression<String>? emoji,
    Expression<String>? imageUrl,
    Expression<DateTime>? nextCheckup,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSynced,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (breed != null) 'breed': breed,
      if (gender != null) 'gender': gender,
      if (age != null) 'age': age,
      if (weight != null) 'weight': weight,
      if (height != null) 'height': height,
      if (health != null) 'health': health,
      if (emoji != null) 'emoji': emoji,
      if (imageUrl != null) 'image_url': imageUrl,
      if (nextCheckup != null) 'next_checkup': nextCheckup,
      if (createdAt != null) 'created_at': createdAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPetsCompanion copyWith(
      {Value<String>? id,
      Value<String>? ownerId,
      Value<String>? name,
      Value<String>? type,
      Value<String?>? breed,
      Value<String?>? gender,
      Value<String?>? age,
      Value<String?>? weight,
      Value<String?>? height,
      Value<String?>? health,
      Value<String?>? emoji,
      Value<String?>? imageUrl,
      Value<DateTime?>? nextCheckup,
      Value<DateTime>? createdAt,
      Value<bool>? isSynced,
      Value<String>? syncStatus,
      Value<int>? rowid}) {
    return LocalPetsCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      type: type ?? this.type,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      health: health ?? this.health,
      emoji: emoji ?? this.emoji,
      imageUrl: imageUrl ?? this.imageUrl,
      nextCheckup: nextCheckup ?? this.nextCheckup,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (breed.present) {
      map['breed'] = Variable<String>(breed.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (age.present) {
      map['age'] = Variable<String>(age.value);
    }
    if (weight.present) {
      map['weight'] = Variable<String>(weight.value);
    }
    if (height.present) {
      map['height'] = Variable<String>(height.value);
    }
    if (health.present) {
      map['health'] = Variable<String>(health.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (nextCheckup.present) {
      map['next_checkup'] = Variable<DateTime>(nextCheckup.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPetsCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('breed: $breed, ')
          ..write('gender: $gender, ')
          ..write('age: $age, ')
          ..write('weight: $weight, ')
          ..write('height: $height, ')
          ..write('health: $health, ')
          ..write('emoji: $emoji, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('nextCheckup: $nextCheckup, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalUsersTable extends LocalUsers
    with TableInfo<$LocalUsersTable, LocalUser> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalUsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pet_owner'));
  static const VerificationMeta _profileImageMeta =
      const VerificationMeta('profileImage');
  @override
  late final GeneratedColumn<String> profileImage = GeneratedColumn<String>(
      'profile_image', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _specialtyMeta =
      const VerificationMeta('specialty');
  @override
  late final GeneratedColumn<String> specialty = GeneratedColumn<String>(
      'specialty', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _clinicMeta = const VerificationMeta('clinic');
  @override
  late final GeneratedColumn<String> clinic = GeneratedColumn<String>(
      'clinic', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bioMeta = const VerificationMeta('bio');
  @override
  late final GeneratedColumn<String> bio = GeneratedColumn<String>(
      'bio', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
      'rating', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _reviewsCountMeta =
      const VerificationMeta('reviewsCount');
  @override
  late final GeneratedColumn<int> reviewsCount = GeneratedColumn<int>(
      'reviews_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _localUpdatedAtMeta =
      const VerificationMeta('localUpdatedAt');
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>('local_updated_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        email,
        name,
        phone,
        role,
        profileImage,
        specialty,
        clinic,
        bio,
        username,
        rating,
        reviewsCount,
        createdAt,
        isSynced,
        localUpdatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_users';
  @override
  VerificationContext validateIntegrity(Insertable<LocalUser> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    }
    if (data.containsKey('profile_image')) {
      context.handle(
          _profileImageMeta,
          profileImage.isAcceptableOrUnknown(
              data['profile_image']!, _profileImageMeta));
    }
    if (data.containsKey('specialty')) {
      context.handle(_specialtyMeta,
          specialty.isAcceptableOrUnknown(data['specialty']!, _specialtyMeta));
    }
    if (data.containsKey('clinic')) {
      context.handle(_clinicMeta,
          clinic.isAcceptableOrUnknown(data['clinic']!, _clinicMeta));
    }
    if (data.containsKey('bio')) {
      context.handle(
          _bioMeta, bio.isAcceptableOrUnknown(data['bio']!, _bioMeta));
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    }
    if (data.containsKey('reviews_count')) {
      context.handle(
          _reviewsCountMeta,
          reviewsCount.isAcceptableOrUnknown(
              data['reviews_count']!, _reviewsCountMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
          _localUpdatedAtMeta,
          localUpdatedAt.isAcceptableOrUnknown(
              data['local_updated_at']!, _localUpdatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalUser map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalUser(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      profileImage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile_image']),
      specialty: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}specialty']),
      clinic: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}clinic']),
      bio: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bio']),
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username']),
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rating']),
      reviewsCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reviews_count'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      localUpdatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}local_updated_at']),
    );
  }

  @override
  $LocalUsersTable createAlias(String alias) {
    return $LocalUsersTable(attachedDatabase, alias);
  }
}

class LocalUser extends DataClass implements Insertable<LocalUser> {
  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String role;
  final String? profileImage;
  final String? specialty;
  final String? clinic;
  final String? bio;
  final String? username;
  final double? rating;
  final int reviewsCount;
  final DateTime createdAt;
  final bool isSynced;
  final DateTime? localUpdatedAt;
  const LocalUser(
      {required this.id,
      required this.email,
      this.name,
      this.phone,
      required this.role,
      this.profileImage,
      this.specialty,
      this.clinic,
      this.bio,
      this.username,
      this.rating,
      required this.reviewsCount,
      required this.createdAt,
      required this.isSynced,
      this.localUpdatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || profileImage != null) {
      map['profile_image'] = Variable<String>(profileImage);
    }
    if (!nullToAbsent || specialty != null) {
      map['specialty'] = Variable<String>(specialty);
    }
    if (!nullToAbsent || clinic != null) {
      map['clinic'] = Variable<String>(clinic);
    }
    if (!nullToAbsent || bio != null) {
      map['bio'] = Variable<String>(bio);
    }
    if (!nullToAbsent || username != null) {
      map['username'] = Variable<String>(username);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<double>(rating);
    }
    map['reviews_count'] = Variable<int>(reviewsCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || localUpdatedAt != null) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    }
    return map;
  }

  LocalUsersCompanion toCompanion(bool nullToAbsent) {
    return LocalUsersCompanion(
      id: Value(id),
      email: Value(email),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      role: Value(role),
      profileImage: profileImage == null && nullToAbsent
          ? const Value.absent()
          : Value(profileImage),
      specialty: specialty == null && nullToAbsent
          ? const Value.absent()
          : Value(specialty),
      clinic:
          clinic == null && nullToAbsent ? const Value.absent() : Value(clinic),
      bio: bio == null && nullToAbsent ? const Value.absent() : Value(bio),
      username: username == null && nullToAbsent
          ? const Value.absent()
          : Value(username),
      rating:
          rating == null && nullToAbsent ? const Value.absent() : Value(rating),
      reviewsCount: Value(reviewsCount),
      createdAt: Value(createdAt),
      isSynced: Value(isSynced),
      localUpdatedAt: localUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(localUpdatedAt),
    );
  }

  factory LocalUser.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalUser(
      id: serializer.fromJson<String>(json['id']),
      email: serializer.fromJson<String>(json['email']),
      name: serializer.fromJson<String?>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      role: serializer.fromJson<String>(json['role']),
      profileImage: serializer.fromJson<String?>(json['profileImage']),
      specialty: serializer.fromJson<String?>(json['specialty']),
      clinic: serializer.fromJson<String?>(json['clinic']),
      bio: serializer.fromJson<String?>(json['bio']),
      username: serializer.fromJson<String?>(json['username']),
      rating: serializer.fromJson<double?>(json['rating']),
      reviewsCount: serializer.fromJson<int>(json['reviewsCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      localUpdatedAt: serializer.fromJson<DateTime?>(json['localUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'email': serializer.toJson<String>(email),
      'name': serializer.toJson<String?>(name),
      'phone': serializer.toJson<String?>(phone),
      'role': serializer.toJson<String>(role),
      'profileImage': serializer.toJson<String?>(profileImage),
      'specialty': serializer.toJson<String?>(specialty),
      'clinic': serializer.toJson<String?>(clinic),
      'bio': serializer.toJson<String?>(bio),
      'username': serializer.toJson<String?>(username),
      'rating': serializer.toJson<double?>(rating),
      'reviewsCount': serializer.toJson<int>(reviewsCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSynced': serializer.toJson<bool>(isSynced),
      'localUpdatedAt': serializer.toJson<DateTime?>(localUpdatedAt),
    };
  }

  LocalUser copyWith(
          {String? id,
          String? email,
          Value<String?> name = const Value.absent(),
          Value<String?> phone = const Value.absent(),
          String? role,
          Value<String?> profileImage = const Value.absent(),
          Value<String?> specialty = const Value.absent(),
          Value<String?> clinic = const Value.absent(),
          Value<String?> bio = const Value.absent(),
          Value<String?> username = const Value.absent(),
          Value<double?> rating = const Value.absent(),
          int? reviewsCount,
          DateTime? createdAt,
          bool? isSynced,
          Value<DateTime?> localUpdatedAt = const Value.absent()}) =>
      LocalUser(
        id: id ?? this.id,
        email: email ?? this.email,
        name: name.present ? name.value : this.name,
        phone: phone.present ? phone.value : this.phone,
        role: role ?? this.role,
        profileImage:
            profileImage.present ? profileImage.value : this.profileImage,
        specialty: specialty.present ? specialty.value : this.specialty,
        clinic: clinic.present ? clinic.value : this.clinic,
        bio: bio.present ? bio.value : this.bio,
        username: username.present ? username.value : this.username,
        rating: rating.present ? rating.value : this.rating,
        reviewsCount: reviewsCount ?? this.reviewsCount,
        createdAt: createdAt ?? this.createdAt,
        isSynced: isSynced ?? this.isSynced,
        localUpdatedAt:
            localUpdatedAt.present ? localUpdatedAt.value : this.localUpdatedAt,
      );
  @override
  String toString() {
    return (StringBuffer('LocalUser(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('role: $role, ')
          ..write('profileImage: $profileImage, ')
          ..write('specialty: $specialty, ')
          ..write('clinic: $clinic, ')
          ..write('bio: $bio, ')
          ..write('username: $username, ')
          ..write('rating: $rating, ')
          ..write('reviewsCount: $reviewsCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('localUpdatedAt: $localUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      email,
      name,
      phone,
      role,
      profileImage,
      specialty,
      clinic,
      bio,
      username,
      rating,
      reviewsCount,
      createdAt,
      isSynced,
      localUpdatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalUser &&
          other.id == this.id &&
          other.email == this.email &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.role == this.role &&
          other.profileImage == this.profileImage &&
          other.specialty == this.specialty &&
          other.clinic == this.clinic &&
          other.bio == this.bio &&
          other.username == this.username &&
          other.rating == this.rating &&
          other.reviewsCount == this.reviewsCount &&
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced &&
          other.localUpdatedAt == this.localUpdatedAt);
}

class LocalUsersCompanion extends UpdateCompanion<LocalUser> {
  final Value<String> id;
  final Value<String> email;
  final Value<String?> name;
  final Value<String?> phone;
  final Value<String> role;
  final Value<String?> profileImage;
  final Value<String?> specialty;
  final Value<String?> clinic;
  final Value<String?> bio;
  final Value<String?> username;
  final Value<double?> rating;
  final Value<int> reviewsCount;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  final Value<DateTime?> localUpdatedAt;
  final Value<int> rowid;
  const LocalUsersCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.role = const Value.absent(),
    this.profileImage = const Value.absent(),
    this.specialty = const Value.absent(),
    this.clinic = const Value.absent(),
    this.bio = const Value.absent(),
    this.username = const Value.absent(),
    this.rating = const Value.absent(),
    this.reviewsCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalUsersCompanion.insert({
    required String id,
    required String email,
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.role = const Value.absent(),
    this.profileImage = const Value.absent(),
    this.specialty = const Value.absent(),
    this.clinic = const Value.absent(),
    this.bio = const Value.absent(),
    this.username = const Value.absent(),
    this.rating = const Value.absent(),
    this.reviewsCount = const Value.absent(),
    required DateTime createdAt,
    this.isSynced = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        email = Value(email),
        createdAt = Value(createdAt);
  static Insertable<LocalUser> custom({
    Expression<String>? id,
    Expression<String>? email,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? role,
    Expression<String>? profileImage,
    Expression<String>? specialty,
    Expression<String>? clinic,
    Expression<String>? bio,
    Expression<String>? username,
    Expression<double>? rating,
    Expression<int>? reviewsCount,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSynced,
    Expression<DateTime>? localUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (role != null) 'role': role,
      if (profileImage != null) 'profile_image': profileImage,
      if (specialty != null) 'specialty': specialty,
      if (clinic != null) 'clinic': clinic,
      if (bio != null) 'bio': bio,
      if (username != null) 'username': username,
      if (rating != null) 'rating': rating,
      if (reviewsCount != null) 'reviews_count': reviewsCount,
      if (createdAt != null) 'created_at': createdAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalUsersCompanion copyWith(
      {Value<String>? id,
      Value<String>? email,
      Value<String?>? name,
      Value<String?>? phone,
      Value<String>? role,
      Value<String?>? profileImage,
      Value<String?>? specialty,
      Value<String?>? clinic,
      Value<String?>? bio,
      Value<String?>? username,
      Value<double?>? rating,
      Value<int>? reviewsCount,
      Value<DateTime>? createdAt,
      Value<bool>? isSynced,
      Value<DateTime?>? localUpdatedAt,
      Value<int>? rowid}) {
    return LocalUsersCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      specialty: specialty ?? this.specialty,
      clinic: clinic ?? this.clinic,
      bio: bio ?? this.bio,
      username: username ?? this.username,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (profileImage.present) {
      map['profile_image'] = Variable<String>(profileImage.value);
    }
    if (specialty.present) {
      map['specialty'] = Variable<String>(specialty.value);
    }
    if (clinic.present) {
      map['clinic'] = Variable<String>(clinic.value);
    }
    if (bio.present) {
      map['bio'] = Variable<String>(bio.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (reviewsCount.present) {
      map['reviews_count'] = Variable<int>(reviewsCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalUsersCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('role: $role, ')
          ..write('profileImage: $profileImage, ')
          ..write('specialty: $specialty, ')
          ..write('clinic: $clinic, ')
          ..write('bio: $bio, ')
          ..write('username: $username, ')
          ..write('rating: $rating, ')
          ..write('reviewsCount: $reviewsCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalDoctorsTable extends LocalDoctors
    with TableInfo<$LocalDoctorsTable, LocalDoctor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDoctorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _specialtyMeta =
      const VerificationMeta('specialty');
  @override
  late final GeneratedColumn<String> specialty = GeneratedColumn<String>(
      'specialty', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _clinicMeta = const VerificationMeta('clinic');
  @override
  late final GeneratedColumn<String> clinic = GeneratedColumn<String>(
      'clinic', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
      'rating', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _reviewsCountMeta =
      const VerificationMeta('reviewsCount');
  @override
  late final GeneratedColumn<int> reviewsCount = GeneratedColumn<int>(
      'reviews_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _profileImageMeta =
      const VerificationMeta('profileImage');
  @override
  late final GeneratedColumn<String> profileImage = GeneratedColumn<String>(
      'profile_image', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nextAvailableMeta =
      const VerificationMeta('nextAvailable');
  @override
  late final GeneratedColumn<String> nextAvailable = GeneratedColumn<String>(
      'next_available', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _availableMeta =
      const VerificationMeta('available');
  @override
  late final GeneratedColumn<bool> available = GeneratedColumn<bool>(
      'available', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("available" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _verifiedMeta =
      const VerificationMeta('verified');
  @override
  late final GeneratedColumn<bool> verified = GeneratedColumn<bool>(
      'verified', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("verified" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        name,
        specialty,
        clinic,
        rating,
        reviewsCount,
        profileImage,
        nextAvailable,
        available,
        verified,
        createdAt,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_doctors';
  @override
  VerificationContext validateIntegrity(Insertable<LocalDoctor> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('specialty')) {
      context.handle(_specialtyMeta,
          specialty.isAcceptableOrUnknown(data['specialty']!, _specialtyMeta));
    }
    if (data.containsKey('clinic')) {
      context.handle(_clinicMeta,
          clinic.isAcceptableOrUnknown(data['clinic']!, _clinicMeta));
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    }
    if (data.containsKey('reviews_count')) {
      context.handle(
          _reviewsCountMeta,
          reviewsCount.isAcceptableOrUnknown(
              data['reviews_count']!, _reviewsCountMeta));
    }
    if (data.containsKey('profile_image')) {
      context.handle(
          _profileImageMeta,
          profileImage.isAcceptableOrUnknown(
              data['profile_image']!, _profileImageMeta));
    }
    if (data.containsKey('next_available')) {
      context.handle(
          _nextAvailableMeta,
          nextAvailable.isAcceptableOrUnknown(
              data['next_available']!, _nextAvailableMeta));
    }
    if (data.containsKey('available')) {
      context.handle(_availableMeta,
          available.isAcceptableOrUnknown(data['available']!, _availableMeta));
    }
    if (data.containsKey('verified')) {
      context.handle(_verifiedMeta,
          verified.isAcceptableOrUnknown(data['verified']!, _verifiedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalDoctor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDoctor(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      specialty: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}specialty']),
      clinic: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}clinic']),
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rating'])!,
      reviewsCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reviews_count'])!,
      profileImage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile_image']),
      nextAvailable: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}next_available']),
      available: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}available'])!,
      verified: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}verified'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $LocalDoctorsTable createAlias(String alias) {
    return $LocalDoctorsTable(attachedDatabase, alias);
  }
}

class LocalDoctor extends DataClass implements Insertable<LocalDoctor> {
  final String id;
  final String userId;
  final String name;
  final String? specialty;
  final String? clinic;
  final double rating;
  final int reviewsCount;
  final String? profileImage;
  final String? nextAvailable;
  final bool available;
  final bool verified;
  final DateTime createdAt;
  final bool isSynced;
  const LocalDoctor(
      {required this.id,
      required this.userId,
      required this.name,
      this.specialty,
      this.clinic,
      required this.rating,
      required this.reviewsCount,
      this.profileImage,
      this.nextAvailable,
      required this.available,
      required this.verified,
      required this.createdAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || specialty != null) {
      map['specialty'] = Variable<String>(specialty);
    }
    if (!nullToAbsent || clinic != null) {
      map['clinic'] = Variable<String>(clinic);
    }
    map['rating'] = Variable<double>(rating);
    map['reviews_count'] = Variable<int>(reviewsCount);
    if (!nullToAbsent || profileImage != null) {
      map['profile_image'] = Variable<String>(profileImage);
    }
    if (!nullToAbsent || nextAvailable != null) {
      map['next_available'] = Variable<String>(nextAvailable);
    }
    map['available'] = Variable<bool>(available);
    map['verified'] = Variable<bool>(verified);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LocalDoctorsCompanion toCompanion(bool nullToAbsent) {
    return LocalDoctorsCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      specialty: specialty == null && nullToAbsent
          ? const Value.absent()
          : Value(specialty),
      clinic:
          clinic == null && nullToAbsent ? const Value.absent() : Value(clinic),
      rating: Value(rating),
      reviewsCount: Value(reviewsCount),
      profileImage: profileImage == null && nullToAbsent
          ? const Value.absent()
          : Value(profileImage),
      nextAvailable: nextAvailable == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAvailable),
      available: Value(available),
      verified: Value(verified),
      createdAt: Value(createdAt),
      isSynced: Value(isSynced),
    );
  }

  factory LocalDoctor.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDoctor(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      specialty: serializer.fromJson<String?>(json['specialty']),
      clinic: serializer.fromJson<String?>(json['clinic']),
      rating: serializer.fromJson<double>(json['rating']),
      reviewsCount: serializer.fromJson<int>(json['reviewsCount']),
      profileImage: serializer.fromJson<String?>(json['profileImage']),
      nextAvailable: serializer.fromJson<String?>(json['nextAvailable']),
      available: serializer.fromJson<bool>(json['available']),
      verified: serializer.fromJson<bool>(json['verified']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'specialty': serializer.toJson<String?>(specialty),
      'clinic': serializer.toJson<String?>(clinic),
      'rating': serializer.toJson<double>(rating),
      'reviewsCount': serializer.toJson<int>(reviewsCount),
      'profileImage': serializer.toJson<String?>(profileImage),
      'nextAvailable': serializer.toJson<String?>(nextAvailable),
      'available': serializer.toJson<bool>(available),
      'verified': serializer.toJson<bool>(verified),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  LocalDoctor copyWith(
          {String? id,
          String? userId,
          String? name,
          Value<String?> specialty = const Value.absent(),
          Value<String?> clinic = const Value.absent(),
          double? rating,
          int? reviewsCount,
          Value<String?> profileImage = const Value.absent(),
          Value<String?> nextAvailable = const Value.absent(),
          bool? available,
          bool? verified,
          DateTime? createdAt,
          bool? isSynced}) =>
      LocalDoctor(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        specialty: specialty.present ? specialty.value : this.specialty,
        clinic: clinic.present ? clinic.value : this.clinic,
        rating: rating ?? this.rating,
        reviewsCount: reviewsCount ?? this.reviewsCount,
        profileImage:
            profileImage.present ? profileImage.value : this.profileImage,
        nextAvailable:
            nextAvailable.present ? nextAvailable.value : this.nextAvailable,
        available: available ?? this.available,
        verified: verified ?? this.verified,
        createdAt: createdAt ?? this.createdAt,
        isSynced: isSynced ?? this.isSynced,
      );
  @override
  String toString() {
    return (StringBuffer('LocalDoctor(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('specialty: $specialty, ')
          ..write('clinic: $clinic, ')
          ..write('rating: $rating, ')
          ..write('reviewsCount: $reviewsCount, ')
          ..write('profileImage: $profileImage, ')
          ..write('nextAvailable: $nextAvailable, ')
          ..write('available: $available, ')
          ..write('verified: $verified, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      name,
      specialty,
      clinic,
      rating,
      reviewsCount,
      profileImage,
      nextAvailable,
      available,
      verified,
      createdAt,
      isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDoctor &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.specialty == this.specialty &&
          other.clinic == this.clinic &&
          other.rating == this.rating &&
          other.reviewsCount == this.reviewsCount &&
          other.profileImage == this.profileImage &&
          other.nextAvailable == this.nextAvailable &&
          other.available == this.available &&
          other.verified == this.verified &&
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced);
}

class LocalDoctorsCompanion extends UpdateCompanion<LocalDoctor> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<String?> specialty;
  final Value<String?> clinic;
  final Value<double> rating;
  final Value<int> reviewsCount;
  final Value<String?> profileImage;
  final Value<String?> nextAvailable;
  final Value<bool> available;
  final Value<bool> verified;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const LocalDoctorsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.specialty = const Value.absent(),
    this.clinic = const Value.absent(),
    this.rating = const Value.absent(),
    this.reviewsCount = const Value.absent(),
    this.profileImage = const Value.absent(),
    this.nextAvailable = const Value.absent(),
    this.available = const Value.absent(),
    this.verified = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDoctorsCompanion.insert({
    required String id,
    required String userId,
    required String name,
    this.specialty = const Value.absent(),
    this.clinic = const Value.absent(),
    this.rating = const Value.absent(),
    this.reviewsCount = const Value.absent(),
    this.profileImage = const Value.absent(),
    this.nextAvailable = const Value.absent(),
    this.available = const Value.absent(),
    this.verified = const Value.absent(),
    required DateTime createdAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        name = Value(name),
        createdAt = Value(createdAt);
  static Insertable<LocalDoctor> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? specialty,
    Expression<String>? clinic,
    Expression<double>? rating,
    Expression<int>? reviewsCount,
    Expression<String>? profileImage,
    Expression<String>? nextAvailable,
    Expression<bool>? available,
    Expression<bool>? verified,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (specialty != null) 'specialty': specialty,
      if (clinic != null) 'clinic': clinic,
      if (rating != null) 'rating': rating,
      if (reviewsCount != null) 'reviews_count': reviewsCount,
      if (profileImage != null) 'profile_image': profileImage,
      if (nextAvailable != null) 'next_available': nextAvailable,
      if (available != null) 'available': available,
      if (verified != null) 'verified': verified,
      if (createdAt != null) 'created_at': createdAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDoctorsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? name,
      Value<String?>? specialty,
      Value<String?>? clinic,
      Value<double>? rating,
      Value<int>? reviewsCount,
      Value<String?>? profileImage,
      Value<String?>? nextAvailable,
      Value<bool>? available,
      Value<bool>? verified,
      Value<DateTime>? createdAt,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return LocalDoctorsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      clinic: clinic ?? this.clinic,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      profileImage: profileImage ?? this.profileImage,
      nextAvailable: nextAvailable ?? this.nextAvailable,
      available: available ?? this.available,
      verified: verified ?? this.verified,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (specialty.present) {
      map['specialty'] = Variable<String>(specialty.value);
    }
    if (clinic.present) {
      map['clinic'] = Variable<String>(clinic.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (reviewsCount.present) {
      map['reviews_count'] = Variable<int>(reviewsCount.value);
    }
    if (profileImage.present) {
      map['profile_image'] = Variable<String>(profileImage.value);
    }
    if (nextAvailable.present) {
      map['next_available'] = Variable<String>(nextAvailable.value);
    }
    if (available.present) {
      map['available'] = Variable<bool>(available.value);
    }
    if (verified.present) {
      map['verified'] = Variable<bool>(verified.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDoctorsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('specialty: $specialty, ')
          ..write('clinic: $clinic, ')
          ..write('rating: $rating, ')
          ..write('reviewsCount: $reviewsCount, ')
          ..write('profileImage: $profileImage, ')
          ..write('nextAvailable: $nextAvailable, ')
          ..write('available: $available, ')
          ..write('verified: $verified, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalNotificationsTable extends LocalNotifications
    with TableInfo<$LocalNotificationsTable, LocalNotification> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalNotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _actorIdMeta =
      const VerificationMeta('actorId');
  @override
  late final GeneratedColumn<String> actorId = GeneratedColumn<String>(
      'actor_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _relatedIdMeta =
      const VerificationMeta('relatedId');
  @override
  late final GeneratedColumn<int> relatedId = GeneratedColumn<int>(
      'related_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
      'is_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_read" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _actorNameMeta =
      const VerificationMeta('actorName');
  @override
  late final GeneratedColumn<String> actorName = GeneratedColumn<String>(
      'actor_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _actorImageMeta =
      const VerificationMeta('actorImage');
  @override
  late final GeneratedColumn<String> actorImage = GeneratedColumn<String>(
      'actor_image', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        actorId,
        type,
        title,
        body,
        relatedId,
        isRead,
        createdAt,
        actorName,
        actorImage,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_notifications';
  @override
  VerificationContext validateIntegrity(Insertable<LocalNotification> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('actor_id')) {
      context.handle(_actorIdMeta,
          actorId.isAcceptableOrUnknown(data['actor_id']!, _actorIdMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('related_id')) {
      context.handle(_relatedIdMeta,
          relatedId.isAcceptableOrUnknown(data['related_id']!, _relatedIdMeta));
    }
    if (data.containsKey('is_read')) {
      context.handle(_isReadMeta,
          isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('actor_name')) {
      context.handle(_actorNameMeta,
          actorName.isAcceptableOrUnknown(data['actor_name']!, _actorNameMeta));
    }
    if (data.containsKey('actor_image')) {
      context.handle(
          _actorImageMeta,
          actorImage.isAcceptableOrUnknown(
              data['actor_image']!, _actorImageMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalNotification map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalNotification(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      actorId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}actor_id']),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      relatedId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}related_id']),
      isRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_read'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      actorName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}actor_name']),
      actorImage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}actor_image']),
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $LocalNotificationsTable createAlias(String alias) {
    return $LocalNotificationsTable(attachedDatabase, alias);
  }
}

class LocalNotification extends DataClass
    implements Insertable<LocalNotification> {
  final int id;
  final String userId;
  final String? actorId;
  final String type;
  final String title;
  final String body;
  final int? relatedId;
  final bool isRead;
  final DateTime createdAt;
  final String? actorName;
  final String? actorImage;
  final bool isSynced;
  const LocalNotification(
      {required this.id,
      required this.userId,
      this.actorId,
      required this.type,
      required this.title,
      required this.body,
      this.relatedId,
      required this.isRead,
      required this.createdAt,
      this.actorName,
      this.actorImage,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || actorId != null) {
      map['actor_id'] = Variable<String>(actorId);
    }
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || relatedId != null) {
      map['related_id'] = Variable<int>(relatedId);
    }
    map['is_read'] = Variable<bool>(isRead);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || actorName != null) {
      map['actor_name'] = Variable<String>(actorName);
    }
    if (!nullToAbsent || actorImage != null) {
      map['actor_image'] = Variable<String>(actorImage);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LocalNotificationsCompanion toCompanion(bool nullToAbsent) {
    return LocalNotificationsCompanion(
      id: Value(id),
      userId: Value(userId),
      actorId: actorId == null && nullToAbsent
          ? const Value.absent()
          : Value(actorId),
      type: Value(type),
      title: Value(title),
      body: Value(body),
      relatedId: relatedId == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedId),
      isRead: Value(isRead),
      createdAt: Value(createdAt),
      actorName: actorName == null && nullToAbsent
          ? const Value.absent()
          : Value(actorName),
      actorImage: actorImage == null && nullToAbsent
          ? const Value.absent()
          : Value(actorImage),
      isSynced: Value(isSynced),
    );
  }

  factory LocalNotification.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalNotification(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      actorId: serializer.fromJson<String?>(json['actorId']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      relatedId: serializer.fromJson<int?>(json['relatedId']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      actorName: serializer.fromJson<String?>(json['actorName']),
      actorImage: serializer.fromJson<String?>(json['actorImage']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'actorId': serializer.toJson<String?>(actorId),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'relatedId': serializer.toJson<int?>(relatedId),
      'isRead': serializer.toJson<bool>(isRead),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'actorName': serializer.toJson<String?>(actorName),
      'actorImage': serializer.toJson<String?>(actorImage),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  LocalNotification copyWith(
          {int? id,
          String? userId,
          Value<String?> actorId = const Value.absent(),
          String? type,
          String? title,
          String? body,
          Value<int?> relatedId = const Value.absent(),
          bool? isRead,
          DateTime? createdAt,
          Value<String?> actorName = const Value.absent(),
          Value<String?> actorImage = const Value.absent(),
          bool? isSynced}) =>
      LocalNotification(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        actorId: actorId.present ? actorId.value : this.actorId,
        type: type ?? this.type,
        title: title ?? this.title,
        body: body ?? this.body,
        relatedId: relatedId.present ? relatedId.value : this.relatedId,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt ?? this.createdAt,
        actorName: actorName.present ? actorName.value : this.actorName,
        actorImage: actorImage.present ? actorImage.value : this.actorImage,
        isSynced: isSynced ?? this.isSynced,
      );
  @override
  String toString() {
    return (StringBuffer('LocalNotification(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('actorId: $actorId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('relatedId: $relatedId, ')
          ..write('isRead: $isRead, ')
          ..write('createdAt: $createdAt, ')
          ..write('actorName: $actorName, ')
          ..write('actorImage: $actorImage, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, actorId, type, title, body,
      relatedId, isRead, createdAt, actorName, actorImage, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalNotification &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.actorId == this.actorId &&
          other.type == this.type &&
          other.title == this.title &&
          other.body == this.body &&
          other.relatedId == this.relatedId &&
          other.isRead == this.isRead &&
          other.createdAt == this.createdAt &&
          other.actorName == this.actorName &&
          other.actorImage == this.actorImage &&
          other.isSynced == this.isSynced);
}

class LocalNotificationsCompanion extends UpdateCompanion<LocalNotification> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String?> actorId;
  final Value<String> type;
  final Value<String> title;
  final Value<String> body;
  final Value<int?> relatedId;
  final Value<bool> isRead;
  final Value<DateTime> createdAt;
  final Value<String?> actorName;
  final Value<String?> actorImage;
  final Value<bool> isSynced;
  const LocalNotificationsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.actorId = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.relatedId = const Value.absent(),
    this.isRead = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.actorName = const Value.absent(),
    this.actorImage = const Value.absent(),
    this.isSynced = const Value.absent(),
  });
  LocalNotificationsCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    this.actorId = const Value.absent(),
    required String type,
    required String title,
    required String body,
    this.relatedId = const Value.absent(),
    this.isRead = const Value.absent(),
    required DateTime createdAt,
    this.actorName = const Value.absent(),
    this.actorImage = const Value.absent(),
    this.isSynced = const Value.absent(),
  })  : userId = Value(userId),
        type = Value(type),
        title = Value(title),
        body = Value(body),
        createdAt = Value(createdAt);
  static Insertable<LocalNotification> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? actorId,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? body,
    Expression<int>? relatedId,
    Expression<bool>? isRead,
    Expression<DateTime>? createdAt,
    Expression<String>? actorName,
    Expression<String>? actorImage,
    Expression<bool>? isSynced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (actorId != null) 'actor_id': actorId,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (relatedId != null) 'related_id': relatedId,
      if (isRead != null) 'is_read': isRead,
      if (createdAt != null) 'created_at': createdAt,
      if (actorName != null) 'actor_name': actorName,
      if (actorImage != null) 'actor_image': actorImage,
      if (isSynced != null) 'is_synced': isSynced,
    });
  }

  LocalNotificationsCompanion copyWith(
      {Value<int>? id,
      Value<String>? userId,
      Value<String?>? actorId,
      Value<String>? type,
      Value<String>? title,
      Value<String>? body,
      Value<int?>? relatedId,
      Value<bool>? isRead,
      Value<DateTime>? createdAt,
      Value<String?>? actorName,
      Value<String?>? actorImage,
      Value<bool>? isSynced}) {
    return LocalNotificationsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      actorId: actorId ?? this.actorId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      actorName: actorName ?? this.actorName,
      actorImage: actorImage ?? this.actorImage,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (actorId.present) {
      map['actor_id'] = Variable<String>(actorId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (relatedId.present) {
      map['related_id'] = Variable<int>(relatedId.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (actorName.present) {
      map['actor_name'] = Variable<String>(actorName.value);
    }
    if (actorImage.present) {
      map['actor_image'] = Variable<String>(actorImage.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalNotificationsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('actorId: $actorId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('relatedId: $relatedId, ')
          ..write('isRead: $isRead, ')
          ..write('createdAt: $createdAt, ')
          ..write('actorName: $actorName, ')
          ..write('actorImage: $actorImage, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }
}

class $LocalSlotsTable extends LocalSlots
    with TableInfo<$LocalSlotsTable, LocalSlot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSlotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _doctorIdMeta =
      const VerificationMeta('doctorId');
  @override
  late final GeneratedColumn<String> doctorId = GeneratedColumn<String>(
      'doctor_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
      'day', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
      'start_time', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
      'end_time', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('synced'));
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, doctorId, day, startTime, endTime, isSynced, syncStatus, isDeleted];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_slots';
  @override
  VerificationContext validateIntegrity(Insertable<LocalSlot> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('doctor_id')) {
      context.handle(_doctorIdMeta,
          doctorId.isAcceptableOrUnknown(data['doctor_id']!, _doctorIdMeta));
    } else if (isInserting) {
      context.missing(_doctorIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
          _dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSlot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSlot(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      doctorId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}doctor_id'])!,
      day: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}day'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}end_time'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $LocalSlotsTable createAlias(String alias) {
    return $LocalSlotsTable(attachedDatabase, alias);
  }
}

class LocalSlot extends DataClass implements Insertable<LocalSlot> {
  final String id;
  final String doctorId;
  final String day;
  final String startTime;
  final String endTime;
  final bool isSynced;
  final String syncStatus;
  final bool isDeleted;
  const LocalSlot(
      {required this.id,
      required this.doctorId,
      required this.day,
      required this.startTime,
      required this.endTime,
      required this.isSynced,
      required this.syncStatus,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['doctor_id'] = Variable<String>(doctorId);
    map['day'] = Variable<String>(day);
    map['start_time'] = Variable<String>(startTime);
    map['end_time'] = Variable<String>(endTime);
    map['is_synced'] = Variable<bool>(isSynced);
    map['sync_status'] = Variable<String>(syncStatus);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  LocalSlotsCompanion toCompanion(bool nullToAbsent) {
    return LocalSlotsCompanion(
      id: Value(id),
      doctorId: Value(doctorId),
      day: Value(day),
      startTime: Value(startTime),
      endTime: Value(endTime),
      isSynced: Value(isSynced),
      syncStatus: Value(syncStatus),
      isDeleted: Value(isDeleted),
    );
  }

  factory LocalSlot.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSlot(
      id: serializer.fromJson<String>(json['id']),
      doctorId: serializer.fromJson<String>(json['doctorId']),
      day: serializer.fromJson<String>(json['day']),
      startTime: serializer.fromJson<String>(json['startTime']),
      endTime: serializer.fromJson<String>(json['endTime']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'doctorId': serializer.toJson<String>(doctorId),
      'day': serializer.toJson<String>(day),
      'startTime': serializer.toJson<String>(startTime),
      'endTime': serializer.toJson<String>(endTime),
      'isSynced': serializer.toJson<bool>(isSynced),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  LocalSlot copyWith(
          {String? id,
          String? doctorId,
          String? day,
          String? startTime,
          String? endTime,
          bool? isSynced,
          String? syncStatus,
          bool? isDeleted}) =>
      LocalSlot(
        id: id ?? this.id,
        doctorId: doctorId ?? this.doctorId,
        day: day ?? this.day,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        isSynced: isSynced ?? this.isSynced,
        syncStatus: syncStatus ?? this.syncStatus,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  @override
  String toString() {
    return (StringBuffer('LocalSlot(')
          ..write('id: $id, ')
          ..write('doctorId: $doctorId, ')
          ..write('day: $day, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, doctorId, day, startTime, endTime, isSynced, syncStatus, isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSlot &&
          other.id == this.id &&
          other.doctorId == this.doctorId &&
          other.day == this.day &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.isSynced == this.isSynced &&
          other.syncStatus == this.syncStatus &&
          other.isDeleted == this.isDeleted);
}

class LocalSlotsCompanion extends UpdateCompanion<LocalSlot> {
  final Value<String> id;
  final Value<String> doctorId;
  final Value<String> day;
  final Value<String> startTime;
  final Value<String> endTime;
  final Value<bool> isSynced;
  final Value<String> syncStatus;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const LocalSlotsCompanion({
    this.id = const Value.absent(),
    this.doctorId = const Value.absent(),
    this.day = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSlotsCompanion.insert({
    required String id,
    required String doctorId,
    required String day,
    required String startTime,
    required String endTime,
    this.isSynced = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        doctorId = Value(doctorId),
        day = Value(day),
        startTime = Value(startTime),
        endTime = Value(endTime);
  static Insertable<LocalSlot> custom({
    Expression<String>? id,
    Expression<String>? doctorId,
    Expression<String>? day,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<bool>? isSynced,
    Expression<String>? syncStatus,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (doctorId != null) 'doctor_id': doctorId,
      if (day != null) 'day': day,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (isSynced != null) 'is_synced': isSynced,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSlotsCompanion copyWith(
      {Value<String>? id,
      Value<String>? doctorId,
      Value<String>? day,
      Value<String>? startTime,
      Value<String>? endTime,
      Value<bool>? isSynced,
      Value<String>? syncStatus,
      Value<bool>? isDeleted,
      Value<int>? rowid}) {
    return LocalSlotsCompanion(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isSynced: isSynced ?? this.isSynced,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (doctorId.present) {
      map['doctor_id'] = Variable<String>(doctorId.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSlotsCompanion(')
          ..write('id: $id, ')
          ..write('doctorId: $doctorId, ')
          ..write('day: $day, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCareTasksTable extends LocalCareTasks
    with TableInfo<$LocalCareTasksTable, LocalCareTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCareTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _petIdMeta = const VerificationMeta('petId');
  @override
  late final GeneratedColumn<String> petId = GeneratedColumn<String>(
      'pet_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _frequencyMeta =
      const VerificationMeta('frequency');
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
      'frequency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('daily'));
  static const VerificationMeta _lastCompletedAtMeta =
      const VerificationMeta('lastCompletedAt');
  @override
  late final GeneratedColumn<DateTime> lastCompletedAt =
      GeneratedColumn<DateTime>('last_completed_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        petId,
        title,
        description,
        frequency,
        lastCompletedAt,
        createdAt,
        isSynced,
        isDeleted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_care_tasks';
  @override
  VerificationContext validateIntegrity(Insertable<LocalCareTask> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pet_id')) {
      context.handle(
          _petIdMeta, petId.isAcceptableOrUnknown(data['pet_id']!, _petIdMeta));
    } else if (isInserting) {
      context.missing(_petIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('frequency')) {
      context.handle(_frequencyMeta,
          frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta));
    }
    if (data.containsKey('last_completed_at')) {
      context.handle(
          _lastCompletedAtMeta,
          lastCompletedAt.isAcceptableOrUnknown(
              data['last_completed_at']!, _lastCompletedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalCareTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCareTask(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      petId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pet_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      frequency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}frequency'])!,
      lastCompletedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_completed_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $LocalCareTasksTable createAlias(String alias) {
    return $LocalCareTasksTable(attachedDatabase, alias);
  }
}

class LocalCareTask extends DataClass implements Insertable<LocalCareTask> {
  final int id;
  final String petId;
  final String title;
  final String? description;
  final String frequency;
  final DateTime? lastCompletedAt;
  final DateTime createdAt;
  final bool isSynced;
  final bool isDeleted;
  const LocalCareTask(
      {required this.id,
      required this.petId,
      required this.title,
      this.description,
      required this.frequency,
      this.lastCompletedAt,
      required this.createdAt,
      required this.isSynced,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['pet_id'] = Variable<String>(petId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['frequency'] = Variable<String>(frequency);
    if (!nullToAbsent || lastCompletedAt != null) {
      map['last_completed_at'] = Variable<DateTime>(lastCompletedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced'] = Variable<bool>(isSynced);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  LocalCareTasksCompanion toCompanion(bool nullToAbsent) {
    return LocalCareTasksCompanion(
      id: Value(id),
      petId: Value(petId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      frequency: Value(frequency),
      lastCompletedAt: lastCompletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCompletedAt),
      createdAt: Value(createdAt),
      isSynced: Value(isSynced),
      isDeleted: Value(isDeleted),
    );
  }

  factory LocalCareTask.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCareTask(
      id: serializer.fromJson<int>(json['id']),
      petId: serializer.fromJson<String>(json['petId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      frequency: serializer.fromJson<String>(json['frequency']),
      lastCompletedAt: serializer.fromJson<DateTime?>(json['lastCompletedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'petId': serializer.toJson<String>(petId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'frequency': serializer.toJson<String>(frequency),
      'lastCompletedAt': serializer.toJson<DateTime?>(lastCompletedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSynced': serializer.toJson<bool>(isSynced),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  LocalCareTask copyWith(
          {int? id,
          String? petId,
          String? title,
          Value<String?> description = const Value.absent(),
          String? frequency,
          Value<DateTime?> lastCompletedAt = const Value.absent(),
          DateTime? createdAt,
          bool? isSynced,
          bool? isDeleted}) =>
      LocalCareTask(
        id: id ?? this.id,
        petId: petId ?? this.petId,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        frequency: frequency ?? this.frequency,
        lastCompletedAt: lastCompletedAt.present
            ? lastCompletedAt.value
            : this.lastCompletedAt,
        createdAt: createdAt ?? this.createdAt,
        isSynced: isSynced ?? this.isSynced,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  @override
  String toString() {
    return (StringBuffer('LocalCareTask(')
          ..write('id: $id, ')
          ..write('petId: $petId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('frequency: $frequency, ')
          ..write('lastCompletedAt: $lastCompletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, petId, title, description, frequency,
      lastCompletedAt, createdAt, isSynced, isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCareTask &&
          other.id == this.id &&
          other.petId == this.petId &&
          other.title == this.title &&
          other.description == this.description &&
          other.frequency == this.frequency &&
          other.lastCompletedAt == this.lastCompletedAt &&
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced &&
          other.isDeleted == this.isDeleted);
}

class LocalCareTasksCompanion extends UpdateCompanion<LocalCareTask> {
  final Value<int> id;
  final Value<String> petId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> frequency;
  final Value<DateTime?> lastCompletedAt;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  final Value<bool> isDeleted;
  const LocalCareTasksCompanion({
    this.id = const Value.absent(),
    this.petId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.frequency = const Value.absent(),
    this.lastCompletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  LocalCareTasksCompanion.insert({
    this.id = const Value.absent(),
    required String petId,
    required String title,
    this.description = const Value.absent(),
    this.frequency = const Value.absent(),
    this.lastCompletedAt = const Value.absent(),
    required DateTime createdAt,
    this.isSynced = const Value.absent(),
    this.isDeleted = const Value.absent(),
  })  : petId = Value(petId),
        title = Value(title),
        createdAt = Value(createdAt);
  static Insertable<LocalCareTask> custom({
    Expression<int>? id,
    Expression<String>? petId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? frequency,
    Expression<DateTime>? lastCompletedAt,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSynced,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (petId != null) 'pet_id': petId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (frequency != null) 'frequency': frequency,
      if (lastCompletedAt != null) 'last_completed_at': lastCompletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  LocalCareTasksCompanion copyWith(
      {Value<int>? id,
      Value<String>? petId,
      Value<String>? title,
      Value<String?>? description,
      Value<String>? frequency,
      Value<DateTime?>? lastCompletedAt,
      Value<DateTime>? createdAt,
      Value<bool>? isSynced,
      Value<bool>? isDeleted}) {
    return LocalCareTasksCompanion(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      title: title ?? this.title,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (petId.present) {
      map['pet_id'] = Variable<String>(petId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (lastCompletedAt.present) {
      map['last_completed_at'] = Variable<DateTime>(lastCompletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCareTasksCompanion(')
          ..write('id: $id, ')
          ..write('petId: $petId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('frequency: $frequency, ')
          ..write('lastCompletedAt: $lastCompletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $LocalHealthEventsTable extends LocalHealthEvents
    with TableInfo<$LocalHealthEventsTable, LocalHealthEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalHealthEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _petIdMeta = const VerificationMeta('petId');
  @override
  late final GeneratedColumn<String> petId = GeneratedColumn<String>(
      'pet_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, petId, title, date, type, notes, createdAt, isSynced, isDeleted];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_health_events';
  @override
  VerificationContext validateIntegrity(Insertable<LocalHealthEvent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pet_id')) {
      context.handle(
          _petIdMeta, petId.isAcceptableOrUnknown(data['pet_id']!, _petIdMeta));
    } else if (isInserting) {
      context.missing(_petIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalHealthEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalHealthEvent(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      petId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pet_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $LocalHealthEventsTable createAlias(String alias) {
    return $LocalHealthEventsTable(attachedDatabase, alias);
  }
}

class LocalHealthEvent extends DataClass
    implements Insertable<LocalHealthEvent> {
  final int id;
  final String petId;
  final String title;
  final DateTime date;
  final String type;
  final String? notes;
  final DateTime createdAt;
  final bool isSynced;
  final bool isDeleted;
  const LocalHealthEvent(
      {required this.id,
      required this.petId,
      required this.title,
      required this.date,
      required this.type,
      this.notes,
      required this.createdAt,
      required this.isSynced,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['pet_id'] = Variable<String>(petId);
    map['title'] = Variable<String>(title);
    map['date'] = Variable<DateTime>(date);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced'] = Variable<bool>(isSynced);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  LocalHealthEventsCompanion toCompanion(bool nullToAbsent) {
    return LocalHealthEventsCompanion(
      id: Value(id),
      petId: Value(petId),
      title: Value(title),
      date: Value(date),
      type: Value(type),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      isSynced: Value(isSynced),
      isDeleted: Value(isDeleted),
    );
  }

  factory LocalHealthEvent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalHealthEvent(
      id: serializer.fromJson<int>(json['id']),
      petId: serializer.fromJson<String>(json['petId']),
      title: serializer.fromJson<String>(json['title']),
      date: serializer.fromJson<DateTime>(json['date']),
      type: serializer.fromJson<String>(json['type']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'petId': serializer.toJson<String>(petId),
      'title': serializer.toJson<String>(title),
      'date': serializer.toJson<DateTime>(date),
      'type': serializer.toJson<String>(type),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSynced': serializer.toJson<bool>(isSynced),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  LocalHealthEvent copyWith(
          {int? id,
          String? petId,
          String? title,
          DateTime? date,
          String? type,
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          bool? isSynced,
          bool? isDeleted}) =>
      LocalHealthEvent(
        id: id ?? this.id,
        petId: petId ?? this.petId,
        title: title ?? this.title,
        date: date ?? this.date,
        type: type ?? this.type,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        isSynced: isSynced ?? this.isSynced,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  @override
  String toString() {
    return (StringBuffer('LocalHealthEvent(')
          ..write('id: $id, ')
          ..write('petId: $petId, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, petId, title, date, type, notes, createdAt, isSynced, isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalHealthEvent &&
          other.id == this.id &&
          other.petId == this.petId &&
          other.title == this.title &&
          other.date == this.date &&
          other.type == this.type &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced &&
          other.isDeleted == this.isDeleted);
}

class LocalHealthEventsCompanion extends UpdateCompanion<LocalHealthEvent> {
  final Value<int> id;
  final Value<String> petId;
  final Value<String> title;
  final Value<DateTime> date;
  final Value<String> type;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  final Value<bool> isDeleted;
  const LocalHealthEventsCompanion({
    this.id = const Value.absent(),
    this.petId = const Value.absent(),
    this.title = const Value.absent(),
    this.date = const Value.absent(),
    this.type = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  LocalHealthEventsCompanion.insert({
    this.id = const Value.absent(),
    required String petId,
    required String title,
    required DateTime date,
    required String type,
    this.notes = const Value.absent(),
    required DateTime createdAt,
    this.isSynced = const Value.absent(),
    this.isDeleted = const Value.absent(),
  })  : petId = Value(petId),
        title = Value(title),
        date = Value(date),
        type = Value(type),
        createdAt = Value(createdAt);
  static Insertable<LocalHealthEvent> custom({
    Expression<int>? id,
    Expression<String>? petId,
    Expression<String>? title,
    Expression<DateTime>? date,
    Expression<String>? type,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSynced,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (petId != null) 'pet_id': petId,
      if (title != null) 'title': title,
      if (date != null) 'date': date,
      if (type != null) 'type': type,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  LocalHealthEventsCompanion copyWith(
      {Value<int>? id,
      Value<String>? petId,
      Value<String>? title,
      Value<DateTime>? date,
      Value<String>? type,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<bool>? isSynced,
      Value<bool>? isDeleted}) {
    return LocalHealthEventsCompanion(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      title: title ?? this.title,
      date: date ?? this.date,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (petId.present) {
      map['pet_id'] = Variable<String>(petId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalHealthEventsCompanion(')
          ..write('id: $id, ')
          ..write('petId: $petId, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $SyncMetadataTable extends SyncMetadata
    with TableInfo<$SyncMetadataTable, SyncMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _syncTableNameMeta =
      const VerificationMeta('syncTableName');
  @override
  late final GeneratedColumn<String> syncTableName = GeneratedColumn<String>(
      'table_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _lastSyncAtMeta =
      const VerificationMeta('lastSyncAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
      'last_sync_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncCountMeta =
      const VerificationMeta('syncCount');
  @override
  late final GeneratedColumn<int> syncCount = GeneratedColumn<int>(
      'sync_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, syncTableName, entityId, lastSyncAt, syncCount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_metadata';
  @override
  VerificationContext validateIntegrity(Insertable<SyncMetadataData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('table_name')) {
      context.handle(
          _syncTableNameMeta,
          syncTableName.isAcceptableOrUnknown(
              data['table_name']!, _syncTableNameMeta));
    } else if (isInserting) {
      context.missing(_syncTableNameMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
          _lastSyncAtMeta,
          lastSyncAt.isAcceptableOrUnknown(
              data['last_sync_at']!, _lastSyncAtMeta));
    } else if (isInserting) {
      context.missing(_lastSyncAtMeta);
    }
    if (data.containsKey('sync_count')) {
      context.handle(_syncCountMeta,
          syncCount.isAcceptableOrUnknown(data['sync_count']!, _syncCountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetadataData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      syncTableName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}table_name'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      lastSyncAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_sync_at'])!,
      syncCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sync_count'])!,
    );
  }

  @override
  $SyncMetadataTable createAlias(String alias) {
    return $SyncMetadataTable(attachedDatabase, alias);
  }
}

class SyncMetadataData extends DataClass
    implements Insertable<SyncMetadataData> {
  final int id;
  final String syncTableName;
  final String entityId;
  final DateTime lastSyncAt;
  final int syncCount;
  const SyncMetadataData(
      {required this.id,
      required this.syncTableName,
      required this.entityId,
      required this.lastSyncAt,
      required this.syncCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['table_name'] = Variable<String>(syncTableName);
    map['entity_id'] = Variable<String>(entityId);
    map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    map['sync_count'] = Variable<int>(syncCount);
    return map;
  }

  SyncMetadataCompanion toCompanion(bool nullToAbsent) {
    return SyncMetadataCompanion(
      id: Value(id),
      syncTableName: Value(syncTableName),
      entityId: Value(entityId),
      lastSyncAt: Value(lastSyncAt),
      syncCount: Value(syncCount),
    );
  }

  factory SyncMetadataData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetadataData(
      id: serializer.fromJson<int>(json['id']),
      syncTableName: serializer.fromJson<String>(json['syncTableName']),
      entityId: serializer.fromJson<String>(json['entityId']),
      lastSyncAt: serializer.fromJson<DateTime>(json['lastSyncAt']),
      syncCount: serializer.fromJson<int>(json['syncCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'syncTableName': serializer.toJson<String>(syncTableName),
      'entityId': serializer.toJson<String>(entityId),
      'lastSyncAt': serializer.toJson<DateTime>(lastSyncAt),
      'syncCount': serializer.toJson<int>(syncCount),
    };
  }

  SyncMetadataData copyWith(
          {int? id,
          String? syncTableName,
          String? entityId,
          DateTime? lastSyncAt,
          int? syncCount}) =>
      SyncMetadataData(
        id: id ?? this.id,
        syncTableName: syncTableName ?? this.syncTableName,
        entityId: entityId ?? this.entityId,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        syncCount: syncCount ?? this.syncCount,
      );
  @override
  String toString() {
    return (StringBuffer('SyncMetadataData(')
          ..write('id: $id, ')
          ..write('syncTableName: $syncTableName, ')
          ..write('entityId: $entityId, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('syncCount: $syncCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, syncTableName, entityId, lastSyncAt, syncCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetadataData &&
          other.id == this.id &&
          other.syncTableName == this.syncTableName &&
          other.entityId == this.entityId &&
          other.lastSyncAt == this.lastSyncAt &&
          other.syncCount == this.syncCount);
}

class SyncMetadataCompanion extends UpdateCompanion<SyncMetadataData> {
  final Value<int> id;
  final Value<String> syncTableName;
  final Value<String> entityId;
  final Value<DateTime> lastSyncAt;
  final Value<int> syncCount;
  const SyncMetadataCompanion({
    this.id = const Value.absent(),
    this.syncTableName = const Value.absent(),
    this.entityId = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.syncCount = const Value.absent(),
  });
  SyncMetadataCompanion.insert({
    this.id = const Value.absent(),
    required String syncTableName,
    this.entityId = const Value.absent(),
    required DateTime lastSyncAt,
    this.syncCount = const Value.absent(),
  })  : syncTableName = Value(syncTableName),
        lastSyncAt = Value(lastSyncAt);
  static Insertable<SyncMetadataData> custom({
    Expression<int>? id,
    Expression<String>? syncTableName,
    Expression<String>? entityId,
    Expression<DateTime>? lastSyncAt,
    Expression<int>? syncCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncTableName != null) 'table_name': syncTableName,
      if (entityId != null) 'entity_id': entityId,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (syncCount != null) 'sync_count': syncCount,
    });
  }

  SyncMetadataCompanion copyWith(
      {Value<int>? id,
      Value<String>? syncTableName,
      Value<String>? entityId,
      Value<DateTime>? lastSyncAt,
      Value<int>? syncCount}) {
    return SyncMetadataCompanion(
      id: id ?? this.id,
      syncTableName: syncTableName ?? this.syncTableName,
      entityId: entityId ?? this.entityId,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      syncCount: syncCount ?? this.syncCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (syncTableName.present) {
      map['table_name'] = Variable<String>(syncTableName.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (syncCount.present) {
      map['sync_count'] = Variable<int>(syncCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataCompanion(')
          ..write('id: $id, ')
          ..write('syncTableName: $syncTableName, ')
          ..write('entityId: $entityId, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('syncCount: $syncCount')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $LocalChatsTable localChats = $LocalChatsTable(this);
  late final $LocalMessagesTable localMessages = $LocalMessagesTable(this);
  late final $LocalPostsTable localPosts = $LocalPostsTable(this);
  late final $LocalAppointmentsTable localAppointments =
      $LocalAppointmentsTable(this);
  late final $LocalPetsTable localPets = $LocalPetsTable(this);
  late final $LocalUsersTable localUsers = $LocalUsersTable(this);
  late final $LocalDoctorsTable localDoctors = $LocalDoctorsTable(this);
  late final $LocalNotificationsTable localNotifications =
      $LocalNotificationsTable(this);
  late final $LocalSlotsTable localSlots = $LocalSlotsTable(this);
  late final $LocalCareTasksTable localCareTasks = $LocalCareTasksTable(this);
  late final $LocalHealthEventsTable localHealthEvents =
      $LocalHealthEventsTable(this);
  late final $SyncMetadataTable syncMetadata = $SyncMetadataTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        localChats,
        localMessages,
        localPosts,
        localAppointments,
        localPets,
        localUsers,
        localDoctors,
        localNotifications,
        localSlots,
        localCareTasks,
        localHealthEvents,
        syncMetadata
      ];
}
