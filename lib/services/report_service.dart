import 'dart:io';
import 'dart:math' as Math;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urbanreport/config/supabase_config.dart';
import 'package:urbanreport/models/report.dart';

class ReportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Crear nuevo reporte
  Future<Report> createReport({
    required String usuarioId,
    required String titulo,
    required String descripcion,
    required ReportCategory categoria,
    required double latitud,
    required double longitud,
    File? imageFile,
  }) async {
    try {
      String? fotoUrl;

      // Subir imagen si existe (no en web)
      if (imageFile != null && !kIsWeb) {
        try {
          fotoUrl = await _uploadImage(imageFile, usuarioId);
          debugPrint('✓ Imagen subida: $fotoUrl');
        } catch (e) {
          debugPrint('⚠ Advertencia al subir imagen: $e');
          // Continuar sin imagen
        }
      }

      final reportData = {
        'usuario_id': usuarioId,
        'titulo': titulo,
        'descripcion': descripcion,
        'categoria': _categoryToString(categoria),
        'estado': _statusToString(ReportStatus.pendiente),
        'latitud': latitud,
        'longitud': longitud,
        'foto_url': fotoUrl,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from(SupabaseConfig.reportsTable)
          .insert(reportData)
          .select()
          .single();

      debugPrint('✓ Reporte creado exitosamente: ${response['id']}');
      return Report.fromJson(response);
    } catch (e) {
      debugPrint('✗ Error al crear reporte: $e');
      throw Exception('Error al crear reporte: $e');
    }
  }

  // Obtener todos los reportes
  Future<List<Report>> getAllReports() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.reportsTable)
          .select()
          .order('created_at', ascending: false);

      final reports = (response as List)
          .map((data) => Report.fromJson(data as Map<String, dynamic>))
          .toList();
      
      debugPrint('✓ Obtenidos ${reports.length} reportes de la BD');
      return reports;
    } catch (e) {
      debugPrint('✗ Error al obtener reportes: $e');
      throw Exception('Error al obtener reportes: $e');
    }
  }

  // Obtener reportes de un usuario
  Future<List<Report>> getUserReports({required String usuarioId}) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.reportsTable)
          .select()
          .eq('usuario_id', usuarioId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => Report.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener reportes del usuario: $e');
    }
  }

  // Obtener reporte por ID
  Future<Report> getReportById({required String reportId}) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.reportsTable)
          .select()
          .eq('id', reportId)
          .single();

      return Report.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener reporte: $e');
    }
  }

  // Actualizar reporte
  Future<Report> updateReport({
    required String reportId,
    String? titulo,
    String? descripcion,
    ReportStatus? estado,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (titulo != null) updateData['titulo'] = titulo;
      if (descripcion != null) updateData['descripcion'] = descripcion;
      if (estado != null) updateData['estado'] = _statusToString(estado);

      if (updateData.isEmpty) {
        throw Exception('No hay datos para actualizar');
      }

      final response = await _supabase
          .from(SupabaseConfig.reportsTable)
          .update(updateData)
          .eq('id', reportId)
          .select()
          .single();

      return Report.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar reporte: $e');
    }
  }

  // Eliminar reporte
  Future<void> deleteReport({required String reportId}) async {
    try {
      await _supabase
          .from(SupabaseConfig.reportsTable)
          .delete()
          .eq('id', reportId);
    } catch (e) {
      throw Exception('Error al eliminar reporte: $e');
    }
  }

  // Obtener reportes cercanos (dentro de un radio)
  Future<List<Report>> getNearbyReports({
    required double latitud,
    required double longitud,
    required double radiusKm,
  }) async {
    try {
      // Esta es una consulta simple. Para una mejor precisión,
      // considera usar funciones de Supabase PostGIS
      final allReports = await getAllReports();

      return allReports.where((report) {
        final distance = _calculateDistance(
          latitud,
          longitud,
          report.latitud,
          report.longitud,
        );
        return distance <= radiusKm;
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener reportes cercanos: $e');
    }
  }

  // Subir imagen a Supabase Storage
  Future<String> _uploadImage(File imageFile, String usuarioId) async {
    try {
      final fileName =
          '${usuarioId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '$usuarioId/$fileName';

      await _supabase.storage
          .from(SupabaseConfig.reportImagesBucket)
          .upload(filePath, imageFile);

      final publicUrl = _supabase.storage
          .from(SupabaseConfig.reportImagesBucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Error al subir imagen: $e');
    }
  }

  // Escuchar cambios en reportes en tiempo real
  // Nota: Implementación simplificada sin soporte realtime
  // Para realtime completo, usar PostgreSQL LISTEN
  Future<List<Report>> watchReports() async {
    return getAllReports();
  }

  // Helpers
  static String _categoryToString(ReportCategory category) {
    return category.toString().split('.').last;
  }

  static String _statusToString(ReportStatus status) {
    return status.toString().split('.').last;
  }

  // Calcular distancia entre dos coordenadas (Haversine formula)
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Radio en km
    final double dLat = _toRad(lat2 - lat1);
    final double dLon = _toRad(lon2 - lon1);

    final double a = (Math.sin(dLat / 2) * Math.sin(dLat / 2)) +
        (Math.cos(_toRad(lat1)) *
            Math.cos(_toRad(lat2)) *
            Math.sin(dLon / 2) *
            Math.sin(dLon / 2));

    final double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRad(double degree) {
    return degree * Math.pi / 180;
  }
}
