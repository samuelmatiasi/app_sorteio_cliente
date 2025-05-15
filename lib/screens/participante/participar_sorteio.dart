import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app_sorteio_cliente/model/sorteio.dart';
import 'package:app_sorteio_cliente/screens/status/status_sorteio.dart';

class ParticiparSorteio extends StatefulWidget {
  final Sorteio sorteio;
  const ParticiparSorteio({super.key, required this.sorteio});

  @override
  State<ParticiparSorteio> createState() => _ParticiparSorteioState();
}

class _ParticiparSorteioState extends State<ParticiparSorteio> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();

  Future<void> _enviarFormulario() async {
    final nome = _nomeController.text.trim();
    final telefone = _telefoneController.text.trim();

    if (nome.isEmpty || telefone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos.")),
      );
      return;
    }

    final url = Uri.parse("https://crud-projeto-87237-default-rtdb.firebaseio.com/participantes/${widget.sorteio.id}.json");
    final body = jsonEncode({
      'nome': nome,
      'telefone': telefone,
      'sorteioId': widget.sorteio.id
    });

    try {
      final response = await http.post(url, body: body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Confirmado!"),
            content: Text("Obrigado por participar, $nome!"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Fechar"),
              )
            ],
          ),
        );
        _nomeController.clear();
        _telefoneController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao enviar participação.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro de conexão com o servidor.")),
      );
    }
        Navigator.pushReplacement(
            context,
          MaterialPageRoute(builder: (_) => StatusSorteio(sorteio: StatusSorteio!)),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Participar: ${widget.sorteio.nome}")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: "Nome"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _telefoneController,
              decoration: const InputDecoration(labelText: "Telefone"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _enviarFormulario,
              child: const Text("Confirmar Participação"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            )
          ],
        ),
      ),
    );
  }
}
