import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/customer_bloc.dart';
import '../../blocs/note_bloc.dart';
import '../../blocs/site_bloc.dart';
import '../../blocs/sync_bloc.dart';
import '../customers/customers_screen.dart';
import '../notes/notes_screen.dart';
import '../settings/settings_screen.dart';
import '../sites/sites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    NotesScreen(),
    CustomersScreen(),
    SitesScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Load initial data for all blocs
    context.read<CustomerBloc>().add(LoadCustomers());
    context.read<SiteBloc>().add(LoadSites());
    context.read<NoteBloc>().add(LoadNotes());
    // Auto-sync in background on app start
    context.read<SyncBloc>().add(TriggerSync());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<SyncBloc, SyncState>(
        listener: (context, state) {
          if (state is SyncSuccess) {
            context.read<CustomerBloc>().add(LoadCustomers());
            context.read<SiteBloc>().add(LoadSites());
            context.read<NoteBloc>().add(LoadNotes());
          }
        },
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() {
            _currentIndex = idx;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.place_outlined),
            selectedIcon: Icon(Icons.place),
            label: 'Sites',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
