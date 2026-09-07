import '../../../../core/network/api_service.dart';
import '../models/pengumuman_response.dart';

class HomeRepository {
  final ApiService _apiService;

  HomeRepository(this._apiService);

  Future<PengumumanResponse?> getPengumuman({
    String? kodeJen,
    String? kodeFak,
    String? kodePst,
  }) async {
    return _apiService.getPengumuman(
      kodeJen: kodeJen,
      kodeFak: kodeFak,
      kodePst: kodePst,
    );
  }
}
