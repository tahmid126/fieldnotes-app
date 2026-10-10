import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../blocs/note_bloc.dart';
import '../../blocs/site_bloc.dart';
import '../../core/constants.dart';
import '../../models/field_note_model.dart';
import '../../models/site_model.dart';

class NoteFormScreen extends StatefulWidget {
  final FieldNoteModel? note;
  final String? initialSiteId;

  const NoteFormScreen({super.key, this.note, this.initialSiteId});

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _locationController;

  String? _selectedSiteId;
  String _selectedStatus = 'DRAFT';
  DateTime _selectedDateTime = DateTime.now();
  double? _latitude;
  double? _longitude;

  File? _imageFile;
  String? _existingPhotoUrl;
  bool _isGettingLocation = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final n = widget.note;

    _titleController = TextEditingController(text: n?.title ?? '');
    _descController = TextEditingController(text: n?.description ?? '');
    _locationController = TextEditingController(text: n?.location ?? '');

    _selectedSiteId = n?.siteId ?? widget.initialSiteId;
    _latitude = n?.latitude;
    _longitude = n?.longitude;
    _existingPhotoUrl = n?.photoUrl;

    if (n != null) {
      _selectedStatus = n.status;
      _selectedDateTime = n.noteDateTime;
    } else {
      _loadDefaultStatus();
    }
  }

  Future<void> _loadDefaultStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultStatus = prefs.getString(AppConstants.defaultNoteStatusKey);
    if (defaultStatus != null && mounted) {
      setState(() {
        _selectedStatus = defaultStatus;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1024,
      );
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
          _existingPhotoUrl = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled on device';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied';
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        if (_locationController.text.isEmpty) {
          _locationController.text =
              'GPS: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location acquired successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('GPS Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _save(List<SiteModel> sites) {
    if (_formKey.currentState!.validate()) {
      if (_selectedSiteId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a site')),
        );
        return;
      }

      final site = sites.firstWhere((s) => s.id == _selectedSiteId);
      final photoPath = _imageFile?.path ?? _existingPhotoUrl;

      if (widget.note == null) {
        final newNote = FieldNoteModel(
          id: const Uuid().v4(),
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          location: _locationController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          noteDateTime: _selectedDateTime,
          status: _selectedStatus,
          photoUrl: photoPath,
          siteId: _selectedSiteId!,
          siteName: site.name,
          customerId: site.customerId,
          customerName: site.customerName,
          deleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: false,
        );
        context.read<NoteBloc>().add(AddNote(newNote));
      } else {
        final updatedNote = widget.note!.copyWith(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          location: _locationController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          noteDateTime: _selectedDateTime,
          status: _selectedStatus,
          photoUrl: photoPath,
          siteId: _selectedSiteId!,
          siteName: site.name,
          customerId: site.customerId,
          customerName: site.customerName,
          updatedAt: DateTime.now(),
          isSynced: false,
        );
        context.read<NoteBloc>().add(UpdateNote(updatedNote));
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Field Note' : 'New Field Note'),
      ),
      body: BlocBuilder<SiteBloc, SiteState>(
        builder: (context, siteState) {
          final sites = siteState is SiteLoaded ? siteState.sites : <SiteModel>[];

          if (sites.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 54, color: Colors.orange),
                    const SizedBox(height: 12),
                    const Text(
                      'You must add at least one site before creating notes.',
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

          if (_selectedSiteId == null && sites.isNotEmpty) {
            _selectedSiteId = sites.first.id;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Site Selector
                  DropdownButtonFormField<String>(
                    value: _selectedSiteId,
                    decoration: const InputDecoration(
                      labelText: 'Site *',
                      prefixIcon: Icon(Icons.location_city),
                      border: OutlineInputBorder(),
                    ),
                    items: sites.map((s) {
                      return DropdownMenuItem<String>(
                        value: s.id,
                        child: Text('${s.name} (${s.customerName ?? ""})'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedSiteId = val),
                    validator: (val) => val == null ? 'Site is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      prefixIcon: Icon(Icons.title),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Status Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status *',
                      prefixIcon: Icon(Icons.flag_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: AppConstants.noteStatuses.map((st) {
                      return DropdownMenuItem(
                        value: st,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppConstants.getStatusColor(st),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(st),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatus = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date & Time Row
                  InkWell(
                    onTap: _pickDateTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date & Time',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        DateFormat('yyyy-MM-dd  hh:mm a').format(_selectedDateTime),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.description_outlined),
                      ),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Location
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Location / Address',
                            prefixIcon: Icon(Icons.place),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: _isGettingLocation ? null : _getCurrentLocation,
                        icon: _isGettingLocation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location),
                        tooltip: 'Capture GPS Location',
                      ),
                    ],
                  ),
                  if (_latitude != null && _longitude != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        'Coords: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Photo Section
                  const Text(
                    'Optional Photo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  if (_imageFile != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _imageFile!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        PositionAction(onDelete: () => setState(() => _imageFile = null)),
                      ],
                    )
                  else if (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _existingPhotoUrl!.startsWith('http')
                              ? Image.network(
                                  _existingPhotoUrl!,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_existingPhotoUrl!),
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 100,
                                    color: Colors.grey[200],
                                    child: const Center(child: Text('Image file saved')),
                                  ),
                                ),
                        ),
                        PositionAction(
                          onDelete: () => setState(() => _existingPhotoUrl = null),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 28),

                  ElevatedButton.icon(
                    onPressed: () => _save(sites),
                    icon: const Icon(Icons.save),
                    label: Text(isEditing ? 'Update Note' : 'Save Field Note'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
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

class PositionAction extends StatelessWidget {
  final VoidCallback onDelete;
  const PositionAction({super.key, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: CircleAvatar(
        backgroundColor: Colors.black54,
        child: IconButton(
          icon: const Icon(Icons.delete, color: Colors.white),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
