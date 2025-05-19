import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _alreadyParticipated = false;
  bool _isChecking = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _checkParticipationStatus();
  }

  Future<void> _checkParticipationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final participated = prefs.getBool('${widget.sorteio.id}_participated') ?? false;
      
      if (participated) {
        setState(() => _alreadyParticipated = true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao verificar participações anteriores")),
      );
    }
    setState(() => _isChecking = false);
  }

  Future<void> _submitParticipation() async {
    if (_alreadyParticipated) return;

    setState(() => _isSubmitting = true);
    
    final nome = _nomeController.text.trim();
    final telefone = _telefoneController.text.trim();

    if (nome.isEmpty || telefone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos obrigatórios")),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      // Check for existing participation
      final participantsUrl = Uri.parse(
        "https://applespace-a00ab-default-rtdb.firebaseio.com/participantes/${widget.sorteio.id}.json"
      );

      final checkResponse = await http.get(participantsUrl);
      if (checkResponse.statusCode == 200) {
        final participants = jsonDecode(checkResponse.body) as Map<String, dynamic>? ?? {};
        final exists = participants.values.any((p) => p['telefone'] == telefone);
        
        if (exists) {
          _handleExistingParticipation();
          return;
        }
      }

      // Submit new participation
      final response = await http.post(
        participantsUrl,
        body: jsonEncode({
          'nome': nome,
          'telefone': telefone,
          'sorteioId': widget.sorteio.id,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _handleSuccessfulSubmission();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => StatusSorteio(sorteio: widget.sorteio)),
        );
      } else {
        throw Exception('Falha no servidor: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro na participação: ${e.toString()}")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleSuccessfulSubmission() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${widget.sorteio.id}_participated', true);
    setState(() => _alreadyParticipated = true);
  }

  void _handleExistingParticipation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${widget.sorteio.id}_participated', true);
    setState(() {
      _alreadyParticipated = true;
      _isSubmitting = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Você já está participando deste sorteio!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_alreadyParticipated)
              _buildParticipationStatus(),
            const SizedBox(height: 20),
            _buildNameField(),
            const SizedBox(height: 16),
            _buildPhoneField(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipationStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        "Você já está participando deste sorteio!",
        style: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

 Widget _buildNameField() {
  return TextField(
    controller: _nomeController,
    style: const TextStyle(color: Colors.white),
    decoration: const InputDecoration(
      labelText: "Nome completo",
      labelStyle: TextStyle(color: Colors.white70),
      border: OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white70),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
    ),
    enabled: !_alreadyParticipated && !_isSubmitting,
  );
}

 Widget _buildPhoneField() {
  return TextField(
    controller: _telefoneController,
    style: const TextStyle(color: Colors.white),
    keyboardType: TextInputType.phone,
    decoration: const InputDecoration(
      labelText: "Telefone",
      labelStyle: TextStyle(color: Colors.white70),
      border: OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white70),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
    ),
    enabled: !_alreadyParticipated && !_isSubmitting,
  );
}

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _alreadyParticipated || _isSubmitting ? null : _submitParticipation,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.blue.shade800,
        disabledBackgroundColor: Colors.grey.shade300,
      ),
      child: _isSubmitting
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(color: Colors.white),
            )
          : const Text(
              "CONFIRMAR PARTICIPAÇÃO",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );
  }
}