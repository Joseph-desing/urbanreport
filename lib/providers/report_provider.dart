import 'dart:io';
import 'package:flutter/material.dart';
import 'package:urbanreport/models/report.dart';
import 'package:urbanreport/services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _reportService = ReportService();

  List<Report> _allReports = [];
  List<Report> _userReports = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Report> get allReports => _allReports;
  List<Report> get userReports => _userReports;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Crear reporte
  Future<Report> createReport({
    required String usuarioId,
    required String titulo,
    required String descripcion,
    required ReportCategory categoria,
    required double latitud,
    required double longitud,
    File? imageFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final report = await _reportService.createReport(
        usuarioId: usuarioId,
        titulo: titulo,
        descripcion: descripcion,
        categoria: categoria,
        latitud: latitud,
        longitud: longitud,
        imageFile: imageFile,
      );

      _allReports.insert(0, report);
      _userReports.insert(0, report);

      return report;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Obtener todos los reportes
  Future<void> fetchAllReports() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allReports = await _reportService.getAllReports();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Obtener reportes del usuario
  Future<void> fetchUserReports({required String usuarioId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userReports = await _reportService.getUserReports(usuarioId: usuarioId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Obtener reporte por ID
  Future<Report> getReportById({required String reportId}) async {
    try {
      return await _reportService.getReportById(reportId: reportId);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  // Actualizar reporte
  Future<void> updateReport({
    required String reportId,
    String? titulo,
    String? descripcion,
    ReportStatus? estado,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedReport = await _reportService.updateReport(
        reportId: reportId,
        titulo: titulo,
        descripcion: descripcion,
        estado: estado,
      );

      // Actualizar en listas locales
      final index = _allReports.indexWhere((r) => r.id == reportId);
      if (index != -1) {
        _allReports[index] = updatedReport;
      }

      final userIndex = _userReports.indexWhere((r) => r.id == reportId);
      if (userIndex != -1) {
        _userReports[userIndex] = updatedReport;
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Eliminar reporte
  Future<void> deleteReport({required String reportId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reportService.deleteReport(reportId: reportId);

      _allReports.removeWhere((r) => r.id == reportId);
      _userReports.removeWhere((r) => r.id == reportId);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Obtener reportes cercanos
  Future<List<Report>> getNearbyReports({
    required double latitud,
    required double longitud,
    required double radiusKm,
  }) async {
    try {
      return await _reportService.getNearbyReports(
        latitud: latitud,
        longitud: longitud,
        radiusKm: radiusKm,
      );
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  // Limpiar error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
