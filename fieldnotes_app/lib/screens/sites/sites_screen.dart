import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/site_bloc.dart';
import '../../models/site_model.dart';
import '../notes/notes_screen.dart';
import 'site_form_screen.dart';

class SitesScreen extends StatefulWidget {
  final String? filterCustomerId;
  final String? customerName;

  const SitesScreen({
    super.key,
    this.filterCustomerId,
    this.customerName,
  });

  @override
  State<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends State<SitesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SiteBloc>().add(LoadSites(customerId: widget.filterCustomerId));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.customerName != null
        ? 'Sites: ${widget.customerName}'
        : 'All Sites';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: BlocBuilder<SiteBloc, SiteState>(
        builder: (context, state) {
          if (state is SiteLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SiteOperationFailure) {
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
                    onPressed: () => context.read<SiteBloc>().add(LoadSites(customerId: widget.filterCustomerId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is SiteLoaded) {
            final sites = state.sites;

            if (sites.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.place_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No sites found',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SiteFormScreen(
                              initialCustomerId: widget.filterCustomerId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Site'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<SiteBloc>().add(LoadSites(customerId: widget.filterCustomerId));
              },
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: sites.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final site = sites[index];
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.withValues(alpha: 0.15),
                        child: const Icon(Icons.location_on, color: Colors.teal),
                      ),
                      title: Text(
                        site.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(site.address),
                          if (site.customerName != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Customer: ${site.customerName}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blueGrey[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                site.isSynced ? Icons.cloud_done : Icons.cloud_queue,
                                size: 14,
                                color: site.isSynced ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                site.isSynced ? 'Synced' : 'Pending sync',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: site.isSynced ? Colors.green : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'notes') {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => NotesScreen(
                                  filterSiteId: site.id,
                                  siteName: site.name,
                                ),
                              ),
                            );
                          } else if (value == 'edit') {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SiteFormScreen(site: site),
                              ),
                            );
                          } else if (value == 'delete') {
                            _confirmDelete(context, site);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'notes',
                            child: Row(
                              children: [
                                Icon(Icons.description, size: 20),
                                SizedBox(width: 8),
                                Text('View Notes'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        // Open Notes for this site
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => NotesScreen(
                              filterSiteId: site.id,
                              siteName: site.name,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_site',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SiteFormScreen(
                initialCustomerId: widget.filterCustomerId,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, SiteModel site) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Site'),
        content: Text('Are you sure you want to delete "${site.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<SiteBloc>().add(DeleteSite(site.id));
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
