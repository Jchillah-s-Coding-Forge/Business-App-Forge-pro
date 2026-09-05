import AppForgeDomain

struct FlutterOfflineSyncCoreSources {
    let specification: ProjectSpecification

    func files() -> [GeneratedFile] {
        var files = [
            GeneratedFile(
                relativePath: "lib/core/sync/sync_status.dart",
                contents: syncStatus()
            ),
            GeneratedFile(
                relativePath: "lib/core/sync/sync_policy.dart",
                contents: syncPolicy()
            )
        ]

        if specification.offline.usesSyncOutbox {
            files += FlutterOfflineOutboxCoreSources().files()
        }

        return files
    }

    private func syncStatus() -> String {
        FlutterGeneratedText.lines([
            "enum SyncStatus {",
            "  clean,",
            "  pending,",
            "  syncing,",
            "  conflict,",
            "  failed,",
            "  deleted,",
            "}",
            ""
        ])
    }

    private func syncPolicy() -> String {
        let strategy = switch specification.offline.conflictResolution {
        case .latestWriteWins:
            "latestWriteWins"
        case .serverWins:
            "serverWins"
        case .clientWins:
            "clientWins"
        case .manualReview:
            "manualReview"
        }
        let reconnect = specification.offline.syncsOnReconnect
            ? "true"
            : "false"

        return FlutterGeneratedText.lines([
            "enum SyncConflictStrategy {",
            "  latestWriteWins,",
            "  serverWins,",
            "  clientWins,",
            "  manualReview,",
            "}",
            "",
            "class SyncPolicy {",
            "  const SyncPolicy({",
            "    required this.strategy,",
            "    required this.syncsOnReconnect,",
            "  });",
            "",
            "  final SyncConflictStrategy strategy;",
            "  final bool syncsOnReconnect;",
            "",
            "  static const current = SyncPolicy(",
            "    strategy: SyncConflictStrategy.\(strategy),",
            "    syncsOnReconnect: \(reconnect),",
            "  );",
            "}",
            ""
        ])
    }
}
