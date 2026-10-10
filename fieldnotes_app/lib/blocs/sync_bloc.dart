import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../services/sync_service.dart';

// EVENTS
abstract class SyncEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class TriggerSync extends SyncEvent {}

class RestoreData extends SyncEvent {}

// STATES
abstract class SyncState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SyncInitial extends SyncState {
  final String? lastSyncTime;
  SyncInitial({this.lastSyncTime});

  @override
  List<Object?> get props => [lastSyncTime];
}

class SyncInProgress extends SyncState {}

class SyncSuccess extends SyncState {
  final String message;
  final String? lastSyncTime;
  SyncSuccess(this.message, {this.lastSyncTime});

  @override
  List<Object?> get props => [message, lastSyncTime];
}

class SyncFailure extends SyncState {
  final String error;
  final bool isOffline;
  SyncFailure(this.error, {this.isOffline = false});

  @override
  List<Object?> get props => [error, isOffline];
}

// BLOC
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncService _sync = SyncService.instance;

  SyncBloc() : super(SyncInitial()) {
    on<TriggerSync>(_onTriggerSync);
    on<RestoreData>(_onRestoreData);
  }

  Future<void> _onTriggerSync(TriggerSync event, Emitter<SyncState> emit) async {
    emit(SyncInProgress());
    try {
      final success = await _sync.performSync();
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString(AppConstants.lastSyncKey);

      if (success) {
        emit(SyncSuccess('Sync completed successfully', lastSyncTime: lastSync));
      } else {
        final err = _sync.lastSyncError ?? 'Offline: changes saved locally and will sync when connected';
        emit(SyncFailure(err, isOffline: _sync.isLastSyncOffline));
      }
    } catch (e) {
      final isOff = _sync.isOfflineException(e);
      emit(SyncFailure(
        isOff
            ? 'Offline mode: Changes saved locally. Will sync automatically when connected.'
            : 'Sync failed: $e',
        isOffline: isOff,
      ));
    }
  }

  Future<void> _onRestoreData(RestoreData event, Emitter<SyncState> emit) async {
    emit(SyncInProgress());
    try {
      final success = await _sync.restoreAllData();
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString(AppConstants.lastSyncKey);

      if (success) {
        emit(SyncSuccess('All data restored from server', lastSyncTime: lastSync));
      } else {
        final err = _sync.lastSyncError ?? 'Failed to restore data from server';
        emit(SyncFailure(err, isOffline: _sync.isLastSyncOffline));
      }
    } catch (e) {
      final isOff = _sync.isOfflineException(e);
      emit(SyncFailure(
        isOff
            ? 'Offline mode: Server unreachable. Connect online to restore data.'
            : 'Restore error: $e',
        isOffline: isOff,
      ));
    }
  }
}
