import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app_sorteio_cliente/model/sorteio.dart';

class SorteioService {
  // Firebase URL
  final String url = "https://applespace-a00ab-default-rtdb.firebaseio.com/sorteio";
  
  // Cache for sorteio data
  Sorteio? _cachedSorteio;
  DateTime? _lastFetchTime;
  
  // Cache expiration time (15 minutes)
  static const Duration cacheExpiration = Duration(minutes: 15);
  
  // Load sorteios with caching
  Future<Sorteio?> carregarSorteios({bool forceRefresh = false}) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _cachedSorteio != null && _lastFetchTime != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceLastFetch < cacheExpiration) {
        debugPrint("Using cached sorteio data");
        return _cachedSorteio;
      }
    }
    
    // Fetch fresh data
    Sorteio? sorteio;
    try {
      debugPrint("Fetching fresh sorteio data from Firebase");
      
      // Add cache busting parameter to avoid HTTP caching
      final fetchUrl = "$url.json?cacheBust=${DateTime.now().millisecondsSinceEpoch}";
      final resp = await http.get(Uri.parse(fetchUrl));
      
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (resp.body.isNotEmpty && resp.body != 'null') {
          final Map<String, dynamic> data = jsonDecode(resp.body);
          if (data.isNotEmpty) {
            // Get the first sorteio from the data
            String firstKey = data.keys.first;
            sorteio = Sorteio.fromJson(data[firstKey]);
            sorteio.id = firstKey;
            
            // Update cache
            _cachedSorteio = sorteio;
            _lastFetchTime = DateTime.now();
          }
        }
      } else {
        debugPrint("Erro ao carregar: ${resp.statusCode} - ${resp.body}");
      }
    } catch (e) {
      debugPrint("Erro ao carregar sorteios: $e");
    }
    
    return sorteio;
  }
  
  // Clear the cache
  void clearCache() {
    _cachedSorteio = null;
    _lastFetchTime = null;
  }
}