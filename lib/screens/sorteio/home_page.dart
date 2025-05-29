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

class _HomePageState extends State<HomePage> 
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final SorteioService _sorteioService = SorteioService();
  Sorteio? _sorteioAtual;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  
  static const Duration refreshInterval = Duration(minutes: 2);
  bool _isAppInForeground = true;
  bool _hasConnectivity = true;
  StreamSubscription? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    WidgetsBinding.instance.addObserver(this);
    _setupConnectivityMonitoring();
    _carregarSorteio();
    
    _refreshTimer = Timer.periodic(refreshInterval, (_) {
      if (_isAppInForeground && _hasConnectivity) {
        _carregarSorteio(silentRefresh: true);
      }
    });
  }
  
  void _setupConnectivityMonitoring() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    _hasConnectivity = connectivityResult != ConnectivityResult.none;
    
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final hasConnectivity = result != ConnectivityResult.none;
      
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
    _isAppInForeground = state == AppLifecycleState.resumed;
    
    if (_isAppInForeground && _hasConnectivity) {
      _carregarSorteio(silentRefresh: true);
    }
  }

  Future<void> _carregarSorteio({bool silentRefresh = false}) async {
    if (!silentRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    
    try {
      final sorteio = await _sorteioService.carregarSorteios(forceRefresh: !silentRefresh);
      
      if (mounted) {
        setState(() {
          _sorteioAtual = sorteio;
          _isLoading = false;
        });
        
        // Trigger fade animation when content loads
        if (!silentRefresh) {
          _fadeController.forward();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
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
    _pulseController.dispose();
    _fadeController.dispose();
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
            onRefresh: () => _carregarSorteio(silentRefresh: false),
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
    if (_isLoading) {
      return _buildLoadingCard();
    }

    if (!_hasConnectivity) {
      return _buildMessageCard(
        icon: Icons.signal_wifi_off,
        title: "Sem conexão com a internet",
        subtitle: "Verifique sua conexão e tente novamente",
        footnote: _sorteioAtual != null ? "Exibindo informações salvas anteriormente" : null,
        iconColor: Colors.orange,
        gradientColors: [Colors.orange.withOpacity(0.1), Colors.orange.withOpacity(0.05)],
      );
    }

    if (_errorMessage != null) {
      return _buildMessageCard(
        icon: Icons.error_outline,
        title: _errorMessage!,
        iconColor: Colors.red,
        gradientColors: [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.05)],
        buttonLabel: "Tentar novamente",
        onButtonPressed: () => _carregarSorteio(silentRefresh: false),
      );
    }

    if (_sorteioAtual == null) {
      return _buildEmptyStateCard();
    }

    return _buildSorteioCard();
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
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
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
                Icons.casino,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Carregando sorteio...",
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

  Widget _buildEmptyStateCard() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
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
              child: Image.asset(
                "assets/aplle_space_light.png",
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Nenhum sorteio encontrado",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Toque no botão abaixo para buscar sorteios disponíveis",
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildGradientButton(
              onPressed: () => _carregarSorteio(silentRefresh: false),
              label: "Buscar Sorteio",
              icon: Icons.search,
              isPrimary: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSorteioCard() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
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
                Icons.emoji_events,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _sorteioAtual!.nome,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
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
                _sorteioAtual!.desc,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: _buildGradientButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParticiparSorteio(sorteio: _sorteioAtual!),
                        ),
                      );
                    },
                    label: "Participar",
                    icon: Icons.input,
                    isPrimary: false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildGradientButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StatusSorteio(sorteio: _sorteioAtual!),
                        ),
                      );
                    },
                    label: "Ver Status",
                    icon: Icons.leaderboard,
                    isPrimary: true,
                  ),
                ),
              ],
            ),
          ],
        ),
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
    String? footnote,
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
          if (footnote != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                footnote,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
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