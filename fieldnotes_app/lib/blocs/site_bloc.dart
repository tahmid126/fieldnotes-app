import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../models/site_model.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';

// EVENTS
abstract class SiteEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadSites extends SiteEvent {
  final String? customerId;
  LoadSites({this.customerId});

  @override
  List<Object?> get props => [customerId];
}

class AddSite extends SiteEvent {
  final String name;
  final String address;
  final String customerId;
  final String? customerName;
  AddSite({
    required this.name,
    required this.address,
    required this.customerId,
    this.customerName,
  });

  @override
  List<Object?> get props => [name, address, customerId, customerName];
}

class UpdateSite extends SiteEvent {
  final SiteModel site;
  UpdateSite(this.site);

  @override
  List<Object?> get props => [site];
}

class DeleteSite extends SiteEvent {
  final String id;
  DeleteSite(this.id);

  @override
  List<Object?> get props => [id];
}

// STATES
abstract class SiteState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SiteInitial extends SiteState {}

class SiteLoading extends SiteState {}

class SiteLoaded extends SiteState {
  final List<SiteModel> sites;
  SiteLoaded(this.sites);

  @override
  List<Object?> get props => [sites];
}

class SiteOperationFailure extends SiteState {
  final String error;
  SiteOperationFailure(this.error);

  @override
  List<Object?> get props => [error];
}

// BLOC
class SiteBloc extends Bloc<SiteEvent, SiteState> {
  final DatabaseService _db = DatabaseService.instance;
  final SyncService _sync = SyncService.instance;

  SiteBloc() : super(SiteInitial()) {
    on<LoadSites>(_onLoadSites);
    on<AddSite>(_onAddSite);
    on<UpdateSite>(_onUpdateSite);
    on<DeleteSite>(_onDeleteSite);
  }

  Future<void> _onLoadSites(LoadSites event, Emitter<SiteState> emit) async {
    emit(SiteLoading());
    try {
      final sites = await _db.getSites(customerId: event.customerId);
      emit(SiteLoaded(sites));
    } catch (e) {
      emit(SiteOperationFailure(e.toString()));
    }
  }

  Future<void> _onAddSite(AddSite event, Emitter<SiteState> emit) async {
    try {
      final now = DateTime.now();
      final newSite = SiteModel(
        id: const Uuid().v4(),
        name: event.name.trim(),
        address: event.address.trim(),
        customerId: event.customerId,
        customerName: event.customerName,
        deleted: false,
        createdAt: now,
        updatedAt: now,
        isSynced: false,
      );

      await _db.saveSite(newSite);
      _sync.performSync(); // background sync

      final updatedList = await _db.getSites();
      emit(SiteLoaded(updatedList));
    } catch (e) {
      emit(SiteOperationFailure(e.toString()));
    }
  }

  Future<void> _onUpdateSite(UpdateSite event, Emitter<SiteState> emit) async {
    try {
      final updated = event.site.copyWith(
        updatedAt: DateTime.now(),
        isSynced: false,
      );
      await _db.saveSite(updated);
      _sync.performSync(); // background sync

      final updatedList = await _db.getSites();
      emit(SiteLoaded(updatedList));
    } catch (e) {
      emit(SiteOperationFailure(e.toString()));
    }
  }

  Future<void> _onDeleteSite(DeleteSite event, Emitter<SiteState> emit) async {
    try {
      await _db.softDeleteSite(event.id);
      _sync.performSync(); // background sync

      final updatedList = await _db.getSites();
      emit(SiteLoaded(updatedList));
    } catch (e) {
      emit(SiteOperationFailure(e.toString()));
    }
  }
}
