import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_sorteio_cliente/model/sorteio.dart';
import 'package:app_sorteio_cliente/model/ganhador.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';

class StatusSorteio extends StatefulWidget {
  final Sorteio sorteio;

  const StatusSorteio({super.key, required this.sorteio});

  @override
  State<StatusSorteio> createState() => _StatusSorteioState();
}

class _StatusSorteioState extends State<StatusSorteio>
    with WidgetsBindingObserver {
  Ganhador? _ganhador;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;
  bool _hasConnectivity = true;
  StreamSubscription? _connectivitySubscription;
  bool _isAppInForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupConnectivity();
    _fetchGanhador();
    _setupRefreshTimer();
  }

  void _setupRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (_isAppInForeground && _hasConnectivity) {
        _fetchGanhador(silent: true);
      }
    });
  }

  void _setupConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    _hasConnectivity = connectivityResult != ConnectivityResult.none;

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      final newConnectivity = result != ConnectivityResult.none;
      if (newConnectivity && !_hasConnectivity && _isAppInForeground) {
        _fetchGanhador();
      }
      setState(() => _hasConnectivity = newConnectivity);
    });
  }

  Future<void> _fetchGanhador({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(
          "https://applespace-a00ab-default-rtdb.firebaseio.com/ganhador.json",
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Ganhador? ganhador;

        if (data != null && data.isNotEmpty) {
          final firstKey = data.keys.first;
          ganhador = Ganhador.fromJson(data[firstKey]);
        }

        if (mounted) {
          setState(() {
            _ganhador = ganhador;
            _isLoading = false;
            _errorMessage = null;
          });
        }
      } else {
        throw Exception('Failed to load winner: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Erro ao carregar ganhador: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = state == AppLifecycleState.resumed;
    if (_isAppInForeground && _hasConnectivity) _fetchGanhador(silent: true);
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
    return Scaffold(backgroundColor: Colors.black, body: _buildBody());
  }

  Widget _buildBody() {
    if (!_hasConnectivity) {
      return _buildMessage(
        icon: Icons.signal_wifi_off,
        title: "Sem conexão com a internet",
        subtitle: "Conecte-se para verificar o ganhador",
        iconColor: Colors.orange,
      );
    }

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                "Verificando ganhador...",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildMessage(
        icon: Icons.error_outline,
        title: _errorMessage!,
        iconColor: Colors.red,
        buttonLabel: "Tentar novamente",
        onButtonPressed: _fetchGanhador,
      );
    }

    return _ganhador != null ? _buildWinnerCard() : _buildNoWinner();
  }

  Widget _buildWinnerCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
            const SizedBox(height: 24),
            Text(
              'Parabéns!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            _buildWinnerInfo('Nome', _ganhador!.nome),
            if (_ganhador == null) ...[
              const SizedBox(height: 32),
              _buildLoadButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWinnerInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoWinner() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildMessage(
          icon: Icons.schedule,
          title: "Aguardando sorteio",
          subtitle: "O resultado será anunciado em breve",
          iconColor: Colors.blue,
        ),
        const SizedBox(height: 24),
        _buildLoadButton(),
      ],
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    String? buttonLabel,
    VoidCallback? onButtonPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: iconColor ?? Colors.white),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 16),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
            if (buttonLabel != null && onButtonPressed != null) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF377DFF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: Text(buttonLabel, style: const TextStyle(fontSize: 18)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadButton() {
    return ElevatedButton(
      onPressed: () => _fetchGanhador(silent: false),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF377DFF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        textStyle: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
      ),
      child: const Text("Carregar"),
    );
  }
}
