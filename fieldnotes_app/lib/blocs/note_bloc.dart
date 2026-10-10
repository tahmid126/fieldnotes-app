import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/field_note_model.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';

// EVENTS
abstract class NoteEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadNotes extends NoteEvent {
  final String? status;
  final String? siteId;
  final String? searchQuery;

  LoadNotes({this.status, this.siteId, this.searchQuery});

  @override
  List<Object?> get props => [status, siteId, searchQuery];
}

class AddNote extends NoteEvent {
  final FieldNoteModel note;
  AddNote(this.note);

  @override
  List<Object?> get props => [note];
}

class UpdateNote extends NoteEvent {
  final FieldNoteModel note;
  UpdateNote(this.note);

  @override
  List<Object?> get props => [note];
}

class DeleteNote extends NoteEvent {
  final String id;
  DeleteNote(this.id);

  @override
  List<Object?> get props => [id];
}

// STATES
abstract class NoteState extends Equatable {
  @override
  List<Object?> get props => [];
}

class NoteInitial extends NoteState {}

class NoteLoading extends NoteState {}

class NoteLoaded extends NoteState {
  final List<FieldNoteModel> notes;
  final String? currentStatusFilter;
  final String? currentSiteFilter;
  final String? currentSearchQuery;

  NoteLoaded({
    required this.notes,
    this.currentStatusFilter,
    this.currentSiteFilter,
    this.currentSearchQuery,
  });

  @override
  List<Object?> get props => [notes, currentStatusFilter, currentSiteFilter, currentSearchQuery];
}

class NoteOperationFailure extends NoteState {
  final String error;
  NoteOperationFailure(this.error);

  @override
  List<Object?> get props => [error];
}

// BLOC
class NoteBloc extends Bloc<NoteEvent, NoteState> {
  final DatabaseService _db = DatabaseService.instance;
  final SyncService _sync = SyncService.instance;

  String? _lastStatus;
  String? _lastSiteId;
  String? _lastQuery;

  NoteBloc() : super(NoteInitial()) {
    on<LoadNotes>(_onLoadNotes);
    on<AddNote>(_onAddNote);
    on<UpdateNote>(_onUpdateNote);
    on<DeleteNote>(_onDeleteNote);
  }

  Future<void> _onLoadNotes(LoadNotes event, Emitter<NoteState> emit) async {
    if (state is! NoteLoaded) {
      emit(NoteLoading());
    }
    try {
      _lastStatus = event.status;
      _lastSiteId = event.siteId;
      _lastQuery = event.searchQuery;

      final notes = await _db.getNotes(
        status: event.status,
        siteId: event.siteId,
        searchQuery: event.searchQuery,
      );

      emit(NoteLoaded(
        notes: notes,
        currentStatusFilter: event.status,
        currentSiteFilter: event.siteId,
        currentSearchQuery: event.searchQuery,
      ));
    } catch (e) {
      emit(NoteOperationFailure(e.toString()));
    }
  }

  Future<void> _onAddNote(AddNote event, Emitter<NoteState> emit) async {
    try {
      await _db.saveNote(event.note);
      _sync.performSync(); // background sync

      final updatedList = await _db.getNotes(
        status: _lastStatus,
        siteId: _lastSiteId,
        searchQuery: _lastQuery,
      );

      emit(NoteLoaded(
        notes: updatedList,
        currentStatusFilter: _lastStatus,
        currentSiteFilter: _lastSiteId,
        currentSearchQuery: _lastQuery,
      ));
    } catch (e) {
      emit(NoteOperationFailure(e.toString()));
    }
  }

  Future<void> _onUpdateNote(UpdateNote event, Emitter<NoteState> emit) async {
    try {
      final updated = event.note.copyWith(
        updatedAt: DateTime.now(),
        isSynced: false,
      );
      await _db.saveNote(updated);
      _sync.performSync(); // background sync

      final updatedList = await _db.getNotes(
        status: _lastStatus,
        siteId: _lastSiteId,
        searchQuery: _lastQuery,
      );

      emit(NoteLoaded(
        notes: updatedList,
        currentStatusFilter: _lastStatus,
        currentSiteFilter: _lastSiteId,
        currentSearchQuery: _lastQuery,
      ));
    } catch (e) {
      emit(NoteOperationFailure(e.toString()));
    }
  }

  Future<void> _onDeleteNote(DeleteNote event, Emitter<NoteState> emit) async {
    try {
      await _db.softDeleteNote(event.id);
      _sync.performSync(); // background sync

      final updatedList = await _db.getNotes(
        status: _lastStatus,
        siteId: _lastSiteId,
        searchQuery: _lastQuery,
      );

      emit(NoteLoaded(
        notes: updatedList,
        currentStatusFilter: _lastStatus,
        currentSiteFilter: _lastSiteId,
        currentSearchQuery: _lastQuery,
      ));
    } catch (e) {
      emit(NoteOperationFailure(e.toString()));
    }
  }
}
