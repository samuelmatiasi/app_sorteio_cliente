import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_sorteio_cliente/model/sorteio.dart';
import 'package:app_sorteio_cliente/service/sorteio_service.dart';
import 'package:app_sorteio_cliente/screens/participante/participar_sorteio.dart';
import 'package:app_sorteio_cliente/screens/status/status_sorteio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final SorteioService _sorteioService = SorteioService();
  Sorteio? _sorteioAtual;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;
  
  // Reduced polling frequency (2 minutes instead of 5 seconds)
  static const Duration refreshInterval = Duration(minutes: 2);
  
  // Track if app is in foreground
  bool _isAppInForeground = true;
  
  // Track connectivity status
  bool _hasConnectivity = true;
  StreamSubscription? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    
    // Register app lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    
    // Set up connectivity monitoring
    _setupConnectivityMonitoring();
    
    // Load data immediately
    _carregarSorteio();
    
    // Set up timer with reduced frequency
    _refreshTimer = Timer.periodic(refreshInterval, (_) {
      // Only refresh if app is in foreground and has connectivity
      if (_isAppInForeground && _hasConnectivity) {
        _carregarSorteio(silentRefresh: true);
      }
    });
  }
  
  void _setupConnectivityMonitoring() async {
    // Check initial connectivity
    var connectivityResult = await (Connectivity().checkConnectivity());
    _hasConnectivity = connectivityResult != ConnectivityResult.none;
    
    // Listen for connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final hasConnectivity = result != ConnectivityResult.none;
      
      // If connectivity was restored, refresh data
      if (!_hasConnectivity && hasConnectivity && _isAppInForeground) {
        _carregarSorteio(silentRefresh: true);
      }
      
      setState(() {
        _hasConnectivity = hasConnectivity;
      });
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Update foreground state
    _isAppInForeground = state == AppLifecycleState.resumed;
    
    // Refresh data when app comes back to foreground
    if (_isAppInForeground && _hasConnectivity) {
      _carregarSorteio(silentRefresh: true);
    }
  }

  Future<void> _carregarSorteio({bool silentRefresh = false}) async {
    // For silent refresh, don't show loading indicator
    if (!silentRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    
    try {
      // Use force refresh based on silent parameter
      final sorteio = await _sorteioService.carregarSorteios(forceRefresh: !silentRefresh);
      
      if (mounted) {
        setState(() {
          _sorteioAtual = sorteio;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Only update error state for non-silent refreshes
          if (!silentRefresh) {
            _errorMessage = "Erro ao carregar sorteio: $e";
          }
          _isLoading = false;
        });
      }
      debugPrint("Erro ao carregar sorteio: $e");
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _carregarSorteio(silentRefresh: false),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Carregando sorteio...", style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    if (!_hasConnectivity) {
      return _buildMessageCard(
        icon: Icons.signal_wifi_off,
        title: "Sem conexão com a internet",
        subtitle: "Verifique sua conexão e tente novamente",
        footnote: _sorteioAtual != null ? "Exibindo informações salvas anteriormente" : null,
        iconColor: Colors.orange,
      );
    }

    if (_errorMessage != null) {
      return _buildMessageCard(
        icon: Icons.error_outline,
        title: _errorMessage!,
        iconColor: Colors.red,
        buttonLabel: "Tentar novamente",
        onButtonPressed: () => _carregarSorteio(silentRefresh: false),
      );
    }

    if (_sorteioAtual == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image(image: AssetImage("assets/aplle_space_light.png"), width: MediaQuery.of(context).size.width * 0.7),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _carregarSorteio(silentRefresh: false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF377DFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              textStyle: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            child: const Text("Buscar Sorteio"),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _sorteioAtual!.nome,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            _sorteioAtual!.desc,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white,foregroundColor: Colors.black),
                icon: const Icon(Icons.input),
                label: const Text("Participar"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ParticiparSorteio(sorteio: _sorteioAtual!),
                    ),
                  );
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.emoji_events),
                label: const Text("Ver Status"),
                style: ElevatedButton.styleFrom(backgroundColor:  Color(0xFF377DFF), foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StatusSorteio(sorteio: _sorteioAtual!),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard({
    required IconData icon,
    required String title,
    Color? iconColor,
    String? subtitle,
    String? footnote,
    String? buttonLabel,
    VoidCallback? onButtonPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: iconColor ?? Colors.grey),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          ],
          if (footnote != null) ...[
            const SizedBox(height: 16),
            Text(footnote,
                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white60),
                textAlign: TextAlign.center),
          ],
          if (buttonLabel != null && onButtonPressed != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onButtonPressed,
              child: Text(buttonLabel),
            ),
          ],
        ],
      ),
    );
  }
}


