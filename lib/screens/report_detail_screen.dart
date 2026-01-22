import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:urbanreport/models/report.dart';
import 'package:urbanreport/providers/auth_provider.dart';
import 'package:urbanreport/providers/report_provider.dart';

class ReportDetailScreen extends StatefulWidget {
  final Report report;
  final VoidCallback onReportUpdated;

  const ReportDetailScreen({
    Key? key,
    required this.report,
    required this.onReportUpdated,
  }) : super(key: key);

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  ReportStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.report.estado;
  }

  Future<void> _updateReportStatus(ReportStatus newStatus) async {
    setState(() => _selectedStatus = newStatus);

    try {
      await context.read<ReportProvider>().updateReport(
            reportId: widget.report.id,
            estado: newStatus,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Estado actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onReportUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteReport() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar reporte'),
        content: const Text('¿Estás seguro de que deseas eliminar este reporte?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<ReportProvider>().deleteReport(
              reportId: widget.report.id,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reporte eliminado'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  bool _isOwnReport() {
    final currentUser = context.read<AuthProvider>().currentUser;
    return currentUser?.id == widget.report.usuarioId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Reporte'),
        actions: [
          if (_isOwnReport())
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteReport,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Foto del reporte
            if (widget.report.fotoUrl != null && widget.report.fotoUrl!.isNotEmpty)
              Container(
                height: 300,
                color: Colors.grey[200],
                child: Image.network(
                  widget.report.fotoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image_not_supported, size: 50),
                          const SizedBox(height: 8),
                          const Text('Error al cargar la imagen'),
                          const SizedBox(height: 8),
                          Text(
                            'URL: ${widget.report.fotoUrl}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                ),
              )
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image_not_supported, size: 50),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoría y estado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _getCategoryColor(widget.report.categoria),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.report.getCategoryDisplay(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.report.estado),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.report.getStatusDisplay(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Título
                  Text(
                    widget.report.titulo,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Descripción
                  Text(
                    widget.report.descripcion,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Fecha
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(widget.report.createdAt),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Ubicación
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Lat: ${widget.report.latitud.toStringAsFixed(4)}, '
                        'Lon: ${widget.report.longitud.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Mapa
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          widget.report.latitud,
                          widget.report.longitud,
                        ),
                        initialZoom: 15.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.urbanreport.app',
                          maxZoom: 19.0,
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                widget.report.latitud,
                                widget.report.longitud,
                              ),
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
                  const SizedBox(height: 24),

                  // Cambiar estado (solo si es propio reporte)
                  if (_isOwnReport())
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Actualizar estado:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButton<ReportStatus>(
                          isExpanded: true,
                          value: _selectedStatus,
                          items: ReportStatus.values.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(_statusToString(status)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedStatus = value);
                              _updateReportStatus(value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(ReportCategory category) {
    switch (category) {
      case ReportCategory.bache:
        return Colors.orange;
      case ReportCategory.luminaria:
        return Colors.yellow;
      case ReportCategory.basura:
        return Colors.green;
      case ReportCategory.alcantarilla:
        return Colors.brown;
      case ReportCategory.otro:
        return Colors.grey;
    }
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pendiente:
        return Colors.red;
      case ReportStatus.en_proceso:
        return Colors.blue;
      case ReportStatus.resuelto:
        return Colors.green;
    }
  }

  String _statusToString(ReportStatus status) {
    switch (status) {
      case ReportStatus.pendiente:
        return 'Pendiente';
      case ReportStatus.en_proceso:
        return 'En proceso';
      case ReportStatus.resuelto:
        return 'Resuelto';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
