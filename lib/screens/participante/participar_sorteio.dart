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
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF377DFF),
          ),
        ),
      ),
    );
  }

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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                        MediaQuery.of(context).padding.top - 
                        MediaQuery.of(context).padding.bottom,
            ),
            child: Center(
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
                    // Header com ícone
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
                        Icons.person_add,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Título
                    const Text(
                      "Participar do Sorteio",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    
                    // Subtítulo
                    Text(
                      "Preencha seus dados para participar",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    
                    // Status de participação
                    if (_alreadyParticipated)
                      _buildParticipationStatus(),
                    
                    if (_alreadyParticipated)
                      const SizedBox(height: 32),
                    
                    // Campos do formulário
                    _buildNameField(),
                    const SizedBox(height: 20),
                    _buildPhoneField(),
                    const SizedBox(height: 40),
                    
                    // Botão de submissão
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildParticipationStatus() {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.green.withOpacity(0.2),
          Colors.green.withOpacity(0.1),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.green.withOpacity(0.3),
        width: 1,
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withOpacity(0.2),
          ),
          child: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            "Você já está participando deste sorteio!",
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildNameField() {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: TextField(
      controller: _nomeController,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: "Nome completo",
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 16,
        ),
        prefixIcon: Icon(
          Icons.person_outline,
          color: Colors.white.withOpacity(0.7),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF377DFF),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
      ),
      enabled: !_alreadyParticipated && !_isSubmitting,
    ),
  );
}

Widget _buildPhoneField() {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: TextField(
      controller: _telefoneController,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: "Telefone",
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 16,
        ),
        prefixIcon: Icon(
          Icons.phone_outlined,
          color: Colors.white.withOpacity(0.7),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF377DFF),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
      ),
      enabled: !_alreadyParticipated && !_isSubmitting,
    ),
  );
}

Widget _buildSubmitButton() {
  return Container(
    width: double.infinity,
    height: 56,
    decoration: BoxDecoration(
      gradient: _alreadyParticipated || _isSubmitting
          ? LinearGradient(
              colors: [
                Colors.grey.withOpacity(0.3),
                Colors.grey.withOpacity(0.2),
              ],
            )
          : const LinearGradient(
              colors: [Color(0xFF377DFF), Color(0xFF2563EB)],
            ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: _alreadyParticipated || _isSubmitting
          ? []
          : [
              BoxShadow(
                color: const Color(0xFF377DFF).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
    ),
    child: ElevatedButton(
      onPressed: _alreadyParticipated || _isSubmitting ? null : _submitParticipation,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: _isSubmitting
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "PROCESSANDO...",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _alreadyParticipated ? Icons.check : Icons.send,
                  color: _alreadyParticipated 
                      ? Colors.white.withOpacity(0.5)
                      : Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _alreadyParticipated 
                      ? "JÁ PARTICIPANDO" 
                      : "CONFIRMAR PARTICIPAÇÃO",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _alreadyParticipated 
                        ? Colors.white.withOpacity(0.5)
                        : Colors.white,
                  ),
                ),
              ],
            ),
    ),
  );
}
}