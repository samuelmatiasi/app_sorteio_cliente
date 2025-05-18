
class Sorteio {
  String id;
  String nome;
  String desc;
  String data;
  
  Sorteio({
    required this.id,
    required this.nome,
    required this.desc,
    required this.data,
  });
  
  // Convert JSON to Sorteio object
  factory Sorteio.fromJson(Map<String, dynamic> json) {
    return Sorteio(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      desc: json['desc'] ?? '',
      data: json['data'] ?? DateTime.now().toString(),
    );
  }
  
  // Convert Sorteio object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'desc': desc,
      'data': data,
    };
  }
}