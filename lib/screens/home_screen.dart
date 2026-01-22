import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:urbanreport/models/report.dart';
import 'package:urbanreport/providers/auth_provider.dart';
import 'package:urbanreport/providers/report_provider.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onCreateReport;
  final Function(Report) onViewReport;
  final VoidCallback onLogout;

  const HomeScreen({
    Key? key,
    required this.onCreateReport,
    required this.onViewReport,
    required this.onLogout,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  double _mapZoom = 13.0;
  bool _showReportsList = false;

  @override
  void initState() {
    super.initState();
    // Cargar reportes al abrir la pantalla
    Future.microtask(() {
      context.read<ReportProvider>().fetchAllReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UrbanReport - Mapa'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              setState(() => _showReportsList = !_showReportsList);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().signout();
              widget.onLogout();
            },
          ),
        ],
      ),
      body: Consumer<ReportProvider>(
        builder: (context, reportProvider, _) {
          return Stack(
            children: [
              // Mapa
              _buildMap(reportProvider.allReports),

              // FAB para crear reporte
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  onPressed: widget.onCreateReport,
                  child: const Icon(Icons.add_location),
                ),
              ),

              // Panel de lista de reportes (si está activo)
              if (_showReportsList)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildReportsList(reportProvider.allReports),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap(List<Report> reports) {
    // Coordenadas predeterminadas (ejemplo: San Francisco)
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(37.7749, -122.4194),
        initialZoom: _mapZoom,
        onPositionChanged: (position, hasGesture) {
          _mapZoom = position.zoom ?? _mapZoom;
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.urbanreport.app',
          maxZoom: 19.0,
        ),
        MarkerLayer(
          markers: _buildMarkers(reports),
        ),
      ],
    );
  }

  List<Marker> _buildMarkers(List<Report> reports) {
    return reports
        .map((report) => Marker(
              point: LatLng(report.latitud, report.longitud),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => widget.onViewReport(report),
                child: Container(
                  decoration: BoxDecoration(
                    color: _getCategoryColor(report.categoria),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _getCategoryIcon(report.categoria),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ))
        .toList();
  }

  Widget _buildReportsList(List<Report> reports) {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            width: 40,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: reports.isEmpty
                ? const Center(
                    child: Text('No hay reportes disponibles'),
                  )
                : ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(report.categoria),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              _getCategoryIcon(report.categoria),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        title: Text(report.titulo),
                        subtitle: Text(report.getStatusDisplay()),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => widget.onViewReport(report),
                      );
                    },
                  ),
          ),
        ],
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

  IconData _getCategoryIcon(ReportCategory category) {
    switch (category) {
      case ReportCategory.bache:
        return Icons.warning;
      case ReportCategory.luminaria:
        return Icons.lightbulb;
      case ReportCategory.basura:
        return Icons.delete;
      case ReportCategory.alcantarilla:
        return Icons.water;
      case ReportCategory.otro:
        return Icons.info;
    }
  }
}
