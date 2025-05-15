import 'package:flutter/foundation.dart';

class Sorteio {
  String? id;
  String nome;
  String desc;
  String img;
  Duration duration;
  List<String> productIds;

  Sorteio({
    this.id,
    required this.nome,
    required this.desc,
    required this.img,
    required this.duration,
    required this.productIds,
  });

  factory Sorteio.fromJson(Map<String, dynamic> json) {
    return Sorteio(
      nome: json['nome'],
      desc: json['desc'],
      img: json['img'],
      duration: Duration(minutes: json['durationMinutes']),
      productIds: List<String>.from(json['productIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'desc': desc,
      'img': img,
      'durationMinutes': duration.inMinutes,
      'productIds': productIds,
    };
  }
}