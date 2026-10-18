// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academic_database.dart';

// ignore_for_file: type=lint
class $LocalAssignmentsTable extends LocalAssignments
    with TableInfo<$LocalAssignmentsTable, LocalAssignment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAssignmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completeMeta = const VerificationMeta(
    'complete',
  );
  @override
  late final GeneratedColumn<bool> complete = GeneratedColumn<bool>(
    'complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("complete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
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
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('student'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    subject,
    dueDate,
    complete,
    recordedAt,
    updatedAt,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_assignments';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalAssignment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('complete')) {
      context.handle(
        _completeMeta,
        complete.isAcceptableOrUnknown(data['complete']!, _completeMeta),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalAssignment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAssignment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      )!,
      complete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}complete'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $LocalAssignmentsTable createAlias(String alias) {
    return $LocalAssignmentsTable(attachedDatabase, alias);
  }
}

class LocalAssignment extends DataClass implements Insertable<LocalAssignment> {
  final String id;
  final String title;
  final String subject;
  final DateTime dueDate;
  final bool complete;
  final DateTime recordedAt;
  final DateTime updatedAt;
  final String source;
  const LocalAssignment({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.complete,
    required this.recordedAt,
    required this.updatedAt,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['subject'] = Variable<String>(subject);
    map['due_date'] = Variable<DateTime>(dueDate);
    map['complete'] = Variable<bool>(complete);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['source'] = Variable<String>(source);
    return map;
  }

  LocalAssignmentsCompanion toCompanion(bool nullToAbsent) {
    return LocalAssignmentsCompanion(
      id: Value(id),
      title: Value(title),
      subject: Value(subject),
      dueDate: Value(dueDate),
      complete: Value(complete),
      recordedAt: Value(recordedAt),
      updatedAt: Value(updatedAt),
      source: Value(source),
    );
  }

  factory LocalAssignment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAssignment(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      subject: serializer.fromJson<String>(json['subject']),
      dueDate: serializer.fromJson<DateTime>(json['dueDate']),
      complete: serializer.fromJson<bool>(json['complete']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'subject': serializer.toJson<String>(subject),
      'dueDate': serializer.toJson<DateTime>(dueDate),
      'complete': serializer.toJson<bool>(complete),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'source': serializer.toJson<String>(source),
    };
  }

  LocalAssignment copyWith({
    String? id,
    String? title,
    String? subject,
    DateTime? dueDate,
    bool? complete,
    DateTime? recordedAt,
    DateTime? updatedAt,
    String? source,
  }) => LocalAssignment(
    id: id ?? this.id,
    title: title ?? this.title,
    subject: subject ?? this.subject,
    dueDate: dueDate ?? this.dueDate,
    complete: complete ?? this.complete,
    recordedAt: recordedAt ?? this.recordedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    source: source ?? this.source,
  );
  LocalAssignment copyWithCompanion(LocalAssignmentsCompanion data) {
    return LocalAssignment(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      subject: data.subject.present ? data.subject.value : this.subject,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      complete: data.complete.present ? data.complete.value : this.complete,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAssignment(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('subject: $subject, ')
          ..write('dueDate: $dueDate, ')
          ..write('complete: $complete, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    subject,
    dueDate,
    complete,
    recordedAt,
    updatedAt,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAssignment &&
          other.id == this.id &&
          other.title == this.title &&
          other.subject == this.subject &&
          other.dueDate == this.dueDate &&
          other.complete == this.complete &&
          other.recordedAt == this.recordedAt &&
          other.updatedAt == this.updatedAt &&
          other.source == this.source);
}

class LocalAssignmentsCompanion extends UpdateCompanion<LocalAssignment> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> subject;
  final Value<DateTime> dueDate;
  final Value<bool> complete;
  final Value<DateTime> recordedAt;
  final Value<DateTime> updatedAt;
  final Value<String> source;
  final Value<int> rowid;
  const LocalAssignmentsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.subject = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.complete = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalAssignmentsCompanion.insert({
    required String id,
    required String title,
    required String subject,
    required DateTime dueDate,
    this.complete = const Value.absent(),
    required DateTime recordedAt,
    required DateTime updatedAt,
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       subject = Value(subject),
       dueDate = Value(dueDate),
       recordedAt = Value(recordedAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalAssignment> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? subject,
    Expression<DateTime>? dueDate,
    Expression<bool>? complete,
    Expression<DateTime>? recordedAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (subject != null) 'subject': subject,
      if (dueDate != null) 'due_date': dueDate,
      if (complete != null) 'complete': complete,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalAssignmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? subject,
    Value<DateTime>? dueDate,
    Value<bool>? complete,
    Value<DateTime>? recordedAt,
    Value<DateTime>? updatedAt,
    Value<String>? source,
    Value<int>? rowid,
  }) {
    return LocalAssignmentsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      dueDate: dueDate ?? this.dueDate,
      complete: complete ?? this.complete,
      recordedAt: recordedAt ?? this.recordedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (complete.present) {
      map['complete'] = Variable<bool>(complete.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAssignmentsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('subject: $subject, ')
          ..write('dueDate: $dueDate, ')
          ..write('complete: $complete, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalClassesTable extends LocalClasses
    with TableInfo<$LocalClassesTable, LocalClassesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalClassesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roomMeta = const VerificationMeta('room');
  @override
  late final GeneratedColumn<String> room = GeneratedColumn<String>(
    'room',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weekdayMeta = const VerificationMeta(
    'weekday',
  );
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
    'weekday',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMinuteMeta = const VerificationMeta(
    'startMinute',
  );
  @override
  late final GeneratedColumn<int> startMinute = GeneratedColumn<int>(
    'start_minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMinuteMeta = const VerificationMeta(
    'endMinute',
  );
  @override
  late final GeneratedColumn<int> endMinute = GeneratedColumn<int>(
    'end_minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('student'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    subject,
    room,
    weekday,
    startMinute,
    endMinute,
    recordedAt,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_classes';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalClassesData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('room')) {
      context.handle(
        _roomMeta,
        room.isAcceptableOrUnknown(data['room']!, _roomMeta),
      );
    } else if (isInserting) {
      context.missing(_roomMeta);
    }
    if (data.containsKey('weekday')) {
      context.handle(
        _weekdayMeta,
        weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta),
      );
    } else if (isInserting) {
      context.missing(_weekdayMeta);
    }
    if (data.containsKey('start_minute')) {
      context.handle(
        _startMinuteMeta,
        startMinute.isAcceptableOrUnknown(
          data['start_minute']!,
          _startMinuteMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startMinuteMeta);
    }
    if (data.containsKey('end_minute')) {
      context.handle(
        _endMinuteMeta,
        endMinute.isAcceptableOrUnknown(data['end_minute']!, _endMinuteMeta),
      );
    } else if (isInserting) {
      context.missing(_endMinuteMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalClassesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalClassesData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      room: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room'],
      )!,
      weekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday'],
      )!,
      startMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_minute'],
      )!,
      endMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_minute'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $LocalClassesTable createAlias(String alias) {
    return $LocalClassesTable(attachedDatabase, alias);
  }
}

class LocalClassesData extends DataClass
    implements Insertable<LocalClassesData> {
  final String id;
  final String subject;
  final String room;
  final int weekday;
  final int startMinute;
  final int endMinute;
  final DateTime recordedAt;
  final String source;
  const LocalClassesData({
    required this.id,
    required this.subject,
    required this.room,
    required this.weekday,
    required this.startMinute,
    required this.endMinute,
    required this.recordedAt,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['subject'] = Variable<String>(subject);
    map['room'] = Variable<String>(room);
    map['weekday'] = Variable<int>(weekday);
    map['start_minute'] = Variable<int>(startMinute);
    map['end_minute'] = Variable<int>(endMinute);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['source'] = Variable<String>(source);
    return map;
  }

  LocalClassesCompanion toCompanion(bool nullToAbsent) {
    return LocalClassesCompanion(
      id: Value(id),
      subject: Value(subject),
      room: Value(room),
      weekday: Value(weekday),
      startMinute: Value(startMinute),
      endMinute: Value(endMinute),
      recordedAt: Value(recordedAt),
      source: Value(source),
    );
  }

  factory LocalClassesData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalClassesData(
      id: serializer.fromJson<String>(json['id']),
      subject: serializer.fromJson<String>(json['subject']),
      room: serializer.fromJson<String>(json['room']),
      weekday: serializer.fromJson<int>(json['weekday']),
      startMinute: serializer.fromJson<int>(json['startMinute']),
      endMinute: serializer.fromJson<int>(json['endMinute']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'subject': serializer.toJson<String>(subject),
      'room': serializer.toJson<String>(room),
      'weekday': serializer.toJson<int>(weekday),
      'startMinute': serializer.toJson<int>(startMinute),
      'endMinute': serializer.toJson<int>(endMinute),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'source': serializer.toJson<String>(source),
    };
  }

  LocalClassesData copyWith({
    String? id,
    String? subject,
    String? room,
    int? weekday,
    int? startMinute,
    int? endMinute,
    DateTime? recordedAt,
    String? source,
  }) => LocalClassesData(
    id: id ?? this.id,
    subject: subject ?? this.subject,
    room: room ?? this.room,
    weekday: weekday ?? this.weekday,
    startMinute: startMinute ?? this.startMinute,
    endMinute: endMinute ?? this.endMinute,
    recordedAt: recordedAt ?? this.recordedAt,
    source: source ?? this.source,
  );
  LocalClassesData copyWithCompanion(LocalClassesCompanion data) {
    return LocalClassesData(
      id: data.id.present ? data.id.value : this.id,
      subject: data.subject.present ? data.subject.value : this.subject,
      room: data.room.present ? data.room.value : this.room,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      startMinute: data.startMinute.present
          ? data.startMinute.value
          : this.startMinute,
      endMinute: data.endMinute.present ? data.endMinute.value : this.endMinute,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalClassesData(')
          ..write('id: $id, ')
          ..write('subject: $subject, ')
          ..write('room: $room, ')
          ..write('weekday: $weekday, ')
          ..write('startMinute: $startMinute, ')
          ..write('endMinute: $endMinute, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    subject,
    room,
    weekday,
    startMinute,
    endMinute,
    recordedAt,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalClassesData &&
          other.id == this.id &&
          other.subject == this.subject &&
          other.room == this.room &&
          other.weekday == this.weekday &&
          other.startMinute == this.startMinute &&
          other.endMinute == this.endMinute &&
          other.recordedAt == this.recordedAt &&
          other.source == this.source);
}

class LocalClassesCompanion extends UpdateCompanion<LocalClassesData> {
  final Value<String> id;
  final Value<String> subject;
  final Value<String> room;
  final Value<int> weekday;
  final Value<int> startMinute;
  final Value<int> endMinute;
  final Value<DateTime> recordedAt;
  final Value<String> source;
  final Value<int> rowid;
  const LocalClassesCompanion({
    this.id = const Value.absent(),
    this.subject = const Value.absent(),
    this.room = const Value.absent(),
    this.weekday = const Value.absent(),
    this.startMinute = const Value.absent(),
    this.endMinute = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalClassesCompanion.insert({
    required String id,
    required String subject,
    required String room,
    required int weekday,
    required int startMinute,
    required int endMinute,
    required DateTime recordedAt,
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       subject = Value(subject),
       room = Value(room),
       weekday = Value(weekday),
       startMinute = Value(startMinute),
       endMinute = Value(endMinute),
       recordedAt = Value(recordedAt);
  static Insertable<LocalClassesData> custom({
    Expression<String>? id,
    Expression<String>? subject,
    Expression<String>? room,
    Expression<int>? weekday,
    Expression<int>? startMinute,
    Expression<int>? endMinute,
    Expression<DateTime>? recordedAt,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subject != null) 'subject': subject,
      if (room != null) 'room': room,
      if (weekday != null) 'weekday': weekday,
      if (startMinute != null) 'start_minute': startMinute,
      if (endMinute != null) 'end_minute': endMinute,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalClassesCompanion copyWith({
    Value<String>? id,
    Value<String>? subject,
    Value<String>? room,
    Value<int>? weekday,
    Value<int>? startMinute,
    Value<int>? endMinute,
    Value<DateTime>? recordedAt,
    Value<String>? source,
    Value<int>? rowid,
  }) {
    return LocalClassesCompanion(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      room: room ?? this.room,
      weekday: weekday ?? this.weekday,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
      recordedAt: recordedAt ?? this.recordedAt,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (room.present) {
      map['room'] = Variable<String>(room.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (startMinute.present) {
      map['start_minute'] = Variable<int>(startMinute.value);
    }
    if (endMinute.present) {
      map['end_minute'] = Variable<int>(endMinute.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalClassesCompanion(')
          ..write('id: $id, ')
          ..write('subject: $subject, ')
          ..write('room: $room, ')
          ..write('weekday: $weekday, ')
          ..write('startMinute: $startMinute, ')
          ..write('endMinute: $endMinute, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalAttendanceTable extends LocalAttendance
    with TableInfo<$LocalAttendanceTable, LocalAttendanceData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAttendanceTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _subjectKeyMeta = const VerificationMeta(
    'subjectKey',
  );
  @override
  late final GeneratedColumn<String> subjectKey = GeneratedColumn<String>(
    'subject_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attendedMeta = const VerificationMeta(
    'attended',
  );
  @override
  late final GeneratedColumn<int> attended = GeneratedColumn<int>(
    'attended',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conductedMeta = const VerificationMeta(
    'conducted',
  );
  @override
  late final GeneratedColumn<int> conducted = GeneratedColumn<int>(
    'conducted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minimumPercentageMeta = const VerificationMeta(
    'minimumPercentage',
  );
  @override
  late final GeneratedColumn<double> minimumPercentage =
      GeneratedColumn<double>(
        'minimum_percentage',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
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
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('student'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    subjectKey,
    subject,
    attended,
    conducted,
    minimumPercentage,
    updatedAt,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_attendance';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalAttendanceData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('subject_key')) {
      context.handle(
        _subjectKeyMeta,
        subjectKey.isAcceptableOrUnknown(data['subject_key']!, _subjectKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectKeyMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('attended')) {
      context.handle(
        _attendedMeta,
        attended.isAcceptableOrUnknown(data['attended']!, _attendedMeta),
      );
    } else if (isInserting) {
      context.missing(_attendedMeta);
    }
    if (data.containsKey('conducted')) {
      context.handle(
        _conductedMeta,
        conducted.isAcceptableOrUnknown(data['conducted']!, _conductedMeta),
      );
    } else if (isInserting) {
      context.missing(_conductedMeta);
    }
    if (data.containsKey('minimum_percentage')) {
      context.handle(
        _minimumPercentageMeta,
        minimumPercentage.isAcceptableOrUnknown(
          data['minimum_percentage']!,
          _minimumPercentageMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {subjectKey};
  @override
  LocalAttendanceData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAttendanceData(
      subjectKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_key'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      attended: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attended'],
      )!,
      conducted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}conducted'],
      )!,
      minimumPercentage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}minimum_percentage'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $LocalAttendanceTable createAlias(String alias) {
    return $LocalAttendanceTable(attachedDatabase, alias);
  }
}

class LocalAttendanceData extends DataClass
    implements Insertable<LocalAttendanceData> {
  final String subjectKey;
  final String subject;
  final int attended;
  final int conducted;
  final double? minimumPercentage;
  final DateTime updatedAt;
  final String source;
  const LocalAttendanceData({
    required this.subjectKey,
    required this.subject,
    required this.attended,
    required this.conducted,
    this.minimumPercentage,
    required this.updatedAt,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['subject_key'] = Variable<String>(subjectKey);
    map['subject'] = Variable<String>(subject);
    map['attended'] = Variable<int>(attended);
    map['conducted'] = Variable<int>(conducted);
    if (!nullToAbsent || minimumPercentage != null) {
      map['minimum_percentage'] = Variable<double>(minimumPercentage);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['source'] = Variable<String>(source);
    return map;
  }

  LocalAttendanceCompanion toCompanion(bool nullToAbsent) {
    return LocalAttendanceCompanion(
      subjectKey: Value(subjectKey),
      subject: Value(subject),
      attended: Value(attended),
      conducted: Value(conducted),
      minimumPercentage: minimumPercentage == null && nullToAbsent
          ? const Value.absent()
          : Value(minimumPercentage),
      updatedAt: Value(updatedAt),
      source: Value(source),
    );
  }

  factory LocalAttendanceData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAttendanceData(
      subjectKey: serializer.fromJson<String>(json['subjectKey']),
      subject: serializer.fromJson<String>(json['subject']),
      attended: serializer.fromJson<int>(json['attended']),
      conducted: serializer.fromJson<int>(json['conducted']),
      minimumPercentage: serializer.fromJson<double?>(
        json['minimumPercentage'],
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'subjectKey': serializer.toJson<String>(subjectKey),
      'subject': serializer.toJson<String>(subject),
      'attended': serializer.toJson<int>(attended),
      'conducted': serializer.toJson<int>(conducted),
      'minimumPercentage': serializer.toJson<double?>(minimumPercentage),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'source': serializer.toJson<String>(source),
    };
  }

  LocalAttendanceData copyWith({
    String? subjectKey,
    String? subject,
    int? attended,
    int? conducted,
    Value<double?> minimumPercentage = const Value.absent(),
    DateTime? updatedAt,
    String? source,
  }) => LocalAttendanceData(
    subjectKey: subjectKey ?? this.subjectKey,
    subject: subject ?? this.subject,
    attended: attended ?? this.attended,
    conducted: conducted ?? this.conducted,
    minimumPercentage: minimumPercentage.present
        ? minimumPercentage.value
        : this.minimumPercentage,
    updatedAt: updatedAt ?? this.updatedAt,
    source: source ?? this.source,
  );
  LocalAttendanceData copyWithCompanion(LocalAttendanceCompanion data) {
    return LocalAttendanceData(
      subjectKey: data.subjectKey.present
          ? data.subjectKey.value
          : this.subjectKey,
      subject: data.subject.present ? data.subject.value : this.subject,
      attended: data.attended.present ? data.attended.value : this.attended,
      conducted: data.conducted.present ? data.conducted.value : this.conducted,
      minimumPercentage: data.minimumPercentage.present
          ? data.minimumPercentage.value
          : this.minimumPercentage,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAttendanceData(')
          ..write('subjectKey: $subjectKey, ')
          ..write('subject: $subject, ')
          ..write('attended: $attended, ')
          ..write('conducted: $conducted, ')
          ..write('minimumPercentage: $minimumPercentage, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    subjectKey,
    subject,
    attended,
    conducted,
    minimumPercentage,
    updatedAt,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAttendanceData &&
          other.subjectKey == this.subjectKey &&
          other.subject == this.subject &&
          other.attended == this.attended &&
          other.conducted == this.conducted &&
          other.minimumPercentage == this.minimumPercentage &&
          other.updatedAt == this.updatedAt &&
          other.source == this.source);
}

class LocalAttendanceCompanion extends UpdateCompanion<LocalAttendanceData> {
  final Value<String> subjectKey;
  final Value<String> subject;
  final Value<int> attended;
  final Value<int> conducted;
  final Value<double?> minimumPercentage;
  final Value<DateTime> updatedAt;
  final Value<String> source;
  final Value<int> rowid;
  const LocalAttendanceCompanion({
    this.subjectKey = const Value.absent(),
    this.subject = const Value.absent(),
    this.attended = const Value.absent(),
    this.conducted = const Value.absent(),
    this.minimumPercentage = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalAttendanceCompanion.insert({
    required String subjectKey,
    required String subject,
    required int attended,
    required int conducted,
    this.minimumPercentage = const Value.absent(),
    required DateTime updatedAt,
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : subjectKey = Value(subjectKey),
       subject = Value(subject),
       attended = Value(attended),
       conducted = Value(conducted),
       updatedAt = Value(updatedAt);
  static Insertable<LocalAttendanceData> custom({
    Expression<String>? subjectKey,
    Expression<String>? subject,
    Expression<int>? attended,
    Expression<int>? conducted,
    Expression<double>? minimumPercentage,
    Expression<DateTime>? updatedAt,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (subjectKey != null) 'subject_key': subjectKey,
      if (subject != null) 'subject': subject,
      if (attended != null) 'attended': attended,
      if (conducted != null) 'conducted': conducted,
      if (minimumPercentage != null) 'minimum_percentage': minimumPercentage,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalAttendanceCompanion copyWith({
    Value<String>? subjectKey,
    Value<String>? subject,
    Value<int>? attended,
    Value<int>? conducted,
    Value<double?>? minimumPercentage,
    Value<DateTime>? updatedAt,
    Value<String>? source,
    Value<int>? rowid,
  }) {
    return LocalAttendanceCompanion(
      subjectKey: subjectKey ?? this.subjectKey,
      subject: subject ?? this.subject,
      attended: attended ?? this.attended,
      conducted: conducted ?? this.conducted,
      minimumPercentage: minimumPercentage ?? this.minimumPercentage,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (subjectKey.present) {
      map['subject_key'] = Variable<String>(subjectKey.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (attended.present) {
      map['attended'] = Variable<int>(attended.value);
    }
    if (conducted.present) {
      map['conducted'] = Variable<int>(conducted.value);
    }
    if (minimumPercentage.present) {
      map['minimum_percentage'] = Variable<double>(minimumPercentage.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAttendanceCompanion(')
          ..write('subjectKey: $subjectKey, ')
          ..write('subject: $subject, ')
          ..write('attended: $attended, ')
          ..write('conducted: $conducted, ')
          ..write('minimumPercentage: $minimumPercentage, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalConsentsTable extends LocalConsents
    with TableInfo<$LocalConsentsTable, LocalConsent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalConsentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noticeVersionMeta = const VerificationMeta(
    'noticeVersion',
  );
  @override
  late final GeneratedColumn<String> noticeVersion = GeneratedColumn<String>(
    'notice_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grantedAtMeta = const VerificationMeta(
    'grantedAt',
  );
  @override
  late final GeneratedColumn<DateTime> grantedAt = GeneratedColumn<DateTime>(
    'granted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, noticeVersion, grantedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_consents';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalConsent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('notice_version')) {
      context.handle(
        _noticeVersionMeta,
        noticeVersion.isAcceptableOrUnknown(
          data['notice_version']!,
          _noticeVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_noticeVersionMeta);
    }
    if (data.containsKey('granted_at')) {
      context.handle(
        _grantedAtMeta,
        grantedAt.isAcceptableOrUnknown(data['granted_at']!, _grantedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_grantedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalConsent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalConsent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      noticeVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notice_version'],
      )!,
      grantedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}granted_at'],
      )!,
    );
  }

  @override
  $LocalConsentsTable createAlias(String alias) {
    return $LocalConsentsTable(attachedDatabase, alias);
  }
}

class LocalConsent extends DataClass implements Insertable<LocalConsent> {
  final int id;
  final String noticeVersion;
  final DateTime grantedAt;
  const LocalConsent({
    required this.id,
    required this.noticeVersion,
    required this.grantedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['notice_version'] = Variable<String>(noticeVersion);
    map['granted_at'] = Variable<DateTime>(grantedAt);
    return map;
  }

  LocalConsentsCompanion toCompanion(bool nullToAbsent) {
    return LocalConsentsCompanion(
      id: Value(id),
      noticeVersion: Value(noticeVersion),
      grantedAt: Value(grantedAt),
    );
  }

  factory LocalConsent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalConsent(
      id: serializer.fromJson<int>(json['id']),
      noticeVersion: serializer.fromJson<String>(json['noticeVersion']),
      grantedAt: serializer.fromJson<DateTime>(json['grantedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'noticeVersion': serializer.toJson<String>(noticeVersion),
      'grantedAt': serializer.toJson<DateTime>(grantedAt),
    };
  }

  LocalConsent copyWith({
    int? id,
    String? noticeVersion,
    DateTime? grantedAt,
  }) => LocalConsent(
    id: id ?? this.id,
    noticeVersion: noticeVersion ?? this.noticeVersion,
    grantedAt: grantedAt ?? this.grantedAt,
  );
  LocalConsent copyWithCompanion(LocalConsentsCompanion data) {
    return LocalConsent(
      id: data.id.present ? data.id.value : this.id,
      noticeVersion: data.noticeVersion.present
          ? data.noticeVersion.value
          : this.noticeVersion,
      grantedAt: data.grantedAt.present ? data.grantedAt.value : this.grantedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalConsent(')
          ..write('id: $id, ')
          ..write('noticeVersion: $noticeVersion, ')
          ..write('grantedAt: $grantedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, noticeVersion, grantedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalConsent &&
          other.id == this.id &&
          other.noticeVersion == this.noticeVersion &&
          other.grantedAt == this.grantedAt);
}

class LocalConsentsCompanion extends UpdateCompanion<LocalConsent> {
  final Value<int> id;
  final Value<String> noticeVersion;
  final Value<DateTime> grantedAt;
  const LocalConsentsCompanion({
    this.id = const Value.absent(),
    this.noticeVersion = const Value.absent(),
    this.grantedAt = const Value.absent(),
  });
  LocalConsentsCompanion.insert({
    this.id = const Value.absent(),
    required String noticeVersion,
    required DateTime grantedAt,
  }) : noticeVersion = Value(noticeVersion),
       grantedAt = Value(grantedAt);
  static Insertable<LocalConsent> custom({
    Expression<int>? id,
    Expression<String>? noticeVersion,
    Expression<DateTime>? grantedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (noticeVersion != null) 'notice_version': noticeVersion,
      if (grantedAt != null) 'granted_at': grantedAt,
    });
  }

  LocalConsentsCompanion copyWith({
    Value<int>? id,
    Value<String>? noticeVersion,
    Value<DateTime>? grantedAt,
  }) {
    return LocalConsentsCompanion(
      id: id ?? this.id,
      noticeVersion: noticeVersion ?? this.noticeVersion,
      grantedAt: grantedAt ?? this.grantedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (noticeVersion.present) {
      map['notice_version'] = Variable<String>(noticeVersion.value);
    }
    if (grantedAt.present) {
      map['granted_at'] = Variable<DateTime>(grantedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalConsentsCompanion(')
          ..write('id: $id, ')
          ..write('noticeVersion: $noticeVersion, ')
          ..write('grantedAt: $grantedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalAcademicProfilesTable extends LocalAcademicProfiles
    with TableInfo<$LocalAcademicProfilesTable, LocalAcademicProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAcademicProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _programmeMeta = const VerificationMeta(
    'programme',
  );
  @override
  late final GeneratedColumn<String> programme = GeneratedColumn<String>(
    'programme',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _semesterNumberMeta = const VerificationMeta(
    'semesterNumber',
  );
  @override
  late final GeneratedColumn<int> semesterNumber = GeneratedColumn<int>(
    'semester_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _semesterStartMeta = const VerificationMeta(
    'semesterStart',
  );
  @override
  late final GeneratedColumn<String> semesterStart = GeneratedColumn<String>(
    'semester_start',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _semesterEndMeta = const VerificationMeta(
    'semesterEnd',
  );
  @override
  late final GeneratedColumn<String> semesterEnd = GeneratedColumn<String>(
    'semester_end',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Asia/Kolkata'),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    programme,
    semesterNumber,
    semesterStart,
    semesterEnd,
    timezone,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_academic_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalAcademicProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('programme')) {
      context.handle(
        _programmeMeta,
        programme.isAcceptableOrUnknown(data['programme']!, _programmeMeta),
      );
    } else if (isInserting) {
      context.missing(_programmeMeta);
    }
    if (data.containsKey('semester_number')) {
      context.handle(
        _semesterNumberMeta,
        semesterNumber.isAcceptableOrUnknown(
          data['semester_number']!,
          _semesterNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_semesterNumberMeta);
    }
    if (data.containsKey('semester_start')) {
      context.handle(
        _semesterStartMeta,
        semesterStart.isAcceptableOrUnknown(
          data['semester_start']!,
          _semesterStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_semesterStartMeta);
    }
    if (data.containsKey('semester_end')) {
      context.handle(
        _semesterEndMeta,
        semesterEnd.isAcceptableOrUnknown(
          data['semester_end']!,
          _semesterEndMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_semesterEndMeta);
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalAcademicProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAcademicProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      programme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}programme'],
      )!,
      semesterNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}semester_number'],
      )!,
      semesterStart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}semester_start'],
      )!,
      semesterEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}semester_end'],
      )!,
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalAcademicProfilesTable createAlias(String alias) {
    return $LocalAcademicProfilesTable(attachedDatabase, alias);
  }
}

class LocalAcademicProfile extends DataClass
    implements Insertable<LocalAcademicProfile> {
  final int id;
  final String programme;
  final int semesterNumber;
  final String semesterStart;
  final String semesterEnd;
  final String timezone;
  final DateTime updatedAt;
  const LocalAcademicProfile({
    required this.id,
    required this.programme,
    required this.semesterNumber,
    required this.semesterStart,
    required this.semesterEnd,
    required this.timezone,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['programme'] = Variable<String>(programme);
    map['semester_number'] = Variable<int>(semesterNumber);
    map['semester_start'] = Variable<String>(semesterStart);
    map['semester_end'] = Variable<String>(semesterEnd);
    map['timezone'] = Variable<String>(timezone);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalAcademicProfilesCompanion toCompanion(bool nullToAbsent) {
    return LocalAcademicProfilesCompanion(
      id: Value(id),
      programme: Value(programme),
      semesterNumber: Value(semesterNumber),
      semesterStart: Value(semesterStart),
      semesterEnd: Value(semesterEnd),
      timezone: Value(timezone),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalAcademicProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAcademicProfile(
      id: serializer.fromJson<int>(json['id']),
      programme: serializer.fromJson<String>(json['programme']),
      semesterNumber: serializer.fromJson<int>(json['semesterNumber']),
      semesterStart: serializer.fromJson<String>(json['semesterStart']),
      semesterEnd: serializer.fromJson<String>(json['semesterEnd']),
      timezone: serializer.fromJson<String>(json['timezone']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'programme': serializer.toJson<String>(programme),
      'semesterNumber': serializer.toJson<int>(semesterNumber),
      'semesterStart': serializer.toJson<String>(semesterStart),
      'semesterEnd': serializer.toJson<String>(semesterEnd),
      'timezone': serializer.toJson<String>(timezone),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalAcademicProfile copyWith({
    int? id,
    String? programme,
    int? semesterNumber,
    String? semesterStart,
    String? semesterEnd,
    String? timezone,
    DateTime? updatedAt,
  }) => LocalAcademicProfile(
    id: id ?? this.id,
    programme: programme ?? this.programme,
    semesterNumber: semesterNumber ?? this.semesterNumber,
    semesterStart: semesterStart ?? this.semesterStart,
    semesterEnd: semesterEnd ?? this.semesterEnd,
    timezone: timezone ?? this.timezone,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalAcademicProfile copyWithCompanion(LocalAcademicProfilesCompanion data) {
    return LocalAcademicProfile(
      id: data.id.present ? data.id.value : this.id,
      programme: data.programme.present ? data.programme.value : this.programme,
      semesterNumber: data.semesterNumber.present
          ? data.semesterNumber.value
          : this.semesterNumber,
      semesterStart: data.semesterStart.present
          ? data.semesterStart.value
          : this.semesterStart,
      semesterEnd: data.semesterEnd.present
          ? data.semesterEnd.value
          : this.semesterEnd,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAcademicProfile(')
          ..write('id: $id, ')
          ..write('programme: $programme, ')
          ..write('semesterNumber: $semesterNumber, ')
          ..write('semesterStart: $semesterStart, ')
          ..write('semesterEnd: $semesterEnd, ')
          ..write('timezone: $timezone, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    programme,
    semesterNumber,
    semesterStart,
    semesterEnd,
    timezone,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAcademicProfile &&
          other.id == this.id &&
          other.programme == this.programme &&
          other.semesterNumber == this.semesterNumber &&
          other.semesterStart == this.semesterStart &&
          other.semesterEnd == this.semesterEnd &&
          other.timezone == this.timezone &&
          other.updatedAt == this.updatedAt);
}

class LocalAcademicProfilesCompanion
    extends UpdateCompanion<LocalAcademicProfile> {
  final Value<int> id;
  final Value<String> programme;
  final Value<int> semesterNumber;
  final Value<String> semesterStart;
  final Value<String> semesterEnd;
  final Value<String> timezone;
  final Value<DateTime> updatedAt;
  const LocalAcademicProfilesCompanion({
    this.id = const Value.absent(),
    this.programme = const Value.absent(),
    this.semesterNumber = const Value.absent(),
    this.semesterStart = const Value.absent(),
    this.semesterEnd = const Value.absent(),
    this.timezone = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalAcademicProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String programme,
    required int semesterNumber,
    required String semesterStart,
    required String semesterEnd,
    this.timezone = const Value.absent(),
    required DateTime updatedAt,
  }) : programme = Value(programme),
       semesterNumber = Value(semesterNumber),
       semesterStart = Value(semesterStart),
       semesterEnd = Value(semesterEnd),
       updatedAt = Value(updatedAt);
  static Insertable<LocalAcademicProfile> custom({
    Expression<int>? id,
    Expression<String>? programme,
    Expression<int>? semesterNumber,
    Expression<String>? semesterStart,
    Expression<String>? semesterEnd,
    Expression<String>? timezone,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (programme != null) 'programme': programme,
      if (semesterNumber != null) 'semester_number': semesterNumber,
      if (semesterStart != null) 'semester_start': semesterStart,
      if (semesterEnd != null) 'semester_end': semesterEnd,
      if (timezone != null) 'timezone': timezone,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalAcademicProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? programme,
    Value<int>? semesterNumber,
    Value<String>? semesterStart,
    Value<String>? semesterEnd,
    Value<String>? timezone,
    Value<DateTime>? updatedAt,
  }) {
    return LocalAcademicProfilesCompanion(
      id: id ?? this.id,
      programme: programme ?? this.programme,
      semesterNumber: semesterNumber ?? this.semesterNumber,
      semesterStart: semesterStart ?? this.semesterStart,
      semesterEnd: semesterEnd ?? this.semesterEnd,
      timezone: timezone ?? this.timezone,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (programme.present) {
      map['programme'] = Variable<String>(programme.value);
    }
    if (semesterNumber.present) {
      map['semester_number'] = Variable<int>(semesterNumber.value);
    }
    if (semesterStart.present) {
      map['semester_start'] = Variable<String>(semesterStart.value);
    }
    if (semesterEnd.present) {
      map['semester_end'] = Variable<String>(semesterEnd.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAcademicProfilesCompanion(')
          ..write('id: $id, ')
          ..write('programme: $programme, ')
          ..write('semesterNumber: $semesterNumber, ')
          ..write('semesterStart: $semesterStart, ')
          ..write('semesterEnd: $semesterEnd, ')
          ..write('timezone: $timezone, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalSyncOutboxTable extends LocalSyncOutbox
    with TableInfo<$LocalSyncOutboxTable, LocalSyncOutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSyncOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
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
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
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
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    operationId,
    entityType,
    payloadJson,
    createdAt,
    attempts,
    lastAttemptAt,
    lastError,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sync_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSyncOutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {operationId};
  @override
  LocalSyncOutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSyncOutboxData(
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $LocalSyncOutboxTable createAlias(String alias) {
    return $LocalSyncOutboxTable(attachedDatabase, alias);
  }
}

class LocalSyncOutboxData extends DataClass
    implements Insertable<LocalSyncOutboxData> {
  final String operationId;
  final String entityType;
  final String payloadJson;
  final DateTime createdAt;
  final int attempts;
  final DateTime? lastAttemptAt;
  final String? lastError;
  final String status;
  const LocalSyncOutboxData({
    required this.operationId,
    required this.entityType,
    required this.payloadJson,
    required this.createdAt,
    required this.attempts,
    this.lastAttemptAt,
    this.lastError,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['operation_id'] = Variable<String>(operationId);
    map['entity_type'] = Variable<String>(entityType);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  LocalSyncOutboxCompanion toCompanion(bool nullToAbsent) {
    return LocalSyncOutboxCompanion(
      operationId: Value(operationId),
      entityType: Value(entityType),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      status: Value(status),
    );
  }

  factory LocalSyncOutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSyncOutboxData(
      operationId: serializer.fromJson<String>(json['operationId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'operationId': serializer.toJson<String>(operationId),
      'entityType': serializer.toJson<String>(entityType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
      'status': serializer.toJson<String>(status),
    };
  }

  LocalSyncOutboxData copyWith({
    String? operationId,
    String? entityType,
    String? payloadJson,
    DateTime? createdAt,
    int? attempts,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    String? status,
  }) => LocalSyncOutboxData(
    operationId: operationId ?? this.operationId,
    entityType: entityType ?? this.entityType,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAt: createdAt ?? this.createdAt,
    attempts: attempts ?? this.attempts,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    status: status ?? this.status,
  );
  LocalSyncOutboxData copyWithCompanion(LocalSyncOutboxCompanion data) {
    return LocalSyncOutboxData(
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncOutboxData(')
          ..write('operationId: $operationId, ')
          ..write('entityType: $entityType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    operationId,
    entityType,
    payloadJson,
    createdAt,
    attempts,
    lastAttemptAt,
    lastError,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSyncOutboxData &&
          other.operationId == this.operationId &&
          other.entityType == this.entityType &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.lastError == this.lastError &&
          other.status == this.status);
}

class LocalSyncOutboxCompanion extends UpdateCompanion<LocalSyncOutboxData> {
  final Value<String> operationId;
  final Value<String> entityType;
  final Value<String> payloadJson;
  final Value<DateTime> createdAt;
  final Value<int> attempts;
  final Value<DateTime?> lastAttemptAt;
  final Value<String?> lastError;
  final Value<String> status;
  final Value<int> rowid;
  const LocalSyncOutboxCompanion({
    this.operationId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSyncOutboxCompanion.insert({
    required String operationId,
    required String entityType,
    required String payloadJson,
    required DateTime createdAt,
    this.attempts = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : operationId = Value(operationId),
       entityType = Value(entityType),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt);
  static Insertable<LocalSyncOutboxData> custom({
    Expression<String>? operationId,
    Expression<String>? entityType,
    Expression<String>? payloadJson,
    Expression<DateTime>? createdAt,
    Expression<int>? attempts,
    Expression<DateTime>? lastAttemptAt,
    Expression<String>? lastError,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (operationId != null) 'operation_id': operationId,
      if (entityType != null) 'entity_type': entityType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSyncOutboxCompanion copyWith({
    Value<String>? operationId,
    Value<String>? entityType,
    Value<String>? payloadJson,
    Value<DateTime>? createdAt,
    Value<int>? attempts,
    Value<DateTime?>? lastAttemptAt,
    Value<String?>? lastError,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return LocalSyncOutboxCompanion(
      operationId: operationId ?? this.operationId,
      entityType: entityType ?? this.entityType,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastError: lastError ?? this.lastError,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncOutboxCompanion(')
          ..write('operationId: $operationId, ')
          ..write('entityType: $entityType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AcademicDatabase extends GeneratedDatabase {
  _$AcademicDatabase(QueryExecutor e) : super(e);
  $AcademicDatabaseManager get managers => $AcademicDatabaseManager(this);
  late final $LocalAssignmentsTable localAssignments = $LocalAssignmentsTable(
    this,
  );
  late final $LocalClassesTable localClasses = $LocalClassesTable(this);
  late final $LocalAttendanceTable localAttendance = $LocalAttendanceTable(
    this,
  );
  late final $LocalConsentsTable localConsents = $LocalConsentsTable(this);
  late final $LocalAcademicProfilesTable localAcademicProfiles =
      $LocalAcademicProfilesTable(this);
  late final $LocalSyncOutboxTable localSyncOutbox = $LocalSyncOutboxTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localAssignments,
    localClasses,
    localAttendance,
    localConsents,
    localAcademicProfiles,
    localSyncOutbox,
  ];
}

typedef $$LocalAssignmentsTableCreateCompanionBuilder =
    LocalAssignmentsCompanion Function({
      required String id,
      required String title,
      required String subject,
      required DateTime dueDate,
      Value<bool> complete,
      required DateTime recordedAt,
      required DateTime updatedAt,
      Value<String> source,
      Value<int> rowid,
    });
typedef $$LocalAssignmentsTableUpdateCompanionBuilder =
    LocalAssignmentsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> subject,
      Value<DateTime> dueDate,
      Value<bool> complete,
      Value<DateTime> recordedAt,
      Value<DateTime> updatedAt,
      Value<String> source,
      Value<int> rowid,
    });

class $$LocalAssignmentsTableFilterComposer
    extends Composer<_$AcademicDatabase, $LocalAssignmentsTable> {
  $$LocalAssignmentsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get complete => $composableBuilder(
    column: $table.complete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalAssignmentsTableOrderingComposer
    extends Composer<_$AcademicDatabase, $LocalAssignmentsTable> {
  $$LocalAssignmentsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get complete => $composableBuilder(
    column: $table.complete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalAssignmentsTableAnnotationComposer
    extends Composer<_$AcademicDatabase, $LocalAssignmentsTable> {
  $$LocalAssignmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<bool> get complete =>
      $composableBuilder(column: $table.complete, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$LocalAssignmentsTableTableManager
    extends
        RootTableManager<
          _$AcademicDatabase,
          $LocalAssignmentsTable,
          LocalAssignment,
          $$LocalAssignmentsTableFilterComposer,
          $$LocalAssignmentsTableOrderingComposer,
          $$LocalAssignmentsTableAnnotationComposer,
          $$LocalAssignmentsTableCreateCompanionBuilder,
          $$LocalAssignmentsTableUpdateCompanionBuilder,
          (
            LocalAssignment,
            BaseReferences<
              _$AcademicDatabase,
              $LocalAssignmentsTable,
              LocalAssignment
            >,
          ),
          LocalAssignment,
          PrefetchHooks Function()
        > {
  $$LocalAssignmentsTableTableManager(
    _$AcademicDatabase db,
    $LocalAssignmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalAssignmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalAssignmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalAssignmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<DateTime> dueDate = const Value.absent(),
                Value<bool> complete = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalAssignmentsCompanion(
                id: id,
                title: title,
                subject: subject,
                dueDate: dueDate,
                complete: complete,
                recordedAt: recordedAt,
                updatedAt: updatedAt,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String subject,
                required DateTime dueDate,
                Value<bool> complete = const Value.absent(),
                required DateTime recordedAt,
                required DateTime updatedAt,
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalAssignmentsCompanion.insert(
                id: id,
                title: title,
                subject: subject,
                dueDate: dueDate,
                complete: complete,
                recordedAt: recordedAt,
                updatedAt: updatedAt,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalAssignmentsTable, LocalAssignment>(table),
                  BaseReferences<
                    _$AcademicDatabase,
                    $LocalAssignmentsTable,
                    LocalAssignment
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalAssignmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AcademicDatabase,
      $LocalAssignmentsTable,
      LocalAssignment,
      $$LocalAssignmentsTableFilterComposer,
      $$LocalAssignmentsTableOrderingComposer,
      $$LocalAssignmentsTableAnnotationComposer,
      $$LocalAssignmentsTableCreateCompanionBuilder,
      $$LocalAssignmentsTableUpdateCompanionBuilder,
      (
        LocalAssignment,
        BaseReferences<
          _$AcademicDatabase,
          $LocalAssignmentsTable,
          LocalAssignment
        >,
      ),
      LocalAssignment,
      PrefetchHooks Function()
    >;
typedef $$LocalClassesTableCreateCompanionBuilder =
    LocalClassesCompanion Function({
      required String id,
      required String subject,
      required String room,
      required int weekday,
      required int startMinute,
      required int endMinute,
      required DateTime recordedAt,
      Value<String> source,
      Value<int> rowid,
    });
typedef $$LocalClassesTableUpdateCompanionBuilder =
    LocalClassesCompanion Function({
      Value<String> id,
      Value<String> subject,
      Value<String> room,
      Value<int> weekday,
      Value<int> startMinute,
      Value<int> endMinute,
      Value<DateTime> recordedAt,
      Value<String> source,
      Value<int> rowid,
    });

class $$LocalClassesTableFilterComposer
    extends Composer<_$AcademicDatabase, $LocalClassesTable> {
  $$LocalClassesTableFilterComposer({
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

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get room => $composableBuilder(
    column: $table.room,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMinute => $composableBuilder(
    column: $table.endMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalClassesTableOrderingComposer
    extends Composer<_$AcademicDatabase, $LocalClassesTable> {
  $$LocalClassesTableOrderingComposer({
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

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get room => $composableBuilder(
    column: $table.room,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMinute => $composableBuilder(
    column: $table.endMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalClassesTableAnnotationComposer
    extends Composer<_$AcademicDatabase, $LocalClassesTable> {
  $$LocalClassesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get room =>
      $composableBuilder(column: $table.room, builder: (column) => column);

  GeneratedColumn<int> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);

  GeneratedColumn<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endMinute =>
      $composableBuilder(column: $table.endMinute, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$LocalClassesTableTableManager
    extends
        RootTableManager<
          _$AcademicDatabase,
          $LocalClassesTable,
          LocalClassesData,
          $$LocalClassesTableFilterComposer,
          $$LocalClassesTableOrderingComposer,
          $$LocalClassesTableAnnotationComposer,
          $$LocalClassesTableCreateCompanionBuilder,
          $$LocalClassesTableUpdateCompanionBuilder,
          (
            LocalClassesData,
            BaseReferences<
              _$AcademicDatabase,
              $LocalClassesTable,
              LocalClassesData
            >,
          ),
          LocalClassesData,
          PrefetchHooks Function()
        > {
  $$LocalClassesTableTableManager(
    _$AcademicDatabase db,
    $LocalClassesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalClassesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalClassesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalClassesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> room = const Value.absent(),
                Value<int> weekday = const Value.absent(),
                Value<int> startMinute = const Value.absent(),
                Value<int> endMinute = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalClassesCompanion(
                id: id,
                subject: subject,
                room: room,
                weekday: weekday,
                startMinute: startMinute,
                endMinute: endMinute,
                recordedAt: recordedAt,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String subject,
                required String room,
                required int weekday,
                required int startMinute,
                required int endMinute,
                required DateTime recordedAt,
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalClassesCompanion.insert(
                id: id,
                subject: subject,
                room: room,
                weekday: weekday,
                startMinute: startMinute,
                endMinute: endMinute,
                recordedAt: recordedAt,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalClassesTable, LocalClassesData>(table),
                  BaseReferences<
                    _$AcademicDatabase,
                    $LocalClassesTable,
                    LocalClassesData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalClassesTableProcessedTableManager =
    ProcessedTableManager<
      _$AcademicDatabase,
      $LocalClassesTable,
      LocalClassesData,
      $$LocalClassesTableFilterComposer,
      $$LocalClassesTableOrderingComposer,
      $$LocalClassesTableAnnotationComposer,
      $$LocalClassesTableCreateCompanionBuilder,
      $$LocalClassesTableUpdateCompanionBuilder,
      (
        LocalClassesData,
        BaseReferences<
          _$AcademicDatabase,
          $LocalClassesTable,
          LocalClassesData
        >,
      ),
      LocalClassesData,
      PrefetchHooks Function()
    >;
typedef $$LocalAttendanceTableCreateCompanionBuilder =
    LocalAttendanceCompanion Function({
      required String subjectKey,
      required String subject,
      required int attended,
      required int conducted,
      Value<double?> minimumPercentage,
      required DateTime updatedAt,
      Value<String> source,
      Value<int> rowid,
    });
typedef $$LocalAttendanceTableUpdateCompanionBuilder =
    LocalAttendanceCompanion Function({
      Value<String> subjectKey,
      Value<String> subject,
      Value<int> attended,
      Value<int> conducted,
      Value<double?> minimumPercentage,
      Value<DateTime> updatedAt,
      Value<String> source,
      Value<int> rowid,
    });

class $$LocalAttendanceTableFilterComposer
    extends Composer<_$AcademicDatabase, $LocalAttendanceTable> {
  $$LocalAttendanceTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get subjectKey => $composableBuilder(
    column: $table.subjectKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attended => $composableBuilder(
    column: $table.attended,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get conducted => $composableBuilder(
    column: $table.conducted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minimumPercentage => $composableBuilder(
    column: $table.minimumPercentage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalAttendanceTableOrderingComposer
    extends Composer<_$AcademicDatabase, $LocalAttendanceTable> {
  $$LocalAttendanceTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get subjectKey => $composableBuilder(
    column: $table.subjectKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attended => $composableBuilder(
    column: $table.attended,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get conducted => $composableBuilder(
    column: $table.conducted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minimumPercentage => $composableBuilder(
    column: $table.minimumPercentage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalAttendanceTableAnnotationComposer
    extends Composer<_$AcademicDatabase, $LocalAttendanceTable> {
  $$LocalAttendanceTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get subjectKey => $composableBuilder(
    column: $table.subjectKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<int> get attended =>
      $composableBuilder(column: $table.attended, builder: (column) => column);

  GeneratedColumn<int> get conducted =>
      $composableBuilder(column: $table.conducted, builder: (column) => column);

  GeneratedColumn<double> get minimumPercentage => $composableBuilder(
    column: $table.minimumPercentage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$LocalAttendanceTableTableManager
    extends
        RootTableManager<
          _$AcademicDatabase,
          $LocalAttendanceTable,
          LocalAttendanceData,
          $$LocalAttendanceTableFilterComposer,
          $$LocalAttendanceTableOrderingComposer,
          $$LocalAttendanceTableAnnotationComposer,
          $$LocalAttendanceTableCreateCompanionBuilder,
          $$LocalAttendanceTableUpdateCompanionBuilder,
          (
            LocalAttendanceData,
            BaseReferences<
              _$AcademicDatabase,
              $LocalAttendanceTable,
              LocalAttendanceData
            >,
          ),
          LocalAttendanceData,
          PrefetchHooks Function()
        > {
  $$LocalAttendanceTableTableManager(
    _$AcademicDatabase db,
    $LocalAttendanceTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalAttendanceTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalAttendanceTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalAttendanceTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> subjectKey = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<int> attended = const Value.absent(),
                Value<int> conducted = const Value.absent(),
                Value<double?> minimumPercentage = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalAttendanceCompanion(
                subjectKey: subjectKey,
                subject: subject,
                attended: attended,
                conducted: conducted,
                minimumPercentage: minimumPercentage,
                updatedAt: updatedAt,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String subjectKey,
                required String subject,
                required int attended,
                required int conducted,
                Value<double?> minimumPercentage = const Value.absent(),
                required DateTime updatedAt,
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalAttendanceCompanion.insert(
                subjectKey: subjectKey,
                subject: subject,
                attended: attended,
                conducted: conducted,
                minimumPercentage: minimumPercentage,
                updatedAt: updatedAt,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalAttendanceTable, LocalAttendanceData>(
                    table,
                  ),
                  BaseReferences<
                    _$AcademicDatabase,
                    $LocalAttendanceTable,
                    LocalAttendanceData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalAttendanceTableProcessedTableManager =
    ProcessedTableManager<
      _$AcademicDatabase,
      $LocalAttendanceTable,
      LocalAttendanceData,
      $$LocalAttendanceTableFilterComposer,
      $$LocalAttendanceTableOrderingComposer,
      $$LocalAttendanceTableAnnotationComposer,
      $$LocalAttendanceTableCreateCompanionBuilder,
      $$LocalAttendanceTableUpdateCompanionBuilder,
      (
        LocalAttendanceData,
        BaseReferences<
          _$AcademicDatabase,
          $LocalAttendanceTable,
          LocalAttendanceData
        >,
      ),
      LocalAttendanceData,
      PrefetchHooks Function()
    >;
typedef $$LocalConsentsTableCreateCompanionBuilder =
    LocalConsentsCompanion Function({
      Value<int> id,
      required String noticeVersion,
      required DateTime grantedAt,
    });
typedef $$LocalConsentsTableUpdateCompanionBuilder =
    LocalConsentsCompanion Function({
      Value<int> id,
      Value<String> noticeVersion,
      Value<DateTime> grantedAt,
    });

class $$LocalConsentsTableFilterComposer
    extends Composer<_$AcademicDatabase, $LocalConsentsTable> {
  $$LocalConsentsTableFilterComposer({
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

  ColumnFilters<String> get noticeVersion => $composableBuilder(
    column: $table.noticeVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get grantedAt => $composableBuilder(
    column: $table.grantedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalConsentsTableOrderingComposer
    extends Composer<_$AcademicDatabase, $LocalConsentsTable> {
  $$LocalConsentsTableOrderingComposer({
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

  ColumnOrderings<String> get noticeVersion => $composableBuilder(
    column: $table.noticeVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get grantedAt => $composableBuilder(
    column: $table.grantedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalConsentsTableAnnotationComposer
    extends Composer<_$AcademicDatabase, $LocalConsentsTable> {
  $$LocalConsentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get noticeVersion => $composableBuilder(
    column: $table.noticeVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get grantedAt =>
      $composableBuilder(column: $table.grantedAt, builder: (column) => column);
}

class $$LocalConsentsTableTableManager
    extends
        RootTableManager<
          _$AcademicDatabase,
          $LocalConsentsTable,
          LocalConsent,
          $$LocalConsentsTableFilterComposer,
          $$LocalConsentsTableOrderingComposer,
          $$LocalConsentsTableAnnotationComposer,
          $$LocalConsentsTableCreateCompanionBuilder,
          $$LocalConsentsTableUpdateCompanionBuilder,
          (
            LocalConsent,
            BaseReferences<
              _$AcademicDatabase,
              $LocalConsentsTable,
              LocalConsent
            >,
          ),
          LocalConsent,
          PrefetchHooks Function()
        > {
  $$LocalConsentsTableTableManager(
    _$AcademicDatabase db,
    $LocalConsentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalConsentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalConsentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalConsentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> noticeVersion = const Value.absent(),
                Value<DateTime> grantedAt = const Value.absent(),
              }) => LocalConsentsCompanion(
                id: id,
                noticeVersion: noticeVersion,
                grantedAt: grantedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String noticeVersion,
                required DateTime grantedAt,
              }) => LocalConsentsCompanion.insert(
                id: id,
                noticeVersion: noticeVersion,
                grantedAt: grantedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalConsentsTable, LocalConsent>(table),
                  BaseReferences<
                    _$AcademicDatabase,
                    $LocalConsentsTable,
                    LocalConsent
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalConsentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AcademicDatabase,
      $LocalConsentsTable,
      LocalConsent,
      $$LocalConsentsTableFilterComposer,
      $$LocalConsentsTableOrderingComposer,
      $$LocalConsentsTableAnnotationComposer,
      $$LocalConsentsTableCreateCompanionBuilder,
      $$LocalConsentsTableUpdateCompanionBuilder,
      (
        LocalConsent,
        BaseReferences<_$AcademicDatabase, $LocalConsentsTable, LocalConsent>,
      ),
      LocalConsent,
      PrefetchHooks Function()
    >;
typedef $$LocalAcademicProfilesTableCreateCompanionBuilder =
    LocalAcademicProfilesCompanion Function({
      Value<int> id,
      required String programme,
      required int semesterNumber,
      required String semesterStart,
      required String semesterEnd,
      Value<String> timezone,
      required DateTime updatedAt,
    });
typedef $$LocalAcademicProfilesTableUpdateCompanionBuilder =
    LocalAcademicProfilesCompanion Function({
      Value<int> id,
      Value<String> programme,
      Value<int> semesterNumber,
      Value<String> semesterStart,
      Value<String> semesterEnd,
      Value<String> timezone,
      Value<DateTime> updatedAt,
    });

class $$LocalAcademicProfilesTableFilterComposer
    extends Composer<_$AcademicDatabase, $LocalAcademicProfilesTable> {
  $$LocalAcademicProfilesTableFilterComposer({
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

  ColumnFilters<String> get programme => $composableBuilder(
    column: $table.programme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get semesterNumber => $composableBuilder(
    column: $table.semesterNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get semesterStart => $composableBuilder(
    column: $table.semesterStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get semesterEnd => $composableBuilder(
    column: $table.semesterEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalAcademicProfilesTableOrderingComposer
    extends Composer<_$AcademicDatabase, $LocalAcademicProfilesTable> {
  $$LocalAcademicProfilesTableOrderingComposer({
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

  ColumnOrderings<String> get programme => $composableBuilder(
    column: $table.programme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get semesterNumber => $composableBuilder(
    column: $table.semesterNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get semesterStart => $composableBuilder(
    column: $table.semesterStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get semesterEnd => $composableBuilder(
    column: $table.semesterEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalAcademicProfilesTableAnnotationComposer
    extends Composer<_$AcademicDatabase, $LocalAcademicProfilesTable> {
  $$LocalAcademicProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get programme =>
      $composableBuilder(column: $table.programme, builder: (column) => column);

  GeneratedColumn<int> get semesterNumber => $composableBuilder(
    column: $table.semesterNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get semesterStart => $composableBuilder(
    column: $table.semesterStart,
    builder: (column) => column,
  );

  GeneratedColumn<String> get semesterEnd => $composableBuilder(
    column: $table.semesterEnd,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalAcademicProfilesTableTableManager
    extends
        RootTableManager<
          _$AcademicDatabase,
          $LocalAcademicProfilesTable,
          LocalAcademicProfile,
          $$LocalAcademicProfilesTableFilterComposer,
          $$LocalAcademicProfilesTableOrderingComposer,
          $$LocalAcademicProfilesTableAnnotationComposer,
          $$LocalAcademicProfilesTableCreateCompanionBuilder,
          $$LocalAcademicProfilesTableUpdateCompanionBuilder,
          (
            LocalAcademicProfile,
            BaseReferences<
              _$AcademicDatabase,
              $LocalAcademicProfilesTable,
              LocalAcademicProfile
            >,
          ),
          LocalAcademicProfile,
          PrefetchHooks Function()
        > {
  $$LocalAcademicProfilesTableTableManager(
    _$AcademicDatabase db,
    $LocalAcademicProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalAcademicProfilesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalAcademicProfilesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalAcademicProfilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> programme = const Value.absent(),
                Value<int> semesterNumber = const Value.absent(),
                Value<String> semesterStart = const Value.absent(),
                Value<String> semesterEnd = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalAcademicProfilesCompanion(
                id: id,
                programme: programme,
                semesterNumber: semesterNumber,
                semesterStart: semesterStart,
                semesterEnd: semesterEnd,
                timezone: timezone,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String programme,
                required int semesterNumber,
                required String semesterStart,
                required String semesterEnd,
                Value<String> timezone = const Value.absent(),
                required DateTime updatedAt,
              }) => LocalAcademicProfilesCompanion.insert(
                id: id,
                programme: programme,
                semesterNumber: semesterNumber,
                semesterStart: semesterStart,
                semesterEnd: semesterEnd,
                timezone: timezone,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $LocalAcademicProfilesTable,
                    LocalAcademicProfile
                  >(table),
                  BaseReferences<
                    _$AcademicDatabase,
                    $LocalAcademicProfilesTable,
                    LocalAcademicProfile
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalAcademicProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AcademicDatabase,
      $LocalAcademicProfilesTable,
      LocalAcademicProfile,
      $$LocalAcademicProfilesTableFilterComposer,
      $$LocalAcademicProfilesTableOrderingComposer,
      $$LocalAcademicProfilesTableAnnotationComposer,
      $$LocalAcademicProfilesTableCreateCompanionBuilder,
      $$LocalAcademicProfilesTableUpdateCompanionBuilder,
      (
        LocalAcademicProfile,
        BaseReferences<
          _$AcademicDatabase,
          $LocalAcademicProfilesTable,
          LocalAcademicProfile
        >,
      ),
      LocalAcademicProfile,
      PrefetchHooks Function()
    >;
typedef $$LocalSyncOutboxTableCreateCompanionBuilder =
    LocalSyncOutboxCompanion Function({
      required String operationId,
      required String entityType,
      required String payloadJson,
      required DateTime createdAt,
      Value<int> attempts,
      Value<DateTime?> lastAttemptAt,
      Value<String?> lastError,
      Value<String> status,
      Value<int> rowid,
    });
typedef $$LocalSyncOutboxTableUpdateCompanionBuilder =
    LocalSyncOutboxCompanion Function({
      Value<String> operationId,
      Value<String> entityType,
      Value<String> payloadJson,
      Value<DateTime> createdAt,
      Value<int> attempts,
      Value<DateTime?> lastAttemptAt,
      Value<String?> lastError,
      Value<String> status,
      Value<int> rowid,
    });

class $$LocalSyncOutboxTableFilterComposer
    extends Composer<_$AcademicDatabase, $LocalSyncOutboxTable> {
  $$LocalSyncOutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSyncOutboxTableOrderingComposer
    extends Composer<_$AcademicDatabase, $LocalSyncOutboxTable> {
  $$LocalSyncOutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSyncOutboxTableAnnotationComposer
    extends Composer<_$AcademicDatabase, $LocalSyncOutboxTable> {
  $$LocalSyncOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$LocalSyncOutboxTableTableManager
    extends
        RootTableManager<
          _$AcademicDatabase,
          $LocalSyncOutboxTable,
          LocalSyncOutboxData,
          $$LocalSyncOutboxTableFilterComposer,
          $$LocalSyncOutboxTableOrderingComposer,
          $$LocalSyncOutboxTableAnnotationComposer,
          $$LocalSyncOutboxTableCreateCompanionBuilder,
          $$LocalSyncOutboxTableUpdateCompanionBuilder,
          (
            LocalSyncOutboxData,
            BaseReferences<
              _$AcademicDatabase,
              $LocalSyncOutboxTable,
              LocalSyncOutboxData
            >,
          ),
          LocalSyncOutboxData,
          PrefetchHooks Function()
        > {
  $$LocalSyncOutboxTableTableManager(
    _$AcademicDatabase db,
    $LocalSyncOutboxTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSyncOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSyncOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSyncOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> operationId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSyncOutboxCompanion(
                operationId: operationId,
                entityType: entityType,
                payloadJson: payloadJson,
                createdAt: createdAt,
                attempts: attempts,
                lastAttemptAt: lastAttemptAt,
                lastError: lastError,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String operationId,
                required String entityType,
                required String payloadJson,
                required DateTime createdAt,
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSyncOutboxCompanion.insert(
                operationId: operationId,
                entityType: entityType,
                payloadJson: payloadJson,
                createdAt: createdAt,
                attempts: attempts,
                lastAttemptAt: lastAttemptAt,
                lastError: lastError,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalSyncOutboxTable, LocalSyncOutboxData>(
                    table,
                  ),
                  BaseReferences<
                    _$AcademicDatabase,
                    $LocalSyncOutboxTable,
                    LocalSyncOutboxData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSyncOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AcademicDatabase,
      $LocalSyncOutboxTable,
      LocalSyncOutboxData,
      $$LocalSyncOutboxTableFilterComposer,
      $$LocalSyncOutboxTableOrderingComposer,
      $$LocalSyncOutboxTableAnnotationComposer,
      $$LocalSyncOutboxTableCreateCompanionBuilder,
      $$LocalSyncOutboxTableUpdateCompanionBuilder,
      (
        LocalSyncOutboxData,
        BaseReferences<
          _$AcademicDatabase,
          $LocalSyncOutboxTable,
          LocalSyncOutboxData
        >,
      ),
      LocalSyncOutboxData,
      PrefetchHooks Function()
    >;

class $AcademicDatabaseManager {
  final _$AcademicDatabase _db;
  $AcademicDatabaseManager(this._db);
  $$LocalAssignmentsTableTableManager get localAssignments =>
      $$LocalAssignmentsTableTableManager(_db, _db.localAssignments);
  $$LocalClassesTableTableManager get localClasses =>
      $$LocalClassesTableTableManager(_db, _db.localClasses);
  $$LocalAttendanceTableTableManager get localAttendance =>
      $$LocalAttendanceTableTableManager(_db, _db.localAttendance);
  $$LocalConsentsTableTableManager get localConsents =>
      $$LocalConsentsTableTableManager(_db, _db.localConsents);
  $$LocalAcademicProfilesTableTableManager get localAcademicProfiles =>
      $$LocalAcademicProfilesTableTableManager(_db, _db.localAcademicProfiles);
  $$LocalSyncOutboxTableTableManager get localSyncOutbox =>
      $$LocalSyncOutboxTableTableManager(_db, _db.localSyncOutbox);
}
