import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fieldnotes_app/blocs/customer_bloc.dart';
import 'package:fieldnotes_app/blocs/site_bloc.dart';
import 'package:fieldnotes_app/blocs/note_bloc.dart';
import 'package:fieldnotes_app/models/customer_model.dart';
import 'package:fieldnotes_app/models/site_model.dart';
import 'package:fieldnotes_app/screens/customers/customer_form_screen.dart';
import 'package:fieldnotes_app/screens/sites/site_form_screen.dart';
import 'package:fieldnotes_app/screens/notes/note_form_screen.dart';

void main() {
  group('CustomerFormScreen Validation & Edit Tests', () {
    testWidgets('Empty customer name displays validation error', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: BlocProvider<CustomerBloc>(
          create: (_) => CustomerBloc(),
          child: const CustomerFormScreen(),
        ),
      ));

      // Attempt to save with empty name
      final saveButton = find.byIcon(Icons.check);
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pump();

      // Validator should show required error message
      expect(find.text('Customer name is required'), findsOneWidget);
    });

    testWidgets('Editing existing customer pre-populates text fields', (WidgetTester tester) async {
      final existingCustomer = CustomerModel(
        id: 'cust-exist',
        name: 'Square Pharmaceuticals',
        contactInformation: 'contact@square.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: BlocProvider<CustomerBloc>(
          create: (_) => CustomerBloc(),
          child: CustomerFormScreen(customer: existingCustomer),
        ),
      ));

      expect(find.text('Square Pharmaceuticals'), findsOneWidget);
      expect(find.text('contact@square.com'), findsOneWidget);
      expect(find.text('Edit Customer'), findsOneWidget);
    });
  });

  group('SiteFormScreen Hierarchy & Validation Tests', () {
    testWidgets('SiteFormScreen displays warning when no customers exist', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<CustomerBloc>(create: (_) => CustomerBloc()),
            BlocProvider<SiteBloc>(create: (_) => SiteBloc()),
          ],
          child: const SiteFormScreen(),
        ),
      ));

      await tester.pump();
      expect(find.text('You must add at least one customer before creating a site.'), findsOneWidget);
    });

    testWidgets('Editing existing site pre-populates site form', (WidgetTester tester) async {
      final existingSite = SiteModel(
        id: 's-edit',
        name: 'Mirpur Data Center',
        address: 'Section 10, Mirpur',
        customerId: 'cust-1',
        customerName: 'Square Pharmaceuticals',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<CustomerBloc>(create: (_) => CustomerBloc()),
            BlocProvider<SiteBloc>(create: (_) => SiteBloc()),
          ],
          child: SiteFormScreen(site: existingSite),
        ),
      ));

      await tester.pump();
      expect(find.text('Edit Site'), findsOneWidget);
    });
  });

  group('NoteFormScreen Hierarchy & Warning Tests', () {
    testWidgets('NoteFormScreen displays warning when no sites exist', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<SiteBloc>(create: (_) => SiteBloc()),
            BlocProvider<NoteBloc>(create: (_) => NoteBloc()),
          ],
          child: const NoteFormScreen(),
        ),
      ));

      await tester.pump();
      expect(find.text('You must add at least one site before creating notes.'), findsOneWidget);
    });
  });
}
