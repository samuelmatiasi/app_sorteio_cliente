import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app_sorteio_cliente/model/sorteio.dart';

class StatusSorteio extends StatefulWidget {
  final Sorteio sorteio;
  
  const StatusSorteio({super.key, required this.sorteio});

  @override
  State<StatusSorteio> createState() => StatusSorteioState();
}

class StatusSorteioState extends State<StatusSorteio> {
  bool _isLoading = true;
  String? _ganhador;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _verificarGanhador();
  }

  Future<void> _verificarGanhador() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = Uri.parse("https://crud-projeto-87237-default-rtdb.firebaseio.com/ganhador/${widget.sorteio.id}.json");
      final response = await http.get(url);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body == 'null' || response.body.isEmpty) {
          // Nenhum ganhador ainda
          setState(() {
            _ganhador = null;
            _isLoading = false;
          });
        } else {
          try {
            final data = jsonDecode(response.body);
            setState(() {
              _ganhador = data['nome'] as String?;
              _isLoading = false;
            });
          } catch (e) {
            setState(() {
              _errorMessage = "Erro ao processar dados do ganhador: $e";
              _isLoading = false;
            });
          }
        }
      } else {
        setState(() {
          _errorMessage = "Erro ao verificar ganhador: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Erro de conexão: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Status do Sorteio: ${widget.sorteio.nome}"),
      ),
      body: RefreshIndicator(
        onRefresh: _verificarGanhador,
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
            onPressed: _verificarGanhador,
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
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Sorteio: ${widget.sorteio.nome}",
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
    
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
}