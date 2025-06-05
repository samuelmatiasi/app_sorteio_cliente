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
  return Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F3460),
          ],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _fetchGanhador(silent: false),
          backgroundColor: Colors.white,
          color: const Color(0xFF377DFF),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top - 
                          MediaQuery.of(context).padding.bottom,
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _buildContent(),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildContent() {
  if (!_hasConnectivity) {
    return _buildMessageCard(
      icon: Icons.signal_wifi_off,
      title: "Sem conexão com a internet",
      subtitle: "Conecte-se para verificar o ganhador",
      iconColor: Colors.orange,
      gradientColors: [Colors.orange.withOpacity(0.1), Colors.orange.withOpacity(0.05)],
      buttonLabel: "Tentar novamente",
      onButtonPressed: () => _fetchGanhador(silent: false),
    );
  }

  if (_isLoading) {
    return _buildLoadingCard();
  }

  if (_errorMessage != null) {
    return _buildMessageCard(
      icon: Icons.error_outline,
      title: _errorMessage!,
      iconColor: Colors.red,
      gradientColors: [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.05)],
      buttonLabel: "Tentar novamente",
      onButtonPressed: () => _fetchGanhador(silent: false),
    );
  }

  return _ganhador != null ? _buildWinnerCard() : _buildNoWinnerCard();
}

Widget _buildLoadingCard() {
  return Container(
    margin: const EdgeInsets.all(24),
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.15),
          Colors.white.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF377DFF).withOpacity(0.8),
                const Color(0xFF377DFF).withOpacity(0.4),
              ],
            ),
          ),
          child: const Icon(
            Icons.search,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "Verificando ganhador...",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 4,
          width: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.white.withOpacity(0.2),
          ),
          child: LinearProgressIndicator(
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(
              const Color(0xFF377DFF).withOpacity(0.8),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildWinnerCard() {
  return Container(
    margin: const EdgeInsets.all(24),
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.15),
          Colors.white.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animação de troféu com partículas douradas
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.amber.withOpacity(0.8),
                Colors.orange.withOpacity(0.6),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.emoji_events,
            color: Colors.white,
            size: 64,
          ),
        ),
        const SizedBox(height: 32),
        
        // Título de parabéns
        const Text(
          "🎉 PARABÉNS! 🎉",
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        
        Text(
          "Temos um ganhador!",
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        
        // Card com informações do ganhador
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.withOpacity(0.1),
                Colors.orange.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.amber.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withOpacity(0.2),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.amber,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "GANHADOR",
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _ganhador!.nome,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        
        // Botão de atualizar
        _buildGradientButton(
          onPressed: () => _fetchGanhador(silent: false),
          label: "Atualizar Resultado",
          icon: Icons.refresh,
          isPrimary: true,
        ),
      ],
    ),
  );
}

Widget _buildNoWinnerCard() {
  return Container(
    margin: const EdgeInsets.all(24),
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.15),
          Colors.white.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF377DFF).withOpacity(0.2),
                const Color(0xFF377DFF).withOpacity(0.1),
              ],
            ),
          ),
          child: const Icon(
            Icons.schedule,
            color: Color(0xFF377DFF),
            size: 48,
          ),
        ),
        const SizedBox(height: 32),
        
        const Text(
          "Aguardando Sorteio",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        
        Text(
          "O resultado será anunciado em breve",
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "Mantenha-se atento para não perder!",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 40),
        
        // Botões de ação
        Row(
          children: [
           
            const SizedBox(width: 16),
            Expanded(
              child: _buildGradientButton(
                onPressed: () => _fetchGanhador(silent: false),
                label: "Atualizar",
                icon: Icons.refresh,
                isPrimary: true,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildGradientButton({
  required VoidCallback onPressed,
  required String label,
  required IconData icon,
  required bool isPrimary,
}) {
  return Container(
    height: 56,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: isPrimary
            ? [const Color(0xFF377DFF), const Color(0xFF2563EB)]
            : [Colors.white, Colors.white.withOpacity(0.9)],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: isPrimary 
              ? const Color(0xFF377DFF).withOpacity(0.4)
              : Colors.white.withOpacity(0.2),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      icon: Icon(
        icon,
        color: isPrimary ? Colors.white : const Color(0xFF1A1A2E),
        size: 20,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isPrimary ? Colors.white : const Color(0xFF1A1A2E),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

Widget _buildMessageCard({
  required IconData icon,
  required String title,
  Color? iconColor,
  List<Color>? gradientColors,
  String? subtitle,
  String? buttonLabel,
  VoidCallback? onButtonPressed,
}) {
  return Container(
    margin: const EdgeInsets.all(24),
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: gradientColors ?? [
          Colors.white.withOpacity(0.15),
          Colors.white.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (iconColor ?? Colors.grey).withOpacity(0.2),
          ),
          child: Icon(
            icon,
            size: 48,
            color: iconColor ?? Colors.grey,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
        if (buttonLabel != null && onButtonPressed != null) ...[
          const SizedBox(height: 32),
          _buildGradientButton(
            onPressed: onButtonPressed,
            label: buttonLabel,
            icon: Icons.refresh,
            isPrimary: true,
          ),
        ],
      ],
    ),
  );
}
    }
