# Offline-First Storage

## Purpose

M4.1 turns the Flutter renderer into an offline-first business-app generator.

When `ProjectSpecification.offline.isEnabled` is enabled, the generated Flutter app treats SQLite as the local **Single Source of Truth (SSOT)**. Reads and writes go through the local repository path first. Remote transports are intentionally not part of this slice.

```text
Presentation
    ↓
ViewModel
    ↓
Use Case
    ↓
Domain Repository
    ↓
Repository Implementation
    ↓
Local Data Source
    ↓
SQLite SSOT
    +
optional Atomic Sync Outbox
```

A later Supabase/Firebase adapter consumes the outbox. It must not bypass the local repository/SSOT boundary.

## Generated dependencies

Offline-enabled Flutter projects add:

- `sqflite: 2.4.2+1`
- `path: 1.9.1`

Offline-disabled projects do not receive those dependencies or any generated SQLite/sync source files.

Dependencies are assembled through one deterministic dependency composer together with the selected state-management dependency.

## Storage names

Business display labels are never used as SQL identifiers.

Table and column names are derived only from validated technical definition codes.

AppForge reserves the leading underscore namespace for system metadata. Business definitions such as `_sync_status` fail closed before SQL is generated.

Storage identifiers are normalized and checked for collisions after normalization.

## Entity table contract

Every offline entity table contains AppForge-owned metadata:

- `_record_id TEXT PRIMARY KEY`
- `_sync_revision INTEGER NOT NULL DEFAULT 0`
- `_sync_status TEXT NOT NULL`
- `_updated_at TEXT NOT NULL`
- `_deleted_at TEXT NULL`

Business fields are appended after those system columns.

Field mappings are deterministic:

| Project field | SQLite |
| --- | --- |
| string, email, phone, URL | TEXT |
| enum | TEXT |
| file, image, color, location | TEXT |
| integer | INTEGER |
| boolean | INTEGER |
| decimal, currency, percentage | REAL |
| date, dateTime, time | TEXT |

Dates/times are serialized as UTC ISO-8601 strings.

Boolean values are stored as SQLite integers.

## Schema versioning

`DatabaseMigrations.schemaVersion` is generated explicitly.

Initial schema creation is represented as deterministic SQL statements. Future schema evolution extends the same migration boundary instead of mutating database setup ad hoc in repositories.

Unique and indexed field metadata from `ProjectSpecification` is reflected in generated schema/index statements.

## Repository contract

Generated domain repositories expose:

- `fetchAll()`
- `save(recordId, value)`
- `delete(recordId)`

Generated Save/Delete Use Cases depend only on the domain repository contract.

For offline projects the data-layer implementation delegates exclusively to the local data source.

DTO/SQLite row mapping remains in the Data layer. Domain entities stay framework-free.

## Local mutation transaction

Every local save executes inside `database.transaction`.

Within the same transaction AppForge:

1. reads the current local revision;
2. increments the revision;
3. serializes the domain entity to a SQLite row;
4. writes the entity row;
5. when outbox is enabled, inserts the matching outbox operation.

The entity mutation and outbox insert therefore succeed or roll back together.

A successful entity mutation must never exist without its corresponding outbox operation when `usesSyncOutbox` is active.

## Sync outbox

The shared outbox table is generated only when `usesSyncOutbox` is enabled.

```text
_sync_outbox
- id TEXT PRIMARY KEY
- entity_code TEXT NOT NULL
- record_id TEXT NOT NULL
- operation TEXT NOT NULL
- payload_json TEXT NULL
- idempotency_key TEXT NOT NULL UNIQUE
- created_at TEXT NOT NULL
- attempt_count INTEGER NOT NULL DEFAULT 0
- last_error TEXT NULL
```

Operations are:

- create
- update
- delete

The idempotency key is deterministic:

```text
<entity-code>:<record-id>:<revision>:<operation>
```

The same key is persisted as both the outbox row ID and idempotency key.

## Tombstones

When the outbox is enabled, delete is a soft delete.

The local entity row remains present and receives:

- incremented `_sync_revision`
- `_sync_status = deleted`
- updated `_updated_at`
- `_deleted_at = now`

The same transaction inserts a delete operation into `_sync_outbox`.

Normal reads filter rows with a non-null `_deleted_at`.

Physical deletion is a later retention/purge concern after remote acknowledgement.

For a deliberately local-only project with no outbox, delete is a normal local hard delete.

## Sync status

Generated status values are:

- clean
- pending
- syncing
- conflict
- failed
- deleted

Local-only saves use `clean`.

Outbox-backed saves use `pending`.

## Conflict policy

`OfflineConfiguration.conflictResolution` is rendered into a typed `SyncPolicy`:

- latestWriteWins
- serverWins
- clientWins
- manualReview

M4.1 does not execute a remote conflict algorithm. It makes the selected policy explicit for the later sync transport.

`syncsOnReconnect` is preserved in the same generated policy.

## Security rules

The generated offline layer follows these constraints:

- no SQL identifier is taken from a display label;
- all table/column identifiers are generated from validated technical codes;
- all runtime values use sqflite value maps / argument binding;
- business fields cannot use the reserved AppForge system namespace;
- remote code is absent from the local repository implementation;
- no entity mutation writes its outbox entry outside the transaction;
- delete uses tombstones when cloud/outbox synchronization is active;
- outbox idempotency is persistent rather than process-memory state.

## M4.1 boundary

Included:

- SQLite SSOT
- deterministic schema
- local row mapping
- domain save/delete use cases
- local repository implementations
- atomic outbox
- tombstones
- sync status/policy contracts
- deterministic dependencies

Not included:

- Supabase transport
- Firebase transport
- connectivity/background scheduler
- retry scheduling policy
- server acknowledgement processing
- remote conflict resolution
- tombstone retention/purge
- encryption at rest

Those capabilities build on this local integrity boundary instead of replacing it.
