import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app_sorteio_cliente/model/sorteio.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class StatusSorteio extends StatefulWidget {
  final Sorteio sorteio;
  const StatusSorteio({super.key, required this.sorteio});
  @override
  State<StatusSorteio> createState() => StatusSorteioState();
}

class StatusSorteioState extends State<StatusSorteio> with WidgetsBindingObserver {
  bool _isLoading = true;
  String? _ganhador;
  String? _errorMessage;
  Timer? _checkTimer;
  bool _isAppInForeground = true;
  
  // Cache data
  DateTime? _lastCheckTime;
  static const Duration checkInterval = Duration(minutes: 1);
  static const String lastCheckTimeKey = 'last_check_time';
  static const String ganhadorKey = 'ganhador_';
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCachedData();
    
    // Less frequent checking - once per minute instead of every 5 seconds
    _checkTimer = Timer.periodic(checkInterval, (timer) {
      if (_ganhador == null && _isAppInForeground) {
        _verificarGanhador(silent: true);
      } else if (_ganhador != null) {
        // If we have a winner, we can stop the timer
        _checkTimer?.cancel();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = state == AppLifecycleState.resumed;
    
    // When app comes to foreground and no winner yet, refresh
    if (_isAppInForeground && _ganhador == null) {
      _verificarGanhador(silent: true);
    }
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if we have cached data for this specific sorteio
    final sorteioGanhadorKey = '$ganhadorKey${widget.sorteio.id}';
    final cachedGanhador = prefs.getString(sorteioGanhadorKey);
    
    if (cachedGanhador != null) {
      setState(() {
        _ganhador = cachedGanhador;
        _isLoading = false;
      });
      // If we already have a winner, no need to keep checking
      _checkTimer?.cancel();
      return;
    }
    
    // If no cached winner, check last lookup time
    final lastCheckTimeStr = prefs.getString(lastCheckTimeKey);
    if (lastCheckTimeStr != null) {
      _lastCheckTime = DateTime.parse(lastCheckTimeStr);
      final timeSinceLastCheck = DateTime.now().difference(_lastCheckTime!);
      
      // If we checked recently, wait before checking again
      if (timeSinceLastCheck < checkInterval) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }
    
    // If no cache or cache is old, check server
    _verificarGanhador();
  }

  Future<void> _cacheData() async {
    if (_ganhador != null) {
      final prefs = await SharedPreferences.getInstance();
      final sorteioGanhadorKey = '$ganhadorKey${widget.sorteio.id}';
      await prefs.setString(sorteioGanhadorKey, _ganhador!);
    }
    
    // Save last check time
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastCheckTimeKey, DateTime.now().toIso8601String());
    _lastCheckTime = DateTime.now();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _verificarGanhador({bool silent = false}) async {
    // Skip if already have a winner
    if (_ganhador != null) return;
    
    // Only show loading if not silent refresh
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Add cache busting to avoid HTTP caching
      final String url = "https://crud-projeto-87237-default-rtdb.firebaseio.com/ganhador";
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(Uri.parse("$url.json?cacheBust=$cacheBuster"));

      if (response.statusCode == 200) {
        if (response.body == 'null') {
          if (mounted) {
            setState(() {
              _ganhador = null;
              _isLoading = false;
            });
          }
        } else {
          try {
            final Map<String, dynamic> data = jsonDecode(response.body);
            final entries = data.values.where((entry) => 
              entry['sorteioNome'] == widget.sorteio.nome
            );
            
            if (entries.isNotEmpty) {
              final ganhadorNome = entries.first['nome'] as String?;
              
              if (mounted) {
                setState(() {
                  _ganhador = ganhadorNome;
                  _isLoading = false;
                });
              }
              
              // Cache the winner
              _cacheData();
              
              // Stop checking once we have a winner
              _checkTimer?.cancel();
            } else {
              if (mounted) {
                setState(() {
                  _ganhador = null;
                  _isLoading = false;
                });
              }
              // Update last check time
              _cacheData();
            }
          } catch (e) {
            if (mounted && !silent) {
              setState(() {
                _errorMessage = "Formato de dados inválido: $e";
                _isLoading = false;
              });
            }
          }
        }
      } else {
        if (mounted && !silent) {
          setState(() {
            _errorMessage = "Erro no servidor: ${response.statusCode}";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _errorMessage = "Erro de conexão: Verifique sua internet e tente novamente";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      
      body: RefreshIndicator(
        onRefresh: () => _verificarGanhador(silent: false),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                  AppBar().preferredSize.height - 
                  MediaQuery.of(context).padding.top,
            ),
            child: Center(
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("Verificando status do sorteio..."),
        ],
      );
    }

    if (_errorMessage != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _verificarGanhador(),
            child: const Text("Tentar novamente"),
          ),
        ],
      );
    }

    if (_ganhador == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.hourglass_empty,
            size: 72,
            color: Colors.amber,
          ),
          const SizedBox(height: 24),
          const Text(
            "O ganhador ainda não foi sorteado",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 255, 255, 255)
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Sorteio: ${widget.sorteio.nome}",
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          if (_lastCheckTime != null)
            Text(
              "Última verificação: ${_formatDateTime(_lastCheckTime!)}",
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_events,
            size: 72,
            color: Colors.amber,
          ),
          const SizedBox(height: 16),
          const Text(
            "Parabéns ao ganhador!",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber),
            ),
            child: Column(
              children: [
                const Text(
                  "Nome do ganhador:",
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  _ganhador!,
                  style: const TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Sorteio: ${widget.sorteio.nome}",
            style: const TextStyle(fontSize: 16),
          ),
        ],
      );
    }
  }
  
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return "agora mesmo";
    } else if (difference.inMinutes < 60) {
      return "há ${difference.inMinutes} minutos";
    } else if (difference.inHours < 24) {
      return "há ${difference.inHours} horas";
    } else {
      return "${dateTime.day}/${dateTime.month}/${dateTime.year} às ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    }
  }
}