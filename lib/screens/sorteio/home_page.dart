import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_sorteio_cliente/model/sorteio.dart';
import 'package:app_sorteio_cliente/service/sorteio_service.dart';
import 'package:app_sorteio_cliente/screens/participante/participar_sorteio.dart';
import 'package:app_sorteio_cliente/screens/status/status_sorteio.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SorteioService _sorteioService = SorteioService();
  Sorteio? _sorteioAtual;
  Timer? _reloadTimer;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarSorteio();
    // Set up timer to refresh the sorteio data every 5 seconds
    _reloadTimer = Timer.periodic(const Duration(seconds: 5), (_) => _carregarSorteio());
  }

  Future<void> _carregarSorteio() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Use the updated method that returns a single Sorteio object
      final sorteio = await _sorteioService.carregarSorteios();
      
      setState(() {
        _sorteioAtual = sorteio; // Now correctly assigning Sorteio? to Sorteio?
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Erro ao carregar sorteio: $e";
        _isLoading = false;
      });
      print("Erro ao carregar sorteio: $e");
    }
  }

  @override
  void dispose() {
    _reloadTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sorteio do Dia"),
        actions: [
          // Add a refresh button to manually reload data
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarSorteio,
            tooltip: "Atualizar sorteio",
          ),
          // Add a status button to check winner status
          if (_sorteioAtual != null)
            IconButton(
              icon: const Icon(Icons.emoji_events),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StatusSorteio(sorteio: _sorteioAtual!),
                  ),
                );
              },
              tooltip: "Ver status do sorteio",
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregarSorteio,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height - 
                   AppBar().preferredSize.height - 
                   MediaQuery.of(context).padding.top,
            padding: const EdgeInsets.all(32.0),
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
          Text("Carregando sorteio..."),
        ],
      );
    }

    if (_errorMessage != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _carregarSorteio,
            child: const Text("Tentar novamente"),
          ),
        ],
      );
    }

    if (_sorteioAtual == null) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 64,
            color: Colors.blue,
          ),
          SizedBox(height: 16),
          Text(
            "Nenhum sorteio disponível no momento.",
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    // Display sorteio information
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _sorteioAtual!.nome,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          _sorteioAtual!.desc,
          style: const TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        if (_sorteioAtual!.img.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _sorteioAtual!.img,
                height: 250,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 250,
                    width: 250,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    width: 250,
                    color: Colors.grey[300],
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ParticiparSorteio(sorteio: _sorteioAtual!),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text("Participar"),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StatusSorteio(sorteio: _sorteioAtual!),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: Colors.amber,
              ),
              child: const Text("Ver Status"),
            ),
          ],
        ),
      ],
    );
  }
}