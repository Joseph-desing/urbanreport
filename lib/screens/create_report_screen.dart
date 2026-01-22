import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:urbanreport/models/report.dart';
import 'package:urbanreport/providers/auth_provider.dart';
import 'package:urbanreport/providers/report_provider.dart';

class CreateReportScreen extends StatefulWidget {
  final VoidCallback onReportCreated;

  const CreateReportScreen({
    Key? key,
    required this.onReportCreated,
  }) : super(key: key);

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final MapController _mapController = MapController();
  final ImagePicker _imagePicker = ImagePicker();

  ReportCategory? _selectedCategory;
  double _selectedLat = 37.7749;
  double _selectedLon = -122.4194;
  File? _selectedImage;
  bool _isLoading = false;
  bool _isGeolocating = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // Solicitar permiso de ubicación
  Future<void> _requestLocationPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permiso de ubicación denegado'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error de permiso: $e');
    }
  }

  // Obtener ubicación actual
  Future<void> _getCurrentLocation() async {
    setState(() => _isGeolocating = true);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedLat = position.latitude;
        _selectedLon = position.longitude;
      });

      // Actualizar mapa
      _mapController.move(
        LatLng(_selectedLat, _selectedLon),
        15.0,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ubicación actualizada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al obtener ubicación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeolocating = false);
    }
  }

  // Seleccionar imagen
  Future<void> _pickImage() async {
    try {
      final ImageSource source = kIsWeb ? ImageSource.gallery : ImageSource.camera;
      
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  // Crear reporte
  Future<void> _createReport() async {
    debugPrint('DEBUG: Iniciando creación de reporte...');
    debugPrint('DEBUG: Título: "${_titleController.text}" (${_titleController.text.length} chars)');
    debugPrint('DEBUG: Descripción: "${_descriptionController.text}" (${_descriptionController.text.length} chars)');
    debugPrint('DEBUG: Categoría: $_selectedCategory');
    
    if (!_formKey.currentState!.validate()) {
      debugPrint('DEBUG: ❌ Validación del formulario falló');
      debugPrint('DEBUG: Título vacío: ${_titleController.text.isEmpty}');
      debugPrint('DEBUG: Descripción vacía: ${_descriptionController.text.isEmpty}');
      return;
    }
    
    if (_selectedCategory == null) {
      debugPrint('DEBUG: ❌ Categoría no seleccionada');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una categoría')),
      );
      return;
    }

    debugPrint('DEBUG: ✓ Validación pasada, iniciando creación...');

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final reportProvider = context.read<ReportProvider>();

      if (authProvider.currentUser == null) {
        debugPrint('DEBUG: ❌ Usuario no autenticado');
        throw Exception('Usuario no autenticado');
      }

      debugPrint('DEBUG: Usuario ID: ${authProvider.currentUser!.id}');
      
      await reportProvider.createReport(
        usuarioId: authProvider.currentUser!.id,
        titulo: _titleController.text.trim(),
        descripcion: _descriptionController.text.trim(),
        categoria: _selectedCategory!,
        latitud: _selectedLat,
        longitud: _selectedLon,
        imageFile: _selectedImage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Reporte creado exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );

        widget.onReportCreated();
      }
    } catch (e) {
      debugPrint('DEBUG: ❌ Error creando reporte: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Reporte'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Título
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Título del problema',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa un título';
                    }
                    if (value.length < 5) {
                      return 'El título debe tener al menos 5 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Descripción
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción detallada',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa una descripción';
                    }
                    if (value.length < 10) {
                      return 'La descripción debe tener al menos 10 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Categoría
                DropdownButtonFormField<ReportCategory>(
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  value: _selectedCategory,
                  items: ReportCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(_getCategoryName(category)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Por favor selecciona una categoría';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Sección de ubicación
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Ubicación del problema',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Mapa
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter:
                                  LatLng(_selectedLat, _selectedLon),
                              initialZoom: 15.0,
                              onTap: (tapPosition, point) {
                                setState(() {
                                  _selectedLat = point.latitude;
                                  _selectedLon = point.longitude;
                                });
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.urbanreport.app',
                                maxZoom: 19.0,
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point:
                                        LatLng(_selectedLat, _selectedLon),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Coordenadas
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Lat: ${_selectedLat.toStringAsFixed(4)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Lon: ${_selectedLon.toStringAsFixed(4)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Botón para obtener ubicación actual
                        ElevatedButton.icon(
                          onPressed: _isGeolocating ? null : _getCurrentLocation,
                          icon: _isGeolocating
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.location_searching),
                          label: const Text('Mi ubicación actual'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Sección de imagen
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Foto del problema',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_selectedImage != null)
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(_selectedImage!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CircleAvatar(
                                  backgroundColor: Colors.red,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() => _selectedImage = null);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey,
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: Text('Sin foto'),
                            ),
                          ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(kIsWeb ? 'Cargar foto' : 'Tomar foto'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Botón para crear reporte
                ElevatedButton(
                  onPressed: _isLoading ? null : _createReport,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Crear Reporte',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCategoryName(ReportCategory category) {
    switch (category) {
      case ReportCategory.bache:
        return 'Bache';
      case ReportCategory.luminaria:
        return 'Luminaria dañada';
      case ReportCategory.basura:
        return 'Acumulación de basura';
      case ReportCategory.alcantarilla:
        return 'Alcantarilla obstruida';
      case ReportCategory.otro:
        return 'Otro';
    }
  }
}
