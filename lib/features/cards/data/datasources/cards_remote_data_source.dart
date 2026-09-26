import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/utils/path_template.dart';
import '../../domain/entities/card_secrets.dart';
import '../models/card_transaction_model.dart';
import '../models/virtual_card_model.dart';

class CardsRemoteDataSource {
  final ApiClient _client;

  const CardsRemoteDataSource(this._client);

  Future<List<VirtualCardModel>> getCards() async => [for (final item in (await _client.get(ApiPaths.cards))['items'] as List<dynamic>) VirtualCardModel.fromJson(item as Map<String, dynamic>)];

  Future<List<CardTransactionModel>> getTransactions(String cardId) async => [
    for (final item in (await _client.get(ApiPaths.cardTransactions.withId(cardId)))['items'] as List<dynamic>) CardTransactionModel.fromJson(item as Map<String, dynamic>),
  ];

  Future<CardTransactionModel> makeTestPurchase(String cardId) async => CardTransactionModel.fromJson(await _client.post(ApiPaths.cardTestPurchase.withId(cardId)));

  Future<CardSecrets> reveal(String cardId, Map<String, dynamic> approval) async {
    final json = await _client.post(ApiPaths.cardReveal.withId(cardId), body: {'approval': approval});
    return CardSecrets(cvv: json['cvv'] as String, expiryMonth: json['expiryMonth'] as int, expiryYear: json['expiryYear'] as int, number: json['number'] as String);
  }

  Future<VirtualCardModel> update(String cardId, Map<String, dynamic> body) async => VirtualCardModel.fromJson(await _client.patch(ApiPaths.card.withId(cardId), body: body));
}
