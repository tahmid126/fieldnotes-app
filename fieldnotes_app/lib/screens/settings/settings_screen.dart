import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../blocs/auth_bloc.dart';
import '../../blocs/customer_bloc.dart';
import '../../blocs/note_bloc.dart';
import '../../blocs/site_bloc.dart';
import '../../blocs/sync_bloc.dart';
import '../../core/constants.dart';
import '../../services/api_service.dart';
import '../../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _defaultNoteStatus = 'DRAFT';
  String? _userName;
  String? _userEmail;
  String? _lastSync;
  final _serverUrlController = TextEditingController();
  bool _isTestingConnection = false;
  String? _connectionTestResult;
  bool? _connectionTestSuccess;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString('custom_server_url') ?? '';
    final activeUrl = await ApiService.instance.getBaseUrl();
    setState(() {
      _defaultNoteStatus = prefs.getString(AppConstants.defaultNoteStatusKey) ?? 'DRAFT';
      _userName = prefs.getString(AppConstants.userNameKey);
      _userEmail = prefs.getString(AppConstants.userEmailKey);
      _lastSync = prefs.getString(AppConstants.lastSyncKey);
      _serverUrlController.text = customUrl.isNotEmpty ? customUrl : activeUrl;
    });
    _testConnection();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionTestResult = null;
    });

    final res = await ApiService.instance.testConnection();

    if (!mounted) return;
    setState(() {
      _isTestingConnection = false;
      _connectionTestSuccess = res['success'] as bool;
      _connectionTestResult = res['message'] as String;
    });
  }

  Future<void> _onStatusChanged(String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.defaultNoteStatusKey, newStatus);
    setState(() {
      _defaultNoteStatus = newStatus;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Default Note Status updated to "$newStatus"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final url = _serverUrlController.text.trim();
    if (url.isNotEmpty) {
      await prefs.setString('custom_server_url', url);
    } else {
      await prefs.remove('custom_server_url');
    }
    ApiService.instance.resetCachedBaseUrl();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Server URL updated')),
    );
    _testConnection();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: BlocListener<SyncBloc, SyncState>(
        listener: (context, state) {
          if (state is SyncSuccess) {
            _loadSettings();
            // Reload all local blocs
            context.read<CustomerBloc>().add(LoadCustomers());
            context.read<SiteBloc>().add(LoadSites());
            context.read<NoteBloc>().add(LoadNotes());

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is SyncFailure) {
            final isOffline = state.isOffline || state.error.toLowerCase().contains('offline');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      isOffline ? Icons.cloud_off : Icons.error_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(state.error)),
                  ],
                ),
                backgroundColor: isOffline ? Colors.blueGrey[800] : Colors.orange[800],
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // User Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.primaryColor,
                  child: Text(
                    (_userName != null && _userName!.isNotEmpty) ? _userName![0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  _userName ?? 'User',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(_userEmail ?? ''),
              ),
            ),
            const SizedBox(height: 16),

            // Mandatory requirement: Default Note Status
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune, color: theme.primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Default Note Status',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'This status will be automatically pre-selected when creating new field notes. Saved locally.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _defaultNoteStatus,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: AppConstants.noteStatuses.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppConstants.getStatusColor(s),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(s),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) _onStatusChanged(val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Offline Sync Management
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.sync, color: theme.primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Synchronization',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _lastSync != null
                          ? 'Last synchronized: ${_lastSync!.replaceAll("T", " ")}'
                          : 'Not synchronized yet',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 14),

                    BlocBuilder<SyncBloc, SyncState>(
                      builder: (context, state) {
                        final isSyncing = state is SyncInProgress;

                        return Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: isSyncing
                                  ? null
                                  : () {
                                      context.read<SyncBloc>().add(TriggerSync());
                                    },
                              icon: isSyncing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.sync),
                              label: const Text('Sync Now With Server'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: isSyncing
                                  ? null
                                  : () {
                                      _confirmRestore(context);
                                    },
                              icon: const Icon(Icons.cloud_download_outlined),
                              label: const Text('Restore All Data from Server'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: isSyncing
                                  ? null
                                  : () {
                                      _confirmClearLocalData(context);
                                    },
                              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                              label: const Text('Clear Local Offline Data', style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                side: const BorderSide(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Server Config (Custom IP for physical device testing)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.dns_outlined, color: theme.primaryColor),
                            const SizedBox(width: 8),
                            const Text(
                              'Server Connection',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        if (_isTestingConnection)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else if (_connectionTestSuccess != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _connectionTestSuccess!
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _connectionTestSuccess! ? Colors.green : Colors.red,
                              ),
                            ),
                            child: Text(
                              _connectionTestSuccess! ? 'ONLINE' : 'OFFLINE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _connectionTestSuccess! ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _connectionTestResult != null
                          ? 'Status: $_connectionTestResult'
                          : 'Configure server endpoint to sync data',
                      style: TextStyle(
                        fontSize: 12,
                        color: _connectionTestSuccess == false ? Colors.red : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _serverUrlController,
                            decoration: const InputDecoration(
                              labelText: 'Base API URL',
                              hintText: 'http://localhost:8080/api',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: _saveServerUrl,
                          tooltip: 'Save URL',
                          icon: const Icon(Icons.save),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isTestingConnection ? null : _testConnection,
                            icon: const Icon(Icons.network_check, size: 16),
                            label: const Text('Test Connection', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton(
                          onPressed: () {
                            _serverUrlController.clear();
                            _saveServerUrl();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          child: const Text('Auto', style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton(
                          onPressed: () {
                            _serverUrlController.text = 'http://localhost:8080/api';
                            _saveServerUrl();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          child: const Text('USB', style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton(
                          onPressed: () {
                            _serverUrlController.text = 'http://192.168.10.99:8080/api';
                            _saveServerUrl();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          child: const Text('Wi-Fi', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            OutlinedButton.icon(
              onPressed: () {
                context.read<AuthBloc>().add(AuthLogoutRequested());
                context.read<CustomerBloc>().add(LoadCustomers());
                context.read<SiteBloc>().add(LoadSites());
                context.read<NoteBloc>().add(LoadNotes());
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Log Out', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRestore(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Data'),
        content: const Text(
          'This will pull all fresh data from the server. Unsynced local changes might be replaced.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<SyncBloc>().add(RestoreData());
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _confirmClearLocalData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Local Offline Data'),
        content: const Text(
          'This will delete all locally cached customers, sites, and notes on this device. Any synced data remains safe on the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await DatabaseService.instance.clearAll();
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove(AppConstants.lastSyncKey);
              if (!context.mounted) return;
              context.read<CustomerBloc>().add(LoadCustomers());
              context.read<SiteBloc>().add(LoadSites());
              context.read<NoteBloc>().add(LoadNotes());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Local offline data cleared successfully')),
              );
            },
            child: const Text('Clear Data', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
