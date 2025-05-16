class Sorteio {
  String id;
  String nome;
  String desc;
  String img;
  String data;
  
  // Optional parameters or ones that might be null
  int? quantidade;
  double? preco;
  
  Sorteio({
    this.id = '',
    required this.nome,
    required this.desc,
    required this.img,
    required this.data,
    this.quantidade,
    this.preco,
  });
  
  factory Sorteio.fromJson(Map<String, dynamic> json) {
    return Sorteio(
      id: json['id'] as String? ?? '',
      nome: json['nome'] as String? ?? 'Sem nome',
      desc: json['desc'] as String? ?? 'Sem descrição',
      img: json['img'] as String? ?? '',
      data: json['data'] as String? ?? 'Data não definida',
      quantidade: json['quantidade'] != null ? int.tryParse(json['quantidade'].toString()) : null,
      preco: json['preco'] != null ? double.tryParse(json['preco'].toString()) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'desc': desc,
      'img': img,
      'data': data,
      if (quantidade != null) 'quantidade': quantidade,
      if (preco != null) 'preco': preco,
    };
  }
}