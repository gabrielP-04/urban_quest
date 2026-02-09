import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/poi.dart';

class PoiService {
  static Future<List<Poi>> loadPois() async {
    final jsonString = await rootBundle.loadString('assets/data/pois.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => Poi.fromJson(e)).toList();
  }
}
