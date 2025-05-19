class Ganhador {
  final String nome;
  final String telefone;
 

  Ganhador({
    required this.nome,
    required this.telefone,
    
  });

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'telefone': telefone,
      
    };
  }

  factory Ganhador.fromJson(Map<String, dynamic> json) {
    return Ganhador(
      nome: json['nome'] ?? '',
      telefone: json['telefone'] ?? '',
     
  
    );
  }
}