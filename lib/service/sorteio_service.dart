import 'dart:convert';
import 'package:app_sorteio_cliente/model/sorteio.dart';
import 'package:http/http.dart' as http;

class SorteioService {
  final String url = "https://crud-projeto-87237-default-rtdb.firebaseio.com/sorteio";

  Future<List<Sorteio>> carregarSorteios() async {
    final List<Sorteio> sorteios = [];
    try {
      final resp = await http.get(Uri.parse("$url.json"));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (resp.body.isNotEmpty && resp.body != 'null') {
          final Map<String, dynamic> data = jsonDecode(resp.body);
          data.forEach((key, value) {
            final sorteio = Sorteio.fromJson(value);
            sorteio.id = key;
            sorteios.add(sorteio);
          });
        }
      } else {
        print("Erro ao carregar: ${resp.statusCode} - ${resp.body}");
      }
    } catch (e) {
      print("Erro ao carregar sorteios: $e");
    }
    return sorteios;
  }

  Future<String?> incluirSorteio(Sorteio sorteio) async {
    try {
      final resp = await http.post(
        Uri.parse("$url.json"),
        body: jsonEncode(sorteio.toJson()),
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        try {
          final data = jsonDecode(resp.body);
          if (data is Map<String, dynamic> && data.containsKey('name')) {
            return data['name'] as String;
          } else {
            print("Resposta inválida: $data");
            return null;
          }
        } catch (e) {
          print("Erro ao decodificar resposta: $e");
          return null;
        }
      } else {
        print("Erro ${resp.statusCode}: ${resp.body}");
        return null;
      }
    } catch (e) {
      print("Erro ao incluir sorteio: $e");
      return null;
    }
  }

  Future<void> deletarSorteio(String id) async {
    try {
      final resp = await http.delete(Uri.parse("$url/$id.json"));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        print("Sorteio deletado.");
      } else {
        print("Erro ${resp.statusCode}: ${resp.body}");
      }
    } catch (e) {
      print("Erro ao deletar sorteio: $e");
    }
  }
}