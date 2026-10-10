import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/customer_bloc.dart';
import '../../blocs/site_bloc.dart';
import '../../models/customer_model.dart';
import '../../models/site_model.dart';

class SiteFormScreen extends StatefulWidget {
  final SiteModel? site;
  final String? initialCustomerId;

  const SiteFormScreen({super.key, this.site, this.initialCustomerId});

  @override
  State<SiteFormScreen> createState() => _SiteFormScreenState();
}

class _SiteFormScreenState extends State<SiteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  String? _selectedCustomerId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.site?.name ?? '');
    _addressController = TextEditingController(text: widget.site?.address ?? '');
    _selectedCustomerId = widget.site?.customerId ?? widget.initialCustomerId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _save(List<CustomerModel> customers) {
    if (_formKey.currentState!.validate()) {
      if (_selectedCustomerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a customer')),
        );
        return;
      }

      final name = _nameController.text.trim();
      final address = _addressController.text.trim();
      final customer = customers.firstWhere((c) => c.id == _selectedCustomerId);

      if (widget.site == null) {
        context.read<SiteBloc>().add(
              AddSite(
                name: name,
                address: address,
                customerId: _selectedCustomerId!,
                customerName: customer.name,
              ),
            );
      } else {
        context.read<SiteBloc>().add(
              UpdateSite(
                widget.site!.copyWith(
                  name: name,
                  address: address,
                  customerId: _selectedCustomerId!,
                  customerName: customer.name,
                ),
              ),
            );
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.site != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Site' : 'Add Site'),
      ),
      body: BlocBuilder<CustomerBloc, CustomerState>(
        builder: (context, custState) {
          final customers = custState is CustomerLoaded ? custState.customers : <CustomerModel>[];

          if (customers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 54, color: Colors.orange),
                    const SizedBox(height: 12),
                    const Text(
                      'You must add at least one customer before creating a site.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (_selectedCustomerId == null && customers.isNotEmpty) {
            _selectedCustomerId = customers.first.id;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedCustomerId,
                    decoration: const InputDecoration(
                      labelText: 'Customer *',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                    items: customers.map((c) {
                      return DropdownMenuItem<String>(
                        value: c.id,
                        child: Text(c.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCustomerId = val;
                      });
                    },
                    validator: (val) => val == null ? 'Customer is required' : null,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Site Name *',
                      prefixIcon: Icon(Icons.location_city),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Site name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Site Address *',
                      prefixIcon: Icon(Icons.place_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Site address is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _save(customers),
                    icon: const Icon(Icons.save),
                    label: Text(isEditing ? 'Update Site' : 'Save Site'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
