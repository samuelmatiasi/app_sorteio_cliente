import 'dart:convert';
import 'package:app_sorteio_cliente/model/sorteio.dart';
import 'package:http/http.dart' as http;

class SorteioService {
  final String url = "https://crud-projeto-87237-default-rtdb.firebaseio.com/sorteio";

  Future<Sorteio?> carregarSorteios() async {
    Sorteio? sorteio;
    try {
      final resp = await http.get(Uri.parse("$url.json"));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (resp.body.isNotEmpty && resp.body != 'null') {
          final Map<String, dynamic> data = jsonDecode(resp.body);
          if (data.isNotEmpty) {
            // Get the first sorteio from the data
            String firstKey = data.keys.first;
            sorteio = Sorteio.fromJson(data[firstKey]);
            sorteio.id = firstKey;
          }
        }
      } else {
        print("Erro ao carregar: ${resp.statusCode} - ${resp.body}");
      }
    } catch (e) {
      print("Erro ao carregar sorteios: $e");
    }
    return sorteio;
  }

}
