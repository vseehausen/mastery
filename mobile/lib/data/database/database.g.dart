// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LanguagesTable extends Languages
    with TableInfo<$LanguagesTable, Language> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LanguagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 5),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, code, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'languages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Language> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Language map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Language(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LanguagesTable createAlias(String alias) {
    return $LanguagesTable(attachedDatabase, alias);
  }
}

class Language extends DataClass implements Insertable<Language> {
  final String id;
  final String code;
  final String name;
  final DateTime createdAt;
  const Language({
    required this.id,
    required this.code,
    required this.name,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LanguagesCompanion toCompanion(bool nullToAbsent) {
    return LanguagesCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory Language.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Language(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Language copyWith({
    String? id,
    String? code,
    String? name,
    DateTime? createdAt,
  }) => Language(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
  );
  Language copyWithCompanion(LanguagesCompanion data) {
    return Language(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Language(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, code, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Language &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class LanguagesCompanion extends UpdateCompanion<Language> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LanguagesCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LanguagesCompanion.insert({
    required String id,
    required String code,
    required String name,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       code = Value(code),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<Language> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LanguagesCompanion copyWith({
    Value<String>? id,
    Value<String>? code,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LanguagesCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LanguagesCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SourcesTable extends Sources with TableInfo<$SourcesTable, Source> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 500),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 255),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _asinMeta = const VerificationMeta('asin');
  @override
  late final GeneratedColumn<String> asin = GeneratedColumn<String>(
    'asin',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  @override
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
    'domain',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 255),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPendingSyncMeta = const VerificationMeta(
    'isPendingSync',
  );
  @override
  late final GeneratedColumn<bool> isPendingSync = GeneratedColumn<bool>(
    'is_pending_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pending_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    type,
    title,
    author,
    asin,
    url,
    domain,
    createdAt,
    updatedAt,
    deletedAt,
    lastSyncedAt,
    isPendingSync,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<Source> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('asin')) {
      context.handle(
        _asinMeta,
        asin.isAcceptableOrUnknown(data['asin']!, _asinMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('domain')) {
      context.handle(
        _domainMeta,
        domain.isAcceptableOrUnknown(data['domain']!, _domainMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_pending_sync')) {
      context.handle(
        _isPendingSyncMeta,
        isPendingSync.isAcceptableOrUnknown(
          data['is_pending_sync']!,
          _isPendingSyncMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Source map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Source(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      asin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asin'],
      ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      domain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      isPendingSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pending_sync'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $SourcesTable createAlias(String alias) {
    return $SourcesTable(attachedDatabase, alias);
  }
}

class Source extends DataClass implements Insertable<Source> {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String? author;
  final String? asin;
  final String? url;
  final String? domain;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? lastSyncedAt;
  final bool isPendingSync;
  final int version;
  const Source({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.author,
    this.asin,
    this.url,
    this.domain,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.lastSyncedAt,
    required this.isPendingSync,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || asin != null) {
      map['asin'] = Variable<String>(asin);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || domain != null) {
      map['domain'] = Variable<String>(domain);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['is_pending_sync'] = Variable<bool>(isPendingSync);
    map['version'] = Variable<int>(version);
    return map;
  }

  SourcesCompanion toCompanion(bool nullToAbsent) {
    return SourcesCompanion(
      id: Value(id),
      userId: Value(userId),
      type: Value(type),
      title: Value(title),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      asin: asin == null && nullToAbsent ? const Value.absent() : Value(asin),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      domain: domain == null && nullToAbsent
          ? const Value.absent()
          : Value(domain),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      isPendingSync: Value(isPendingSync),
      version: Value(version),
    );
  }

  factory Source.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Source(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String?>(json['author']),
      asin: serializer.fromJson<String?>(json['asin']),
      url: serializer.fromJson<String?>(json['url']),
      domain: serializer.fromJson<String?>(json['domain']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      isPendingSync: serializer.fromJson<bool>(json['isPendingSync']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String?>(author),
      'asin': serializer.toJson<String?>(asin),
      'url': serializer.toJson<String?>(url),
      'domain': serializer.toJson<String?>(domain),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'isPendingSync': serializer.toJson<bool>(isPendingSync),
      'version': serializer.toJson<int>(version),
    };
  }

  Source copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    Value<String?> author = const Value.absent(),
    Value<String?> asin = const Value.absent(),
    Value<String?> url = const Value.absent(),
    Value<String?> domain = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    bool? isPendingSync,
    int? version,
  }) => Source(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    type: type ?? this.type,
    title: title ?? this.title,
    author: author.present ? author.value : this.author,
    asin: asin.present ? asin.value : this.asin,
    url: url.present ? url.value : this.url,
    domain: domain.present ? domain.value : this.domain,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    isPendingSync: isPendingSync ?? this.isPendingSync,
    version: version ?? this.version,
  );
  Source copyWithCompanion(SourcesCompanion data) {
    return Source(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      asin: data.asin.present ? data.asin.value : this.asin,
      url: data.url.present ? data.url.value : this.url,
      domain: data.domain.present ? data.domain.value : this.domain,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      isPendingSync: data.isPendingSync.present
          ? data.isPendingSync.value
          : this.isPendingSync,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Source(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('asin: $asin, ')
          ..write('url: $url, ')
          ..write('domain: $domain, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('isPendingSync: $isPendingSync, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    type,
    title,
    author,
    asin,
    url,
    domain,
    createdAt,
    updatedAt,
    deletedAt,
    lastSyncedAt,
    isPendingSync,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Source &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.type == this.type &&
          other.title == this.title &&
          other.author == this.author &&
          other.asin == this.asin &&
          other.url == this.url &&
          other.domain == this.domain &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.isPendingSync == this.isPendingSync &&
          other.version == this.version);
}

class SourcesCompanion extends UpdateCompanion<Source> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> type;
  final Value<String> title;
  final Value<String?> author;
  final Value<String?> asin;
  final Value<String?> url;
  final Value<String?> domain;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<bool> isPendingSync;
  final Value<int> version;
  final Value<int> rowid;
  const SourcesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.asin = const Value.absent(),
    this.url = const Value.absent(),
    this.domain = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.isPendingSync = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SourcesCompanion.insert({
    required String id,
    required String userId,
    required String type,
    required String title,
    this.author = const Value.absent(),
    this.asin = const Value.absent(),
    this.url = const Value.absent(),
    this.domain = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.isPendingSync = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       type = Value(type),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Source> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? asin,
    Expression<String>? url,
    Expression<String>? domain,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<bool>? isPendingSync,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (asin != null) 'asin': asin,
      if (url != null) 'url': url,
      if (domain != null) 'domain': domain,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (isPendingSync != null) 'is_pending_sync': isPendingSync,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SourcesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? type,
    Value<String>? title,
    Value<String?>? author,
    Value<String?>? asin,
    Value<String?>? url,
    Value<String?>? domain,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<bool>? isPendingSync,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return SourcesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      author: author ?? this.author,
      asin: asin ?? this.asin,
      url: url ?? this.url,
      domain: domain ?? this.domain,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isPendingSync: isPendingSync ?? this.isPendingSync,
      version: version ?? this.version,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (asin.present) {
      map['asin'] = Variable<String>(asin.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (isPendingSync.present) {
      map['is_pending_sync'] = Variable<bool>(isPendingSync.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourcesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('asin: $asin, ')
          ..write('url: $url, ')
          ..write('domain: $domain, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('isPendingSync: $isPendingSync, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EncountersTable extends Encounters
    with TableInfo<$EncountersTable, Encounter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EncountersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vocabularyIdMeta = const VerificationMeta(
    'vocabularyId',
  );
  @override
  late final GeneratedColumn<String> vocabularyId = GeneratedColumn<String>(
    'vocabulary_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contextMeta = const VerificationMeta(
    'context',
  );
  @override
  late final GeneratedColumn<String> context = GeneratedColumn<String>(
    'context',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locatorJsonMeta = const VerificationMeta(
    'locatorJson',
  );
  @override
  late final GeneratedColumn<String> locatorJson = GeneratedColumn<String>(
    'locator_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPendingSyncMeta = const VerificationMeta(
    'isPendingSync',
  );
  @override
  late final GeneratedColumn<bool> isPendingSync = GeneratedColumn<bool>(
    'is_pending_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pending_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    vocabularyId,
    sourceId,
    context,
    locatorJson,
    occurredAt,
    createdAt,
    updatedAt,
    deletedAt,
    lastSyncedAt,
    isPendingSync,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'encounters';
  @override
  VerificationContext validateIntegrity(
    Insertable<Encounter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('vocabulary_id')) {
      context.handle(
        _vocabularyIdMeta,
        vocabularyId.isAcceptableOrUnknown(
          data['vocabulary_id']!,
          _vocabularyIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vocabularyIdMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('context')) {
      context.handle(
        _contextMeta,
        this.context.isAcceptableOrUnknown(data['context']!, _contextMeta),
      );
    }
    if (data.containsKey('locator_json')) {
      context.handle(
        _locatorJsonMeta,
        locatorJson.isAcceptableOrUnknown(
          data['locator_json']!,
          _locatorJsonMeta,
        ),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_pending_sync')) {
      context.handle(
        _isPendingSyncMeta,
        isPendingSync.isAcceptableOrUnknown(
          data['is_pending_sync']!,
          _isPendingSyncMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Encounter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Encounter(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      vocabularyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vocabulary_id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      context: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context'],
      ),
      locatorJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locator_json'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      isPendingSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pending_sync'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $EncountersTable createAlias(String alias) {
    return $EncountersTable(attachedDatabase, alias);
  }
}

class Encounter extends DataClass implements Insertable<Encounter> {
  final String id;
  final String userId;
  final String vocabularyId;
  final String? sourceId;
  final String? context;
  final String? locatorJson;
  final DateTime? occurredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? lastSyncedAt;
  final bool isPendingSync;
  final int version;
  const Encounter({
    required this.id,
    required this.userId,
    required this.vocabularyId,
    this.sourceId,
    this.context,
    this.locatorJson,
    this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.lastSyncedAt,
    required this.isPendingSync,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['vocabulary_id'] = Variable<String>(vocabularyId);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    if (!nullToAbsent || context != null) {
      map['context'] = Variable<String>(context);
    }
    if (!nullToAbsent || locatorJson != null) {
      map['locator_json'] = Variable<String>(locatorJson);
    }
    if (!nullToAbsent || occurredAt != null) {
      map['occurred_at'] = Variable<DateTime>(occurredAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['is_pending_sync'] = Variable<bool>(isPendingSync);
    map['version'] = Variable<int>(version);
    return map;
  }

  EncountersCompanion toCompanion(bool nullToAbsent) {
    return EncountersCompanion(
      id: Value(id),
      userId: Value(userId),
      vocabularyId: Value(vocabularyId),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      context: context == null && nullToAbsent
          ? const Value.absent()
          : Value(context),
      locatorJson: locatorJson == null && nullToAbsent
          ? const Value.absent()
          : Value(locatorJson),
      occurredAt: occurredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(occurredAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      isPendingSync: Value(isPendingSync),
      version: Value(version),
    );
  }

  factory Encounter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Encounter(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      vocabularyId: serializer.fromJson<String>(json['vocabularyId']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      context: serializer.fromJson<String?>(json['context']),
      locatorJson: serializer.fromJson<String?>(json['locatorJson']),
      occurredAt: serializer.fromJson<DateTime?>(json['occurredAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      isPendingSync: serializer.fromJson<bool>(json['isPendingSync']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'vocabularyId': serializer.toJson<String>(vocabularyId),
      'sourceId': serializer.toJson<String?>(sourceId),
      'context': serializer.toJson<String?>(context),
      'locatorJson': serializer.toJson<String?>(locatorJson),
      'occurredAt': serializer.toJson<DateTime?>(occurredAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'isPendingSync': serializer.toJson<bool>(isPendingSync),
      'version': serializer.toJson<int>(version),
    };
  }

  Encounter copyWith({
    String? id,
    String? userId,
    String? vocabularyId,
    Value<String?> sourceId = const Value.absent(),
    Value<String?> context = const Value.absent(),
    Value<String?> locatorJson = const Value.absent(),
    Value<DateTime?> occurredAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    bool? isPendingSync,
    int? version,
  }) => Encounter(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    vocabularyId: vocabularyId ?? this.vocabularyId,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    context: context.present ? context.value : this.context,
    locatorJson: locatorJson.present ? locatorJson.value : this.locatorJson,
    occurredAt: occurredAt.present ? occurredAt.value : this.occurredAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    isPendingSync: isPendingSync ?? this.isPendingSync,
    version: version ?? this.version,
  );
  Encounter copyWithCompanion(EncountersCompanion data) {
    return Encounter(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      vocabularyId: data.vocabularyId.present
          ? data.vocabularyId.value
          : this.vocabularyId,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      context: data.context.present ? data.context.value : this.context,
      locatorJson: data.locatorJson.present
          ? data.locatorJson.value
          : this.locatorJson,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      isPendingSync: data.isPendingSync.present
          ? data.isPendingSync.value
          : this.isPendingSync,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Encounter(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('vocabularyId: $vocabularyId, ')
          ..write('sourceId: $sourceId, ')
          ..write('context: $context, ')
          ..write('locatorJson: $locatorJson, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('isPendingSync: $isPendingSync, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    vocabularyId,
    sourceId,
    context,
    locatorJson,
    occurredAt,
    createdAt,
    updatedAt,
    deletedAt,
    lastSyncedAt,
    isPendingSync,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Encounter &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.vocabularyId == this.vocabularyId &&
          other.sourceId == this.sourceId &&
          other.context == this.context &&
          other.locatorJson == this.locatorJson &&
          other.occurredAt == this.occurredAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.isPendingSync == this.isPendingSync &&
          other.version == this.version);
}

class EncountersCompanion extends UpdateCompanion<Encounter> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> vocabularyId;
  final Value<String?> sourceId;
  final Value<String?> context;
  final Value<String?> locatorJson;
  final Value<DateTime?> occurredAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<bool> isPendingSync;
  final Value<int> version;
  final Value<int> rowid;
  const EncountersCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.vocabularyId = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.context = const Value.absent(),
    this.locatorJson = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.isPendingSync = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EncountersCompanion.insert({
    required String id,
    required String userId,
    required String vocabularyId,
    this.sourceId = const Value.absent(),
    this.context = const Value.absent(),
    this.locatorJson = const Value.absent(),
    this.occurredAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.isPendingSync = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       vocabularyId = Value(vocabularyId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Encounter> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? vocabularyId,
    Expression<String>? sourceId,
    Expression<String>? context,
    Expression<String>? locatorJson,
    Expression<DateTime>? occurredAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<bool>? isPendingSync,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (vocabularyId != null) 'vocabulary_id': vocabularyId,
      if (sourceId != null) 'source_id': sourceId,
      if (context != null) 'context': context,
      if (locatorJson != null) 'locator_json': locatorJson,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (isPendingSync != null) 'is_pending_sync': isPendingSync,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EncountersCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? vocabularyId,
    Value<String?>? sourceId,
    Value<String?>? context,
    Value<String?>? locatorJson,
    Value<DateTime?>? occurredAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<bool>? isPendingSync,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return EncountersCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vocabularyId: vocabularyId ?? this.vocabularyId,
      sourceId: sourceId ?? this.sourceId,
      context: context ?? this.context,
      locatorJson: locatorJson ?? this.locatorJson,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isPendingSync: isPendingSync ?? this.isPendingSync,
      version: version ?? this.version,
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
    if (vocabularyId.present) {
      map['vocabulary_id'] = Variable<String>(vocabularyId.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (context.present) {
      map['context'] = Variable<String>(context.value);
    }
    if (locatorJson.present) {
      map['locator_json'] = Variable<String>(locatorJson.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (isPendingSync.present) {
      map['is_pending_sync'] = Variable<bool>(isPendingSync.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EncountersCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('vocabularyId: $vocabularyId, ')
          ..write('sourceId: $sourceId, ')
          ..write('context: $context, ')
          ..write('locatorJson: $locatorJson, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('isPendingSync: $isPendingSync, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportSessionsTable extends ImportSessions
    with TableInfo<$ImportSessionsTable, ImportSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filenameMeta = const VerificationMeta(
    'filename',
  );
  @override
  late final GeneratedColumn<String> filename = GeneratedColumn<String>(
    'filename',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceNameMeta = const VerificationMeta(
    'deviceName',
  );
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
    'device_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalFoundMeta = const VerificationMeta(
    'totalFound',
  );
  @override
  late final GeneratedColumn<int> totalFound = GeneratedColumn<int>(
    'total_found',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedMeta = const VerificationMeta(
    'imported',
  );
  @override
  late final GeneratedColumn<int> imported = GeneratedColumn<int>(
    'imported',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skippedMeta = const VerificationMeta(
    'skipped',
  );
  @override
  late final GeneratedColumn<int> skipped = GeneratedColumn<int>(
    'skipped',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _errorsMeta = const VerificationMeta('errors');
  @override
  late final GeneratedColumn<int> errors = GeneratedColumn<int>(
    'errors',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _errorDetailsMeta = const VerificationMeta(
    'errorDetails',
  );
  @override
  late final GeneratedColumn<String> errorDetails = GeneratedColumn<String>(
    'error_details',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    source,
    filename,
    deviceName,
    totalFound,
    imported,
    skipped,
    errors,
    errorDetails,
    startedAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('filename')) {
      context.handle(
        _filenameMeta,
        filename.isAcceptableOrUnknown(data['filename']!, _filenameMeta),
      );
    }
    if (data.containsKey('device_name')) {
      context.handle(
        _deviceNameMeta,
        deviceName.isAcceptableOrUnknown(data['device_name']!, _deviceNameMeta),
      );
    }
    if (data.containsKey('total_found')) {
      context.handle(
        _totalFoundMeta,
        totalFound.isAcceptableOrUnknown(data['total_found']!, _totalFoundMeta),
      );
    } else if (isInserting) {
      context.missing(_totalFoundMeta);
    }
    if (data.containsKey('imported')) {
      context.handle(
        _importedMeta,
        imported.isAcceptableOrUnknown(data['imported']!, _importedMeta),
      );
    } else if (isInserting) {
      context.missing(_importedMeta);
    }
    if (data.containsKey('skipped')) {
      context.handle(
        _skippedMeta,
        skipped.isAcceptableOrUnknown(data['skipped']!, _skippedMeta),
      );
    } else if (isInserting) {
      context.missing(_skippedMeta);
    }
    if (data.containsKey('errors')) {
      context.handle(
        _errorsMeta,
        errors.isAcceptableOrUnknown(data['errors']!, _errorsMeta),
      );
    }
    if (data.containsKey('error_details')) {
      context.handle(
        _errorDetailsMeta,
        errorDetails.isAcceptableOrUnknown(
          data['error_details']!,
          _errorDetailsMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImportSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      filename: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filename'],
      ),
      deviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_name'],
      ),
      totalFound: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_found'],
      )!,
      imported: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}imported'],
      )!,
      skipped: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}skipped'],
      )!,
      errors: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}errors'],
      )!,
      errorDetails: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_details'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $ImportSessionsTable createAlias(String alias) {
    return $ImportSessionsTable(attachedDatabase, alias);
  }
}

class ImportSession extends DataClass implements Insertable<ImportSession> {
  final String id;
  final String userId;
  final String source;
  final String? filename;
  final String? deviceName;
  final int totalFound;
  final int imported;
  final int skipped;
  final int errors;
  final String? errorDetails;
  final DateTime startedAt;
  final DateTime? completedAt;
  const ImportSession({
    required this.id,
    required this.userId,
    required this.source,
    this.filename,
    this.deviceName,
    required this.totalFound,
    required this.imported,
    required this.skipped,
    required this.errors,
    this.errorDetails,
    required this.startedAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || filename != null) {
      map['filename'] = Variable<String>(filename);
    }
    if (!nullToAbsent || deviceName != null) {
      map['device_name'] = Variable<String>(deviceName);
    }
    map['total_found'] = Variable<int>(totalFound);
    map['imported'] = Variable<int>(imported);
    map['skipped'] = Variable<int>(skipped);
    map['errors'] = Variable<int>(errors);
    if (!nullToAbsent || errorDetails != null) {
      map['error_details'] = Variable<String>(errorDetails);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  ImportSessionsCompanion toCompanion(bool nullToAbsent) {
    return ImportSessionsCompanion(
      id: Value(id),
      userId: Value(userId),
      source: Value(source),
      filename: filename == null && nullToAbsent
          ? const Value.absent()
          : Value(filename),
      deviceName: deviceName == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceName),
      totalFound: Value(totalFound),
      imported: Value(imported),
      skipped: Value(skipped),
      errors: Value(errors),
      errorDetails: errorDetails == null && nullToAbsent
          ? const Value.absent()
          : Value(errorDetails),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory ImportSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportSession(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      source: serializer.fromJson<String>(json['source']),
      filename: serializer.fromJson<String?>(json['filename']),
      deviceName: serializer.fromJson<String?>(json['deviceName']),
      totalFound: serializer.fromJson<int>(json['totalFound']),
      imported: serializer.fromJson<int>(json['imported']),
      skipped: serializer.fromJson<int>(json['skipped']),
      errors: serializer.fromJson<int>(json['errors']),
      errorDetails: serializer.fromJson<String?>(json['errorDetails']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'source': serializer.toJson<String>(source),
      'filename': serializer.toJson<String?>(filename),
      'deviceName': serializer.toJson<String?>(deviceName),
      'totalFound': serializer.toJson<int>(totalFound),
      'imported': serializer.toJson<int>(imported),
      'skipped': serializer.toJson<int>(skipped),
      'errors': serializer.toJson<int>(errors),
      'errorDetails': serializer.toJson<String?>(errorDetails),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  ImportSession copyWith({
    String? id,
    String? userId,
    String? source,
    Value<String?> filename = const Value.absent(),
    Value<String?> deviceName = const Value.absent(),
    int? totalFound,
    int? imported,
    int? skipped,
    int? errors,
    Value<String?> errorDetails = const Value.absent(),
    DateTime? startedAt,
    Value<DateTime?> completedAt = const Value.absent(),
  }) => ImportSession(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    source: source ?? this.source,
    filename: filename.present ? filename.value : this.filename,
    deviceName: deviceName.present ? deviceName.value : this.deviceName,
    totalFound: totalFound ?? this.totalFound,
    imported: imported ?? this.imported,
    skipped: skipped ?? this.skipped,
    errors: errors ?? this.errors,
    errorDetails: errorDetails.present ? errorDetails.value : this.errorDetails,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  ImportSession copyWithCompanion(ImportSessionsCompanion data) {
    return ImportSession(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      source: data.source.present ? data.source.value : this.source,
      filename: data.filename.present ? data.filename.value : this.filename,
      deviceName: data.deviceName.present
          ? data.deviceName.value
          : this.deviceName,
      totalFound: data.totalFound.present
          ? data.totalFound.value
          : this.totalFound,
      imported: data.imported.present ? data.imported.value : this.imported,
      skipped: data.skipped.present ? data.skipped.value : this.skipped,
      errors: data.errors.present ? data.errors.value : this.errors,
      errorDetails: data.errorDetails.present
          ? data.errorDetails.value
          : this.errorDetails,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportSession(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('source: $source, ')
          ..write('filename: $filename, ')
          ..write('deviceName: $deviceName, ')
          ..write('totalFound: $totalFound, ')
          ..write('imported: $imported, ')
          ..write('skipped: $skipped, ')
          ..write('errors: $errors, ')
          ..write('errorDetails: $errorDetails, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    source,
    filename,
    deviceName,
    totalFound,
    imported,
    skipped,
    errors,
    errorDetails,
    startedAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportSession &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.source == this.source &&
          other.filename == this.filename &&
          other.deviceName == this.deviceName &&
          other.totalFound == this.totalFound &&
          other.imported == this.imported &&
          other.skipped == this.skipped &&
          other.errors == this.errors &&
          other.errorDetails == this.errorDetails &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt);
}

class ImportSessionsCompanion extends UpdateCompanion<ImportSession> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> source;
  final Value<String?> filename;
  final Value<String?> deviceName;
  final Value<int> totalFound;
  final Value<int> imported;
  final Value<int> skipped;
  final Value<int> errors;
  final Value<String?> errorDetails;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const ImportSessionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.source = const Value.absent(),
    this.filename = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.totalFound = const Value.absent(),
    this.imported = const Value.absent(),
    this.skipped = const Value.absent(),
    this.errors = const Value.absent(),
    this.errorDetails = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportSessionsCompanion.insert({
    required String id,
    required String userId,
    required String source,
    this.filename = const Value.absent(),
    this.deviceName = const Value.absent(),
    required int totalFound,
    required int imported,
    required int skipped,
    this.errors = const Value.absent(),
    this.errorDetails = const Value.absent(),
    required DateTime startedAt,
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       source = Value(source),
       totalFound = Value(totalFound),
       imported = Value(imported),
       skipped = Value(skipped),
       startedAt = Value(startedAt);
  static Insertable<ImportSession> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? source,
    Expression<String>? filename,
    Expression<String>? deviceName,
    Expression<int>? totalFound,
    Expression<int>? imported,
    Expression<int>? skipped,
    Expression<int>? errors,
    Expression<String>? errorDetails,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (source != null) 'source': source,
      if (filename != null) 'filename': filename,
      if (deviceName != null) 'device_name': deviceName,
      if (totalFound != null) 'total_found': totalFound,
      if (imported != null) 'imported': imported,
      if (skipped != null) 'skipped': skipped,
      if (errors != null) 'errors': errors,
      if (errorDetails != null) 'error_details': errorDetails,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? source,
    Value<String?>? filename,
    Value<String?>? deviceName,
    Value<int>? totalFound,
    Value<int>? imported,
    Value<int>? skipped,
    Value<int>? errors,
    Value<String?>? errorDetails,
    Value<DateTime>? startedAt,
    Value<DateTime?>? completedAt,
    Value<int>? rowid,
  }) {
    return ImportSessionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      source: source ?? this.source,
      filename: filename ?? this.filename,
      deviceName: deviceName ?? this.deviceName,
      totalFound: totalFound ?? this.totalFound,
      imported: imported ?? this.imported,
      skipped: skipped ?? this.skipped,
      errors: errors ?? this.errors,
      errorDetails: errorDetails ?? this.errorDetails,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
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
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (filename.present) {
      map['filename'] = Variable<String>(filename.value);
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    if (totalFound.present) {
      map['total_found'] = Variable<int>(totalFound.value);
    }
    if (imported.present) {
      map['imported'] = Variable<int>(imported.value);
    }
    if (skipped.present) {
      map['skipped'] = Variable<int>(skipped.value);
    }
    if (errors.present) {
      map['errors'] = Variable<int>(errors.value);
    }
    if (errorDetails.present) {
      map['error_details'] = Variable<String>(errorDetails.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportSessionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('source: $source, ')
          ..write('filename: $filename, ')
          ..write('deviceName: $deviceName, ')
          ..write('totalFound: $totalFound, ')
          ..write('imported: $imported, ')
          ..write('skipped: $skipped, ')
          ..write('errors: $errors, ')
          ..write('errorDetails: $errorDetails, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOutboxTable extends SyncOutbox
    with TableInfo<$SyncOutboxTable, SyncOutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entityTableMeta = const VerificationMeta(
    'entityTable',
  );
  @override
  late final GeneratedColumn<String> entityTable = GeneratedColumn<String>(
    'entity_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityTable,
    recordId,
    operation,
    payload,
    createdAt,
    retryCount,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_table')) {
      context.handle(
        _entityTableMeta,
        entityTable.isAcceptableOrUnknown(
          data['entity_table']!,
          _entityTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entityTableMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncOutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOutboxData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entityTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_table'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncOutboxTable createAlias(String alias) {
    return $SyncOutboxTable(attachedDatabase, alias);
  }
}

class SyncOutboxData extends DataClass implements Insertable<SyncOutboxData> {
  final int id;
  final String entityTable;
  final String recordId;
  final String operation;
  final String payload;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;
  const SyncOutboxData({
    required this.id,
    required this.entityTable,
    required this.recordId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    required this.retryCount,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_table'] = Variable<String>(entityTable);
    map['record_id'] = Variable<String>(recordId);
    map['operation'] = Variable<String>(operation);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncOutboxCompanion toCompanion(bool nullToAbsent) {
    return SyncOutboxCompanion(
      id: Value(id),
      entityTable: Value(entityTable),
      recordId: Value(recordId),
      operation: Value(operation),
      payload: Value(payload),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncOutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOutboxData(
      id: serializer.fromJson<int>(json['id']),
      entityTable: serializer.fromJson<String>(json['entityTable']),
      recordId: serializer.fromJson<String>(json['recordId']),
      operation: serializer.fromJson<String>(json['operation']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityTable': serializer.toJson<String>(entityTable),
      'recordId': serializer.toJson<String>(recordId),
      'operation': serializer.toJson<String>(operation),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncOutboxData copyWith({
    int? id,
    String? entityTable,
    String? recordId,
    String? operation,
    String? payload,
    DateTime? createdAt,
    int? retryCount,
    Value<String?> lastError = const Value.absent(),
  }) => SyncOutboxData(
    id: id ?? this.id,
    entityTable: entityTable ?? this.entityTable,
    recordId: recordId ?? this.recordId,
    operation: operation ?? this.operation,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SyncOutboxData copyWithCompanion(SyncOutboxCompanion data) {
    return SyncOutboxData(
      id: data.id.present ? data.id.value : this.id,
      entityTable: data.entityTable.present
          ? data.entityTable.value
          : this.entityTable,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxData(')
          ..write('id: $id, ')
          ..write('entityTable: $entityTable, ')
          ..write('recordId: $recordId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityTable,
    recordId,
    operation,
    payload,
    createdAt,
    retryCount,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOutboxData &&
          other.id == this.id &&
          other.entityTable == this.entityTable &&
          other.recordId == this.recordId &&
          other.operation == this.operation &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError);
}

class SyncOutboxCompanion extends UpdateCompanion<SyncOutboxData> {
  final Value<int> id;
  final Value<String> entityTable;
  final Value<String> recordId;
  final Value<String> operation;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<int> retryCount;
  final Value<String?> lastError;
  const SyncOutboxCompanion({
    this.id = const Value.absent(),
    this.entityTable = const Value.absent(),
    this.recordId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  SyncOutboxCompanion.insert({
    this.id = const Value.absent(),
    required String entityTable,
    required String recordId,
    required String operation,
    required String payload,
    required DateTime createdAt,
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
  }) : entityTable = Value(entityTable),
       recordId = Value(recordId),
       operation = Value(operation),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<SyncOutboxData> custom({
    Expression<int>? id,
    Expression<String>? entityTable,
    Expression<String>? recordId,
    Expression<String>? operation,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<int>? retryCount,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityTable != null) 'entity_table': entityTable,
      if (recordId != null) 'record_id': recordId,
      if (operation != null) 'operation': operation,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
    });
  }

  SyncOutboxCompanion copyWith({
    Value<int>? id,
    Value<String>? entityTable,
    Value<String>? recordId,
    Value<String>? operation,
    Value<String>? payload,
    Value<DateTime>? createdAt,
    Value<int>? retryCount,
    Value<String?>? lastError,
  }) {
    return SyncOutboxCompanion(
      id: id ?? this.id,
      entityTable: entityTable ?? this.entityTable,
      recordId: recordId ?? this.recordId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityTable.present) {
      map['entity_table'] = Variable<String>(entityTable.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxCompanion(')
          ..write('id: $id, ')
          ..write('entityTable: $entityTable, ')
          ..write('recordId: $recordId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

class $VocabularysTable extends Vocabularys
    with TableInfo<$VocabularysTable, Vocabulary> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VocabularysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 100),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stemMeta = const VerificationMeta('stem');
  @override
  late final GeneratedColumn<String> stem = GeneratedColumn<String>(
    'stem',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 100),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 64),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPendingSyncMeta = const VerificationMeta(
    'isPendingSync',
  );
  @override
  late final GeneratedColumn<bool> isPendingSync = GeneratedColumn<bool>(
    'is_pending_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pending_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    word,
    stem,
    contentHash,
    createdAt,
    updatedAt,
    deletedAt,
    lastSyncedAt,
    isPendingSync,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vocabularys';
  @override
  VerificationContext validateIntegrity(
    Insertable<Vocabulary> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('stem')) {
      context.handle(
        _stemMeta,
        stem.isAcceptableOrUnknown(data['stem']!, _stemMeta),
      );
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_pending_sync')) {
      context.handle(
        _isPendingSyncMeta,
        isPendingSync.isAcceptableOrUnknown(
          data['is_pending_sync']!,
          _isPendingSyncMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Vocabulary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Vocabulary(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      stem: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stem'],
      ),
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      isPendingSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pending_sync'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $VocabularysTable createAlias(String alias) {
    return $VocabularysTable(attachedDatabase, alias);
  }
}

class Vocabulary extends DataClass implements Insertable<Vocabulary> {
  final String id;
  final String userId;
  final String word;
  final String? stem;
  final String contentHash;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? lastSyncedAt;
  final bool isPendingSync;
  final int version;
  const Vocabulary({
    required this.id,
    required this.userId,
    required this.word,
    this.stem,
    required this.contentHash,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.lastSyncedAt,
    required this.isPendingSync,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['word'] = Variable<String>(word);
    if (!nullToAbsent || stem != null) {
      map['stem'] = Variable<String>(stem);
    }
    map['content_hash'] = Variable<String>(contentHash);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['is_pending_sync'] = Variable<bool>(isPendingSync);
    map['version'] = Variable<int>(version);
    return map;
  }

  VocabularysCompanion toCompanion(bool nullToAbsent) {
    return VocabularysCompanion(
      id: Value(id),
      userId: Value(userId),
      word: Value(word),
      stem: stem == null && nullToAbsent ? const Value.absent() : Value(stem),
      contentHash: Value(contentHash),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      isPendingSync: Value(isPendingSync),
      version: Value(version),
    );
  }

  factory Vocabulary.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Vocabulary(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      word: serializer.fromJson<String>(json['word']),
      stem: serializer.fromJson<String?>(json['stem']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      isPendingSync: serializer.fromJson<bool>(json['isPendingSync']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'word': serializer.toJson<String>(word),
      'stem': serializer.toJson<String?>(stem),
      'contentHash': serializer.toJson<String>(contentHash),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'isPendingSync': serializer.toJson<bool>(isPendingSync),
      'version': serializer.toJson<int>(version),
    };
  }

  Vocabulary copyWith({
    String? id,
    String? userId,
    String? word,
    Value<String?> stem = const Value.absent(),
    String? contentHash,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    bool? isPendingSync,
    int? version,
  }) => Vocabulary(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    word: word ?? this.word,
    stem: stem.present ? stem.value : this.stem,
    contentHash: contentHash ?? this.contentHash,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    isPendingSync: isPendingSync ?? this.isPendingSync,
    version: version ?? this.version,
  );
  Vocabulary copyWithCompanion(VocabularysCompanion data) {
    return Vocabulary(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      word: data.word.present ? data.word.value : this.word,
      stem: data.stem.present ? data.stem.value : this.stem,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      isPendingSync: data.isPendingSync.present
          ? data.isPendingSync.value
          : this.isPendingSync,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Vocabulary(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('word: $word, ')
          ..write('stem: $stem, ')
          ..write('contentHash: $contentHash, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('isPendingSync: $isPendingSync, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    word,
    stem,
    contentHash,
    createdAt,
    updatedAt,
    deletedAt,
    lastSyncedAt,
    isPendingSync,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Vocabulary &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.word == this.word &&
          other.stem == this.stem &&
          other.contentHash == this.contentHash &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.isPendingSync == this.isPendingSync &&
          other.version == this.version);
}

class VocabularysCompanion extends UpdateCompanion<Vocabulary> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> word;
  final Value<String?> stem;
  final Value<String> contentHash;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<bool> isPendingSync;
  final Value<int> version;
  final Value<int> rowid;
  const VocabularysCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.word = const Value.absent(),
    this.stem = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.isPendingSync = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VocabularysCompanion.insert({
    required String id,
    required String userId,
    required String word,
    this.stem = const Value.absent(),
    required String contentHash,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.isPendingSync = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       word = Value(word),
       contentHash = Value(contentHash),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Vocabulary> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? word,
    Expression<String>? stem,
    Expression<String>? contentHash,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<bool>? isPendingSync,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (word != null) 'word': word,
      if (stem != null) 'stem': stem,
      if (contentHash != null) 'content_hash': contentHash,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (isPendingSync != null) 'is_pending_sync': isPendingSync,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VocabularysCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? word,
    Value<String?>? stem,
    Value<String>? contentHash,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<bool>? isPendingSync,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return VocabularysCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      word: word ?? this.word,
      stem: stem ?? this.stem,
      contentHash: contentHash ?? this.contentHash,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isPendingSync: isPendingSync ?? this.isPendingSync,
      version: version ?? this.version,
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
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (stem.present) {
      map['stem'] = Variable<String>(stem.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (isPendingSync.present) {
      map['is_pending_sync'] = Variable<bool>(isPendingSync.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VocabularysCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('word: $word, ')
          ..write('stem: $stem, ')
          ..write('contentHash: $contentHash, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('isPendingSync: $isPendingSync, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LearningCardsTable extends LearningCards
    with TableInfo<$LearningCardsTable, LearningCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearningCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vocabularyIdMeta = const VerificationMeta(
    'vocabularyId',
  );
  @override
  late final GeneratedColumn<String> vocabularyId = GeneratedColumn<String>(
    'vocabulary_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<int> state = GeneratedColumn<int>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dueMeta = const VerificationMeta('due');
  @override
  late final GeneratedColumn<DateTime> due = GeneratedColumn<DateTime>(
    'due',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stabilityMeta = const VerificationMeta(
    'stability',
  );
  @override
  late final GeneratedColumn<double> stability = GeneratedColumn<double>(
    'stability',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<double> difficulty = GeneratedColumn<double>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
    'lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastReviewMeta = const VerificationMeta(
    'lastReview',
  );
  @override
  late final GeneratedColumn<DateTime> lastReview = GeneratedColumn<DateTime>(
    'last_review',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isLeechMeta = const VerificationMeta(
    'isLeech',
  );
  @override
  late final GeneratedColumn<bool> isLeech = GeneratedColumn<bool>(
    'is_leech',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_leech" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPendingSyncMeta = const VerificationMeta(
    'isPendingSync',
  );
  @override
  late final GeneratedColumn<bool> isPendingSync = GeneratedColumn<bool>(
    'is_pending_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pending_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    vocabularyId,
    state,
    due,
    stability,
    difficulty,
    reps,
    lapses,
    lastReview,
    isLeech,
    createdAt,
    updatedAt,
    deletedAt,
    lastSyncedAt,
    isPendingSync,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learning_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<LearningCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('vocabulary_id')) {
      context.handle(
        _vocabularyIdMeta,
        vocabularyId.isAcceptableOrUnknown(
          data['vocabulary_id']!,
          _vocabularyIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vocabularyIdMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('due')) {
      context.handle(
        _dueMeta,
        due.isAcceptableOrUnknown(data['due']!, _dueMeta),
      );
    } else if (isInserting) {
      context.missing(_dueMeta);
    }
    if (data.containsKey('stability')) {
      context.handle(
        _stabilityMeta,
        stability.isAcceptableOrUnknown(data['stability']!, _stabilityMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('lapses')) {
      context.handle(
        _lapsesMeta,
        lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta),
      );
    }
    if (data.containsKey('last_review')) {
      context.handle(
        _lastReviewMeta,
        lastReview.isAcceptableOrUnknown(data['last_review']!, _lastReviewMeta),
      );
    }
    if (data.containsKey('is_leech')) {
      context.handle(
        _isLeechMeta,
        isLeech.isAcceptableOrUnknown(data['is_leech']!, _isLeechMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_pending_sync')) {
      context.handle(
        _isPendingSyncMeta,
        isPendingSync.isAcceptableOrUnknown(
          data['is_pending_sync']!,
          _isPendingSyncMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LearningCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearningCard(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      vocabularyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vocabulary_id'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state'],
      )!,
      due: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due'],
      )!,
      stability: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stability'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}difficulty'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      )!,
      lapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapses'],
      )!,
      lastReview: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_review'],
      ),
      isLeech: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_leech'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      isPendingSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pending_sync'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $LearningCardsTable createAlias(String alias) {
    return $LearningCardsTable(attachedDatabase, alias);
  }
}

class LearningCard extends DataClass implements Insertable<LearningCard> {
  final String id;
  final String userId;
  final String vocabularyId;
  final int state;
  final DateTime due;
  final double stability;
  final double difficulty;
  final int reps;
  final int lapses;
  final DateTime? lastReview;
  final bool isLeech;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? lastSyncedAt;
  final bool isPendingSync;
  final int version;
  const LearningCard({
    required this.id,
    required this.userId,
    required this.vocabularyId,
    required this.state,
    required this.due,
    required this.stability,
    required this.difficulty,
    required this.reps,
    required this.lapses,
    this.lastReview,
    required this.isLeech,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.lastSyncedAt,
    required this.isPendingSync,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['vocabulary_id'] = Variable<String>(vocabularyId);
    map['state'] = Variable<int>(state);
    map['due'] = Variable<DateTime>(due);
    map['stability'] = Variable<double>(stability);
    map['difficulty'] = Variable<double>(difficulty);
    map['reps'] = Variable<int>(reps);
    map['lapses'] = Variable<int>(lapses);
    if (!nullToAbsent || lastReview != null) {
      map['last_review'] = Variable<DateTime>(lastReview);
    }
    map['is_leech'] = Variable<bool>(isLeech);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['is_pending_sync'] = Variable<bool>(isPendingSync);
    map['version'] = Variable<int>(version);
    return map;
  }

  LearningCardsCompanion toCompanion(bool nullToAbsent) {
    return LearningCardsCompanion(
      id: Value(id),
      userId: Value(userId),
      vocabularyId: Value(vocabularyId),
      state: Value(state),
      due: Value(due),
      stability: Value(stability),
      difficulty: Value(difficulty),
      reps: Value(reps),
      lapses: Value(lapses),
      lastReview: lastReview == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReview),
      isLeech: Value(isLeech),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      isPendingSync: Value(isPendingSync),
      version: Value(version),
    );
  }

  factory LearningCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearningCard(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      vocabularyId: serializer.fromJson<String>(json['vocabularyId']),
      state: serializer.fromJson<int>(json['state']),
      due: serializer.fromJson<DateTime>(json['due']),
      stability: serializer.fromJson<double>(json['stability']),
      difficulty: serializer.fromJson<double>(json['difficulty']),
      reps: serializer.fromJson<int>(json['reps']),
      lapses: serializer.fromJson<int>(json['lapses']),
      lastReview: serializer.fromJson<DateTime?>(json['lastReview']),
      isLeech: serializer.fromJson<bool>(json['isLeech']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      isPendingSync: serializer.fromJson<bool>(json['isPendingSync']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'vocabularyId': serializer.toJson<String>(vocabularyId),
      'state': serializer.toJson<int>(state),
      'due': serializer.toJson<DateTime>(due),
      'stability': serializer.toJson<double>(stability),
      'difficulty': serializer.toJson<double>(difficulty),
      'reps': serializer.toJson<int>(reps),
      'lapses': serializer.toJson<int>(lapses),
      'lastReview': serializer.toJson<DateTime?>(lastReview),
      'isLeech': serializer.toJson<bool>(isLeech),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'isPendingSync': serializer.toJson<bool>(isPendingSync),
      'version': serializer.toJson<int>(version),
    };
  }

  LearningCard copyWith({
    String? id,
    String? userId,
    String? vocabularyId,
    int? state,
    DateTime? due,
    double? stability,
    double? difficulty,
    int? reps,
    int? lapses,
    Value<DateTime?> lastReview = const Value.absent(),
    bool? isLeech,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    bool? isPendingSync,
    int? version,
  }) => LearningCard(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    vocabularyId: vocabularyId ?? this.vocabularyId,
    state: state ?? this.state,
    due: due ?? this.due,
    stability: stability ?? this.stability,
    difficulty: difficulty ?? this.difficulty,
    reps: reps ?? this.reps,
    lapses: lapses ?? this.lapses,
    lastReview: lastReview.present ? lastReview.value : this.lastReview,
    isLeech: isLeech ?? this.isLeech,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    isPendingSync: isPendingSync ?? this.isPendingSync,
    version: version ?? this.version,
  );
  LearningCard copyWithCompanion(LearningCardsCompanion data) {
    return LearningCard(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      vocabularyId: data.vocabularyId.present
          ? data.vocabularyId.value
          : this.vocabularyId,
      state: data.state.present ? data.state.value : this.state,
      due: data.due.present ? data.due.value : this.due,
      stability: data.stability.present ? data.stability.value : this.stability,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      reps: data.reps.present ? data.reps.value : this.reps,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      lastReview: data.lastReview.present
          ? data.lastReview.value
          : this.lastReview,
      isLeech: data.isLeech.present ? data.isLeech.value : this.isLeech,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      isPendingSync: data.isPendingSync.present
          ? data.isPendingSync.value
          : this.isPendingSync,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearningCard(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('vocabularyId: $vocabularyId, ')
          ..write('state: $state, ')
          ..write('due: $due, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('lastReview: $lastReview, ')
          ..write('isLeech: $isLeech, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('isPendingSync: $isPendingSync, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    vocabularyId,
    state,
    due,
    stability,
    difficulty,
    reps,
    lapses,
    lastReview,
    isLeech,
    createdAt,
    updatedAt,
    deletedAt,
    lastSyncedAt,
    isPendingSync,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearningCard &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.vocabularyId == this.vocabularyId &&
          other.state == this.state &&
          other.due == this.due &&
          other.stability == this.stability &&
          other.difficulty == this.difficulty &&
          other.reps == this.reps &&
          other.lapses == this.lapses &&
          other.lastReview == this.lastReview &&
          other.isLeech == this.isLeech &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.isPendingSync == this.isPendingSync &&
          other.version == this.version);
}

class LearningCardsCompanion extends UpdateCompanion<LearningCard> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> vocabularyId;
  final Value<int> state;
  final Value<DateTime> due;
  final Value<double> stability;
  final Value<double> difficulty;
  final Value<int> reps;
  final Value<int> lapses;
  final Value<DateTime?> lastReview;
  final Value<bool> isLeech;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<bool> isPendingSync;
  final Value<int> version;
  final Value<int> rowid;
  const LearningCardsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.vocabularyId = const Value.absent(),
    this.state = const Value.absent(),
    this.due = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.lastReview = const Value.absent(),
    this.isLeech = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.isPendingSync = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LearningCardsCompanion.insert({
    required String id,
    required String userId,
    required String vocabularyId,
    this.state = const Value.absent(),
    required DateTime due,
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.lastReview = const Value.absent(),
    this.isLeech = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.isPendingSync = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       vocabularyId = Value(vocabularyId),
       due = Value(due),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LearningCard> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? vocabularyId,
    Expression<int>? state,
    Expression<DateTime>? due,
    Expression<double>? stability,
    Expression<double>? difficulty,
    Expression<int>? reps,
    Expression<int>? lapses,
    Expression<DateTime>? lastReview,
    Expression<bool>? isLeech,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<bool>? isPendingSync,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (vocabularyId != null) 'vocabulary_id': vocabularyId,
      if (state != null) 'state': state,
      if (due != null) 'due': due,
      if (stability != null) 'stability': stability,
      if (difficulty != null) 'difficulty': difficulty,
      if (reps != null) 'reps': reps,
      if (lapses != null) 'lapses': lapses,
      if (lastReview != null) 'last_review': lastReview,
      if (isLeech != null) 'is_leech': isLeech,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (isPendingSync != null) 'is_pending_sync': isPendingSync,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LearningCardsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? vocabularyId,
    Value<int>? state,
    Value<DateTime>? due,
    Value<double>? stability,
    Value<double>? difficulty,
    Value<int>? reps,
    Value<int>? lapses,
    Value<DateTime?>? lastReview,
    Value<bool>? isLeech,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<bool>? isPendingSync,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return LearningCardsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vocabularyId: vocabularyId ?? this.vocabularyId,
      state: state ?? this.state,
      due: due ?? this.due,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      lastReview: lastReview ?? this.lastReview,
      isLeech: isLeech ?? this.isLeech,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isPendingSync: isPendingSync ?? this.isPendingSync,
      version: version ?? this.version,
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
    if (vocabularyId.present) {
      map['vocabulary_id'] = Variable<String>(vocabularyId.value);
    }
    if (state.present) {
      map['state'] = Variable<int>(state.value);
    }
    if (due.present) {
      map['due'] = Variable<DateTime>(due.value);
    }
    if (stability.present) {
      map['stability'] = Variable<double>(stability.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<double>(difficulty.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (lastReview.present) {
      map['last_review'] = Variable<DateTime>(lastReview.value);
    }
    if (isLeech.present) {
      map['is_leech'] = Variable<bool>(isLeech.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (isPendingSync.present) {
      map['is_pending_sync'] = Variable<bool>(isPendingSync.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearningCardsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('vocabularyId: $vocabularyId, ')
          ..write('state: $state, ')
          ..write('due: $due, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('lastReview: $lastReview, ')
          ..write('isLeech: $isLeech, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('isPendingSync: $isPendingSync, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewLogsTable extends ReviewLogs
    with TableInfo<$ReviewLogsTable, ReviewLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _learningCardIdMeta = const VerificationMeta(
    'learningCardId',
  );
  @override
  late final GeneratedColumn<String> learningCardId = GeneratedColumn<String>(
    'learning_card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _interactionModeMeta = const VerificationMeta(
    'interactionMode',
  );
  @override
  late final GeneratedColumn<int> interactionMode = GeneratedColumn<int>(
    'interaction_mode',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateBeforeMeta = const VerificationMeta(
    'stateBefore',
  );
  @override
  late final GeneratedColumn<int> stateBefore = GeneratedColumn<int>(
    'state_before',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateAfterMeta = const VerificationMeta(
    'stateAfter',
  );
  @override
  late final GeneratedColumn<int> stateAfter = GeneratedColumn<int>(
    'state_after',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stabilityBeforeMeta = const VerificationMeta(
    'stabilityBefore',
  );
  @override
  late final GeneratedColumn<double> stabilityBefore = GeneratedColumn<double>(
    'stability_before',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stabilityAfterMeta = const VerificationMeta(
    'stabilityAfter',
  );
  @override
  late final GeneratedColumn<double> stabilityAfter = GeneratedColumn<double>(
    'stability_after',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyBeforeMeta = const VerificationMeta(
    'difficultyBefore',
  );
  @override
  late final GeneratedColumn<double> difficultyBefore = GeneratedColumn<double>(
    'difficulty_before',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyAfterMeta = const VerificationMeta(
    'difficultyAfter',
  );
  @override
  late final GeneratedColumn<double> difficultyAfter = GeneratedColumn<double>(
    'difficulty_after',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _responseTimeMsMeta = const VerificationMeta(
    'responseTimeMs',
  );
  @override
  late final GeneratedColumn<int> responseTimeMs = GeneratedColumn<int>(
    'response_time_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retrievabilityAtReviewMeta =
      const VerificationMeta('retrievabilityAtReview');
  @override
  late final GeneratedColumn<double> retrievabilityAtReview =
      GeneratedColumn<double>(
        'retrievability_at_review',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
    'reviewed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cueTypeMeta = const VerificationMeta(
    'cueType',
  );
  @override
  late final GeneratedColumn<String> cueType = GeneratedColumn<String>(
    'cue_type',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPendingSyncMeta = const VerificationMeta(
    'isPendingSync',
  );
  @override
  late final GeneratedColumn<bool> isPendingSync = GeneratedColumn<bool>(
    'is_pending_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pending_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    learningCardId,
    rating,
    interactionMode,
    stateBefore,
    stateAfter,
    stabilityBefore,
    stabilityAfter,
    difficultyBefore,
    difficultyAfter,
    responseTimeMs,
    retrievabilityAtReview,
    reviewedAt,
    sessionId,
    cueType,
    isPendingSync,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('learning_card_id')) {
      context.handle(
        _learningCardIdMeta,
        learningCardId.isAcceptableOrUnknown(
          data['learning_card_id']!,
          _learningCardIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_learningCardIdMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('interaction_mode')) {
      context.handle(
        _interactionModeMeta,
        interactionMode.isAcceptableOrUnknown(
          data['interaction_mode']!,
          _interactionModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_interactionModeMeta);
    }
    if (data.containsKey('state_before')) {
      context.handle(
        _stateBeforeMeta,
        stateBefore.isAcceptableOrUnknown(
          data['state_before']!,
          _stateBeforeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stateBeforeMeta);
    }
    if (data.containsKey('state_after')) {
      context.handle(
        _stateAfterMeta,
        stateAfter.isAcceptableOrUnknown(data['state_after']!, _stateAfterMeta),
      );
    } else if (isInserting) {
      context.missing(_stateAfterMeta);
    }
    if (data.containsKey('stability_before')) {
      context.handle(
        _stabilityBeforeMeta,
        stabilityBefore.isAcceptableOrUnknown(
          data['stability_before']!,
          _stabilityBeforeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stabilityBeforeMeta);
    }
    if (data.containsKey('stability_after')) {
      context.handle(
        _stabilityAfterMeta,
        stabilityAfter.isAcceptableOrUnknown(
          data['stability_after']!,
          _stabilityAfterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stabilityAfterMeta);
    }
    if (data.containsKey('difficulty_before')) {
      context.handle(
        _difficultyBeforeMeta,
        difficultyBefore.isAcceptableOrUnknown(
          data['difficulty_before']!,
          _difficultyBeforeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_difficultyBeforeMeta);
    }
    if (data.containsKey('difficulty_after')) {
      context.handle(
        _difficultyAfterMeta,
        difficultyAfter.isAcceptableOrUnknown(
          data['difficulty_after']!,
          _difficultyAfterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_difficultyAfterMeta);
    }
    if (data.containsKey('response_time_ms')) {
      context.handle(
        _responseTimeMsMeta,
        responseTimeMs.isAcceptableOrUnknown(
          data['response_time_ms']!,
          _responseTimeMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_responseTimeMsMeta);
    }
    if (data.containsKey('retrievability_at_review')) {
      context.handle(
        _retrievabilityAtReviewMeta,
        retrievabilityAtReview.isAcceptableOrUnknown(
          data['retrievability_at_review']!,
          _retrievabilityAtReviewMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_retrievabilityAtReviewMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('cue_type')) {
      context.handle(
        _cueTypeMeta,
        cueType.isAcceptableOrUnknown(data['cue_type']!, _cueTypeMeta),
      );
    }
    if (data.containsKey('is_pending_sync')) {
      context.handle(
        _isPendingSyncMeta,
        isPendingSync.isAcceptableOrUnknown(
          data['is_pending_sync']!,
          _isPendingSyncMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      learningCardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}learning_card_id'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      )!,
      interactionMode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interaction_mode'],
      )!,
      stateBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state_before'],
      )!,
      stateAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state_after'],
      )!,
      stabilityBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stability_before'],
      )!,
      stabilityAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stability_after'],
      )!,
      difficultyBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}difficulty_before'],
      )!,
      difficultyAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}difficulty_after'],
      )!,
      responseTimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}response_time_ms'],
      )!,
      retrievabilityAtReview: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}retrievability_at_review'],
      )!,
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reviewed_at'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      ),
      cueType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cue_type'],
      ),
      isPendingSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pending_sync'],
      )!,
    );
  }

  @override
  $ReviewLogsTable createAlias(String alias) {
    return $ReviewLogsTable(attachedDatabase, alias);
  }
}

class ReviewLog extends DataClass implements Insertable<ReviewLog> {
  final String id;
  final String userId;
  final String learningCardId;
  final int rating;
  final int interactionMode;
  final int stateBefore;
  final int stateAfter;
  final double stabilityBefore;
  final double stabilityAfter;
  final double difficultyBefore;
  final double difficultyAfter;
  final int responseTimeMs;
  final double retrievabilityAtReview;
  final DateTime reviewedAt;
  final String? sessionId;
  final String? cueType;
  final bool isPendingSync;
  const ReviewLog({
    required this.id,
    required this.userId,
    required this.learningCardId,
    required this.rating,
    required this.interactionMode,
    required this.stateBefore,
    required this.stateAfter,
    required this.stabilityBefore,
    required this.stabilityAfter,
    required this.difficultyBefore,
    required this.difficultyAfter,
    required this.responseTimeMs,
    required this.retrievabilityAtReview,
    required this.reviewedAt,
    this.sessionId,
    this.cueType,
    required this.isPendingSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['learning_card_id'] = Variable<String>(learningCardId);
    map['rating'] = Variable<int>(rating);
    map['interaction_mode'] = Variable<int>(interactionMode);
    map['state_before'] = Variable<int>(stateBefore);
    map['state_after'] = Variable<int>(stateAfter);
    map['stability_before'] = Variable<double>(stabilityBefore);
    map['stability_after'] = Variable<double>(stabilityAfter);
    map['difficulty_before'] = Variable<double>(difficultyBefore);
    map['difficulty_after'] = Variable<double>(difficultyAfter);
    map['response_time_ms'] = Variable<int>(responseTimeMs);
    map['retrievability_at_review'] = Variable<double>(retrievabilityAtReview);
    map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    if (!nullToAbsent || cueType != null) {
      map['cue_type'] = Variable<String>(cueType);
    }
    map['is_pending_sync'] = Variable<bool>(isPendingSync);
    return map;
  }

  ReviewLogsCompanion toCompanion(bool nullToAbsent) {
    return ReviewLogsCompanion(
      id: Value(id),
      userId: Value(userId),
      learningCardId: Value(learningCardId),
      rating: Value(rating),
      interactionMode: Value(interactionMode),
      stateBefore: Value(stateBefore),
      stateAfter: Value(stateAfter),
      stabilityBefore: Value(stabilityBefore),
      stabilityAfter: Value(stabilityAfter),
      difficultyBefore: Value(difficultyBefore),
      difficultyAfter: Value(difficultyAfter),
      responseTimeMs: Value(responseTimeMs),
      retrievabilityAtReview: Value(retrievabilityAtReview),
      reviewedAt: Value(reviewedAt),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      cueType: cueType == null && nullToAbsent
          ? const Value.absent()
          : Value(cueType),
      isPendingSync: Value(isPendingSync),
    );
  }

  factory ReviewLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewLog(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      learningCardId: serializer.fromJson<String>(json['learningCardId']),
      rating: serializer.fromJson<int>(json['rating']),
      interactionMode: serializer.fromJson<int>(json['interactionMode']),
      stateBefore: serializer.fromJson<int>(json['stateBefore']),
      stateAfter: serializer.fromJson<int>(json['stateAfter']),
      stabilityBefore: serializer.fromJson<double>(json['stabilityBefore']),
      stabilityAfter: serializer.fromJson<double>(json['stabilityAfter']),
      difficultyBefore: serializer.fromJson<double>(json['difficultyBefore']),
      difficultyAfter: serializer.fromJson<double>(json['difficultyAfter']),
      responseTimeMs: serializer.fromJson<int>(json['responseTimeMs']),
      retrievabilityAtReview: serializer.fromJson<double>(
        json['retrievabilityAtReview'],
      ),
      reviewedAt: serializer.fromJson<DateTime>(json['reviewedAt']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      cueType: serializer.fromJson<String?>(json['cueType']),
      isPendingSync: serializer.fromJson<bool>(json['isPendingSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'learningCardId': serializer.toJson<String>(learningCardId),
      'rating': serializer.toJson<int>(rating),
      'interactionMode': serializer.toJson<int>(interactionMode),
      'stateBefore': serializer.toJson<int>(stateBefore),
      'stateAfter': serializer.toJson<int>(stateAfter),
      'stabilityBefore': serializer.toJson<double>(stabilityBefore),
      'stabilityAfter': serializer.toJson<double>(stabilityAfter),
      'difficultyBefore': serializer.toJson<double>(difficultyBefore),
      'difficultyAfter': serializer.toJson<double>(difficultyAfter),
      'responseTimeMs': serializer.toJson<int>(responseTimeMs),
      'retrievabilityAtReview': serializer.toJson<double>(
        retrievabilityAtReview,
      ),
      'reviewedAt': serializer.toJson<DateTime>(reviewedAt),
      'sessionId': serializer.toJson<String?>(sessionId),
      'cueType': serializer.toJson<String?>(cueType),
      'isPendingSync': serializer.toJson<bool>(isPendingSync),
    };
  }

  ReviewLog copyWith({
    String? id,
    String? userId,
    String? learningCardId,
    int? rating,
    int? interactionMode,
    int? stateBefore,
    int? stateAfter,
    double? stabilityBefore,
    double? stabilityAfter,
    double? difficultyBefore,
    double? difficultyAfter,
    int? responseTimeMs,
    double? retrievabilityAtReview,
    DateTime? reviewedAt,
    Value<String?> sessionId = const Value.absent(),
    Value<String?> cueType = const Value.absent(),
    bool? isPendingSync,
  }) => ReviewLog(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    learningCardId: learningCardId ?? this.learningCardId,
    rating: rating ?? this.rating,
    interactionMode: interactionMode ?? this.interactionMode,
    stateBefore: stateBefore ?? this.stateBefore,
    stateAfter: stateAfter ?? this.stateAfter,
    stabilityBefore: stabilityBefore ?? this.stabilityBefore,
    stabilityAfter: stabilityAfter ?? this.stabilityAfter,
    difficultyBefore: difficultyBefore ?? this.difficultyBefore,
    difficultyAfter: difficultyAfter ?? this.difficultyAfter,
    responseTimeMs: responseTimeMs ?? this.responseTimeMs,
    retrievabilityAtReview:
        retrievabilityAtReview ?? this.retrievabilityAtReview,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    cueType: cueType.present ? cueType.value : this.cueType,
    isPendingSync: isPendingSync ?? this.isPendingSync,
  );
  ReviewLog copyWithCompanion(ReviewLogsCompanion data) {
    return ReviewLog(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      learningCardId: data.learningCardId.present
          ? data.learningCardId.value
          : this.learningCardId,
      rating: data.rating.present ? data.rating.value : this.rating,
      interactionMode: data.interactionMode.present
          ? data.interactionMode.value
          : this.interactionMode,
      stateBefore: data.stateBefore.present
          ? data.stateBefore.value
          : this.stateBefore,
      stateAfter: data.stateAfter.present
          ? data.stateAfter.value
          : this.stateAfter,
      stabilityBefore: data.stabilityBefore.present
          ? data.stabilityBefore.value
          : this.stabilityBefore,
      stabilityAfter: data.stabilityAfter.present
          ? data.stabilityAfter.value
          : this.stabilityAfter,
      difficultyBefore: data.difficultyBefore.present
          ? data.difficultyBefore.value
          : this.difficultyBefore,
      difficultyAfter: data.difficultyAfter.present
          ? data.difficultyAfter.value
          : this.difficultyAfter,
      responseTimeMs: data.responseTimeMs.present
          ? data.responseTimeMs.value
          : this.responseTimeMs,
      retrievabilityAtReview: data.retrievabilityAtReview.present
          ? data.retrievabilityAtReview.value
          : this.retrievabilityAtReview,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      cueType: data.cueType.present ? data.cueType.value : this.cueType,
      isPendingSync: data.isPendingSync.present
          ? data.isPendingSync.value
          : this.isPendingSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLog(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('learningCardId: $learningCardId, ')
          ..write('rating: $rating, ')
          ..write('interactionMode: $interactionMode, ')
          ..write('stateBefore: $stateBefore, ')
          ..write('stateAfter: $stateAfter, ')
          ..write('stabilityBefore: $stabilityBefore, ')
          ..write('stabilityAfter: $stabilityAfter, ')
          ..write('difficultyBefore: $difficultyBefore, ')
          ..write('difficultyAfter: $difficultyAfter, ')
          ..write('responseTimeMs: $responseTimeMs, ')
          ..write('retrievabilityAtReview: $retrievabilityAtReview, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('sessionId: $sessionId, ')
          ..write('cueType: $cueType, ')
          ..write('isPendingSync: $isPendingSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    learningCardId,
    rating,
    interactionMode,
    stateBefore,
    stateAfter,
    stabilityBefore,
    stabilityAfter,
    difficultyBefore,
    difficultyAfter,
    responseTimeMs,
    retrievabilityAtReview,
    reviewedAt,
    sessionId,
    cueType,
    isPendingSync,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewLog &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.learningCardId == this.learningCardId &&
          other.rating == this.rating &&
          other.interactionMode == this.interactionMode &&
          other.stateBefore == this.stateBefore &&
          other.stateAfter == this.stateAfter &&
          other.stabilityBefore == this.stabilityBefore &&
          other.stabilityAfter == this.stabilityAfter &&
          other.difficultyBefore == this.difficultyBefore &&
          other.difficultyAfter == this.difficultyAfter &&
          other.responseTimeMs == this.responseTimeMs &&
          other.retrievabilityAtReview == this.retrievabilityAtReview &&
          other.reviewedAt == this.reviewedAt &&
          other.sessionId == this.sessionId &&
          other.cueType == this.cueType &&
          other.isPendingSync == this.isPendingSync);
}

class ReviewLogsCompanion extends UpdateCompanion<ReviewLog> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> learningCardId;
  final Value<int> rating;
  final Value<int> interactionMode;
  final Value<int> stateBefore;
  final Value<int> stateAfter;
  final Value<double> stabilityBefore;
  final Value<double> stabilityAfter;
  final Value<double> difficultyBefore;
  final Value<double> difficultyAfter;
  final Value<int> responseTimeMs;
  final Value<double> retrievabilityAtReview;
  final Value<DateTime> reviewedAt;
  final Value<String?> sessionId;
  final Value<String?> cueType;
  final Value<bool> isPendingSync;
  final Value<int> rowid;
  const ReviewLogsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.learningCardId = const Value.absent(),
    this.rating = const Value.absent(),
    this.interactionMode = const Value.absent(),
    this.stateBefore = const Value.absent(),
    this.stateAfter = const Value.absent(),
    this.stabilityBefore = const Value.absent(),
    this.stabilityAfter = const Value.absent(),
    this.difficultyBefore = const Value.absent(),
    this.difficultyAfter = const Value.absent(),
    this.responseTimeMs = const Value.absent(),
    this.retrievabilityAtReview = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.cueType = const Value.absent(),
    this.isPendingSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReviewLogsCompanion.insert({
    required String id,
    required String userId,
    required String learningCardId,
    required int rating,
    required int interactionMode,
    required int stateBefore,
    required int stateAfter,
    required double stabilityBefore,
    required double stabilityAfter,
    required double difficultyBefore,
    required double difficultyAfter,
    required int responseTimeMs,
    required double retrievabilityAtReview,
    required DateTime reviewedAt,
    this.sessionId = const Value.absent(),
    this.cueType = const Value.absent(),
    this.isPendingSync = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       learningCardId = Value(learningCardId),
       rating = Value(rating),
       interactionMode = Value(interactionMode),
       stateBefore = Value(stateBefore),
       stateAfter = Value(stateAfter),
       stabilityBefore = Value(stabilityBefore),
       stabilityAfter = Value(stabilityAfter),
       difficultyBefore = Value(difficultyBefore),
       difficultyAfter = Value(difficultyAfter),
       responseTimeMs = Value(responseTimeMs),
       retrievabilityAtReview = Value(retrievabilityAtReview),
       reviewedAt = Value(reviewedAt);
  static Insertable<ReviewLog> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? learningCardId,
    Expression<int>? rating,
    Expression<int>? interactionMode,
    Expression<int>? stateBefore,
    Expression<int>? stateAfter,
    Expression<double>? stabilityBefore,
    Expression<double>? stabilityAfter,
    Expression<double>? difficultyBefore,
    Expression<double>? difficultyAfter,
    Expression<int>? responseTimeMs,
    Expression<double>? retrievabilityAtReview,
    Expression<DateTime>? reviewedAt,
    Expression<String>? sessionId,
    Expression<String>? cueType,
    Expression<bool>? isPendingSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (learningCardId != null) 'learning_card_id': learningCardId,
      if (rating != null) 'rating': rating,
      if (interactionMode != null) 'interaction_mode': interactionMode,
      if (stateBefore != null) 'state_before': stateBefore,
      if (stateAfter != null) 'state_after': stateAfter,
      if (stabilityBefore != null) 'stability_before': stabilityBefore,
      if (stabilityAfter != null) 'stability_after': stabilityAfter,
      if (difficultyBefore != null) 'difficulty_before': difficultyBefore,
      if (difficultyAfter != null) 'difficulty_after': difficultyAfter,
      if (responseTimeMs != null) 'response_time_ms': responseTimeMs,
      if (retrievabilityAtReview != null)
        'retrievability_at_review': retrievabilityAtReview,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (sessionId != null) 'session_id': sessionId,
      if (cueType != null) 'cue_type': cueType,
      if (isPendingSync != null) 'is_pending_sync': isPendingSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReviewLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? learningCardId,
    Value<int>? rating,
    Value<int>? interactionMode,
    Value<int>? stateBefore,
    Value<int>? stateAfter,
    Value<double>? stabilityBefore,
    Value<double>? stabilityAfter,
    Value<double>? difficultyBefore,
    Value<double>? difficultyAfter,
    Value<int>? responseTimeMs,
    Value<double>? retrievabilityAtReview,
    Value<DateTime>? reviewedAt,
    Value<String?>? sessionId,
    Value<String?>? cueType,
    Value<bool>? isPendingSync,
    Value<int>? rowid,
  }) {
    return ReviewLogsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      learningCardId: learningCardId ?? this.learningCardId,
      rating: rating ?? this.rating,
      interactionMode: interactionMode ?? this.interactionMode,
      stateBefore: stateBefore ?? this.stateBefore,
      stateAfter: stateAfter ?? this.stateAfter,
      stabilityBefore: stabilityBefore ?? this.stabilityBefore,
      stabilityAfter: stabilityAfter ?? this.stabilityAfter,
      difficultyBefore: difficultyBefore ?? this.difficultyBefore,
      difficultyAfter: difficultyAfter ?? this.difficultyAfter,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      retrievabilityAtReview:
          retrievabilityAtReview ?? this.retrievabilityAtReview,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      sessionId: sessionId ?? this.sessionId,
      cueType: cueType ?? this.cueType,
      isPendingSync: isPendingSync ?? this.isPendingSync,
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
    if (learningCardId.present) {
      map['learning_card_id'] = Variable<String>(learningCardId.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (interactionMode.present) {
      map['interaction_mode'] = Variable<int>(interactionMode.value);
    }
    if (stateBefore.present) {
      map['state_before'] = Variable<int>(stateBefore.value);
    }
    if (stateAfter.present) {
      map['state_after'] = Variable<int>(stateAfter.value);
    }
    if (stabilityBefore.present) {
      map['stability_before'] = Variable<double>(stabilityBefore.value);
    }
    if (stabilityAfter.present) {
      map['stability_after'] = Variable<double>(stabilityAfter.value);
    }
    if (difficultyBefore.present) {
      map['difficulty_before'] = Variable<double>(difficultyBefore.value);
    }
    if (difficultyAfter.present) {
      map['difficulty_after'] = Variable<double>(difficultyAfter.value);
    }
    if (responseTimeMs.present) {
      map['response_time_ms'] = Variable<int>(responseTimeMs.value);
    }
    if (retrievabilityAtReview.present) {
      map['retrievability_at_review'] = Variable<double>(
        retrievabilityAtReview.value,
      );
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (cueType.present) {
      map['cue_type'] = Variable<String>(cueType.value);
    }
    if (isPendingSync.present) {
      map['is_pending_sync'] = Variable<bool>(isPendingSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('learningCardId: $learningCardId, ')
          ..write('rating: $rating, ')
          ..write('interactionMode: $interactionMode, ')
          ..write('stateBefore: $stateBefore, ')
          ..write('stateAfter: $stateAfter, ')
          ..write('stabilityBefore: $stabilityBefore, ')
          ..write('stabilityAfter: $stabilityAfter, ')
          ..write('difficultyBefore: $difficultyBefore, ')
          ..write('difficultyAfter: $difficultyAfter, ')
          ..write('responseTimeMs: $responseTimeMs, ')
          ..write('retrievabilityAtReview: $retrievabilityAtReview, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('sessionId: $sessionId, ')
          ..write('cueType: $cueType, ')
          ..write('isPendingSync: $isPendingSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LearningSessionsTable extends LearningSessions
    with TableInfo<$LearningSessionsTable, LearningSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearningSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedMinutesMeta = const VerificationMeta(
    'plannedMinutes',
  );
  @override
  late final GeneratedColumn<int> plannedMinutes = GeneratedColumn<int>(
    'planned_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elapsedSecondsMeta = const VerificationMeta(
    'elapsedSeconds',
  );
  @override
  late final GeneratedColumn<int> elapsedSeconds = GeneratedColumn<int>(
    'elapsed_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bonusSecondsMeta = const VerificationMeta(
    'bonusSeconds',
  );
  @override
  late final GeneratedColumn<int> bonusSeconds = GeneratedColumn<int>(
    'bonus_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _itemsPresentedMeta = const VerificationMeta(
    'itemsPresented',
  );
  @override
  late final GeneratedColumn<int> itemsPresented = GeneratedColumn<int>(
    'items_presented',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _itemsCompletedMeta = const VerificationMeta(
    'itemsCompleted',
  );
  @override
  late final GeneratedColumn<int> itemsCompleted = GeneratedColumn<int>(
    'items_completed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _newWordsPresentedMeta = const VerificationMeta(
    'newWordsPresented',
  );
  @override
  late final GeneratedColumn<int> newWordsPresented = GeneratedColumn<int>(
    'new_words_presented',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _reviewsPresentedMeta = const VerificationMeta(
    'reviewsPresented',
  );
  @override
  late final GeneratedColumn<int> reviewsPresented = GeneratedColumn<int>(
    'reviews_presented',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _accuracyRateMeta = const VerificationMeta(
    'accuracyRate',
  );
  @override
  late final GeneratedColumn<double> accuracyRate = GeneratedColumn<double>(
    'accuracy_rate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avgResponseTimeMsMeta = const VerificationMeta(
    'avgResponseTimeMs',
  );
  @override
  late final GeneratedColumn<int> avgResponseTimeMs = GeneratedColumn<int>(
    'avg_response_time_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<int> outcome = GeneratedColumn<int>(
    'outcome',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPendingSyncMeta = const VerificationMeta(
    'isPendingSync',
  );
  @override
  late final GeneratedColumn<bool> isPendingSync = GeneratedColumn<bool>(
    'is_pending_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pending_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    startedAt,
    expiresAt,
    plannedMinutes,
    elapsedSeconds,
    bonusSeconds,
    itemsPresented,
    itemsCompleted,
    newWordsPresented,
    reviewsPresented,
    accuracyRate,
    avgResponseTimeMs,
    outcome,
    createdAt,
    updatedAt,
    isPendingSync,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learning_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LearningSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('planned_minutes')) {
      context.handle(
        _plannedMinutesMeta,
        plannedMinutes.isAcceptableOrUnknown(
          data['planned_minutes']!,
          _plannedMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedMinutesMeta);
    }
    if (data.containsKey('elapsed_seconds')) {
      context.handle(
        _elapsedSecondsMeta,
        elapsedSeconds.isAcceptableOrUnknown(
          data['elapsed_seconds']!,
          _elapsedSecondsMeta,
        ),
      );
    }
    if (data.containsKey('bonus_seconds')) {
      context.handle(
        _bonusSecondsMeta,
        bonusSeconds.isAcceptableOrUnknown(
          data['bonus_seconds']!,
          _bonusSecondsMeta,
        ),
      );
    }
    if (data.containsKey('items_presented')) {
      context.handle(
        _itemsPresentedMeta,
        itemsPresented.isAcceptableOrUnknown(
          data['items_presented']!,
          _itemsPresentedMeta,
        ),
      );
    }
    if (data.containsKey('items_completed')) {
      context.handle(
        _itemsCompletedMeta,
        itemsCompleted.isAcceptableOrUnknown(
          data['items_completed']!,
          _itemsCompletedMeta,
        ),
      );
    }
    if (data.containsKey('new_words_presented')) {
      context.handle(
        _newWordsPresentedMeta,
        newWordsPresented.isAcceptableOrUnknown(
          data['new_words_presented']!,
          _newWordsPresentedMeta,
        ),
      );
    }
    if (data.containsKey('reviews_presented')) {
      context.handle(
        _reviewsPresentedMeta,
        reviewsPresented.isAcceptableOrUnknown(
          data['reviews_presented']!,
          _reviewsPresentedMeta,
        ),
      );
    }
    if (data.containsKey('accuracy_rate')) {
      context.handle(
        _accuracyRateMeta,
        accuracyRate.isAcceptableOrUnknown(
          data['accuracy_rate']!,
          _accuracyRateMeta,
        ),
      );
    }
    if (data.containsKey('avg_response_time_ms')) {
      context.handle(
        _avgResponseTimeMsMeta,
        avgResponseTimeMs.isAcceptableOrUnknown(
          data['avg_response_time_ms']!,
          _avgResponseTimeMsMeta,
        ),
      );
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_pending_sync')) {
      context.handle(
        _isPendingSyncMeta,
        isPendingSync.isAcceptableOrUnknown(
          data['is_pending_sync']!,
          _isPendingSyncMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LearningSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearningSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
      plannedMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_minutes'],
      )!,
      elapsedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elapsed_seconds'],
      )!,
      bonusSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bonus_seconds'],
      )!,
      itemsPresented: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}items_presented'],
      )!,
      itemsCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}items_completed'],
      )!,
      newWordsPresented: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}new_words_presented'],
      )!,
      reviewsPresented: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reviews_presented'],
      )!,
      accuracyRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy_rate'],
      ),
      avgResponseTimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avg_response_time_ms'],
      ),
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}outcome'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isPendingSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pending_sync'],
      )!,
    );
  }

  @override
  $LearningSessionsTable createAlias(String alias) {
    return $LearningSessionsTable(attachedDatabase, alias);
  }
}

class LearningSession extends DataClass implements Insertable<LearningSession> {
  final String id;
  final String userId;
  final DateTime startedAt;
  final DateTime expiresAt;
  final int plannedMinutes;
  final int elapsedSeconds;
  final int bonusSeconds;
  final int itemsPresented;
  final int itemsCompleted;
  final int newWordsPresented;
  final int reviewsPresented;
  final double? accuracyRate;
  final int? avgResponseTimeMs;
  final int outcome;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPendingSync;
  const LearningSession({
    required this.id,
    required this.userId,
    required this.startedAt,
    required this.expiresAt,
    required this.plannedMinutes,
    required this.elapsedSeconds,
    required this.bonusSeconds,
    required this.itemsPresented,
    required this.itemsCompleted,
    required this.newWordsPresented,
    required this.reviewsPresented,
    this.accuracyRate,
    this.avgResponseTimeMs,
    required this.outcome,
    required this.createdAt,
    required this.updatedAt,
    required this.isPendingSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    map['planned_minutes'] = Variable<int>(plannedMinutes);
    map['elapsed_seconds'] = Variable<int>(elapsedSeconds);
    map['bonus_seconds'] = Variable<int>(bonusSeconds);
    map['items_presented'] = Variable<int>(itemsPresented);
    map['items_completed'] = Variable<int>(itemsCompleted);
    map['new_words_presented'] = Variable<int>(newWordsPresented);
    map['reviews_presented'] = Variable<int>(reviewsPresented);
    if (!nullToAbsent || accuracyRate != null) {
      map['accuracy_rate'] = Variable<double>(accuracyRate);
    }
    if (!nullToAbsent || avgResponseTimeMs != null) {
      map['avg_response_time_ms'] = Variable<int>(avgResponseTimeMs);
    }
    map['outcome'] = Variable<int>(outcome);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_pending_sync'] = Variable<bool>(isPendingSync);
    return map;
  }

  LearningSessionsCompanion toCompanion(bool nullToAbsent) {
    return LearningSessionsCompanion(
      id: Value(id),
      userId: Value(userId),
      startedAt: Value(startedAt),
      expiresAt: Value(expiresAt),
      plannedMinutes: Value(plannedMinutes),
      elapsedSeconds: Value(elapsedSeconds),
      bonusSeconds: Value(bonusSeconds),
      itemsPresented: Value(itemsPresented),
      itemsCompleted: Value(itemsCompleted),
      newWordsPresented: Value(newWordsPresented),
      reviewsPresented: Value(reviewsPresented),
      accuracyRate: accuracyRate == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracyRate),
      avgResponseTimeMs: avgResponseTimeMs == null && nullToAbsent
          ? const Value.absent()
          : Value(avgResponseTimeMs),
      outcome: Value(outcome),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isPendingSync: Value(isPendingSync),
    );
  }

  factory LearningSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearningSession(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
      plannedMinutes: serializer.fromJson<int>(json['plannedMinutes']),
      elapsedSeconds: serializer.fromJson<int>(json['elapsedSeconds']),
      bonusSeconds: serializer.fromJson<int>(json['bonusSeconds']),
      itemsPresented: serializer.fromJson<int>(json['itemsPresented']),
      itemsCompleted: serializer.fromJson<int>(json['itemsCompleted']),
      newWordsPresented: serializer.fromJson<int>(json['newWordsPresented']),
      reviewsPresented: serializer.fromJson<int>(json['reviewsPresented']),
      accuracyRate: serializer.fromJson<double?>(json['accuracyRate']),
      avgResponseTimeMs: serializer.fromJson<int?>(json['avgResponseTimeMs']),
      outcome: serializer.fromJson<int>(json['outcome']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isPendingSync: serializer.fromJson<bool>(json['isPendingSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
      'plannedMinutes': serializer.toJson<int>(plannedMinutes),
      'elapsedSeconds': serializer.toJson<int>(elapsedSeconds),
      'bonusSeconds': serializer.toJson<int>(bonusSeconds),
      'itemsPresented': serializer.toJson<int>(itemsPresented),
      'itemsCompleted': serializer.toJson<int>(itemsCompleted),
      'newWordsPresented': serializer.toJson<int>(newWordsPresented),
      'reviewsPresented': serializer.toJson<int>(reviewsPresented),
      'accuracyRate': serializer.toJson<double?>(accuracyRate),
      'avgResponseTimeMs': serializer.toJson<int?>(avgResponseTimeMs),
      'outcome': serializer.toJson<int>(outcome),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isPendingSync': serializer.toJson<bool>(isPendingSync),
    };
  }

  LearningSession copyWith({
    String? id,
    String? userId,
    DateTime? startedAt,
    DateTime? expiresAt,
    int? plannedMinutes,
    int? elapsedSeconds,
    int? bonusSeconds,
    int? itemsPresented,
    int? itemsCompleted,
    int? newWordsPresented,
    int? reviewsPresented,
    Value<double?> accuracyRate = const Value.absent(),
    Value<int?> avgResponseTimeMs = const Value.absent(),
    int? outcome,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPendingSync,
  }) => LearningSession(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    startedAt: startedAt ?? this.startedAt,
    expiresAt: expiresAt ?? this.expiresAt,
    plannedMinutes: plannedMinutes ?? this.plannedMinutes,
    elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    bonusSeconds: bonusSeconds ?? this.bonusSeconds,
    itemsPresented: itemsPresented ?? this.itemsPresented,
    itemsCompleted: itemsCompleted ?? this.itemsCompleted,
    newWordsPresented: newWordsPresented ?? this.newWordsPresented,
    reviewsPresented: reviewsPresented ?? this.reviewsPresented,
    accuracyRate: accuracyRate.present ? accuracyRate.value : this.accuracyRate,
    avgResponseTimeMs: avgResponseTimeMs.present
        ? avgResponseTimeMs.value
        : this.avgResponseTimeMs,
    outcome: outcome ?? this.outcome,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isPendingSync: isPendingSync ?? this.isPendingSync,
  );
  LearningSession copyWithCompanion(LearningSessionsCompanion data) {
    return LearningSession(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      plannedMinutes: data.plannedMinutes.present
          ? data.plannedMinutes.value
          : this.plannedMinutes,
      elapsedSeconds: data.elapsedSeconds.present
          ? data.elapsedSeconds.value
          : this.elapsedSeconds,
      bonusSeconds: data.bonusSeconds.present
          ? data.bonusSeconds.value
          : this.bonusSeconds,
      itemsPresented: data.itemsPresented.present
          ? data.itemsPresented.value
          : this.itemsPresented,
      itemsCompleted: data.itemsCompleted.present
          ? data.itemsCompleted.value
          : this.itemsCompleted,
      newWordsPresented: data.newWordsPresented.present
          ? data.newWordsPresented.value
          : this.newWordsPresented,
      reviewsPresented: data.reviewsPresented.present
          ? data.reviewsPresented.value
          : this.reviewsPresented,
      accuracyRate: data.accuracyRate.present
          ? data.accuracyRate.value
          : this.accuracyRate,
      avgResponseTimeMs: data.avgResponseTimeMs.present
          ? data.avgResponseTimeMs.value
          : this.avgResponseTimeMs,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isPendingSync: data.isPendingSync.present
          ? data.isPendingSync.value
          : this.isPendingSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearningSession(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('startedAt: $startedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('plannedMinutes: $plannedMinutes, ')
          ..write('elapsedSeconds: $elapsedSeconds, ')
          ..write('bonusSeconds: $bonusSeconds, ')
          ..write('itemsPresented: $itemsPresented, ')
          ..write('itemsCompleted: $itemsCompleted, ')
          ..write('newWordsPresented: $newWordsPresented, ')
          ..write('reviewsPresented: $reviewsPresented, ')
          ..write('accuracyRate: $accuracyRate, ')
          ..write('avgResponseTimeMs: $avgResponseTimeMs, ')
          ..write('outcome: $outcome, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isPendingSync: $isPendingSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    startedAt,
    expiresAt,
    plannedMinutes,
    elapsedSeconds,
    bonusSeconds,
    itemsPresented,
    itemsCompleted,
    newWordsPresented,
    reviewsPresented,
    accuracyRate,
    avgResponseTimeMs,
    outcome,
    createdAt,
    updatedAt,
    isPendingSync,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearningSession &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.startedAt == this.startedAt &&
          other.expiresAt == this.expiresAt &&
          other.plannedMinutes == this.plannedMinutes &&
          other.elapsedSeconds == this.elapsedSeconds &&
          other.bonusSeconds == this.bonusSeconds &&
          other.itemsPresented == this.itemsPresented &&
          other.itemsCompleted == this.itemsCompleted &&
          other.newWordsPresented == this.newWordsPresented &&
          other.reviewsPresented == this.reviewsPresented &&
          other.accuracyRate == this.accuracyRate &&
          other.avgResponseTimeMs == this.avgResponseTimeMs &&
          other.outcome == this.outcome &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isPendingSync == this.isPendingSync);
}

class LearningSessionsCompanion extends UpdateCompanion<LearningSession> {
  final Value<String> id;
  final Value<String> userId;
  final Value<DateTime> startedAt;
  final Value<DateTime> expiresAt;
  final Value<int> plannedMinutes;
  final Value<int> elapsedSeconds;
  final Value<int> bonusSeconds;
  final Value<int> itemsPresented;
  final Value<int> itemsCompleted;
  final Value<int> newWordsPresented;
  final Value<int> reviewsPresented;
  final Value<double?> accuracyRate;
  final Value<int?> avgResponseTimeMs;
  final Value<int> outcome;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isPendingSync;
  final Value<int> rowid;
  const LearningSessionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.plannedMinutes = const Value.absent(),
    this.elapsedSeconds = const Value.absent(),
    this.bonusSeconds = const Value.absent(),
    this.itemsPresented = const Value.absent(),
    this.itemsCompleted = const Value.absent(),
    this.newWordsPresented = const Value.absent(),
    this.reviewsPresented = const Value.absent(),
    this.accuracyRate = const Value.absent(),
    this.avgResponseTimeMs = const Value.absent(),
    this.outcome = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isPendingSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LearningSessionsCompanion.insert({
    required String id,
    required String userId,
    required DateTime startedAt,
    required DateTime expiresAt,
    required int plannedMinutes,
    this.elapsedSeconds = const Value.absent(),
    this.bonusSeconds = const Value.absent(),
    this.itemsPresented = const Value.absent(),
    this.itemsCompleted = const Value.absent(),
    this.newWordsPresented = const Value.absent(),
    this.reviewsPresented = const Value.absent(),
    this.accuracyRate = const Value.absent(),
    this.avgResponseTimeMs = const Value.absent(),
    this.outcome = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.isPendingSync = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       startedAt = Value(startedAt),
       expiresAt = Value(expiresAt),
       plannedMinutes = Value(plannedMinutes),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LearningSession> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? expiresAt,
    Expression<int>? plannedMinutes,
    Expression<int>? elapsedSeconds,
    Expression<int>? bonusSeconds,
    Expression<int>? itemsPresented,
    Expression<int>? itemsCompleted,
    Expression<int>? newWordsPresented,
    Expression<int>? reviewsPresented,
    Expression<double>? accuracyRate,
    Expression<int>? avgResponseTimeMs,
    Expression<int>? outcome,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isPendingSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (startedAt != null) 'started_at': startedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (plannedMinutes != null) 'planned_minutes': plannedMinutes,
      if (elapsedSeconds != null) 'elapsed_seconds': elapsedSeconds,
      if (bonusSeconds != null) 'bonus_seconds': bonusSeconds,
      if (itemsPresented != null) 'items_presented': itemsPresented,
      if (itemsCompleted != null) 'items_completed': itemsCompleted,
      if (newWordsPresented != null) 'new_words_presented': newWordsPresented,
      if (reviewsPresented != null) 'reviews_presented': reviewsPresented,
      if (accuracyRate != null) 'accuracy_rate': accuracyRate,
      if (avgResponseTimeMs != null) 'avg_response_time_ms': avgResponseTimeMs,
      if (outcome != null) 'outcome': outcome,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isPendingSync != null) 'is_pending_sync': isPendingSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LearningSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<DateTime>? startedAt,
    Value<DateTime>? expiresAt,
    Value<int>? plannedMinutes,
    Value<int>? elapsedSeconds,
    Value<int>? bonusSeconds,
    Value<int>? itemsPresented,
    Value<int>? itemsCompleted,
    Value<int>? newWordsPresented,
    Value<int>? reviewsPresented,
    Value<double?>? accuracyRate,
    Value<int?>? avgResponseTimeMs,
    Value<int>? outcome,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? isPendingSync,
    Value<int>? rowid,
  }) {
    return LearningSessionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      bonusSeconds: bonusSeconds ?? this.bonusSeconds,
      itemsPresented: itemsPresented ?? this.itemsPresented,
      itemsCompleted: itemsCompleted ?? this.itemsCompleted,
      newWordsPresented: newWordsPresented ?? this.newWordsPresented,
      reviewsPresented: reviewsPresented ?? this.reviewsPresented,
      accuracyRate: accuracyRate ?? this.accuracyRate,
      avgResponseTimeMs: avgResponseTimeMs ?? this.avgResponseTimeMs,
      outcome: outcome ?? this.outcome,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPendingSync: isPendingSync ?? this.isPendingSync,
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
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (plannedMinutes.present) {
      map['planned_minutes'] = Variable<int>(plannedMinutes.value);
    }
    if (elapsedSeconds.present) {
      map['elapsed_seconds'] = Variable<int>(elapsedSeconds.value);
    }
    if (bonusSeconds.present) {
      map['bonus_seconds'] = Variable<int>(bonusSeconds.value);
    }
    if (itemsPresented.present) {
      map['items_presented'] = Variable<int>(itemsPresented.value);
    }
    if (itemsCompleted.present) {
      map['items_completed'] = Variable<int>(itemsCompleted.value);
    }
    if (newWordsPresented.present) {
      map['new_words_presented'] = Variable<int>(newWordsPresented.value);
    }
    if (reviewsPresented.present) {
      map['reviews_presented'] = Variable<int>(reviewsPresented.value);
    }
    if (accuracyRate.present) {
      map['accuracy_rate'] = Variable<double>(accuracyRate.value);
    }
    if (avgResponseTimeMs.present) {
      map['avg_response_time_ms'] = Variable<int>(avgResponseTimeMs.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<int>(outcome.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isPendingSync.present) {
      map['is_pending_sync'] = Variable<bool>(isPendingSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearningSessionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('startedAt: $startedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('plannedMinutes: $plannedMinutes, ')
          ..write('elapsedSeconds: $elapsedSeconds, ')
          ..write('bonusSeconds: $bonusSeconds, ')
          ..write('itemsPresented: $itemsPresented, ')
          ..write('itemsCompleted: $itemsCompleted, ')
          ..write('newWordsPresented: $newWordsPresented, ')
          ..write('reviewsPresented: $reviewsPresented, ')
          ..write('accuracyRate: $accuracyRate, ')
          ..write('avgResponseTimeMs: $avgResponseTimeMs, ')
          ..write('outcome: $outcome, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isPendingSync: $isPendingSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserLearningPreferencesTable extends UserLearningPreferences
    with TableInfo<$UserLearningPreferencesTable, UserLearningPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserLearningPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _dailyTimeTargetMinutesMeta =
      const VerificationMeta('dailyTimeTargetMinutes');
  @override
  late final GeneratedColumn<int> dailyTimeTargetMinutes = GeneratedColumn<int>(
    'daily_time_target_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(10),
  );
  static const VerificationMeta _targetRetentionMeta = const VerificationMeta(
    'targetRetention',
  );
  @override
  late final GeneratedColumn<double> targetRetention = GeneratedColumn<double>(
    'target_retention',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.90),
  );
  static const VerificationMeta _intensityMeta = const VerificationMeta(
    'intensity',
  );
  @override
  late final GeneratedColumn<int> intensity = GeneratedColumn<int>(
    'intensity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _newWordSuppressionActiveMeta =
      const VerificationMeta('newWordSuppressionActive');
  @override
  late final GeneratedColumn<bool> newWordSuppressionActive =
      GeneratedColumn<bool>(
        'new_word_suppression_active',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("new_word_suppression_active" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _nativeLanguageCodeMeta =
      const VerificationMeta('nativeLanguageCode');
  @override
  late final GeneratedColumn<String> nativeLanguageCode =
      GeneratedColumn<String>(
        'native_language_code',
        aliasedName,
        false,
        additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 5),
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('de'),
      );
  static const VerificationMeta _meaningDisplayModeMeta =
      const VerificationMeta('meaningDisplayMode');
  @override
  late final GeneratedColumn<String> meaningDisplayMode =
      GeneratedColumn<String>(
        'meaning_display_mode',
        aliasedName,
        false,
        additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 10),
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('both'),
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPendingSyncMeta = const VerificationMeta(
    'isPendingSync',
  );
  @override
  late final GeneratedColumn<bool> isPendingSync = GeneratedColumn<bool>(
    'is_pending_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pending_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    dailyTimeTargetMinutes,
    targetRetention,
    intensity,
    newWordSuppressionActive,
    nativeLanguageCode,
    meaningDisplayMode,
    createdAt,
    updatedAt,
    lastSyncedAt,
    isPendingSync,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_learning_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserLearningPreference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('daily_time_target_minutes')) {
      context.handle(
        _dailyTimeTargetMinutesMeta,
        dailyTimeTargetMinutes.isAcceptableOrUnknown(
          data['daily_time_target_minutes']!,
          _dailyTimeTargetMinutesMeta,
        ),
      );
    }
    if (data.containsKey('target_retention')) {
      context.handle(
        _targetRetentionMeta,
        targetRetention.isAcceptableOrUnknown(
          data['target_retention']!,
          _targetRetentionMeta,
        ),
      );
    }
    if (data.containsKey('intensity')) {
      context.handle(
        _intensityMeta,
        intensity.isAcceptableOrUnknown(data['intensity']!, _intensityMeta),
      );
    }
    if (data.containsKey('new_word_suppression_active')) {
      context.handle(
        _newWordSuppressionActiveMeta,
        newWordSuppressionActive.isAcceptableOrUnknown(
          data['new_word_suppression_active']!,
          _newWordSuppressionActiveMeta,
        ),
      );
    }
    if (data.containsKey('native_language_code')) {
      context.handle(
        _nativeLanguageCodeMeta,
        nativeLanguageCode.isAcceptableOrUnknown(
          data['native_language_code']!,
          _nativeLanguageCodeMeta,
        ),
      );
    }
    if (data.containsKey('meaning_display_mode')) {
      context.handle(
        _meaningDisplayModeMeta,
        meaningDisplayMode.isAcceptableOrUnknown(
          data['meaning_display_mode']!,
          _meaningDisplayModeMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_pending_sync')) {
      context.handle(
        _isPendingSyncMeta,
        isPendingSync.isAcceptableOrUnknown(
          data['is_pending_sync']!,
          _isPendingSyncMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserLearningPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserLearningPreference(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      dailyTimeTargetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_time_target_minutes'],
      )!,
      targetRetention: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_retention'],
      )!,
      intensity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}intensity'],
      )!,
      newWordSuppressionActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}new_word_suppression_active'],
      )!,
      nativeLanguageCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}native_language_code'],
      )!,
      meaningDisplayMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meaning_display_mode'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      isPendingSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pending_sync'],
      )!,
    );
  }

  @override
  $UserLearningPreferencesTable createAlias(String alias) {
    return $UserLearningPreferencesTable(attachedDatabase, alias);
  }
}

class UserLearningPreference extends DataClass
    implements Insertable<UserLearningPreference> {
  final String id;
  final String userId;
  final int dailyTimeTargetMinutes;
  final double targetRetention;
  final int intensity;
  final bool newWordSuppressionActive;
  final String nativeLanguageCode;
  final String meaningDisplayMode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncedAt;
  final bool isPendingSync;
  const UserLearningPreference({
    required this.id,
    required this.userId,
    required this.dailyTimeTargetMinutes,
    required this.targetRetention,
    required this.intensity,
    required this.newWordSuppressionActive,
    required this.nativeLanguageCode,
    required this.meaningDisplayMode,
    required this.createdAt,
    required this.updatedAt,
    this.lastSyncedAt,
    required this.isPendingSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['daily_time_target_minutes'] = Variable<int>(dailyTimeTargetMinutes);
    map['target_retention'] = Variable<double>(targetRetention);
    map['intensity'] = Variable<int>(intensity);
    map['new_word_suppression_active'] = Variable<bool>(
      newWordSuppressionActive,
    );
    map['native_language_code'] = Variable<String>(nativeLanguageCode);
    map['meaning_display_mode'] = Variable<String>(meaningDisplayMode);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['is_pending_sync'] = Variable<bool>(isPendingSync);
    return map;
  }

  UserLearningPreferencesCompanion toCompanion(bool nullToAbsent) {
    return UserLearningPreferencesCompanion(
      id: Value(id),
      userId: Value(userId),
      dailyTimeTargetMinutes: Value(dailyTimeTargetMinutes),
      targetRetention: Value(targetRetention),
      intensity: Value(intensity),
      newWordSuppressionActive: Value(newWordSuppressionActive),
      nativeLanguageCode: Value(nativeLanguageCode),
      meaningDisplayMode: Value(meaningDisplayMode),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      isPendingSync: Value(isPendingSync),
    );
  }

  factory UserLearningPreference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserLearningPreference(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      dailyTimeTargetMinutes: serializer.fromJson<int>(
        json['dailyTimeTargetMinutes'],
      ),
      targetRetention: serializer.fromJson<double>(json['targetRetention']),
      intensity: serializer.fromJson<int>(json['intensity']),
      newWordSuppressionActive: serializer.fromJson<bool>(
        json['newWordSuppressionActive'],
      ),
      nativeLanguageCode: serializer.fromJson<String>(
        json['nativeLanguageCode'],
      ),
      meaningDisplayMode: serializer.fromJson<String>(
        json['meaningDisplayMode'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      isPendingSync: serializer.fromJson<bool>(json['isPendingSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'dailyTimeTargetMinutes': serializer.toJson<int>(dailyTimeTargetMinutes),
      'targetRetention': serializer.toJson<double>(targetRetention),
      'intensity': serializer.toJson<int>(intensity),
      'newWordSuppressionActive': serializer.toJson<bool>(
        newWordSuppressionActive,
      ),
      'nativeLanguageCode': serializer.toJson<String>(nativeLanguageCode),
      'meaningDisplayMode': serializer.toJson<String>(meaningDisplayMode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'isPendingSync': serializer.toJson<bool>(isPendingSync),
    };
  }

  UserLearningPreference copyWith({
    String? id,
    String? userId,
    int? dailyTimeTargetMinutes,
    double? targetRetention,
    int? intensity,
    bool? newWordSuppressionActive,
    String? nativeLanguageCode,
    String? meaningDisplayMode,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    bool? isPendingSync,
  }) => UserLearningPreference(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    dailyTimeTargetMinutes:
        dailyTimeTargetMinutes ?? this.dailyTimeTargetMinutes,
    targetRetention: targetRetention ?? this.targetRetention,
    intensity: intensity ?? this.intensity,
    newWordSuppressionActive:
        newWordSuppressionActive ?? this.newWordSuppressionActive,
    nativeLanguageCode: nativeLanguageCode ?? this.nativeLanguageCode,
    meaningDisplayMode: meaningDisplayMode ?? this.meaningDisplayMode,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    isPendingSync: isPendingSync ?? this.isPendingSync,
  );
  UserLearningPreference copyWithCompanion(
    UserLearningPreferencesCompanion data,
  ) {
    return UserLearningPreference(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      dailyTimeTargetMinutes: data.dailyTimeTargetMinutes.present
          ? data.dailyTimeTargetMinutes.value
          : this.dailyTimeTargetMinutes,
      targetRetention: data.targetRetention.present
          ? data.targetRetention.value
          : this.targetRetention,
      intensity: data.intensity.present ? data.intensity.value : this.intensity,
      newWordSuppressionActive: data.newWordSuppressionActive.present
          ? data.newWordSuppressionActive.value
          : this.newWordSuppressionActive,
      nativeLanguageCode: data.nativeLanguageCode.present
          ? data.nativeLanguageCode.value
          : this.nativeLanguageCode,
      meaningDisplayMode: data.meaningDisplayMode.present
          ? data.meaningDisplayMode.value
          : this.meaningDisplayMode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      isPendingSync: data.isPendingSync.present
          ? data.isPendingSync.value
          : this.isPendingSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserLearningPreference(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('dailyTimeTargetMinutes: $dailyTimeTargetMinutes, ')
          ..write('targetRetention: $targetRetention, ')
          ..write('intensity: $intensity, ')
          ..write('newWordSuppressionActive: $newWordSuppressionActive, ')
          ..write('nativeLanguageCode: $nativeLanguageCode, ')
          ..write('meaningDisplayMode: $meaningDisplayMode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('isPendingSync: $isPendingSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    dailyTimeTargetMinutes,
    targetRetention,
    intensity,
    newWordSuppressionActive,
    nativeLanguageCode,
    meaningDisplayMode,
    createdAt,
    updatedAt,
    lastSyncedAt,
    isPendingSync,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserLearningPreference &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.dailyTimeTargetMinutes == this.dailyTimeTargetMinutes &&
          other.targetRetention == this.targetRetention &&
          other.intensity == this.intensity &&
          other.newWordSuppressionActive == this.newWordSuppressionActive &&
          other.nativeLanguageCode == this.nativeLanguageCode &&
          other.meaningDisplayMode == this.meaningDisplayMode &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.isPendingSync == this.isPendingSync);
}

class UserLearningPreferencesCompanion
    extends UpdateCompanion<UserLearningPreference> {
  final Value<String> id;
  final Value<String> userId;
  final Value<int> dailyTimeTargetMinutes;
  final Value<double> targetRetention;
  final Value<int> intensity;
  final Value<bool> newWordSuppressionActive;
  final Value<String> nativeLanguageCode;
  final Value<String> meaningDisplayMode;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<bool> isPendingSync;
  final Value<int> rowid;
  const UserLearningPreferencesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.dailyTimeTargetMinutes = const Value.absent(),
    this.targetRetention = const Value.absent(),
    this.intensity = const Value.absent(),
    this.newWordSuppressionActive = const Value.absent(),
    this.nativeLanguageCode = const Value.absent(),
    this.meaningDisplayMode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.isPendingSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserLearningPreferencesCompanion.insert({
    required String id,
    required String userId,
    this.dailyTimeTargetMinutes = const Value.absent(),
    this.targetRetention = const Value.absent(),
    this.intensity = const Value.absent(),
    this.newWordSuppressionActive = const Value.absent(),
    this.nativeLanguageCode = const Value.absent(),
    this.meaningDisplayMode = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.lastSyncedAt = const Value.absent(),
    this.isPendingSync = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<UserLearningPreference> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<int>? dailyTimeTargetMinutes,
    Expression<double>? targetRetention,
    Expression<int>? intensity,
    Expression<bool>? newWordSuppressionActive,
    Expression<String>? nativeLanguageCode,
    Expression<String>? meaningDisplayMode,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<bool>? isPendingSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (dailyTimeTargetMinutes != null)
        'daily_time_target_minutes': dailyTimeTargetMinutes,
      if (targetRetention != null) 'target_retention': targetRetention,
      if (intensity != null) 'intensity': intensity,
      if (newWordSuppressionActive != null)
        'new_word_suppression_active': newWordSuppressionActive,
      if (nativeLanguageCode != null)
        'native_language_code': nativeLanguageCode,
      if (meaningDisplayMode != null)
        'meaning_display_mode': meaningDisplayMode,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (isPendingSync != null) 'is_pending_sync': isPendingSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserLearningPreferencesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<int>? dailyTimeTargetMinutes,
    Value<double>? targetRetention,
    Value<int>? intensity,
    Value<bool>? newWordSuppressionActive,
    Value<String>? nativeLanguageCode,
    Value<String>? meaningDisplayMode,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<bool>? isPendingSync,
    Value<int>? rowid,
  }) {
    return UserLearningPreferencesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dailyTimeTargetMinutes:
          dailyTimeTargetMinutes ?? this.dailyTimeTargetMinutes,
      targetRetention: targetRetention ?? this.targetRetention,
      intensity: intensity ?? this.intensity,
      newWordSuppressionActive:
          newWordSuppressionActive ?? this.newWordSuppressionActive,
      nativeLanguageCode: nativeLanguageCode ?? this.nativeLanguageCode,
      meaningDisplayMode: meaningDisplayMode ?? this.meaningDisplayMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isPendingSync: isPendingSync ?? this.isPendingSync,
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
    if (dailyTimeTargetMinutes.present) {
      map['daily_time_target_minutes'] = Variable<int>(
        dailyTimeTargetMinutes.value,
      );
    }
    if (targetRetention.present) {
      map['target_retention'] = Variable<double>(targetRetention.value);
    }
    if (intensity.present) {
      map['intensity'] = Variable<int>(intensity.value);
    }
    if (newWordSuppressionActive.present) {
      map['new_word_suppression_active'] = Variable<bool>(
        newWordSuppressionActive.value,
      );
    }
    if (nativeLanguageCode.present) {
      map['native_language_code'] = Variable<String>(nativeLanguageCode.value);
    }
    if (meaningDisplayMode.present) {
      map['meaning_display_mode'] = Variable<String>(meaningDisplayMode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (isPendingSync.present) {
      map['is_pending_sync'] = Variable<bool>(isPendingSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserLearningPreferencesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('dailyTimeTargetMinutes: $dailyTimeTargetMinutes, ')
          ..write('targetRetention: $targetRetention, ')
          ..write('intensity: $intensity, ')
          ..write('newWordSuppressionActive: $newWordSuppressionActive, ')
          ..write('nativeLanguageCode: $nativeLanguageCode, ')
          ..write('meaningDisplayMode: $meaningDisplayMode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('isPendingSync: $isPendingSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StreaksTable extends Streaks with TableInfo<$StreaksTable, Streak> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StreaksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _currentCountMeta = const VerificationMeta(
    'currentCount',
  );
  @override
  late final GeneratedColumn<int> currentCount = GeneratedColumn<int>(
    'current_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _longestCountMeta = const VerificationMeta(
    'longestCount',
  );
  @override
  late final GeneratedColumn<int> longestCount = GeneratedColumn<int>(
    'longest_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastCompletedDateMeta = const VerificationMeta(
    'lastCompletedDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastCompletedDate =
      GeneratedColumn<DateTime>(
        'last_completed_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPendingSyncMeta = const VerificationMeta(
    'isPendingSync',
  );
  @override
  late final GeneratedColumn<bool> isPendingSync = GeneratedColumn<bool>(
    'is_pending_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pending_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    currentCount,
    longestCount,
    lastCompletedDate,
    createdAt,
    updatedAt,
    lastSyncedAt,
    isPendingSync,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'streaks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Streak> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('current_count')) {
      context.handle(
        _currentCountMeta,
        currentCount.isAcceptableOrUnknown(
          data['current_count']!,
          _currentCountMeta,
        ),
      );
    }
    if (data.containsKey('longest_count')) {
      context.handle(
        _longestCountMeta,
        longestCount.isAcceptableOrUnknown(
          data['longest_count']!,
          _longestCountMeta,
        ),
      );
    }
    if (data.containsKey('last_completed_date')) {
      context.handle(
        _lastCompletedDateMeta,
        lastCompletedDate.isAcceptableOrUnknown(
          data['last_completed_date']!,
          _lastCompletedDateMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_pending_sync')) {
      context.handle(
        _isPendingSyncMeta,
        isPendingSync.isAcceptableOrUnknown(
          data['is_pending_sync']!,
          _isPendingSyncMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Streak map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Streak(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      currentCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_count'],
      )!,
      longestCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}longest_count'],
      )!,
      lastCompletedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_completed_date'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      isPendingSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pending_sync'],
      )!,
    );
  }

  @override
  $StreaksTable createAlias(String alias) {
    return $StreaksTable(attachedDatabase, alias);
  }
}

class Streak extends DataClass implements Insertable<Streak> {
  final String id;
  final String userId;
  final int currentCount;
  final int longestCount;
  final DateTime? lastCompletedDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncedAt;
  final bool isPendingSync;
  const Streak({
    required this.id,
    required this.userId,
    required this.currentCount,
    required this.longestCount,
    this.lastCompletedDate,
    required this.createdAt,
    required this.updatedAt,
    this.lastSyncedAt,
    required this.isPendingSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['current_count'] = Variable<int>(currentCount);
    map['longest_count'] = Variable<int>(longestCount);
    if (!nullToAbsent || lastCompletedDate != null) {
      map['last_completed_date'] = Variable<DateTime>(lastCompletedDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['is_pending_sync'] = Variable<bool>(isPendingSync);
    return map;
  }

  StreaksCompanion toCompanion(bool nullToAbsent) {
    return StreaksCompanion(
      id: Value(id),
      userId: Value(userId),
      currentCount: Value(currentCount),
      longestCount: Value(longestCount),
      lastCompletedDate: lastCompletedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCompletedDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      isPendingSync: Value(isPendingSync),
    );
  }

  factory Streak.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Streak(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      currentCount: serializer.fromJson<int>(json['currentCount']),
      longestCount: serializer.fromJson<int>(json['longestCount']),
      lastCompletedDate: serializer.fromJson<DateTime?>(
        json['lastCompletedDate'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      isPendingSync: serializer.fromJson<bool>(json['isPendingSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'currentCount': serializer.toJson<int>(currentCount),
      'longestCount': serializer.toJson<int>(longestCount),
      'lastCompletedDate': serializer.toJson<DateTime?>(lastCompletedDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'isPendingSync': serializer.toJson<bool>(isPendingSync),
    };
  }

  Streak copyWith({
    String? id,
    String? userId,
    int? currentCount,
    int? longestCount,
    Value<DateTime?> lastCompletedDate = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    bool? isPendingSync,
  }) => Streak(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    currentCount: currentCount ?? this.currentCount,
    longestCount: longestCount ?? this.longestCount,
    lastCompletedDate: lastCompletedDate.present
        ? lastCompletedDate.value
        : this.lastCompletedDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    isPendingSync: isPendingSync ?? this.isPendingSync,
  );
  Streak copyWithCompanion(StreaksCompanion data) {
    return Streak(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      currentCount: data.currentCount.present
          ? data.currentCount.value
          : this.currentCount,
      longestCount: data.longestCount.present
          ? data.longestCount.value
          : this.longestCount,
      lastCompletedDate: data.lastCompletedDate.present
          ? data.lastCompletedDate.value
          : this.lastCompletedDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      isPendingSync: data.isPendingSync.present
          ? data.isPendingSync.value
          : this.isPendingSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Streak(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('currentCount: $currentCount, ')
          ..write('longestCount: $longestCount, ')
          ..write('lastCompletedDate: $lastCompletedDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('isPendingSync: $isPendingSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    currentCount,
    longestCount,
    lastCompletedDate,
    createdAt,
    updatedAt,
    lastSyncedAt,
    isPendingSync,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Streak &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.currentCount == this.currentCount &&
          other.longestCount == this.longestCount &&
          other.lastCompletedDate == this.lastCompletedDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.isPendingSync == this.isPendingSync);
}

class StreaksCompanion extends UpdateCompanion<Streak> {
  final Value<String> id;
  final Value<String> userId;
  final Value<int> currentCount;
  final Value<int> longestCount;
  final Value<DateTime?> lastCompletedDate;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<bool> isPendingSync;
  final Value<int> rowid;
  const StreaksCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.currentCount = const Value.absent(),
    this.longestCount = const Value.absent(),
    this.lastCompletedDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.isPendingSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StreaksCompanion.insert({
    required String id,
    required String userId,
    this.currentCount = const Value.absent(),
    this.longestCount = const Value.absent(),
    this.lastCompletedDate = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.lastSyncedAt = const Value.absent(),
    this.isPendingSync = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Streak> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<int>? currentCount,
    Expression<int>? longestCount,
    Expression<DateTime>? lastCompletedDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<bool>? isPendingSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (currentCount != null) 'current_count': currentCount,
      if (longestCount != null) 'longest_count': longestCount,
      if (lastCompletedDate != null) 'last_completed_date': lastCompletedDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (isPendingSync != null) 'is_pending_sync': isPendingSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StreaksCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<int>? currentCount,
    Value<int>? longestCount,
    Value<DateTime?>? lastCompletedDate,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<bool>? isPendingSync,
    Value<int>? rowid,
  }) {
    return StreaksCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      currentCount: currentCount ?? this.currentCount,
      longestCount: longestCount ?? this.longestCount,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isPendingSync: isPendingSync ?? this.isPendingSync,
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
    if (currentCount.present) {
      map['current_count'] = Variable<int>(currentCount.value);
    }
    if (longestCount.present) {
      map['longest_count'] = Variable<int>(longestCount.value);
    }
    if (lastCompletedDate.present) {
      map['last_completed_date'] = Variable<DateTime>(lastCompletedDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (isPendingSync.present) {
      map['is_pending_sync'] = Variable<bool>(isPendingSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StreaksCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('currentCount: $currentCount, ')
          ..write('longestCount: $longestCount, ')
          ..write('lastCompletedDate: $lastCompletedDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('isPendingSync: $isPendingSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MeaningsTable extends Meanings with TableInfo<$MeaningsTable, Meaning> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeaningsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vocabularyIdMeta = const VerificationMeta(
    'vocabularyId',
  );
  @override
  late final GeneratedColumn<String> vocabularyId = GeneratedColumn<String>(
    'vocabulary_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageCodeMeta = const VerificationMeta(
    'languageCode',
  );
  @override
  late final GeneratedColumn<String> languageCode = GeneratedColumn<String>(
    'language_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 5),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _primaryTranslationMeta =
      const VerificationMeta('primaryTranslation');
  @override
  late final GeneratedColumn<String> primaryTranslation =
      GeneratedColumn<String>(
        'primary_translation',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _alternativeTranslationsMeta =
      const VerificationMeta('alternativeTranslations');
  @override
  late final GeneratedColumn<String> alternativeTranslations =
      GeneratedColumn<String>(
        'alternative_translations',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _englishDefinitionMeta = const VerificationMeta(
    'englishDefinition',
  );
  @override
  late final GeneratedColumn<String> englishDefinition =
      GeneratedColumn<String>(
        'english_definition',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _extendedDefinitionMeta =
      const VerificationMeta('extendedDefinition');
  @override
  late final GeneratedColumn<String> extendedDefinition =
      GeneratedColumn<String>(
        'extended_definition',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _partOfSpeechMeta = const VerificationMeta(
    'partOfSpeech',
  );
  @override
  late final GeneratedColumn<String> partOfSpeech = GeneratedColumn<String>(
    'part_of_speech',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _synonymsMeta = const VerificationMeta(
    'synonyms',
  );
  @override
  late final GeneratedColumn<String> synonyms = GeneratedColumn<String>(
    'synonyms',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ai'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPendingSyncMeta = const VerificationMeta(
    'isPendingSync',
  );
  @override
  late final GeneratedColumn<bool> isPendingSync = GeneratedColumn<bool>(
    'is_pending_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pending_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    vocabularyId,
    languageCode,
    primaryTranslation,
    alternativeTranslations,
    englishDefinition,
    extendedDefinition,
    partOfSpeech,
    synonyms,
    confidence,
    isPrimary,
    isActive,
    sortOrder,
    source,
    createdAt,
    updatedAt,
    deletedAt,
    lastSyncedAt,
    isPendingSync,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meanings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Meaning> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('vocabulary_id')) {
      context.handle(
        _vocabularyIdMeta,
        vocabularyId.isAcceptableOrUnknown(
          data['vocabulary_id']!,
          _vocabularyIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vocabularyIdMeta);
    }
    if (data.containsKey('language_code')) {
      context.handle(
        _languageCodeMeta,
        languageCode.isAcceptableOrUnknown(
          data['language_code']!,
          _languageCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_languageCodeMeta);
    }
    if (data.containsKey('primary_translation')) {
      context.handle(
        _primaryTranslationMeta,
        primaryTranslation.isAcceptableOrUnknown(
          data['primary_translation']!,
          _primaryTranslationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_primaryTranslationMeta);
    }
    if (data.containsKey('alternative_translations')) {
      context.handle(
        _alternativeTranslationsMeta,
        alternativeTranslations.isAcceptableOrUnknown(
          data['alternative_translations']!,
          _alternativeTranslationsMeta,
        ),
      );
    }
    if (data.containsKey('english_definition')) {
      context.handle(
        _englishDefinitionMeta,
        englishDefinition.isAcceptableOrUnknown(
          data['english_definition']!,
          _englishDefinitionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_englishDefinitionMeta);
    }
    if (data.containsKey('extended_definition')) {
      context.handle(
        _extendedDefinitionMeta,
        extendedDefinition.isAcceptableOrUnknown(
          data['extended_definition']!,
          _extendedDefinitionMeta,
        ),
      );
    }
    if (data.containsKey('part_of_speech')) {
      context.handle(
        _partOfSpeechMeta,
        partOfSpeech.isAcceptableOrUnknown(
          data['part_of_speech']!,
          _partOfSpeechMeta,
        ),
      );
    }
    if (data.containsKey('synonyms')) {
      context.handle(
        _synonymsMeta,
        synonyms.isAcceptableOrUnknown(data['synonyms']!, _synonymsMeta),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_pending_sync')) {
      context.handle(
        _isPendingSyncMeta,
        isPendingSync.isAcceptableOrUnknown(
          data['is_pending_sync']!,
          _isPendingSyncMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Meaning map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Meaning(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      vocabularyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vocabulary_id'],
      )!,
      languageCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_code'],
      )!,
      primaryTranslation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_translation'],
      )!,
      alternativeTranslations: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alternative_translations'],
      )!,
      englishDefinition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}english_definition'],
      )!,
      extendedDefinition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extended_definition'],
      ),
      partOfSpeech: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}part_of_speech'],
      ),
      synonyms: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}synonyms'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      )!,
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      isPendingSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pending_sync'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $MeaningsTable createAlias(String alias) {
    return $MeaningsTable(attachedDatabase, alias);
  }
}

class Meaning extends DataClass implements Insertable<Meaning> {
  final String id;
  final String userId;
  final String vocabularyId;
  final String languageCode;
  final String primaryTranslation;
  final String alternativeTranslations;
  final String englishDefinition;
  final String? extendedDefinition;
  final String? partOfSpeech;
  final String synonyms;
  final double confidence;
  final bool isPrimary;
  final bool isActive;
  final int sortOrder;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? lastSyncedAt;
  final bool isPendingSync;
  final int version;
  const Meaning({
    required this.id,
    required this.userId,
    required this.vocabularyId,
    required this.languageCode,
    required this.primaryTranslation,
    required this.alternativeTranslations,
    required this.englishDefinition,
    this.extendedDefinition,
    this.partOfSpeech,
    required this.synonyms,
    required this.confidence,
    required this.isPrimary,
    required this.isActive,
    required this.sortOrder,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.lastSyncedAt,
    required this.isPendingSync,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['vocabulary_id'] = Variable<String>(vocabularyId);
    map['language_code'] = Variable<String>(languageCode);
    map['primary_translation'] = Variable<String>(primaryTranslation);
    map['alternative_translations'] = Variable<String>(alternativeTranslations);
    map['english_definition'] = Variable<String>(englishDefinition);
    if (!nullToAbsent || extendedDefinition != null) {
      map['extended_definition'] = Variable<String>(extendedDefinition);
    }
    if (!nullToAbsent || partOfSpeech != null) {
      map['part_of_speech'] = Variable<String>(partOfSpeech);
    }
    map['synonyms'] = Variable<String>(synonyms);
    map['confidence'] = Variable<double>(confidence);
    map['is_primary'] = Variable<bool>(isPrimary);
    map['is_active'] = Variable<bool>(isActive);
    map['sort_order'] = Variable<int>(sortOrder);
    map['source'] = Variable<String>(source);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['is_pending_sync'] = Variable<bool>(isPendingSync);
    map['version'] = Variable<int>(version);
    return map;
  }

  MeaningsCompanion toCompanion(bool nullToAbsent) {
    return MeaningsCompanion(
      id: Value(id),
      userId: Value(userId),
      vocabularyId: Value(vocabularyId),
      languageCode: Value(languageCode),
      primaryTranslation: Value(primaryTranslation),
      alternativeTranslations: Value(alternativeTranslations),
      englishDefinition: Value(englishDefinition),
      extendedDefinition: extendedDefinition == null && nullToAbsent
          ? const Value.absent()
          : Value(extendedDefinition),
      partOfSpeech: partOfSpeech == null && nullToAbsent
          ? const Value.absent()
          : Value(partOfSpeech),
      synonyms: Value(synonyms),
      confidence: Value(confidence),
      isPrimary: Value(isPrimary),
      isActive: Value(isActive),
      sortOrder: Value(sortOrder),
      source: Value(source),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      isPendingSync: Value(isPendingSync),
      version: Value(version),
    );
  }

  factory Meaning.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Meaning(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      vocabularyId: serializer.fromJson<String>(json['vocabularyId']),
      languageCode: serializer.fromJson<String>(json['languageCode']),
      primaryTranslation: serializer.fromJson<String>(
        json['primaryTranslation'],
      ),
      alternativeTranslations: serializer.fromJson<String>(
        json['alternativeTranslations'],
      ),
      englishDefinition: serializer.fromJson<String>(json['englishDefinition']),
      extendedDefinition: serializer.fromJson<String?>(
        json['extendedDefinition'],
      ),
      partOfSpeech: serializer.fromJson<String?>(json['partOfSpeech']),
      synonyms: serializer.fromJson<String>(json['synonyms']),
      confidence: serializer.fromJson<double>(json['confidence']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      isPendingSync: serializer.fromJson<bool>(json['isPendingSync']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'vocabularyId': serializer.toJson<String>(vocabularyId),
      'languageCode': serializer.toJson<String>(languageCode),
      'primaryTranslation': serializer.toJson<String>(primaryTranslation),
      'alternativeTranslations': serializer.toJson<String>(
        alternativeTranslations,
      ),
      'englishDefinition': serializer.toJson<String>(englishDefinition),
      'extendedDefinition': serializer.toJson<String?>(extendedDefinition),
      'partOfSpeech': serializer.toJson<String?>(partOfSpeech),
      'synonyms': serializer.toJson<String>(synonyms),
      'confidence': serializer.toJson<double>(confidence),
      'isPrimary': serializer.toJson<bool>(isPrimary),
      'isActive': serializer.toJson<bool>(isActive),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'isPendingSync': serializer.toJson<bool>(isPendingSync),
      'version': serializer.toJson<int>(version),
    };
  }

  Meaning copyWith({
    String? id,
    String? userId,
    String? vocabularyId,
    String? languageCode,
    String? primaryTranslation,
    String? alternativeTranslations,
    String? englishDefinition,
    Value<String?> extendedDefinition = const Value.absent(),
    Value<String?> partOfSpeech = const Value.absent(),
    String? synonyms,
    double? confidence,
    bool? isPrimary,
    bool? isActive,
    int? sortOrder,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    bool? isPendingSync,
    int? version,
  }) => Meaning(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    vocabularyId: vocabularyId ?? this.vocabularyId,
    languageCode: languageCode ?? this.languageCode,
    primaryTranslation: primaryTranslation ?? this.primaryTranslation,
    alternativeTranslations:
        alternativeTranslations ?? this.alternativeTranslations,
    englishDefinition: englishDefinition ?? this.englishDefinition,
    extendedDefinition: extendedDefinition.present
        ? extendedDefinition.value
        : this.extendedDefinition,
    partOfSpeech: partOfSpeech.present ? partOfSpeech.value : this.partOfSpeech,
    synonyms: synonyms ?? this.synonyms,
    confidence: confidence ?? this.confidence,
    isPrimary: isPrimary ?? this.isPrimary,
    isActive: isActive ?? this.isActive,
    sortOrder: sortOrder ?? this.sortOrder,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    isPendingSync: isPendingSync ?? this.isPendingSync,
    version: version ?? this.version,
  );
  Meaning copyWithCompanion(MeaningsCompanion data) {
    return Meaning(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      vocabularyId: data.vocabularyId.present
          ? data.vocabularyId.value
          : this.vocabularyId,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
      primaryTranslation: data.primaryTranslation.present
          ? data.primaryTranslation.value
          : this.primaryTranslation,
      alternativeTranslations: data.alternativeTranslations.present
          ? data.alternativeTranslations.value
          : this.alternativeTranslations,
      englishDefinition: data.englishDefinition.present
          ? data.englishDefinition.value
          : this.englishDefinition,
      extendedDefinition: data.extendedDefinition.present
          ? data.extendedDefinition.value
          : this.extendedDefinition,
      partOfSpeech: data.partOfSpeech.present
          ? data.partOfSpeech.value
          : this.partOfSpeech,
      synonyms: data.synonyms.present ? data.synonyms.value : this.synonyms,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      isPendingSync: data.isPendingSync.present
          ? data.isPendingSync.value
          : this.isPendingSync,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Meaning(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('vocabularyId: $vocabularyId, ')
          ..write('languageCode: $languageCode, ')
          ..write('primaryTranslation: $primaryTranslation, ')
          ..write('alternativeTranslations: $alternativeTranslations, ')
          ..write('englishDefinition: $englishDefinition, ')
          ..write('extendedDefinition: $extendedDefinition, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('synonyms: $synonyms, ')
          ..write('confidence: $confidence, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('isActive: $isActive, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('isPendingSync: $isPendingSync, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    vocabularyId,
    languageCode,
    primaryTranslation,
    alternativeTranslations,
    englishDefinition,
    extendedDefinition,
    partOfSpeech,
    synonyms,
    confidence,
    isPrimary,
    isActive,
    sortOrder,
    source,
    createdAt,
    updatedAt,
    deletedAt,
    lastSyncedAt,
    isPendingSync,
    version,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Meaning &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.vocabularyId == this.vocabularyId &&
          other.languageCode == this.languageCode &&
          other.primaryTranslation == this.primaryTranslation &&
          other.alternativeTranslations == this.alternativeTranslations &&
          other.englishDefinition == this.englishDefinition &&
          other.extendedDefinition == this.extendedDefinition &&
          other.partOfSpeech == this.partOfSpeech &&
          other.synonyms == this.synonyms &&
          other.confidence == this.confidence &&
          other.isPrimary == this.isPrimary &&
          other.isActive == this.isActive &&
          other.sortOrder == this.sortOrder &&
          other.source == this.source &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.isPendingSync == this.isPendingSync &&
          other.version == this.version);
}

class MeaningsCompanion extends UpdateCompanion<Meaning> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> vocabularyId;
  final Value<String> languageCode;
  final Value<String> primaryTranslation;
  final Value<String> alternativeTranslations;
  final Value<String> englishDefinition;
  final Value<String?> extendedDefinition;
  final Value<String?> partOfSpeech;
  final Value<String> synonyms;
  final Value<double> confidence;
  final Value<bool> isPrimary;
  final Value<bool> isActive;
  final Value<int> sortOrder;
  final Value<String> source;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<bool> isPendingSync;
  final Value<int> version;
  final Value<int> rowid;
  const MeaningsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.vocabularyId = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.primaryTranslation = const Value.absent(),
    this.alternativeTranslations = const Value.absent(),
    this.englishDefinition = const Value.absent(),
    this.extendedDefinition = const Value.absent(),
    this.partOfSpeech = const Value.absent(),
    this.synonyms = const Value.absent(),
    this.confidence = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.isPendingSync = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MeaningsCompanion.insert({
    required String id,
    required String userId,
    required String vocabularyId,
    required String languageCode,
    required String primaryTranslation,
    this.alternativeTranslations = const Value.absent(),
    required String englishDefinition,
    this.extendedDefinition = const Value.absent(),
    this.partOfSpeech = const Value.absent(),
    this.synonyms = const Value.absent(),
    this.confidence = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.source = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.isPendingSync = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       vocabularyId = Value(vocabularyId),
       languageCode = Value(languageCode),
       primaryTranslation = Value(primaryTranslation),
       englishDefinition = Value(englishDefinition),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Meaning> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? vocabularyId,
    Expression<String>? languageCode,
    Expression<String>? primaryTranslation,
    Expression<String>? alternativeTranslations,
    Expression<String>? englishDefinition,
    Expression<String>? extendedDefinition,
    Expression<String>? partOfSpeech,
    Expression<String>? synonyms,
    Expression<double>? confidence,
    Expression<bool>? isPrimary,
    Expression<bool>? isActive,
    Expression<int>? sortOrder,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<bool>? isPendingSync,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (vocabularyId != null) 'vocabulary_id': vocabularyId,
      if (languageCode != null) 'language_code': languageCode,
      if (primaryTranslation != null) 'primary_translation': primaryTranslation,
      if (alternativeTranslations != null)
        'alternative_translations': alternativeTranslations,
      if (englishDefinition != null) 'english_definition': englishDefinition,
      if (extendedDefinition != null) 'extended_definition': extendedDefinition,
      if (partOfSpeech != null) 'part_of_speech': partOfSpeech,
      if (synonyms != null) 'synonyms': synonyms,
      if (confidence != null) 'confidence': confidence,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (isActive != null) 'is_active': isActive,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (isPendingSync != null) 'is_pending_sync': isPendingSync,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MeaningsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? vocabularyId,
    Value<String>? languageCode,
    Value<String>? primaryTranslation,
    Value<String>? alternativeTranslations,
    Value<String>? englishDefinition,
    Value<String?>? extendedDefinition,
    Value<String?>? partOfSpeech,
    Value<String>? synonyms,
    Value<double>? confidence,
    Value<bool>? isPrimary,
    Value<bool>? isActive,
    Value<int>? sortOrder,
    Value<String>? source,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<bool>? isPendingSync,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return MeaningsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vocabularyId: vocabularyId ?? this.vocabularyId,
      languageCode: languageCode ?? this.languageCode,
      primaryTranslation: primaryTranslation ?? this.primaryTranslation,
      alternativeTranslations:
          alternativeTranslations ?? this.alternativeTranslations,
      englishDefinition: englishDefinition ?? this.englishDefinition,
      extendedDefinition: extendedDefinition ?? this.extendedDefinition,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      synonyms: synonyms ?? this.synonyms,
      confidence: confidence ?? this.confidence,
      isPrimary: isPrimary ?? this.isPrimary,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isPendingSync: isPendingSync ?? this.isPendingSync,
      version: version ?? this.version,
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
    if (vocabularyId.present) {
      map['vocabulary_id'] = Variable<String>(vocabularyId.value);
    }
    if (languageCode.present) {
      map['language_code'] = Variable<String>(languageCode.value);
    }
    if (primaryTranslation.present) {
      map['primary_translation'] = Variable<String>(primaryTranslation.value);
    }
    if (alternativeTranslations.present) {
      map['alternative_translations'] = Variable<String>(
        alternativeTranslations.value,
      );
    }
    if (englishDefinition.present) {
      map['english_definition'] = Variable<String>(englishDefinition.value);
    }
    if (extendedDefinition.present) {
      map['extended_definition'] = Variable<String>(extendedDefinition.value);
    }
    if (partOfSpeech.present) {
      map['part_of_speech'] = Variable<String>(partOfSpeech.value);
    }
    if (synonyms.present) {
      map['synonyms'] = Variable<String>(synonyms.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (isPendingSync.present) {
      map['is_pending_sync'] = Variable<bool>(isPendingSync.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeaningsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('vocabularyId: $vocabularyId, ')
          ..write('languageCode: $languageCode, ')
          ..write('primaryTranslation: $primaryTranslation, ')
          ..write('alternativeTranslations: $alternativeTranslations, ')
          ..write('englishDefinition: $englishDefinition, ')
          ..write('extendedDefinition: $extendedDefinition, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('synonyms: $synonyms, ')
          ..write('confidence: $confidence, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('isActive: $isActive, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('isPendingSync: $isPendingSync, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CuesTable extends Cues with TableInfo<$CuesTable, Cue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meaningIdMeta = const VerificationMeta(
    'meaningId',
  );
  @override
  late final GeneratedColumn<String> meaningId = GeneratedColumn<String>(
    'meaning_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cueTypeMeta = const VerificationMeta(
    'cueType',
  );
  @override
  late final GeneratedColumn<String> cueType = GeneratedColumn<String>(
    'cue_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _promptTextMeta = const VerificationMeta(
    'promptText',
  );
  @override
  late final GeneratedColumn<String> promptText = GeneratedColumn<String>(
    'prompt_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answerTextMeta = const VerificationMeta(
    'answerText',
  );
  @override
  late final GeneratedColumn<String> answerText = GeneratedColumn<String>(
    'answer_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hintTextMeta = const VerificationMeta(
    'hintText',
  );
  @override
  late final GeneratedColumn<String> hintText = GeneratedColumn<String>(
    'hint_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPendingSyncMeta = const VerificationMeta(
    'isPendingSync',
  );
  @override
  late final GeneratedColumn<bool> isPendingSync = GeneratedColumn<bool>(
    'is_pending_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pending_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    meaningId,
    cueType,
    promptText,
    answerText,
    hintText,
    metadata,
    createdAt,
    updatedAt,
    deletedAt,
    lastSyncedAt,
    isPendingSync,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cues';
  @override
  VerificationContext validateIntegrity(
    Insertable<Cue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('meaning_id')) {
      context.handle(
        _meaningIdMeta,
        meaningId.isAcceptableOrUnknown(data['meaning_id']!, _meaningIdMeta),
      );
    } else if (isInserting) {
      context.missing(_meaningIdMeta);
    }
    if (data.containsKey('cue_type')) {
      context.handle(
        _cueTypeMeta,
        cueType.isAcceptableOrUnknown(data['cue_type']!, _cueTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_cueTypeMeta);
    }
    if (data.containsKey('prompt_text')) {
      context.handle(
        _promptTextMeta,
        promptText.isAcceptableOrUnknown(data['prompt_text']!, _promptTextMeta),
      );
    } else if (isInserting) {
      context.missing(_promptTextMeta);
    }
    if (data.containsKey('answer_text')) {
      context.handle(
        _answerTextMeta,
        answerText.isAcceptableOrUnknown(data['answer_text']!, _answerTextMeta),
      );
    } else if (isInserting) {
      context.missing(_answerTextMeta);
    }
    if (data.containsKey('hint_text')) {
      context.handle(
        _hintTextMeta,
        hintText.isAcceptableOrUnknown(data['hint_text']!, _hintTextMeta),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_pending_sync')) {
      context.handle(
        _isPendingSyncMeta,
        isPendingSync.isAcceptableOrUnknown(
          data['is_pending_sync']!,
          _isPendingSyncMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Cue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cue(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      meaningId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meaning_id'],
      )!,
      cueType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cue_type'],
      )!,
      promptText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt_text'],
      )!,
      answerText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_text'],
      )!,
      hintText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hint_text'],
      ),
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      isPendingSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pending_sync'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $CuesTable createAlias(String alias) {
    return $CuesTable(attachedDatabase, alias);
  }
}

class Cue extends DataClass implements Insertable<Cue> {
  final String id;
  final String userId;
  final String meaningId;
  final String cueType;
  final String promptText;
  final String answerText;
  final String? hintText;
  final String metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? lastSyncedAt;
  final bool isPendingSync;
  final int version;
  const Cue({
    required this.id,
    required this.userId,
    required this.meaningId,
    required this.cueType,
    required this.promptText,
    required this.answerText,
    this.hintText,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.lastSyncedAt,
    required this.isPendingSync,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['meaning_id'] = Variable<String>(meaningId);
    map['cue_type'] = Variable<String>(cueType);
    map['prompt_text'] = Variable<String>(promptText);
    map['answer_text'] = Variable<String>(answerText);
    if (!nullToAbsent || hintText != null) {
      map['hint_text'] = Variable<String>(hintText);
    }
    map['metadata'] = Variable<String>(metadata);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['is_pending_sync'] = Variable<bool>(isPendingSync);
    map['version'] = Variable<int>(version);
    return map;
  }

  CuesCompanion toCompanion(bool nullToAbsent) {
    return CuesCompanion(
      id: Value(id),
      userId: Value(userId),
      meaningId: Value(meaningId),
      cueType: Value(cueType),
      promptText: Value(promptText),
      answerText: Value(answerText),
      hintText: hintText == null && nullToAbsent
          ? const Value.absent()
          : Value(hintText),
      metadata: Value(metadata),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      isPendingSync: Value(isPendingSync),
      version: Value(version),
    );
  }

  factory Cue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cue(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      meaningId: serializer.fromJson<String>(json['meaningId']),
      cueType: serializer.fromJson<String>(json['cueType']),
      promptText: serializer.fromJson<String>(json['promptText']),
      answerText: serializer.fromJson<String>(json['answerText']),
      hintText: serializer.fromJson<String?>(json['hintText']),
      metadata: serializer.fromJson<String>(json['metadata']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      isPendingSync: serializer.fromJson<bool>(json['isPendingSync']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'meaningId': serializer.toJson<String>(meaningId),
      'cueType': serializer.toJson<String>(cueType),
      'promptText': serializer.toJson<String>(promptText),
      'answerText': serializer.toJson<String>(answerText),
      'hintText': serializer.toJson<String?>(hintText),
      'metadata': serializer.toJson<String>(metadata),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'isPendingSync': serializer.toJson<bool>(isPendingSync),
      'version': serializer.toJson<int>(version),
    };
  }

  Cue copyWith({
    String? id,
    String? userId,
    String? meaningId,
    String? cueType,
    String? promptText,
    String? answerText,
    Value<String?> hintText = const Value.absent(),
    String? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    bool? isPendingSync,
    int? version,
  }) => Cue(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    meaningId: meaningId ?? this.meaningId,
    cueType: cueType ?? this.cueType,
    promptText: promptText ?? this.promptText,
    answerText: answerText ?? this.answerText,
    hintText: hintText.present ? hintText.value : this.hintText,
    metadata: metadata ?? this.metadata,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    isPendingSync: isPendingSync ?? this.isPendingSync,
    version: version ?? this.version,
  );
  Cue copyWithCompanion(CuesCompanion data) {
    return Cue(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      meaningId: data.meaningId.present ? data.meaningId.value : this.meaningId,
      cueType: data.cueType.present ? data.cueType.value : this.cueType,
      promptText: data.promptText.present
          ? data.promptText.value
          : this.promptText,
      answerText: data.answerText.present
          ? data.answerText.value
          : this.answerText,
      hintText: data.hintText.present ? data.hintText.value : this.hintText,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      isPendingSync: data.isPendingSync.present
          ? data.isPendingSync.value
          : this.isPendingSync,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cue(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('meaningId: $meaningId, ')
          ..write('cueType: $cueType, ')
          ..write('promptText: $promptText, ')
          ..write('answerText: $answerText, ')
          ..write('hintText: $hintText, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('isPendingSync: $isPendingSync, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    meaningId,
    cueType,
    promptText,
    answerText,
    hintText,
    metadata,
    createdAt,
    updatedAt,
    deletedAt,
    lastSyncedAt,
    isPendingSync,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cue &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.meaningId == this.meaningId &&
          other.cueType == this.cueType &&
          other.promptText == this.promptText &&
          other.answerText == this.answerText &&
          other.hintText == this.hintText &&
          other.metadata == this.metadata &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.isPendingSync == this.isPendingSync &&
          other.version == this.version);
}

class CuesCompanion extends UpdateCompanion<Cue> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> meaningId;
  final Value<String> cueType;
  final Value<String> promptText;
  final Value<String> answerText;
  final Value<String?> hintText;
  final Value<String> metadata;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<bool> isPendingSync;
  final Value<int> version;
  final Value<int> rowid;
  const CuesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.meaningId = const Value.absent(),
    this.cueType = const Value.absent(),
    this.promptText = const Value.absent(),
    this.answerText = const Value.absent(),
    this.hintText = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.isPendingSync = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CuesCompanion.insert({
    required String id,
    required String userId,
    required String meaningId,
    required String cueType,
    required String promptText,
    required String answerText,
    this.hintText = const Value.absent(),
    this.metadata = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.isPendingSync = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       meaningId = Value(meaningId),
       cueType = Value(cueType),
       promptText = Value(promptText),
       answerText = Value(answerText),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Cue> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? meaningId,
    Expression<String>? cueType,
    Expression<String>? promptText,
    Expression<String>? answerText,
    Expression<String>? hintText,
    Expression<String>? metadata,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<bool>? isPendingSync,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (meaningId != null) 'meaning_id': meaningId,
      if (cueType != null) 'cue_type': cueType,
      if (promptText != null) 'prompt_text': promptText,
      if (answerText != null) 'answer_text': answerText,
      if (hintText != null) 'hint_text': hintText,
      if (metadata != null) 'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (isPendingSync != null) 'is_pending_sync': isPendingSync,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CuesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? meaningId,
    Value<String>? cueType,
    Value<String>? promptText,
    Value<String>? answerText,
    Value<String?>? hintText,
    Value<String>? metadata,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<bool>? isPendingSync,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return CuesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      meaningId: meaningId ?? this.meaningId,
      cueType: cueType ?? this.cueType,
      promptText: promptText ?? this.promptText,
      answerText: answerText ?? this.answerText,
      hintText: hintText ?? this.hintText,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isPendingSync: isPendingSync ?? this.isPendingSync,
      version: version ?? this.version,
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
    if (meaningId.present) {
      map['meaning_id'] = Variable<String>(meaningId.value);
    }
    if (cueType.present) {
      map['cue_type'] = Variable<String>(cueType.value);
    }
    if (promptText.present) {
      map['prompt_text'] = Variable<String>(promptText.value);
    }
    if (answerText.present) {
      map['answer_text'] = Variable<String>(answerText.value);
    }
    if (hintText.present) {
      map['hint_text'] = Variable<String>(hintText.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (isPendingSync.present) {
      map['is_pending_sync'] = Variable<bool>(isPendingSync.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CuesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('meaningId: $meaningId, ')
          ..write('cueType: $cueType, ')
          ..write('promptText: $promptText, ')
          ..write('answerText: $answerText, ')
          ..write('hintText: $hintText, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('isPendingSync: $isPendingSync, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConfusableSetsTable extends ConfusableSets
    with TableInfo<$ConfusableSetsTable, ConfusableSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConfusableSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageCodeMeta = const VerificationMeta(
    'languageCode',
  );
  @override
  late final GeneratedColumn<String> languageCode = GeneratedColumn<String>(
    'language_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 5),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordsMeta = const VerificationMeta('words');
  @override
  late final GeneratedColumn<String> words = GeneratedColumn<String>(
    'words',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _explanationsMeta = const VerificationMeta(
    'explanations',
  );
  @override
  late final GeneratedColumn<String> explanations = GeneratedColumn<String>(
    'explanations',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exampleSentencesMeta = const VerificationMeta(
    'exampleSentences',
  );
  @override
  late final GeneratedColumn<String> exampleSentences = GeneratedColumn<String>(
    'example_sentences',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPendingSyncMeta = const VerificationMeta(
    'isPendingSync',
  );
  @override
  late final GeneratedColumn<bool> isPendingSync = GeneratedColumn<bool>(
    'is_pending_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pending_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    languageCode,
    words,
    explanations,
    exampleSentences,
    createdAt,
    updatedAt,
    deletedAt,
    lastSyncedAt,
    isPendingSync,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'confusable_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConfusableSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('language_code')) {
      context.handle(
        _languageCodeMeta,
        languageCode.isAcceptableOrUnknown(
          data['language_code']!,
          _languageCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_languageCodeMeta);
    }
    if (data.containsKey('words')) {
      context.handle(
        _wordsMeta,
        words.isAcceptableOrUnknown(data['words']!, _wordsMeta),
      );
    } else if (isInserting) {
      context.missing(_wordsMeta);
    }
    if (data.containsKey('explanations')) {
      context.handle(
        _explanationsMeta,
        explanations.isAcceptableOrUnknown(
          data['explanations']!,
          _explanationsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_explanationsMeta);
    }
    if (data.containsKey('example_sentences')) {
      context.handle(
        _exampleSentencesMeta,
        exampleSentences.isAcceptableOrUnknown(
          data['example_sentences']!,
          _exampleSentencesMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_pending_sync')) {
      context.handle(
        _isPendingSyncMeta,
        isPendingSync.isAcceptableOrUnknown(
          data['is_pending_sync']!,
          _isPendingSyncMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConfusableSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConfusableSet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      languageCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_code'],
      )!,
      words: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}words'],
      )!,
      explanations: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanations'],
      )!,
      exampleSentences: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example_sentences'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      isPendingSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pending_sync'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $ConfusableSetsTable createAlias(String alias) {
    return $ConfusableSetsTable(attachedDatabase, alias);
  }
}

class ConfusableSet extends DataClass implements Insertable<ConfusableSet> {
  final String id;
  final String userId;
  final String languageCode;
  final String words;
  final String explanations;
  final String exampleSentences;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? lastSyncedAt;
  final bool isPendingSync;
  final int version;
  const ConfusableSet({
    required this.id,
    required this.userId,
    required this.languageCode,
    required this.words,
    required this.explanations,
    required this.exampleSentences,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.lastSyncedAt,
    required this.isPendingSync,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['language_code'] = Variable<String>(languageCode);
    map['words'] = Variable<String>(words);
    map['explanations'] = Variable<String>(explanations);
    map['example_sentences'] = Variable<String>(exampleSentences);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['is_pending_sync'] = Variable<bool>(isPendingSync);
    map['version'] = Variable<int>(version);
    return map;
  }

  ConfusableSetsCompanion toCompanion(bool nullToAbsent) {
    return ConfusableSetsCompanion(
      id: Value(id),
      userId: Value(userId),
      languageCode: Value(languageCode),
      words: Value(words),
      explanations: Value(explanations),
      exampleSentences: Value(exampleSentences),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      isPendingSync: Value(isPendingSync),
      version: Value(version),
    );
  }

  factory ConfusableSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConfusableSet(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      languageCode: serializer.fromJson<String>(json['languageCode']),
      words: serializer.fromJson<String>(json['words']),
      explanations: serializer.fromJson<String>(json['explanations']),
      exampleSentences: serializer.fromJson<String>(json['exampleSentences']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      isPendingSync: serializer.fromJson<bool>(json['isPendingSync']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'languageCode': serializer.toJson<String>(languageCode),
      'words': serializer.toJson<String>(words),
      'explanations': serializer.toJson<String>(explanations),
      'exampleSentences': serializer.toJson<String>(exampleSentences),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'isPendingSync': serializer.toJson<bool>(isPendingSync),
      'version': serializer.toJson<int>(version),
    };
  }

  ConfusableSet copyWith({
    String? id,
    String? userId,
    String? languageCode,
    String? words,
    String? explanations,
    String? exampleSentences,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    bool? isPendingSync,
    int? version,
  }) => ConfusableSet(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    languageCode: languageCode ?? this.languageCode,
    words: words ?? this.words,
    explanations: explanations ?? this.explanations,
    exampleSentences: exampleSentences ?? this.exampleSentences,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    isPendingSync: isPendingSync ?? this.isPendingSync,
    version: version ?? this.version,
  );
  ConfusableSet copyWithCompanion(ConfusableSetsCompanion data) {
    return ConfusableSet(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
      words: data.words.present ? data.words.value : this.words,
      explanations: data.explanations.present
          ? data.explanations.value
          : this.explanations,
      exampleSentences: data.exampleSentences.present
          ? data.exampleSentences.value
          : this.exampleSentences,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      isPendingSync: data.isPendingSync.present
          ? data.isPendingSync.value
          : this.isPendingSync,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConfusableSet(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('languageCode: $languageCode, ')
          ..write('words: $words, ')
          ..write('explanations: $explanations, ')
          ..write('exampleSentences: $exampleSentences, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('isPendingSync: $isPendingSync, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    languageCode,
    words,
    explanations,
    exampleSentences,
    createdAt,
    updatedAt,
    deletedAt,
    lastSyncedAt,
    isPendingSync,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConfusableSet &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.languageCode == this.languageCode &&
          other.words == this.words &&
          other.explanations == this.explanations &&
          other.exampleSentences == this.exampleSentences &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.isPendingSync == this.isPendingSync &&
          other.version == this.version);
}

class ConfusableSetsCompanion extends UpdateCompanion<ConfusableSet> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> languageCode;
  final Value<String> words;
  final Value<String> explanations;
  final Value<String> exampleSentences;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<bool> isPendingSync;
  final Value<int> version;
  final Value<int> rowid;
  const ConfusableSetsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.words = const Value.absent(),
    this.explanations = const Value.absent(),
    this.exampleSentences = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.isPendingSync = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConfusableSetsCompanion.insert({
    required String id,
    required String userId,
    required String languageCode,
    required String words,
    required String explanations,
    this.exampleSentences = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.isPendingSync = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       languageCode = Value(languageCode),
       words = Value(words),
       explanations = Value(explanations),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ConfusableSet> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? languageCode,
    Expression<String>? words,
    Expression<String>? explanations,
    Expression<String>? exampleSentences,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<bool>? isPendingSync,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (languageCode != null) 'language_code': languageCode,
      if (words != null) 'words': words,
      if (explanations != null) 'explanations': explanations,
      if (exampleSentences != null) 'example_sentences': exampleSentences,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (isPendingSync != null) 'is_pending_sync': isPendingSync,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConfusableSetsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? languageCode,
    Value<String>? words,
    Value<String>? explanations,
    Value<String>? exampleSentences,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<bool>? isPendingSync,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return ConfusableSetsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      languageCode: languageCode ?? this.languageCode,
      words: words ?? this.words,
      explanations: explanations ?? this.explanations,
      exampleSentences: exampleSentences ?? this.exampleSentences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isPendingSync: isPendingSync ?? this.isPendingSync,
      version: version ?? this.version,
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
    if (languageCode.present) {
      map['language_code'] = Variable<String>(languageCode.value);
    }
    if (words.present) {
      map['words'] = Variable<String>(words.value);
    }
    if (explanations.present) {
      map['explanations'] = Variable<String>(explanations.value);
    }
    if (exampleSentences.present) {
      map['example_sentences'] = Variable<String>(exampleSentences.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (isPendingSync.present) {
      map['is_pending_sync'] = Variable<bool>(isPendingSync.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConfusableSetsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('languageCode: $languageCode, ')
          ..write('words: $words, ')
          ..write('explanations: $explanations, ')
          ..write('exampleSentences: $exampleSentences, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('isPendingSync: $isPendingSync, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConfusableSetMembersTable extends ConfusableSetMembers
    with TableInfo<$ConfusableSetMembersTable, ConfusableSetMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConfusableSetMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confusableSetIdMeta = const VerificationMeta(
    'confusableSetId',
  );
  @override
  late final GeneratedColumn<String> confusableSetId = GeneratedColumn<String>(
    'confusable_set_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vocabularyIdMeta = const VerificationMeta(
    'vocabularyId',
  );
  @override
  late final GeneratedColumn<String> vocabularyId = GeneratedColumn<String>(
    'vocabulary_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    confusableSetId,
    vocabularyId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'confusable_set_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConfusableSetMember> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('confusable_set_id')) {
      context.handle(
        _confusableSetIdMeta,
        confusableSetId.isAcceptableOrUnknown(
          data['confusable_set_id']!,
          _confusableSetIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_confusableSetIdMeta);
    }
    if (data.containsKey('vocabulary_id')) {
      context.handle(
        _vocabularyIdMeta,
        vocabularyId.isAcceptableOrUnknown(
          data['vocabulary_id']!,
          _vocabularyIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vocabularyIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConfusableSetMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConfusableSetMember(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      confusableSetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confusable_set_id'],
      )!,
      vocabularyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vocabulary_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ConfusableSetMembersTable createAlias(String alias) {
    return $ConfusableSetMembersTable(attachedDatabase, alias);
  }
}

class ConfusableSetMember extends DataClass
    implements Insertable<ConfusableSetMember> {
  final String id;
  final String confusableSetId;
  final String vocabularyId;
  final DateTime createdAt;
  const ConfusableSetMember({
    required this.id,
    required this.confusableSetId,
    required this.vocabularyId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['confusable_set_id'] = Variable<String>(confusableSetId);
    map['vocabulary_id'] = Variable<String>(vocabularyId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ConfusableSetMembersCompanion toCompanion(bool nullToAbsent) {
    return ConfusableSetMembersCompanion(
      id: Value(id),
      confusableSetId: Value(confusableSetId),
      vocabularyId: Value(vocabularyId),
      createdAt: Value(createdAt),
    );
  }

  factory ConfusableSetMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConfusableSetMember(
      id: serializer.fromJson<String>(json['id']),
      confusableSetId: serializer.fromJson<String>(json['confusableSetId']),
      vocabularyId: serializer.fromJson<String>(json['vocabularyId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'confusableSetId': serializer.toJson<String>(confusableSetId),
      'vocabularyId': serializer.toJson<String>(vocabularyId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ConfusableSetMember copyWith({
    String? id,
    String? confusableSetId,
    String? vocabularyId,
    DateTime? createdAt,
  }) => ConfusableSetMember(
    id: id ?? this.id,
    confusableSetId: confusableSetId ?? this.confusableSetId,
    vocabularyId: vocabularyId ?? this.vocabularyId,
    createdAt: createdAt ?? this.createdAt,
  );
  ConfusableSetMember copyWithCompanion(ConfusableSetMembersCompanion data) {
    return ConfusableSetMember(
      id: data.id.present ? data.id.value : this.id,
      confusableSetId: data.confusableSetId.present
          ? data.confusableSetId.value
          : this.confusableSetId,
      vocabularyId: data.vocabularyId.present
          ? data.vocabularyId.value
          : this.vocabularyId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConfusableSetMember(')
          ..write('id: $id, ')
          ..write('confusableSetId: $confusableSetId, ')
          ..write('vocabularyId: $vocabularyId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, confusableSetId, vocabularyId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConfusableSetMember &&
          other.id == this.id &&
          other.confusableSetId == this.confusableSetId &&
          other.vocabularyId == this.vocabularyId &&
          other.createdAt == this.createdAt);
}

class ConfusableSetMembersCompanion
    extends UpdateCompanion<ConfusableSetMember> {
  final Value<String> id;
  final Value<String> confusableSetId;
  final Value<String> vocabularyId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ConfusableSetMembersCompanion({
    this.id = const Value.absent(),
    this.confusableSetId = const Value.absent(),
    this.vocabularyId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConfusableSetMembersCompanion.insert({
    required String id,
    required String confusableSetId,
    required String vocabularyId,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       confusableSetId = Value(confusableSetId),
       vocabularyId = Value(vocabularyId),
       createdAt = Value(createdAt);
  static Insertable<ConfusableSetMember> custom({
    Expression<String>? id,
    Expression<String>? confusableSetId,
    Expression<String>? vocabularyId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (confusableSetId != null) 'confusable_set_id': confusableSetId,
      if (vocabularyId != null) 'vocabulary_id': vocabularyId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConfusableSetMembersCompanion copyWith({
    Value<String>? id,
    Value<String>? confusableSetId,
    Value<String>? vocabularyId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ConfusableSetMembersCompanion(
      id: id ?? this.id,
      confusableSetId: confusableSetId ?? this.confusableSetId,
      vocabularyId: vocabularyId ?? this.vocabularyId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (confusableSetId.present) {
      map['confusable_set_id'] = Variable<String>(confusableSetId.value);
    }
    if (vocabularyId.present) {
      map['vocabulary_id'] = Variable<String>(vocabularyId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConfusableSetMembersCompanion(')
          ..write('id: $id, ')
          ..write('confusableSetId: $confusableSetId, ')
          ..write('vocabularyId: $vocabularyId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MeaningEditsTable extends MeaningEdits
    with TableInfo<$MeaningEditsTable, MeaningEdit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeaningEditsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meaningIdMeta = const VerificationMeta(
    'meaningId',
  );
  @override
  late final GeneratedColumn<String> meaningId = GeneratedColumn<String>(
    'meaning_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldNameMeta = const VerificationMeta(
    'fieldName',
  );
  @override
  late final GeneratedColumn<String> fieldName = GeneratedColumn<String>(
    'field_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalValueMeta = const VerificationMeta(
    'originalValue',
  );
  @override
  late final GeneratedColumn<String> originalValue = GeneratedColumn<String>(
    'original_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userValueMeta = const VerificationMeta(
    'userValue',
  );
  @override
  late final GeneratedColumn<String> userValue = GeneratedColumn<String>(
    'user_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    meaningId,
    fieldName,
    originalValue,
    userValue,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meaning_edits';
  @override
  VerificationContext validateIntegrity(
    Insertable<MeaningEdit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('meaning_id')) {
      context.handle(
        _meaningIdMeta,
        meaningId.isAcceptableOrUnknown(data['meaning_id']!, _meaningIdMeta),
      );
    } else if (isInserting) {
      context.missing(_meaningIdMeta);
    }
    if (data.containsKey('field_name')) {
      context.handle(
        _fieldNameMeta,
        fieldName.isAcceptableOrUnknown(data['field_name']!, _fieldNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldNameMeta);
    }
    if (data.containsKey('original_value')) {
      context.handle(
        _originalValueMeta,
        originalValue.isAcceptableOrUnknown(
          data['original_value']!,
          _originalValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalValueMeta);
    }
    if (data.containsKey('user_value')) {
      context.handle(
        _userValueMeta,
        userValue.isAcceptableOrUnknown(data['user_value']!, _userValueMeta),
      );
    } else if (isInserting) {
      context.missing(_userValueMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MeaningEdit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MeaningEdit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      meaningId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meaning_id'],
      )!,
      fieldName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_name'],
      )!,
      originalValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_value'],
      )!,
      userValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_value'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MeaningEditsTable createAlias(String alias) {
    return $MeaningEditsTable(attachedDatabase, alias);
  }
}

class MeaningEdit extends DataClass implements Insertable<MeaningEdit> {
  final String id;
  final String userId;
  final String meaningId;
  final String fieldName;
  final String originalValue;
  final String userValue;
  final DateTime createdAt;
  const MeaningEdit({
    required this.id,
    required this.userId,
    required this.meaningId,
    required this.fieldName,
    required this.originalValue,
    required this.userValue,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['meaning_id'] = Variable<String>(meaningId);
    map['field_name'] = Variable<String>(fieldName);
    map['original_value'] = Variable<String>(originalValue);
    map['user_value'] = Variable<String>(userValue);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MeaningEditsCompanion toCompanion(bool nullToAbsent) {
    return MeaningEditsCompanion(
      id: Value(id),
      userId: Value(userId),
      meaningId: Value(meaningId),
      fieldName: Value(fieldName),
      originalValue: Value(originalValue),
      userValue: Value(userValue),
      createdAt: Value(createdAt),
    );
  }

  factory MeaningEdit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MeaningEdit(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      meaningId: serializer.fromJson<String>(json['meaningId']),
      fieldName: serializer.fromJson<String>(json['fieldName']),
      originalValue: serializer.fromJson<String>(json['originalValue']),
      userValue: serializer.fromJson<String>(json['userValue']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'meaningId': serializer.toJson<String>(meaningId),
      'fieldName': serializer.toJson<String>(fieldName),
      'originalValue': serializer.toJson<String>(originalValue),
      'userValue': serializer.toJson<String>(userValue),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MeaningEdit copyWith({
    String? id,
    String? userId,
    String? meaningId,
    String? fieldName,
    String? originalValue,
    String? userValue,
    DateTime? createdAt,
  }) => MeaningEdit(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    meaningId: meaningId ?? this.meaningId,
    fieldName: fieldName ?? this.fieldName,
    originalValue: originalValue ?? this.originalValue,
    userValue: userValue ?? this.userValue,
    createdAt: createdAt ?? this.createdAt,
  );
  MeaningEdit copyWithCompanion(MeaningEditsCompanion data) {
    return MeaningEdit(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      meaningId: data.meaningId.present ? data.meaningId.value : this.meaningId,
      fieldName: data.fieldName.present ? data.fieldName.value : this.fieldName,
      originalValue: data.originalValue.present
          ? data.originalValue.value
          : this.originalValue,
      userValue: data.userValue.present ? data.userValue.value : this.userValue,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MeaningEdit(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('meaningId: $meaningId, ')
          ..write('fieldName: $fieldName, ')
          ..write('originalValue: $originalValue, ')
          ..write('userValue: $userValue, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    meaningId,
    fieldName,
    originalValue,
    userValue,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MeaningEdit &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.meaningId == this.meaningId &&
          other.fieldName == this.fieldName &&
          other.originalValue == this.originalValue &&
          other.userValue == this.userValue &&
          other.createdAt == this.createdAt);
}

class MeaningEditsCompanion extends UpdateCompanion<MeaningEdit> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> meaningId;
  final Value<String> fieldName;
  final Value<String> originalValue;
  final Value<String> userValue;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MeaningEditsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.meaningId = const Value.absent(),
    this.fieldName = const Value.absent(),
    this.originalValue = const Value.absent(),
    this.userValue = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MeaningEditsCompanion.insert({
    required String id,
    required String userId,
    required String meaningId,
    required String fieldName,
    required String originalValue,
    required String userValue,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       meaningId = Value(meaningId),
       fieldName = Value(fieldName),
       originalValue = Value(originalValue),
       userValue = Value(userValue),
       createdAt = Value(createdAt);
  static Insertable<MeaningEdit> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? meaningId,
    Expression<String>? fieldName,
    Expression<String>? originalValue,
    Expression<String>? userValue,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (meaningId != null) 'meaning_id': meaningId,
      if (fieldName != null) 'field_name': fieldName,
      if (originalValue != null) 'original_value': originalValue,
      if (userValue != null) 'user_value': userValue,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MeaningEditsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? meaningId,
    Value<String>? fieldName,
    Value<String>? originalValue,
    Value<String>? userValue,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MeaningEditsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      meaningId: meaningId ?? this.meaningId,
      fieldName: fieldName ?? this.fieldName,
      originalValue: originalValue ?? this.originalValue,
      userValue: userValue ?? this.userValue,
      createdAt: createdAt ?? this.createdAt,
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
    if (meaningId.present) {
      map['meaning_id'] = Variable<String>(meaningId.value);
    }
    if (fieldName.present) {
      map['field_name'] = Variable<String>(fieldName.value);
    }
    if (originalValue.present) {
      map['original_value'] = Variable<String>(originalValue.value);
    }
    if (userValue.present) {
      map['user_value'] = Variable<String>(userValue.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeaningEditsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('meaningId: $meaningId, ')
          ..write('fieldName: $fieldName, ')
          ..write('originalValue: $originalValue, ')
          ..write('userValue: $userValue, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LanguagesTable languages = $LanguagesTable(this);
  late final $SourcesTable sources = $SourcesTable(this);
  late final $EncountersTable encounters = $EncountersTable(this);
  late final $ImportSessionsTable importSessions = $ImportSessionsTable(this);
  late final $SyncOutboxTable syncOutbox = $SyncOutboxTable(this);
  late final $VocabularysTable vocabularys = $VocabularysTable(this);
  late final $LearningCardsTable learningCards = $LearningCardsTable(this);
  late final $ReviewLogsTable reviewLogs = $ReviewLogsTable(this);
  late final $LearningSessionsTable learningSessions = $LearningSessionsTable(
    this,
  );
  late final $UserLearningPreferencesTable userLearningPreferences =
      $UserLearningPreferencesTable(this);
  late final $StreaksTable streaks = $StreaksTable(this);
  late final $MeaningsTable meanings = $MeaningsTable(this);
  late final $CuesTable cues = $CuesTable(this);
  late final $ConfusableSetsTable confusableSets = $ConfusableSetsTable(this);
  late final $ConfusableSetMembersTable confusableSetMembers =
      $ConfusableSetMembersTable(this);
  late final $MeaningEditsTable meaningEdits = $MeaningEditsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    languages,
    sources,
    encounters,
    importSessions,
    syncOutbox,
    vocabularys,
    learningCards,
    reviewLogs,
    learningSessions,
    userLearningPreferences,
    streaks,
    meanings,
    cues,
    confusableSets,
    confusableSetMembers,
    meaningEdits,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$LanguagesTableCreateCompanionBuilder =
    LanguagesCompanion Function({
      required String id,
      required String code,
      required String name,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$LanguagesTableUpdateCompanionBuilder =
    LanguagesCompanion Function({
      Value<String> id,
      Value<String> code,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LanguagesTableFilterComposer
    extends Composer<_$AppDatabase, $LanguagesTable> {
  $$LanguagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LanguagesTableOrderingComposer
    extends Composer<_$AppDatabase, $LanguagesTable> {
  $$LanguagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LanguagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LanguagesTable> {
  $$LanguagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LanguagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LanguagesTable,
          Language,
          $$LanguagesTableFilterComposer,
          $$LanguagesTableOrderingComposer,
          $$LanguagesTableAnnotationComposer,
          $$LanguagesTableCreateCompanionBuilder,
          $$LanguagesTableUpdateCompanionBuilder,
          (Language, BaseReferences<_$AppDatabase, $LanguagesTable, Language>),
          Language,
          PrefetchHooks Function()
        > {
  $$LanguagesTableTableManager(_$AppDatabase db, $LanguagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LanguagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LanguagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LanguagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LanguagesCompanion(
                id: id,
                code: code,
                name: name,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String code,
                required String name,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LanguagesCompanion.insert(
                id: id,
                code: code,
                name: name,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LanguagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LanguagesTable,
      Language,
      $$LanguagesTableFilterComposer,
      $$LanguagesTableOrderingComposer,
      $$LanguagesTableAnnotationComposer,
      $$LanguagesTableCreateCompanionBuilder,
      $$LanguagesTableUpdateCompanionBuilder,
      (Language, BaseReferences<_$AppDatabase, $LanguagesTable, Language>),
      Language,
      PrefetchHooks Function()
    >;
typedef $$SourcesTableCreateCompanionBuilder =
    SourcesCompanion Function({
      required String id,
      required String userId,
      required String type,
      required String title,
      Value<String?> author,
      Value<String?> asin,
      Value<String?> url,
      Value<String?> domain,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<bool> isPendingSync,
      Value<int> version,
      Value<int> rowid,
    });
typedef $$SourcesTableUpdateCompanionBuilder =
    SourcesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> type,
      Value<String> title,
      Value<String?> author,
      Value<String?> asin,
      Value<String?> url,
      Value<String?> domain,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<bool> isPendingSync,
      Value<int> version,
      Value<int> rowid,
    });

class $$SourcesTableFilterComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get asin => $composableBuilder(
    column: $table.asin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get asin => $composableBuilder(
    column: $table.asin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get asin =>
      $composableBuilder(column: $table.asin, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$SourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SourcesTable,
          Source,
          $$SourcesTableFilterComposer,
          $$SourcesTableOrderingComposer,
          $$SourcesTableAnnotationComposer,
          $$SourcesTableCreateCompanionBuilder,
          $$SourcesTableUpdateCompanionBuilder,
          (Source, BaseReferences<_$AppDatabase, $SourcesTable, Source>),
          Source,
          PrefetchHooks Function()
        > {
  $$SourcesTableTableManager(_$AppDatabase db, $SourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> asin = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> domain = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<bool> isPendingSync = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourcesCompanion(
                id: id,
                userId: userId,
                type: type,
                title: title,
                author: author,
                asin: asin,
                url: url,
                domain: domain,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                isPendingSync: isPendingSync,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String type,
                required String title,
                Value<String?> author = const Value.absent(),
                Value<String?> asin = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> domain = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<bool> isPendingSync = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourcesCompanion.insert(
                id: id,
                userId: userId,
                type: type,
                title: title,
                author: author,
                asin: asin,
                url: url,
                domain: domain,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                isPendingSync: isPendingSync,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SourcesTable,
      Source,
      $$SourcesTableFilterComposer,
      $$SourcesTableOrderingComposer,
      $$SourcesTableAnnotationComposer,
      $$SourcesTableCreateCompanionBuilder,
      $$SourcesTableUpdateCompanionBuilder,
      (Source, BaseReferences<_$AppDatabase, $SourcesTable, Source>),
      Source,
      PrefetchHooks Function()
    >;
typedef $$EncountersTableCreateCompanionBuilder =
    EncountersCompanion Function({
      required String id,
      required String userId,
      required String vocabularyId,
      Value<String?> sourceId,
      Value<String?> context,
      Value<String?> locatorJson,
      Value<DateTime?> occurredAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<bool> isPendingSync,
      Value<int> version,
      Value<int> rowid,
    });
typedef $$EncountersTableUpdateCompanionBuilder =
    EncountersCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> vocabularyId,
      Value<String?> sourceId,
      Value<String?> context,
      Value<String?> locatorJson,
      Value<DateTime?> occurredAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<bool> isPendingSync,
      Value<int> version,
      Value<int> rowid,
    });

class $$EncountersTableFilterComposer
    extends Composer<_$AppDatabase, $EncountersTable> {
  $$EncountersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vocabularyId => $composableBuilder(
    column: $table.vocabularyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locatorJson => $composableBuilder(
    column: $table.locatorJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EncountersTableOrderingComposer
    extends Composer<_$AppDatabase, $EncountersTable> {
  $$EncountersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vocabularyId => $composableBuilder(
    column: $table.vocabularyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locatorJson => $composableBuilder(
    column: $table.locatorJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EncountersTableAnnotationComposer
    extends Composer<_$AppDatabase, $EncountersTable> {
  $$EncountersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get vocabularyId => $composableBuilder(
    column: $table.vocabularyId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get context =>
      $composableBuilder(column: $table.context, builder: (column) => column);

  GeneratedColumn<String> get locatorJson => $composableBuilder(
    column: $table.locatorJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$EncountersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EncountersTable,
          Encounter,
          $$EncountersTableFilterComposer,
          $$EncountersTableOrderingComposer,
          $$EncountersTableAnnotationComposer,
          $$EncountersTableCreateCompanionBuilder,
          $$EncountersTableUpdateCompanionBuilder,
          (
            Encounter,
            BaseReferences<_$AppDatabase, $EncountersTable, Encounter>,
          ),
          Encounter,
          PrefetchHooks Function()
        > {
  $$EncountersTableTableManager(_$AppDatabase db, $EncountersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EncountersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EncountersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EncountersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> vocabularyId = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String?> context = const Value.absent(),
                Value<String?> locatorJson = const Value.absent(),
                Value<DateTime?> occurredAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<bool> isPendingSync = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EncountersCompanion(
                id: id,
                userId: userId,
                vocabularyId: vocabularyId,
                sourceId: sourceId,
                context: context,
                locatorJson: locatorJson,
                occurredAt: occurredAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                isPendingSync: isPendingSync,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String vocabularyId,
                Value<String?> sourceId = const Value.absent(),
                Value<String?> context = const Value.absent(),
                Value<String?> locatorJson = const Value.absent(),
                Value<DateTime?> occurredAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<bool> isPendingSync = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EncountersCompanion.insert(
                id: id,
                userId: userId,
                vocabularyId: vocabularyId,
                sourceId: sourceId,
                context: context,
                locatorJson: locatorJson,
                occurredAt: occurredAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                isPendingSync: isPendingSync,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EncountersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EncountersTable,
      Encounter,
      $$EncountersTableFilterComposer,
      $$EncountersTableOrderingComposer,
      $$EncountersTableAnnotationComposer,
      $$EncountersTableCreateCompanionBuilder,
      $$EncountersTableUpdateCompanionBuilder,
      (Encounter, BaseReferences<_$AppDatabase, $EncountersTable, Encounter>),
      Encounter,
      PrefetchHooks Function()
    >;
typedef $$ImportSessionsTableCreateCompanionBuilder =
    ImportSessionsCompanion Function({
      required String id,
      required String userId,
      required String source,
      Value<String?> filename,
      Value<String?> deviceName,
      required int totalFound,
      required int imported,
      required int skipped,
      Value<int> errors,
      Value<String?> errorDetails,
      required DateTime startedAt,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });
typedef $$ImportSessionsTableUpdateCompanionBuilder =
    ImportSessionsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> source,
      Value<String?> filename,
      Value<String?> deviceName,
      Value<int> totalFound,
      Value<int> imported,
      Value<int> skipped,
      Value<int> errors,
      Value<String?> errorDetails,
      Value<DateTime> startedAt,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });

class $$ImportSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ImportSessionsTable> {
  $$ImportSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filename => $composableBuilder(
    column: $table.filename,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalFound => $composableBuilder(
    column: $table.totalFound,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get imported => $composableBuilder(
    column: $table.imported,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get skipped => $composableBuilder(
    column: $table.skipped,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get errors => $composableBuilder(
    column: $table.errors,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorDetails => $composableBuilder(
    column: $table.errorDetails,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImportSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportSessionsTable> {
  $$ImportSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filename => $composableBuilder(
    column: $table.filename,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalFound => $composableBuilder(
    column: $table.totalFound,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get imported => $composableBuilder(
    column: $table.imported,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get skipped => $composableBuilder(
    column: $table.skipped,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get errors => $composableBuilder(
    column: $table.errors,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorDetails => $composableBuilder(
    column: $table.errorDetails,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImportSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportSessionsTable> {
  $$ImportSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get filename =>
      $composableBuilder(column: $table.filename, builder: (column) => column);

  GeneratedColumn<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalFound => $composableBuilder(
    column: $table.totalFound,
    builder: (column) => column,
  );

  GeneratedColumn<int> get imported =>
      $composableBuilder(column: $table.imported, builder: (column) => column);

  GeneratedColumn<int> get skipped =>
      $composableBuilder(column: $table.skipped, builder: (column) => column);

  GeneratedColumn<int> get errors =>
      $composableBuilder(column: $table.errors, builder: (column) => column);

  GeneratedColumn<String> get errorDetails => $composableBuilder(
    column: $table.errorDetails,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$ImportSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportSessionsTable,
          ImportSession,
          $$ImportSessionsTableFilterComposer,
          $$ImportSessionsTableOrderingComposer,
          $$ImportSessionsTableAnnotationComposer,
          $$ImportSessionsTableCreateCompanionBuilder,
          $$ImportSessionsTableUpdateCompanionBuilder,
          (
            ImportSession,
            BaseReferences<_$AppDatabase, $ImportSessionsTable, ImportSession>,
          ),
          ImportSession,
          PrefetchHooks Function()
        > {
  $$ImportSessionsTableTableManager(
    _$AppDatabase db,
    $ImportSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> filename = const Value.absent(),
                Value<String?> deviceName = const Value.absent(),
                Value<int> totalFound = const Value.absent(),
                Value<int> imported = const Value.absent(),
                Value<int> skipped = const Value.absent(),
                Value<int> errors = const Value.absent(),
                Value<String?> errorDetails = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportSessionsCompanion(
                id: id,
                userId: userId,
                source: source,
                filename: filename,
                deviceName: deviceName,
                totalFound: totalFound,
                imported: imported,
                skipped: skipped,
                errors: errors,
                errorDetails: errorDetails,
                startedAt: startedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String source,
                Value<String?> filename = const Value.absent(),
                Value<String?> deviceName = const Value.absent(),
                required int totalFound,
                required int imported,
                required int skipped,
                Value<int> errors = const Value.absent(),
                Value<String?> errorDetails = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportSessionsCompanion.insert(
                id: id,
                userId: userId,
                source: source,
                filename: filename,
                deviceName: deviceName,
                totalFound: totalFound,
                imported: imported,
                skipped: skipped,
                errors: errors,
                errorDetails: errorDetails,
                startedAt: startedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImportSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportSessionsTable,
      ImportSession,
      $$ImportSessionsTableFilterComposer,
      $$ImportSessionsTableOrderingComposer,
      $$ImportSessionsTableAnnotationComposer,
      $$ImportSessionsTableCreateCompanionBuilder,
      $$ImportSessionsTableUpdateCompanionBuilder,
      (
        ImportSession,
        BaseReferences<_$AppDatabase, $ImportSessionsTable, ImportSession>,
      ),
      ImportSession,
      PrefetchHooks Function()
    >;
typedef $$SyncOutboxTableCreateCompanionBuilder =
    SyncOutboxCompanion Function({
      Value<int> id,
      required String entityTable,
      required String recordId,
      required String operation,
      required String payload,
      required DateTime createdAt,
      Value<int> retryCount,
      Value<String?> lastError,
    });
typedef $$SyncOutboxTableUpdateCompanionBuilder =
    SyncOutboxCompanion Function({
      Value<int> id,
      Value<String> entityTable,
      Value<String> recordId,
      Value<String> operation,
      Value<String> payload,
      Value<DateTime> createdAt,
      Value<int> retryCount,
      Value<String?> lastError,
    });

class $$SyncOutboxTableFilterComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityTable => $composableBuilder(
    column: $table.entityTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncOutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityTable => $composableBuilder(
    column: $table.entityTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncOutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityTable => $composableBuilder(
    column: $table.entityTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncOutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncOutboxTable,
          SyncOutboxData,
          $$SyncOutboxTableFilterComposer,
          $$SyncOutboxTableOrderingComposer,
          $$SyncOutboxTableAnnotationComposer,
          $$SyncOutboxTableCreateCompanionBuilder,
          $$SyncOutboxTableUpdateCompanionBuilder,
          (
            SyncOutboxData,
            BaseReferences<_$AppDatabase, $SyncOutboxTable, SyncOutboxData>,
          ),
          SyncOutboxData,
          PrefetchHooks Function()
        > {
  $$SyncOutboxTableTableManager(_$AppDatabase db, $SyncOutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entityTable = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => SyncOutboxCompanion(
                id: id,
                entityTable: entityTable,
                recordId: recordId,
                operation: operation,
                payload: payload,
                createdAt: createdAt,
                retryCount: retryCount,
                lastError: lastError,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entityTable,
                required String recordId,
                required String operation,
                required String payload,
                required DateTime createdAt,
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => SyncOutboxCompanion.insert(
                id: id,
                entityTable: entityTable,
                recordId: recordId,
                operation: operation,
                payload: payload,
                createdAt: createdAt,
                retryCount: retryCount,
                lastError: lastError,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncOutboxTable,
      SyncOutboxData,
      $$SyncOutboxTableFilterComposer,
      $$SyncOutboxTableOrderingComposer,
      $$SyncOutboxTableAnnotationComposer,
      $$SyncOutboxTableCreateCompanionBuilder,
      $$SyncOutboxTableUpdateCompanionBuilder,
      (
        SyncOutboxData,
        BaseReferences<_$AppDatabase, $SyncOutboxTable, SyncOutboxData>,
      ),
      SyncOutboxData,
      PrefetchHooks Function()
    >;
typedef $$VocabularysTableCreateCompanionBuilder =
    VocabularysCompanion Function({
      required String id,
      required String userId,
      required String word,
      Value<String?> stem,
      required String contentHash,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<bool> isPendingSync,
      Value<int> version,
      Value<int> rowid,
    });
typedef $$VocabularysTableUpdateCompanionBuilder =
    VocabularysCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> word,
      Value<String?> stem,
      Value<String> contentHash,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<bool> isPendingSync,
      Value<int> version,
      Value<int> rowid,
    });

class $$VocabularysTableFilterComposer
    extends Composer<_$AppDatabase, $VocabularysTable> {
  $$VocabularysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stem => $composableBuilder(
    column: $table.stem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VocabularysTableOrderingComposer
    extends Composer<_$AppDatabase, $VocabularysTable> {
  $$VocabularysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stem => $composableBuilder(
    column: $table.stem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VocabularysTableAnnotationComposer
    extends Composer<_$AppDatabase, $VocabularysTable> {
  $$VocabularysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get stem =>
      $composableBuilder(column: $table.stem, builder: (column) => column);

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$VocabularysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VocabularysTable,
          Vocabulary,
          $$VocabularysTableFilterComposer,
          $$VocabularysTableOrderingComposer,
          $$VocabularysTableAnnotationComposer,
          $$VocabularysTableCreateCompanionBuilder,
          $$VocabularysTableUpdateCompanionBuilder,
          (
            Vocabulary,
            BaseReferences<_$AppDatabase, $VocabularysTable, Vocabulary>,
          ),
          Vocabulary,
          PrefetchHooks Function()
        > {
  $$VocabularysTableTableManager(_$AppDatabase db, $VocabularysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VocabularysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VocabularysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VocabularysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<String?> stem = const Value.absent(),
                Value<String> contentHash = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<bool> isPendingSync = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VocabularysCompanion(
                id: id,
                userId: userId,
                word: word,
                stem: stem,
                contentHash: contentHash,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                isPendingSync: isPendingSync,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String word,
                Value<String?> stem = const Value.absent(),
                required String contentHash,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<bool> isPendingSync = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VocabularysCompanion.insert(
                id: id,
                userId: userId,
                word: word,
                stem: stem,
                contentHash: contentHash,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                isPendingSync: isPendingSync,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VocabularysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VocabularysTable,
      Vocabulary,
      $$VocabularysTableFilterComposer,
      $$VocabularysTableOrderingComposer,
      $$VocabularysTableAnnotationComposer,
      $$VocabularysTableCreateCompanionBuilder,
      $$VocabularysTableUpdateCompanionBuilder,
      (
        Vocabulary,
        BaseReferences<_$AppDatabase, $VocabularysTable, Vocabulary>,
      ),
      Vocabulary,
      PrefetchHooks Function()
    >;
typedef $$LearningCardsTableCreateCompanionBuilder =
    LearningCardsCompanion Function({
      required String id,
      required String userId,
      required String vocabularyId,
      Value<int> state,
      required DateTime due,
      Value<double> stability,
      Value<double> difficulty,
      Value<int> reps,
      Value<int> lapses,
      Value<DateTime?> lastReview,
      Value<bool> isLeech,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<bool> isPendingSync,
      Value<int> version,
      Value<int> rowid,
    });
typedef $$LearningCardsTableUpdateCompanionBuilder =
    LearningCardsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> vocabularyId,
      Value<int> state,
      Value<DateTime> due,
      Value<double> stability,
      Value<double> difficulty,
      Value<int> reps,
      Value<int> lapses,
      Value<DateTime?> lastReview,
      Value<bool> isLeech,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<bool> isPendingSync,
      Value<int> version,
      Value<int> rowid,
    });

class $$LearningCardsTableFilterComposer
    extends Composer<_$AppDatabase, $LearningCardsTable> {
  $$LearningCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vocabularyId => $composableBuilder(
    column: $table.vocabularyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLeech => $composableBuilder(
    column: $table.isLeech,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LearningCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $LearningCardsTable> {
  $$LearningCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vocabularyId => $composableBuilder(
    column: $table.vocabularyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLeech => $composableBuilder(
    column: $table.isLeech,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LearningCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LearningCardsTable> {
  $$LearningCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get vocabularyId => $composableBuilder(
    column: $table.vocabularyId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<DateTime> get due =>
      $composableBuilder(column: $table.due, builder: (column) => column);

  GeneratedColumn<double> get stability =>
      $composableBuilder(column: $table.stability, builder: (column) => column);

  GeneratedColumn<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isLeech =>
      $composableBuilder(column: $table.isLeech, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$LearningCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LearningCardsTable,
          LearningCard,
          $$LearningCardsTableFilterComposer,
          $$LearningCardsTableOrderingComposer,
          $$LearningCardsTableAnnotationComposer,
          $$LearningCardsTableCreateCompanionBuilder,
          $$LearningCardsTableUpdateCompanionBuilder,
          (
            LearningCard,
            BaseReferences<_$AppDatabase, $LearningCardsTable, LearningCard>,
          ),
          LearningCard,
          PrefetchHooks Function()
        > {
  $$LearningCardsTableTableManager(_$AppDatabase db, $LearningCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LearningCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LearningCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LearningCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> vocabularyId = const Value.absent(),
                Value<int> state = const Value.absent(),
                Value<DateTime> due = const Value.absent(),
                Value<double> stability = const Value.absent(),
                Value<double> difficulty = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<DateTime?> lastReview = const Value.absent(),
                Value<bool> isLeech = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<bool> isPendingSync = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LearningCardsCompanion(
                id: id,
                userId: userId,
                vocabularyId: vocabularyId,
                state: state,
                due: due,
                stability: stability,
                difficulty: difficulty,
                reps: reps,
                lapses: lapses,
                lastReview: lastReview,
                isLeech: isLeech,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                isPendingSync: isPendingSync,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String vocabularyId,
                Value<int> state = const Value.absent(),
                required DateTime due,
                Value<double> stability = const Value.absent(),
                Value<double> difficulty = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<DateTime?> lastReview = const Value.absent(),
                Value<bool> isLeech = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<bool> isPendingSync = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LearningCardsCompanion.insert(
                id: id,
                userId: userId,
                vocabularyId: vocabularyId,
                state: state,
                due: due,
                stability: stability,
                difficulty: difficulty,
                reps: reps,
                lapses: lapses,
                lastReview: lastReview,
                isLeech: isLeech,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                isPendingSync: isPendingSync,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LearningCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LearningCardsTable,
      LearningCard,
      $$LearningCardsTableFilterComposer,
      $$LearningCardsTableOrderingComposer,
      $$LearningCardsTableAnnotationComposer,
      $$LearningCardsTableCreateCompanionBuilder,
      $$LearningCardsTableUpdateCompanionBuilder,
      (
        LearningCard,
        BaseReferences<_$AppDatabase, $LearningCardsTable, LearningCard>,
      ),
      LearningCard,
      PrefetchHooks Function()
    >;
typedef $$ReviewLogsTableCreateCompanionBuilder =
    ReviewLogsCompanion Function({
      required String id,
      required String userId,
      required String learningCardId,
      required int rating,
      required int interactionMode,
      required int stateBefore,
      required int stateAfter,
      required double stabilityBefore,
      required double stabilityAfter,
      required double difficultyBefore,
      required double difficultyAfter,
      required int responseTimeMs,
      required double retrievabilityAtReview,
      required DateTime reviewedAt,
      Value<String?> sessionId,
      Value<String?> cueType,
      Value<bool> isPendingSync,
      Value<int> rowid,
    });
typedef $$ReviewLogsTableUpdateCompanionBuilder =
    ReviewLogsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> learningCardId,
      Value<int> rating,
      Value<int> interactionMode,
      Value<int> stateBefore,
      Value<int> stateAfter,
      Value<double> stabilityBefore,
      Value<double> stabilityAfter,
      Value<double> difficultyBefore,
      Value<double> difficultyAfter,
      Value<int> responseTimeMs,
      Value<double> retrievabilityAtReview,
      Value<DateTime> reviewedAt,
      Value<String?> sessionId,
      Value<String?> cueType,
      Value<bool> isPendingSync,
      Value<int> rowid,
    });

class $$ReviewLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get learningCardId => $composableBuilder(
    column: $table.learningCardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get interactionMode => $composableBuilder(
    column: $table.interactionMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stateBefore => $composableBuilder(
    column: $table.stateBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stateAfter => $composableBuilder(
    column: $table.stateAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stabilityBefore => $composableBuilder(
    column: $table.stabilityBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stabilityAfter => $composableBuilder(
    column: $table.stabilityAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get difficultyBefore => $composableBuilder(
    column: $table.difficultyBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get difficultyAfter => $composableBuilder(
    column: $table.difficultyAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get responseTimeMs => $composableBuilder(
    column: $table.responseTimeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get retrievabilityAtReview => $composableBuilder(
    column: $table.retrievabilityAtReview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cueType => $composableBuilder(
    column: $table.cueType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReviewLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get learningCardId => $composableBuilder(
    column: $table.learningCardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get interactionMode => $composableBuilder(
    column: $table.interactionMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stateBefore => $composableBuilder(
    column: $table.stateBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stateAfter => $composableBuilder(
    column: $table.stateAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stabilityBefore => $composableBuilder(
    column: $table.stabilityBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stabilityAfter => $composableBuilder(
    column: $table.stabilityAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get difficultyBefore => $composableBuilder(
    column: $table.difficultyBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get difficultyAfter => $composableBuilder(
    column: $table.difficultyAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get responseTimeMs => $composableBuilder(
    column: $table.responseTimeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get retrievabilityAtReview => $composableBuilder(
    column: $table.retrievabilityAtReview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cueType => $composableBuilder(
    column: $table.cueType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReviewLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get learningCardId => $composableBuilder(
    column: $table.learningCardId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get interactionMode => $composableBuilder(
    column: $table.interactionMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stateBefore => $composableBuilder(
    column: $table.stateBefore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stateAfter => $composableBuilder(
    column: $table.stateAfter,
    builder: (column) => column,
  );

  GeneratedColumn<double> get stabilityBefore => $composableBuilder(
    column: $table.stabilityBefore,
    builder: (column) => column,
  );

  GeneratedColumn<double> get stabilityAfter => $composableBuilder(
    column: $table.stabilityAfter,
    builder: (column) => column,
  );

  GeneratedColumn<double> get difficultyBefore => $composableBuilder(
    column: $table.difficultyBefore,
    builder: (column) => column,
  );

  GeneratedColumn<double> get difficultyAfter => $composableBuilder(
    column: $table.difficultyAfter,
    builder: (column) => column,
  );

  GeneratedColumn<int> get responseTimeMs => $composableBuilder(
    column: $table.responseTimeMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get retrievabilityAtReview => $composableBuilder(
    column: $table.retrievabilityAtReview,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get cueType =>
      $composableBuilder(column: $table.cueType, builder: (column) => column);

  GeneratedColumn<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => column,
  );
}

class $$ReviewLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewLogsTable,
          ReviewLog,
          $$ReviewLogsTableFilterComposer,
          $$ReviewLogsTableOrderingComposer,
          $$ReviewLogsTableAnnotationComposer,
          $$ReviewLogsTableCreateCompanionBuilder,
          $$ReviewLogsTableUpdateCompanionBuilder,
          (
            ReviewLog,
            BaseReferences<_$AppDatabase, $ReviewLogsTable, ReviewLog>,
          ),
          ReviewLog,
          PrefetchHooks Function()
        > {
  $$ReviewLogsTableTableManager(_$AppDatabase db, $ReviewLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> learningCardId = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<int> interactionMode = const Value.absent(),
                Value<int> stateBefore = const Value.absent(),
                Value<int> stateAfter = const Value.absent(),
                Value<double> stabilityBefore = const Value.absent(),
                Value<double> stabilityAfter = const Value.absent(),
                Value<double> difficultyBefore = const Value.absent(),
                Value<double> difficultyAfter = const Value.absent(),
                Value<int> responseTimeMs = const Value.absent(),
                Value<double> retrievabilityAtReview = const Value.absent(),
                Value<DateTime> reviewedAt = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                Value<String?> cueType = const Value.absent(),
                Value<bool> isPendingSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewLogsCompanion(
                id: id,
                userId: userId,
                learningCardId: learningCardId,
                rating: rating,
                interactionMode: interactionMode,
                stateBefore: stateBefore,
                stateAfter: stateAfter,
                stabilityBefore: stabilityBefore,
                stabilityAfter: stabilityAfter,
                difficultyBefore: difficultyBefore,
                difficultyAfter: difficultyAfter,
                responseTimeMs: responseTimeMs,
                retrievabilityAtReview: retrievabilityAtReview,
                reviewedAt: reviewedAt,
                sessionId: sessionId,
                cueType: cueType,
                isPendingSync: isPendingSync,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String learningCardId,
                required int rating,
                required int interactionMode,
                required int stateBefore,
                required int stateAfter,
                required double stabilityBefore,
                required double stabilityAfter,
                required double difficultyBefore,
                required double difficultyAfter,
                required int responseTimeMs,
                required double retrievabilityAtReview,
                required DateTime reviewedAt,
                Value<String?> sessionId = const Value.absent(),
                Value<String?> cueType = const Value.absent(),
                Value<bool> isPendingSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewLogsCompanion.insert(
                id: id,
                userId: userId,
                learningCardId: learningCardId,
                rating: rating,
                interactionMode: interactionMode,
                stateBefore: stateBefore,
                stateAfter: stateAfter,
                stabilityBefore: stabilityBefore,
                stabilityAfter: stabilityAfter,
                difficultyBefore: difficultyBefore,
                difficultyAfter: difficultyAfter,
                responseTimeMs: responseTimeMs,
                retrievabilityAtReview: retrievabilityAtReview,
                reviewedAt: reviewedAt,
                sessionId: sessionId,
                cueType: cueType,
                isPendingSync: isPendingSync,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReviewLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewLogsTable,
      ReviewLog,
      $$ReviewLogsTableFilterComposer,
      $$ReviewLogsTableOrderingComposer,
      $$ReviewLogsTableAnnotationComposer,
      $$ReviewLogsTableCreateCompanionBuilder,
      $$ReviewLogsTableUpdateCompanionBuilder,
      (ReviewLog, BaseReferences<_$AppDatabase, $ReviewLogsTable, ReviewLog>),
      ReviewLog,
      PrefetchHooks Function()
    >;
typedef $$LearningSessionsTableCreateCompanionBuilder =
    LearningSessionsCompanion Function({
      required String id,
      required String userId,
      required DateTime startedAt,
      required DateTime expiresAt,
      required int plannedMinutes,
      Value<int> elapsedSeconds,
      Value<int> bonusSeconds,
      Value<int> itemsPresented,
      Value<int> itemsCompleted,
      Value<int> newWordsPresented,
      Value<int> reviewsPresented,
      Value<double?> accuracyRate,
      Value<int?> avgResponseTimeMs,
      Value<int> outcome,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<bool> isPendingSync,
      Value<int> rowid,
    });
typedef $$LearningSessionsTableUpdateCompanionBuilder =
    LearningSessionsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<DateTime> startedAt,
      Value<DateTime> expiresAt,
      Value<int> plannedMinutes,
      Value<int> elapsedSeconds,
      Value<int> bonusSeconds,
      Value<int> itemsPresented,
      Value<int> itemsCompleted,
      Value<int> newWordsPresented,
      Value<int> reviewsPresented,
      Value<double?> accuracyRate,
      Value<int?> avgResponseTimeMs,
      Value<int> outcome,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> isPendingSync,
      Value<int> rowid,
    });

class $$LearningSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $LearningSessionsTable> {
  $$LearningSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedMinutes => $composableBuilder(
    column: $table.plannedMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elapsedSeconds => $composableBuilder(
    column: $table.elapsedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bonusSeconds => $composableBuilder(
    column: $table.bonusSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemsPresented => $composableBuilder(
    column: $table.itemsPresented,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemsCompleted => $composableBuilder(
    column: $table.itemsCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newWordsPresented => $composableBuilder(
    column: $table.newWordsPresented,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewsPresented => $composableBuilder(
    column: $table.reviewsPresented,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracyRate => $composableBuilder(
    column: $table.accuracyRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get avgResponseTimeMs => $composableBuilder(
    column: $table.avgResponseTimeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LearningSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LearningSessionsTable> {
  $$LearningSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedMinutes => $composableBuilder(
    column: $table.plannedMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elapsedSeconds => $composableBuilder(
    column: $table.elapsedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bonusSeconds => $composableBuilder(
    column: $table.bonusSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemsPresented => $composableBuilder(
    column: $table.itemsPresented,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemsCompleted => $composableBuilder(
    column: $table.itemsCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newWordsPresented => $composableBuilder(
    column: $table.newWordsPresented,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewsPresented => $composableBuilder(
    column: $table.reviewsPresented,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracyRate => $composableBuilder(
    column: $table.accuracyRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get avgResponseTimeMs => $composableBuilder(
    column: $table.avgResponseTimeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LearningSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LearningSessionsTable> {
  $$LearningSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<int> get plannedMinutes => $composableBuilder(
    column: $table.plannedMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get elapsedSeconds => $composableBuilder(
    column: $table.elapsedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bonusSeconds => $composableBuilder(
    column: $table.bonusSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get itemsPresented => $composableBuilder(
    column: $table.itemsPresented,
    builder: (column) => column,
  );

  GeneratedColumn<int> get itemsCompleted => $composableBuilder(
    column: $table.itemsCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get newWordsPresented => $composableBuilder(
    column: $table.newWordsPresented,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reviewsPresented => $composableBuilder(
    column: $table.reviewsPresented,
    builder: (column) => column,
  );

  GeneratedColumn<double> get accuracyRate => $composableBuilder(
    column: $table.accuracyRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get avgResponseTimeMs => $composableBuilder(
    column: $table.avgResponseTimeMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => column,
  );
}

class $$LearningSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LearningSessionsTable,
          LearningSession,
          $$LearningSessionsTableFilterComposer,
          $$LearningSessionsTableOrderingComposer,
          $$LearningSessionsTableAnnotationComposer,
          $$LearningSessionsTableCreateCompanionBuilder,
          $$LearningSessionsTableUpdateCompanionBuilder,
          (
            LearningSession,
            BaseReferences<
              _$AppDatabase,
              $LearningSessionsTable,
              LearningSession
            >,
          ),
          LearningSession,
          PrefetchHooks Function()
        > {
  $$LearningSessionsTableTableManager(
    _$AppDatabase db,
    $LearningSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LearningSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LearningSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LearningSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<int> plannedMinutes = const Value.absent(),
                Value<int> elapsedSeconds = const Value.absent(),
                Value<int> bonusSeconds = const Value.absent(),
                Value<int> itemsPresented = const Value.absent(),
                Value<int> itemsCompleted = const Value.absent(),
                Value<int> newWordsPresented = const Value.absent(),
                Value<int> reviewsPresented = const Value.absent(),
                Value<double?> accuracyRate = const Value.absent(),
                Value<int?> avgResponseTimeMs = const Value.absent(),
                Value<int> outcome = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isPendingSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LearningSessionsCompanion(
                id: id,
                userId: userId,
                startedAt: startedAt,
                expiresAt: expiresAt,
                plannedMinutes: plannedMinutes,
                elapsedSeconds: elapsedSeconds,
                bonusSeconds: bonusSeconds,
                itemsPresented: itemsPresented,
                itemsCompleted: itemsCompleted,
                newWordsPresented: newWordsPresented,
                reviewsPresented: reviewsPresented,
                accuracyRate: accuracyRate,
                avgResponseTimeMs: avgResponseTimeMs,
                outcome: outcome,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isPendingSync: isPendingSync,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required DateTime startedAt,
                required DateTime expiresAt,
                required int plannedMinutes,
                Value<int> elapsedSeconds = const Value.absent(),
                Value<int> bonusSeconds = const Value.absent(),
                Value<int> itemsPresented = const Value.absent(),
                Value<int> itemsCompleted = const Value.absent(),
                Value<int> newWordsPresented = const Value.absent(),
                Value<int> reviewsPresented = const Value.absent(),
                Value<double?> accuracyRate = const Value.absent(),
                Value<int?> avgResponseTimeMs = const Value.absent(),
                Value<int> outcome = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> isPendingSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LearningSessionsCompanion.insert(
                id: id,
                userId: userId,
                startedAt: startedAt,
                expiresAt: expiresAt,
                plannedMinutes: plannedMinutes,
                elapsedSeconds: elapsedSeconds,
                bonusSeconds: bonusSeconds,
                itemsPresented: itemsPresented,
                itemsCompleted: itemsCompleted,
                newWordsPresented: newWordsPresented,
                reviewsPresented: reviewsPresented,
                accuracyRate: accuracyRate,
                avgResponseTimeMs: avgResponseTimeMs,
                outcome: outcome,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isPendingSync: isPendingSync,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LearningSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LearningSessionsTable,
      LearningSession,
      $$LearningSessionsTableFilterComposer,
      $$LearningSessionsTableOrderingComposer,
      $$LearningSessionsTableAnnotationComposer,
      $$LearningSessionsTableCreateCompanionBuilder,
      $$LearningSessionsTableUpdateCompanionBuilder,
      (
        LearningSession,
        BaseReferences<_$AppDatabase, $LearningSessionsTable, LearningSession>,
      ),
      LearningSession,
      PrefetchHooks Function()
    >;
typedef $$UserLearningPreferencesTableCreateCompanionBuilder =
    UserLearningPreferencesCompanion Function({
      required String id,
      required String userId,
      Value<int> dailyTimeTargetMinutes,
      Value<double> targetRetention,
      Value<int> intensity,
      Value<bool> newWordSuppressionActive,
      Value<String> nativeLanguageCode,
      Value<String> meaningDisplayMode,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<bool> isPendingSync,
      Value<int> rowid,
    });
typedef $$UserLearningPreferencesTableUpdateCompanionBuilder =
    UserLearningPreferencesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<int> dailyTimeTargetMinutes,
      Value<double> targetRetention,
      Value<int> intensity,
      Value<bool> newWordSuppressionActive,
      Value<String> nativeLanguageCode,
      Value<String> meaningDisplayMode,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<bool> isPendingSync,
      Value<int> rowid,
    });

class $$UserLearningPreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $UserLearningPreferencesTable> {
  $$UserLearningPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyTimeTargetMinutes => $composableBuilder(
    column: $table.dailyTimeTargetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetRetention => $composableBuilder(
    column: $table.targetRetention,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intensity => $composableBuilder(
    column: $table.intensity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get newWordSuppressionActive => $composableBuilder(
    column: $table.newWordSuppressionActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nativeLanguageCode => $composableBuilder(
    column: $table.nativeLanguageCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaningDisplayMode => $composableBuilder(
    column: $table.meaningDisplayMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserLearningPreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserLearningPreferencesTable> {
  $$UserLearningPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyTimeTargetMinutes => $composableBuilder(
    column: $table.dailyTimeTargetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetRetention => $composableBuilder(
    column: $table.targetRetention,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intensity => $composableBuilder(
    column: $table.intensity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get newWordSuppressionActive => $composableBuilder(
    column: $table.newWordSuppressionActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nativeLanguageCode => $composableBuilder(
    column: $table.nativeLanguageCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaningDisplayMode => $composableBuilder(
    column: $table.meaningDisplayMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserLearningPreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserLearningPreferencesTable> {
  $$UserLearningPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get dailyTimeTargetMinutes => $composableBuilder(
    column: $table.dailyTimeTargetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetRetention => $composableBuilder(
    column: $table.targetRetention,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intensity =>
      $composableBuilder(column: $table.intensity, builder: (column) => column);

  GeneratedColumn<bool> get newWordSuppressionActive => $composableBuilder(
    column: $table.newWordSuppressionActive,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nativeLanguageCode => $composableBuilder(
    column: $table.nativeLanguageCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get meaningDisplayMode => $composableBuilder(
    column: $table.meaningDisplayMode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => column,
  );
}

class $$UserLearningPreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserLearningPreferencesTable,
          UserLearningPreference,
          $$UserLearningPreferencesTableFilterComposer,
          $$UserLearningPreferencesTableOrderingComposer,
          $$UserLearningPreferencesTableAnnotationComposer,
          $$UserLearningPreferencesTableCreateCompanionBuilder,
          $$UserLearningPreferencesTableUpdateCompanionBuilder,
          (
            UserLearningPreference,
            BaseReferences<
              _$AppDatabase,
              $UserLearningPreferencesTable,
              UserLearningPreference
            >,
          ),
          UserLearningPreference,
          PrefetchHooks Function()
        > {
  $$UserLearningPreferencesTableTableManager(
    _$AppDatabase db,
    $UserLearningPreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserLearningPreferencesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$UserLearningPreferencesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UserLearningPreferencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> dailyTimeTargetMinutes = const Value.absent(),
                Value<double> targetRetention = const Value.absent(),
                Value<int> intensity = const Value.absent(),
                Value<bool> newWordSuppressionActive = const Value.absent(),
                Value<String> nativeLanguageCode = const Value.absent(),
                Value<String> meaningDisplayMode = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<bool> isPendingSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserLearningPreferencesCompanion(
                id: id,
                userId: userId,
                dailyTimeTargetMinutes: dailyTimeTargetMinutes,
                targetRetention: targetRetention,
                intensity: intensity,
                newWordSuppressionActive: newWordSuppressionActive,
                nativeLanguageCode: nativeLanguageCode,
                meaningDisplayMode: meaningDisplayMode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastSyncedAt: lastSyncedAt,
                isPendingSync: isPendingSync,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                Value<int> dailyTimeTargetMinutes = const Value.absent(),
                Value<double> targetRetention = const Value.absent(),
                Value<int> intensity = const Value.absent(),
                Value<bool> newWordSuppressionActive = const Value.absent(),
                Value<String> nativeLanguageCode = const Value.absent(),
                Value<String> meaningDisplayMode = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<bool> isPendingSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserLearningPreferencesCompanion.insert(
                id: id,
                userId: userId,
                dailyTimeTargetMinutes: dailyTimeTargetMinutes,
                targetRetention: targetRetention,
                intensity: intensity,
                newWordSuppressionActive: newWordSuppressionActive,
                nativeLanguageCode: nativeLanguageCode,
                meaningDisplayMode: meaningDisplayMode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastSyncedAt: lastSyncedAt,
                isPendingSync: isPendingSync,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserLearningPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserLearningPreferencesTable,
      UserLearningPreference,
      $$UserLearningPreferencesTableFilterComposer,
      $$UserLearningPreferencesTableOrderingComposer,
      $$UserLearningPreferencesTableAnnotationComposer,
      $$UserLearningPreferencesTableCreateCompanionBuilder,
      $$UserLearningPreferencesTableUpdateCompanionBuilder,
      (
        UserLearningPreference,
        BaseReferences<
          _$AppDatabase,
          $UserLearningPreferencesTable,
          UserLearningPreference
        >,
      ),
      UserLearningPreference,
      PrefetchHooks Function()
    >;
typedef $$StreaksTableCreateCompanionBuilder =
    StreaksCompanion Function({
      required String id,
      required String userId,
      Value<int> currentCount,
      Value<int> longestCount,
      Value<DateTime?> lastCompletedDate,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<bool> isPendingSync,
      Value<int> rowid,
    });
typedef $$StreaksTableUpdateCompanionBuilder =
    StreaksCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<int> currentCount,
      Value<int> longestCount,
      Value<DateTime?> lastCompletedDate,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<bool> isPendingSync,
      Value<int> rowid,
    });

class $$StreaksTableFilterComposer
    extends Composer<_$AppDatabase, $StreaksTable> {
  $$StreaksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentCount => $composableBuilder(
    column: $table.currentCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get longestCount => $composableBuilder(
    column: $table.longestCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastCompletedDate => $composableBuilder(
    column: $table.lastCompletedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StreaksTableOrderingComposer
    extends Composer<_$AppDatabase, $StreaksTable> {
  $$StreaksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentCount => $composableBuilder(
    column: $table.currentCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get longestCount => $composableBuilder(
    column: $table.longestCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastCompletedDate => $composableBuilder(
    column: $table.lastCompletedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StreaksTableAnnotationComposer
    extends Composer<_$AppDatabase, $StreaksTable> {
  $$StreaksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get currentCount => $composableBuilder(
    column: $table.currentCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get longestCount => $composableBuilder(
    column: $table.longestCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastCompletedDate => $composableBuilder(
    column: $table.lastCompletedDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => column,
  );
}

class $$StreaksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StreaksTable,
          Streak,
          $$StreaksTableFilterComposer,
          $$StreaksTableOrderingComposer,
          $$StreaksTableAnnotationComposer,
          $$StreaksTableCreateCompanionBuilder,
          $$StreaksTableUpdateCompanionBuilder,
          (Streak, BaseReferences<_$AppDatabase, $StreaksTable, Streak>),
          Streak,
          PrefetchHooks Function()
        > {
  $$StreaksTableTableManager(_$AppDatabase db, $StreaksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StreaksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StreaksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StreaksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> currentCount = const Value.absent(),
                Value<int> longestCount = const Value.absent(),
                Value<DateTime?> lastCompletedDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<bool> isPendingSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StreaksCompanion(
                id: id,
                userId: userId,
                currentCount: currentCount,
                longestCount: longestCount,
                lastCompletedDate: lastCompletedDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastSyncedAt: lastSyncedAt,
                isPendingSync: isPendingSync,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                Value<int> currentCount = const Value.absent(),
                Value<int> longestCount = const Value.absent(),
                Value<DateTime?> lastCompletedDate = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<bool> isPendingSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StreaksCompanion.insert(
                id: id,
                userId: userId,
                currentCount: currentCount,
                longestCount: longestCount,
                lastCompletedDate: lastCompletedDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastSyncedAt: lastSyncedAt,
                isPendingSync: isPendingSync,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StreaksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StreaksTable,
      Streak,
      $$StreaksTableFilterComposer,
      $$StreaksTableOrderingComposer,
      $$StreaksTableAnnotationComposer,
      $$StreaksTableCreateCompanionBuilder,
      $$StreaksTableUpdateCompanionBuilder,
      (Streak, BaseReferences<_$AppDatabase, $StreaksTable, Streak>),
      Streak,
      PrefetchHooks Function()
    >;
typedef $$MeaningsTableCreateCompanionBuilder =
    MeaningsCompanion Function({
      required String id,
      required String userId,
      required String vocabularyId,
      required String languageCode,
      required String primaryTranslation,
      Value<String> alternativeTranslations,
      required String englishDefinition,
      Value<String?> extendedDefinition,
      Value<String?> partOfSpeech,
      Value<String> synonyms,
      Value<double> confidence,
      Value<bool> isPrimary,
      Value<bool> isActive,
      Value<int> sortOrder,
      Value<String> source,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<bool> isPendingSync,
      Value<int> version,
      Value<int> rowid,
    });
typedef $$MeaningsTableUpdateCompanionBuilder =
    MeaningsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> vocabularyId,
      Value<String> languageCode,
      Value<String> primaryTranslation,
      Value<String> alternativeTranslations,
      Value<String> englishDefinition,
      Value<String?> extendedDefinition,
      Value<String?> partOfSpeech,
      Value<String> synonyms,
      Value<double> confidence,
      Value<bool> isPrimary,
      Value<bool> isActive,
      Value<int> sortOrder,
      Value<String> source,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<bool> isPendingSync,
      Value<int> version,
      Value<int> rowid,
    });

class $$MeaningsTableFilterComposer
    extends Composer<_$AppDatabase, $MeaningsTable> {
  $$MeaningsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vocabularyId => $composableBuilder(
    column: $table.vocabularyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaryTranslation => $composableBuilder(
    column: $table.primaryTranslation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alternativeTranslations => $composableBuilder(
    column: $table.alternativeTranslations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get englishDefinition => $composableBuilder(
    column: $table.englishDefinition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extendedDefinition => $composableBuilder(
    column: $table.extendedDefinition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get synonyms => $composableBuilder(
    column: $table.synonyms,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MeaningsTableOrderingComposer
    extends Composer<_$AppDatabase, $MeaningsTable> {
  $$MeaningsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vocabularyId => $composableBuilder(
    column: $table.vocabularyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaryTranslation => $composableBuilder(
    column: $table.primaryTranslation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alternativeTranslations => $composableBuilder(
    column: $table.alternativeTranslations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get englishDefinition => $composableBuilder(
    column: $table.englishDefinition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extendedDefinition => $composableBuilder(
    column: $table.extendedDefinition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get synonyms => $composableBuilder(
    column: $table.synonyms,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MeaningsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MeaningsTable> {
  $$MeaningsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get vocabularyId => $composableBuilder(
    column: $table.vocabularyId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get primaryTranslation => $composableBuilder(
    column: $table.primaryTranslation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get alternativeTranslations => $composableBuilder(
    column: $table.alternativeTranslations,
    builder: (column) => column,
  );

  GeneratedColumn<String> get englishDefinition => $composableBuilder(
    column: $table.englishDefinition,
    builder: (column) => column,
  );

  GeneratedColumn<String> get extendedDefinition => $composableBuilder(
    column: $table.extendedDefinition,
    builder: (column) => column,
  );

  GeneratedColumn<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => column,
  );

  GeneratedColumn<String> get synonyms =>
      $composableBuilder(column: $table.synonyms, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$MeaningsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MeaningsTable,
          Meaning,
          $$MeaningsTableFilterComposer,
          $$MeaningsTableOrderingComposer,
          $$MeaningsTableAnnotationComposer,
          $$MeaningsTableCreateCompanionBuilder,
          $$MeaningsTableUpdateCompanionBuilder,
          (Meaning, BaseReferences<_$AppDatabase, $MeaningsTable, Meaning>),
          Meaning,
          PrefetchHooks Function()
        > {
  $$MeaningsTableTableManager(_$AppDatabase db, $MeaningsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeaningsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeaningsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeaningsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> vocabularyId = const Value.absent(),
                Value<String> languageCode = const Value.absent(),
                Value<String> primaryTranslation = const Value.absent(),
                Value<String> alternativeTranslations = const Value.absent(),
                Value<String> englishDefinition = const Value.absent(),
                Value<String?> extendedDefinition = const Value.absent(),
                Value<String?> partOfSpeech = const Value.absent(),
                Value<String> synonyms = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<bool> isPendingSync = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MeaningsCompanion(
                id: id,
                userId: userId,
                vocabularyId: vocabularyId,
                languageCode: languageCode,
                primaryTranslation: primaryTranslation,
                alternativeTranslations: alternativeTranslations,
                englishDefinition: englishDefinition,
                extendedDefinition: extendedDefinition,
                partOfSpeech: partOfSpeech,
                synonyms: synonyms,
                confidence: confidence,
                isPrimary: isPrimary,
                isActive: isActive,
                sortOrder: sortOrder,
                source: source,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                isPendingSync: isPendingSync,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String vocabularyId,
                required String languageCode,
                required String primaryTranslation,
                Value<String> alternativeTranslations = const Value.absent(),
                required String englishDefinition,
                Value<String?> extendedDefinition = const Value.absent(),
                Value<String?> partOfSpeech = const Value.absent(),
                Value<String> synonyms = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> source = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<bool> isPendingSync = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MeaningsCompanion.insert(
                id: id,
                userId: userId,
                vocabularyId: vocabularyId,
                languageCode: languageCode,
                primaryTranslation: primaryTranslation,
                alternativeTranslations: alternativeTranslations,
                englishDefinition: englishDefinition,
                extendedDefinition: extendedDefinition,
                partOfSpeech: partOfSpeech,
                synonyms: synonyms,
                confidence: confidence,
                isPrimary: isPrimary,
                isActive: isActive,
                sortOrder: sortOrder,
                source: source,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                isPendingSync: isPendingSync,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MeaningsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MeaningsTable,
      Meaning,
      $$MeaningsTableFilterComposer,
      $$MeaningsTableOrderingComposer,
      $$MeaningsTableAnnotationComposer,
      $$MeaningsTableCreateCompanionBuilder,
      $$MeaningsTableUpdateCompanionBuilder,
      (Meaning, BaseReferences<_$AppDatabase, $MeaningsTable, Meaning>),
      Meaning,
      PrefetchHooks Function()
    >;
typedef $$CuesTableCreateCompanionBuilder =
    CuesCompanion Function({
      required String id,
      required String userId,
      required String meaningId,
      required String cueType,
      required String promptText,
      required String answerText,
      Value<String?> hintText,
      Value<String> metadata,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<bool> isPendingSync,
      Value<int> version,
      Value<int> rowid,
    });
typedef $$CuesTableUpdateCompanionBuilder =
    CuesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> meaningId,
      Value<String> cueType,
      Value<String> promptText,
      Value<String> answerText,
      Value<String?> hintText,
      Value<String> metadata,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<bool> isPendingSync,
      Value<int> version,
      Value<int> rowid,
    });

class $$CuesTableFilterComposer extends Composer<_$AppDatabase, $CuesTable> {
  $$CuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaningId => $composableBuilder(
    column: $table.meaningId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cueType => $composableBuilder(
    column: $table.cueType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get promptText => $composableBuilder(
    column: $table.promptText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answerText => $composableBuilder(
    column: $table.answerText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hintText => $composableBuilder(
    column: $table.hintText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CuesTableOrderingComposer extends Composer<_$AppDatabase, $CuesTable> {
  $$CuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaningId => $composableBuilder(
    column: $table.meaningId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cueType => $composableBuilder(
    column: $table.cueType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get promptText => $composableBuilder(
    column: $table.promptText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answerText => $composableBuilder(
    column: $table.answerText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hintText => $composableBuilder(
    column: $table.hintText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CuesTable> {
  $$CuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get meaningId =>
      $composableBuilder(column: $table.meaningId, builder: (column) => column);

  GeneratedColumn<String> get cueType =>
      $composableBuilder(column: $table.cueType, builder: (column) => column);

  GeneratedColumn<String> get promptText => $composableBuilder(
    column: $table.promptText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get answerText => $composableBuilder(
    column: $table.answerText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hintText =>
      $composableBuilder(column: $table.hintText, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$CuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CuesTable,
          Cue,
          $$CuesTableFilterComposer,
          $$CuesTableOrderingComposer,
          $$CuesTableAnnotationComposer,
          $$CuesTableCreateCompanionBuilder,
          $$CuesTableUpdateCompanionBuilder,
          (Cue, BaseReferences<_$AppDatabase, $CuesTable, Cue>),
          Cue,
          PrefetchHooks Function()
        > {
  $$CuesTableTableManager(_$AppDatabase db, $CuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> meaningId = const Value.absent(),
                Value<String> cueType = const Value.absent(),
                Value<String> promptText = const Value.absent(),
                Value<String> answerText = const Value.absent(),
                Value<String?> hintText = const Value.absent(),
                Value<String> metadata = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<bool> isPendingSync = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CuesCompanion(
                id: id,
                userId: userId,
                meaningId: meaningId,
                cueType: cueType,
                promptText: promptText,
                answerText: answerText,
                hintText: hintText,
                metadata: metadata,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                isPendingSync: isPendingSync,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String meaningId,
                required String cueType,
                required String promptText,
                required String answerText,
                Value<String?> hintText = const Value.absent(),
                Value<String> metadata = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<bool> isPendingSync = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CuesCompanion.insert(
                id: id,
                userId: userId,
                meaningId: meaningId,
                cueType: cueType,
                promptText: promptText,
                answerText: answerText,
                hintText: hintText,
                metadata: metadata,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                isPendingSync: isPendingSync,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CuesTable,
      Cue,
      $$CuesTableFilterComposer,
      $$CuesTableOrderingComposer,
      $$CuesTableAnnotationComposer,
      $$CuesTableCreateCompanionBuilder,
      $$CuesTableUpdateCompanionBuilder,
      (Cue, BaseReferences<_$AppDatabase, $CuesTable, Cue>),
      Cue,
      PrefetchHooks Function()
    >;
typedef $$ConfusableSetsTableCreateCompanionBuilder =
    ConfusableSetsCompanion Function({
      required String id,
      required String userId,
      required String languageCode,
      required String words,
      required String explanations,
      Value<String> exampleSentences,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<bool> isPendingSync,
      Value<int> version,
      Value<int> rowid,
    });
typedef $$ConfusableSetsTableUpdateCompanionBuilder =
    ConfusableSetsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> languageCode,
      Value<String> words,
      Value<String> explanations,
      Value<String> exampleSentences,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<bool> isPendingSync,
      Value<int> version,
      Value<int> rowid,
    });

class $$ConfusableSetsTableFilterComposer
    extends Composer<_$AppDatabase, $ConfusableSetsTable> {
  $$ConfusableSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get words => $composableBuilder(
    column: $table.words,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanations => $composableBuilder(
    column: $table.explanations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exampleSentences => $composableBuilder(
    column: $table.exampleSentences,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConfusableSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConfusableSetsTable> {
  $$ConfusableSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get words => $composableBuilder(
    column: $table.words,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanations => $composableBuilder(
    column: $table.explanations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exampleSentences => $composableBuilder(
    column: $table.exampleSentences,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConfusableSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConfusableSetsTable> {
  $$ConfusableSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get words =>
      $composableBuilder(column: $table.words, builder: (column) => column);

  GeneratedColumn<String> get explanations => $composableBuilder(
    column: $table.explanations,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exampleSentences => $composableBuilder(
    column: $table.exampleSentences,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$ConfusableSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConfusableSetsTable,
          ConfusableSet,
          $$ConfusableSetsTableFilterComposer,
          $$ConfusableSetsTableOrderingComposer,
          $$ConfusableSetsTableAnnotationComposer,
          $$ConfusableSetsTableCreateCompanionBuilder,
          $$ConfusableSetsTableUpdateCompanionBuilder,
          (
            ConfusableSet,
            BaseReferences<_$AppDatabase, $ConfusableSetsTable, ConfusableSet>,
          ),
          ConfusableSet,
          PrefetchHooks Function()
        > {
  $$ConfusableSetsTableTableManager(
    _$AppDatabase db,
    $ConfusableSetsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConfusableSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConfusableSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConfusableSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> languageCode = const Value.absent(),
                Value<String> words = const Value.absent(),
                Value<String> explanations = const Value.absent(),
                Value<String> exampleSentences = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<bool> isPendingSync = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConfusableSetsCompanion(
                id: id,
                userId: userId,
                languageCode: languageCode,
                words: words,
                explanations: explanations,
                exampleSentences: exampleSentences,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                isPendingSync: isPendingSync,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String languageCode,
                required String words,
                required String explanations,
                Value<String> exampleSentences = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<bool> isPendingSync = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConfusableSetsCompanion.insert(
                id: id,
                userId: userId,
                languageCode: languageCode,
                words: words,
                explanations: explanations,
                exampleSentences: exampleSentences,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                isPendingSync: isPendingSync,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConfusableSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConfusableSetsTable,
      ConfusableSet,
      $$ConfusableSetsTableFilterComposer,
      $$ConfusableSetsTableOrderingComposer,
      $$ConfusableSetsTableAnnotationComposer,
      $$ConfusableSetsTableCreateCompanionBuilder,
      $$ConfusableSetsTableUpdateCompanionBuilder,
      (
        ConfusableSet,
        BaseReferences<_$AppDatabase, $ConfusableSetsTable, ConfusableSet>,
      ),
      ConfusableSet,
      PrefetchHooks Function()
    >;
typedef $$ConfusableSetMembersTableCreateCompanionBuilder =
    ConfusableSetMembersCompanion Function({
      required String id,
      required String confusableSetId,
      required String vocabularyId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ConfusableSetMembersTableUpdateCompanionBuilder =
    ConfusableSetMembersCompanion Function({
      Value<String> id,
      Value<String> confusableSetId,
      Value<String> vocabularyId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ConfusableSetMembersTableFilterComposer
    extends Composer<_$AppDatabase, $ConfusableSetMembersTable> {
  $$ConfusableSetMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confusableSetId => $composableBuilder(
    column: $table.confusableSetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vocabularyId => $composableBuilder(
    column: $table.vocabularyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConfusableSetMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $ConfusableSetMembersTable> {
  $$ConfusableSetMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confusableSetId => $composableBuilder(
    column: $table.confusableSetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vocabularyId => $composableBuilder(
    column: $table.vocabularyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConfusableSetMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConfusableSetMembersTable> {
  $$ConfusableSetMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get confusableSetId => $composableBuilder(
    column: $table.confusableSetId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vocabularyId => $composableBuilder(
    column: $table.vocabularyId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ConfusableSetMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConfusableSetMembersTable,
          ConfusableSetMember,
          $$ConfusableSetMembersTableFilterComposer,
          $$ConfusableSetMembersTableOrderingComposer,
          $$ConfusableSetMembersTableAnnotationComposer,
          $$ConfusableSetMembersTableCreateCompanionBuilder,
          $$ConfusableSetMembersTableUpdateCompanionBuilder,
          (
            ConfusableSetMember,
            BaseReferences<
              _$AppDatabase,
              $ConfusableSetMembersTable,
              ConfusableSetMember
            >,
          ),
          ConfusableSetMember,
          PrefetchHooks Function()
        > {
  $$ConfusableSetMembersTableTableManager(
    _$AppDatabase db,
    $ConfusableSetMembersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConfusableSetMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConfusableSetMembersTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ConfusableSetMembersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> confusableSetId = const Value.absent(),
                Value<String> vocabularyId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConfusableSetMembersCompanion(
                id: id,
                confusableSetId: confusableSetId,
                vocabularyId: vocabularyId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String confusableSetId,
                required String vocabularyId,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ConfusableSetMembersCompanion.insert(
                id: id,
                confusableSetId: confusableSetId,
                vocabularyId: vocabularyId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConfusableSetMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConfusableSetMembersTable,
      ConfusableSetMember,
      $$ConfusableSetMembersTableFilterComposer,
      $$ConfusableSetMembersTableOrderingComposer,
      $$ConfusableSetMembersTableAnnotationComposer,
      $$ConfusableSetMembersTableCreateCompanionBuilder,
      $$ConfusableSetMembersTableUpdateCompanionBuilder,
      (
        ConfusableSetMember,
        BaseReferences<
          _$AppDatabase,
          $ConfusableSetMembersTable,
          ConfusableSetMember
        >,
      ),
      ConfusableSetMember,
      PrefetchHooks Function()
    >;
typedef $$MeaningEditsTableCreateCompanionBuilder =
    MeaningEditsCompanion Function({
      required String id,
      required String userId,
      required String meaningId,
      required String fieldName,
      required String originalValue,
      required String userValue,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$MeaningEditsTableUpdateCompanionBuilder =
    MeaningEditsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> meaningId,
      Value<String> fieldName,
      Value<String> originalValue,
      Value<String> userValue,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$MeaningEditsTableFilterComposer
    extends Composer<_$AppDatabase, $MeaningEditsTable> {
  $$MeaningEditsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaningId => $composableBuilder(
    column: $table.meaningId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldName => $composableBuilder(
    column: $table.fieldName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalValue => $composableBuilder(
    column: $table.originalValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userValue => $composableBuilder(
    column: $table.userValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MeaningEditsTableOrderingComposer
    extends Composer<_$AppDatabase, $MeaningEditsTable> {
  $$MeaningEditsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaningId => $composableBuilder(
    column: $table.meaningId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldName => $composableBuilder(
    column: $table.fieldName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalValue => $composableBuilder(
    column: $table.originalValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userValue => $composableBuilder(
    column: $table.userValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MeaningEditsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MeaningEditsTable> {
  $$MeaningEditsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get meaningId =>
      $composableBuilder(column: $table.meaningId, builder: (column) => column);

  GeneratedColumn<String> get fieldName =>
      $composableBuilder(column: $table.fieldName, builder: (column) => column);

  GeneratedColumn<String> get originalValue => $composableBuilder(
    column: $table.originalValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userValue =>
      $composableBuilder(column: $table.userValue, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MeaningEditsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MeaningEditsTable,
          MeaningEdit,
          $$MeaningEditsTableFilterComposer,
          $$MeaningEditsTableOrderingComposer,
          $$MeaningEditsTableAnnotationComposer,
          $$MeaningEditsTableCreateCompanionBuilder,
          $$MeaningEditsTableUpdateCompanionBuilder,
          (
            MeaningEdit,
            BaseReferences<_$AppDatabase, $MeaningEditsTable, MeaningEdit>,
          ),
          MeaningEdit,
          PrefetchHooks Function()
        > {
  $$MeaningEditsTableTableManager(_$AppDatabase db, $MeaningEditsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeaningEditsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeaningEditsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeaningEditsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> meaningId = const Value.absent(),
                Value<String> fieldName = const Value.absent(),
                Value<String> originalValue = const Value.absent(),
                Value<String> userValue = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MeaningEditsCompanion(
                id: id,
                userId: userId,
                meaningId: meaningId,
                fieldName: fieldName,
                originalValue: originalValue,
                userValue: userValue,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String meaningId,
                required String fieldName,
                required String originalValue,
                required String userValue,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => MeaningEditsCompanion.insert(
                id: id,
                userId: userId,
                meaningId: meaningId,
                fieldName: fieldName,
                originalValue: originalValue,
                userValue: userValue,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MeaningEditsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MeaningEditsTable,
      MeaningEdit,
      $$MeaningEditsTableFilterComposer,
      $$MeaningEditsTableOrderingComposer,
      $$MeaningEditsTableAnnotationComposer,
      $$MeaningEditsTableCreateCompanionBuilder,
      $$MeaningEditsTableUpdateCompanionBuilder,
      (
        MeaningEdit,
        BaseReferences<_$AppDatabase, $MeaningEditsTable, MeaningEdit>,
      ),
      MeaningEdit,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LanguagesTableTableManager get languages =>
      $$LanguagesTableTableManager(_db, _db.languages);
  $$SourcesTableTableManager get sources =>
      $$SourcesTableTableManager(_db, _db.sources);
  $$EncountersTableTableManager get encounters =>
      $$EncountersTableTableManager(_db, _db.encounters);
  $$ImportSessionsTableTableManager get importSessions =>
      $$ImportSessionsTableTableManager(_db, _db.importSessions);
  $$SyncOutboxTableTableManager get syncOutbox =>
      $$SyncOutboxTableTableManager(_db, _db.syncOutbox);
  $$VocabularysTableTableManager get vocabularys =>
      $$VocabularysTableTableManager(_db, _db.vocabularys);
  $$LearningCardsTableTableManager get learningCards =>
      $$LearningCardsTableTableManager(_db, _db.learningCards);
  $$ReviewLogsTableTableManager get reviewLogs =>
      $$ReviewLogsTableTableManager(_db, _db.reviewLogs);
  $$LearningSessionsTableTableManager get learningSessions =>
      $$LearningSessionsTableTableManager(_db, _db.learningSessions);
  $$UserLearningPreferencesTableTableManager get userLearningPreferences =>
      $$UserLearningPreferencesTableTableManager(
        _db,
        _db.userLearningPreferences,
      );
  $$StreaksTableTableManager get streaks =>
      $$StreaksTableTableManager(_db, _db.streaks);
  $$MeaningsTableTableManager get meanings =>
      $$MeaningsTableTableManager(_db, _db.meanings);
  $$CuesTableTableManager get cues => $$CuesTableTableManager(_db, _db.cues);
  $$ConfusableSetsTableTableManager get confusableSets =>
      $$ConfusableSetsTableTableManager(_db, _db.confusableSets);
  $$ConfusableSetMembersTableTableManager get confusableSetMembers =>
      $$ConfusableSetMembersTableTableManager(_db, _db.confusableSetMembers);
  $$MeaningEditsTableTableManager get meaningEdits =>
      $$MeaningEditsTableTableManager(_db, _db.meaningEdits);
}
