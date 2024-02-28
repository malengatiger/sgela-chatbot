import 'package:dart_mistral_api/dart_mistral_api.dart';

class MistralClientService {

  final MistralService mistralService;

  MistralClientService(this.mistralService);
  Future<List<MistralModel>> getModels(String apiKey) async {
    List<MistralModel> models = [];
    models = await mistralService.listModels(debug: true);

    return models;

  }
}
