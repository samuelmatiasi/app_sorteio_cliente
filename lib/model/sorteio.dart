class Sorteio {
  String id;
  String nome;
  String desc;
  String data;
  

  Sorteio({
    this.id = '',
    required this.nome,
    required this.desc,
    required this.data,
  });
  
  factory Sorteio.fromJson(Map<String, dynamic> json) {
    return Sorteio(
      id: json['id'] as String? ?? '',
      nome: json['nome'] as String? ?? 'Sem nome',
      desc: json['desc'] as String? ?? 'Sem descrição',
      data: json['data'] as String? ?? 'Data não definida',
  
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'desc': desc,
      'data': data,
    };
  }
}