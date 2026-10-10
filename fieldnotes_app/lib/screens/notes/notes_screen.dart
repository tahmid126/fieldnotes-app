import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/note_bloc.dart';
import '../../blocs/sync_bloc.dart';
import '../../core/constants.dart';
import '../../models/field_note_model.dart';
import 'note_form_screen.dart';

class NotesScreen extends StatefulWidget {
  final String? filterSiteId;
  final String? siteName;

  const NotesScreen({
    super.key,
    this.filterSiteId,
    this.siteName,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _searchController = TextEditingController();
  String _selectedStatusFilter = 'ALL';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _triggerLoad();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    setState(() {}); // Update clear icon visibility
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      _triggerLoad();
    });
  }

  void _triggerLoad() {
    context.read<NoteBloc>().add(
          LoadNotes(
            status: _selectedStatusFilter == 'ALL' ? null : _selectedStatusFilter,
            siteId: widget.filterSiteId,
            searchQuery: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.siteName != null ? 'Notes: ${widget.siteName}' : 'Field Notes';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Builder(
            builder: (ctx) {
              SyncBloc? syncBloc;
              try {
                syncBloc = ctx.read<SyncBloc>();
              } catch (_) {}
              if (syncBloc == null) return const SizedBox.shrink();
              return BlocBuilder<SyncBloc, SyncState>(
                builder: (context, syncState) {
                  if (syncState is SyncInProgress) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                      ),
                    );
                  }

                  final isOffline = syncState is SyncFailure &&
                      (syncState.isOffline || syncState.error.toLowerCase().contains('offline'));

                  return IconButton(
                    tooltip: isOffline ? 'Offline Mode (Tap to sync)' : 'Sync with Server',
                    icon: Icon(
                      isOffline ? Icons.cloud_off : Icons.sync,
                      color: isOffline ? Colors.amberAccent : null,
                    ),
                    onPressed: () {
                      context.read<SyncBloc>().add(TriggerSync());
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search title, description, site, customer, location...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                              _triggerLoad();
                            },
                          )
                        : null,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 8),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', 'All'),
                      const SizedBox(width: 6),
                      _buildFilterChip('DRAFT', 'Draft'),
                      const SizedBox(width: 6),
                      _buildFilterChip('IN_PROGRESS', 'In Progress'),
                      const SizedBox(width: 6),
                      _buildFilterChip('COMPLETED', 'Completed'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Notes List
          Expanded(
            child: BlocBuilder<NoteBloc, NoteState>(
              builder: (context, state) {
                if (state is NoteLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is NoteOperationFailure) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(state.error, textAlign: TextAlign.center),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _triggerLoad(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is NoteLoaded) {
                  final notes = state.notes;

                  if (notes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notes_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'No field notes found',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => NoteFormScreen(
                                    initialSiteId: widget.filterSiteId,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create Field Note'),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _triggerLoad(),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: notes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return _buildNoteCard(note);
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_note',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NoteFormScreen(
                initialSiteId: widget.filterSiteId,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String statusKey, String label) {
    final isSelected = _selectedStatusFilter == statusKey;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        setState(() {
          _selectedStatusFilter = statusKey;
        });
        _triggerLoad();
      },
    );
  }

  Widget _buildNoteCard(FieldNoteModel note) {
    final statusColor = AppConstants.getStatusColor(note.status);
    final dateFormatted = DateFormat('MMM dd, yyyy • hh:mm a').format(note.noteDateTime);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NoteFormScreen(note: note),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title and Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor, width: 0.8),
                    ),
                    child: Text(
                      note.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Site and Customer info
              if (note.siteName != null || note.customerName != null)
                Row(
                  children: [
                    const Icon(Icons.location_city, size: 14, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${note.siteName ?? "Site"} (${note.customerName ?? "Customer"})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.blueGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 6),

              // Description preview
              if (note.description != null && note.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    note.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[800], fontSize: 13),
                  ),
                ),

              // Photo thumbnail if exists
              if (note.photoUrl != null && note.photoUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: note.photoUrl!.startsWith('http')
                        ? Image.network(
                            note.photoUrl!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(note.photoUrl!),
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                  ),
                ),

              // Footer: Location & Date & Sync status
              const Divider(height: 14),
              Row(
                children: [
                  if (note.location != null && note.location!.isNotEmpty) ...[
                    const Icon(Icons.place, size: 14, color: Colors.grey),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        note.location!,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Spacer(),

                  Text(
                    dateFormatted,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),

                  Icon(
                    note.isSynced ? Icons.cloud_done : Icons.cloud_queue,
                    size: 16,
                    color: note.isSynced ? Colors.green : Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
