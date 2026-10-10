import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../models/customer_model.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';

// EVENTS
abstract class CustomerEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadCustomers extends CustomerEvent {}

class AddCustomer extends CustomerEvent {
  final String name;
  final String? contactInformation;
  AddCustomer(this.name, this.contactInformation);

  @override
  List<Object?> get props => [name, contactInformation];
}

class UpdateCustomer extends CustomerEvent {
  final CustomerModel customer;
  UpdateCustomer(this.customer);

  @override
  List<Object?> get props => [customer];
}

class DeleteCustomer extends CustomerEvent {
  final String id;
  DeleteCustomer(this.id);

  @override
  List<Object?> get props => [id];
}

// STATES
abstract class CustomerState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerLoaded extends CustomerState {
  final List<CustomerModel> customers;
  CustomerLoaded(this.customers);

  @override
  List<Object?> get props => [customers];
}

class CustomerOperationFailure extends CustomerState {
  final String error;
  CustomerOperationFailure(this.error);

  @override
  List<Object?> get props => [error];
}

// BLOC
class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final DatabaseService _db = DatabaseService.instance;
  final SyncService _sync = SyncService.instance;

  CustomerBloc() : super(CustomerInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<AddCustomer>(_onAddCustomer);
    on<UpdateCustomer>(_onUpdateCustomer);
    on<DeleteCustomer>(_onDeleteCustomer);
  }

  Future<void> _onLoadCustomers(LoadCustomers event, Emitter<CustomerState> emit) async {
    emit(CustomerLoading());
    try {
      final customers = await _db.getCustomers();
      emit(CustomerLoaded(customers));
    } catch (e) {
      emit(CustomerOperationFailure(e.toString()));
    }
  }

  Future<void> _onAddCustomer(AddCustomer event, Emitter<CustomerState> emit) async {
    try {
      final now = DateTime.now();
      final newCustomer = CustomerModel(
        id: const Uuid().v4(),
        name: event.name.trim(),
        contactInformation: event.contactInformation?.trim(),
        deleted: false,
        createdAt: now,
        updatedAt: now,
        isSynced: false,
      );

      await _db.saveCustomer(newCustomer);
      _sync.performSync(); // background sync

      final updatedList = await _db.getCustomers();
      emit(CustomerLoaded(updatedList));
    } catch (e) {
      emit(CustomerOperationFailure(e.toString()));
    }
  }

  Future<void> _onUpdateCustomer(UpdateCustomer event, Emitter<CustomerState> emit) async {
    try {
      final updated = event.customer.copyWith(
        updatedAt: DateTime.now(),
        isSynced: false,
      );
      await _db.saveCustomer(updated);
      _sync.performSync(); // background sync

      final updatedList = await _db.getCustomers();
      emit(CustomerLoaded(updatedList));
    } catch (e) {
      emit(CustomerOperationFailure(e.toString()));
    }
  }

  Future<void> _onDeleteCustomer(DeleteCustomer event, Emitter<CustomerState> emit) async {
    try {
      await _db.softDeleteCustomer(event.id);
      _sync.performSync(); // background sync

      final updatedList = await _db.getCustomers();
      emit(CustomerLoaded(updatedList));
    } catch (e) {
      emit(CustomerOperationFailure(e.toString()));
    }
  }
}
