import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_sorteio_cliente/model/sorteio.dart';
import 'package:app_sorteio_cliente/service/sorteio_service.dart';
import 'package:app_sorteio_cliente/screens/participante/participar_sorteio.dart';

class HomePageWeb extends StatefulWidget {
  const HomePageWeb({super.key});

  @override
  State<HomePageWeb> createState() => _HomePageWebState();
}

class _HomePageWebState extends State<HomePageWeb> {
  final SorteioService _sorteioService = SorteioService();
  Sorteio? _sorteioAtual;
  Timer? _reloadTimer;

  @override
  void initState() {
    super.initState();
    _carregarSorteio();
    _reloadTimer = Timer.periodic(const Duration(seconds: 5), (_) => _carregarSorteio());
  }

  Future<void> _carregarSorteio() async {
    final sorteios = await _sorteioService.carregarSorteios();
    setState(() {
      _sorteioAtual = sorteios.isNotEmpty ? sorteios.first : null;
    });
  }

  @override
  void dispose() {
    _reloadTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sorteio do Dia")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: _sorteioAtual != null
              ? Column(
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
                      Image.network(
                        _sorteioAtual!.img,
                        height: 250,
                        fit: BoxFit.cover,
                      ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                         Navigator.push(
                           context,
                          MaterialPageRoute(builder: (_) => ParticiparSorteio(sorteio: _sorteioAtual!)),
                       );
                      },
                      child: const Text("Participar"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    )
                  ],
                )
              : const Text(
                  "Nenhum sorteio disponível no momento.",
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
        ),
      ),
    );
  }
}