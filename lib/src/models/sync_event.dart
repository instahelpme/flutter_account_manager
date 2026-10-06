import '../../src/generated/account_manager_api.g.dart';
import 'account.dart';
import 'sync_result.dart';

/// Base class for sync-related events emitted by [AccountManagerPlugin.syncEvents].
sealed class SyncEvent {
  const SyncEvent();
}

class SyncStartedEvent extends SyncEvent {
  const SyncStartedEvent({required this.account});
  final Account account;
}

class SyncProgressEvent extends SyncEvent {
  const SyncProgressEvent({required this.account, required this.progress});
  final Account account;
  final SyncProgress progress;
}

class SyncCompletedEvent extends SyncEvent {
  const SyncCompletedEvent({required this.account, required this.result});
  final Account account;
  final SyncResult result;
}

class SyncCancelledEvent extends SyncEvent {
  const SyncCancelledEvent({required this.account});
  final Account account;
}

class SyncConflictEvent extends SyncEvent {
  const SyncConflictEvent({
    required this.account,
    required this.conflictId,
    required this.localData,
    required this.remoteData,
  });
  final Account account;
  final String conflictId;
  final String localData;
  final String remoteData;
}

/// Progress information for an ongoing sync.
class SyncProgress {
  const SyncProgress({
    required this.phase,
    required this.progress,
    this.message,
  });

  final String phase;

  /// 0.0 to 1.0
  final double progress;
  final String? message;

  factory SyncProgress.fromData(SyncProgressData data) => SyncProgress(
        phase: data.phase,
        progress: data.progress,
        message: data.message,
      );
}
