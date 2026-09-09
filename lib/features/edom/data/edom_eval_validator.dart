import 'models/edom_post_models.dart';
import 'models/edom_soal_response.dart';

class EdomValidationResult {
  final bool validate;
  final String errorMessage;
  final List<EdomPostItem> payload;

  EdomValidationResult({
    required this.validate,
    required this.errorMessage,
    required this.payload,
  });
}

class EdomEvalValidator {
  static EdomValidationResult buildEdomPayload({
    required List<EdomIndikator> indicators,
    required String Function(String indicator, int number) errorTemplate,
  }) {
    bool overallValidate = true;
    String firstErrorMessage = '';
    List<EdomPostItem> datapost = [];

    for (var indicator in indicators) {
      for (int i = 0; i < indicator.itemsoal.length; i++) {
        var soal = indicator.itemsoal[i];
        
        // Find answered option
        EdomJawaban? answered;
        try {
          answered = soal.itemjawaban.firstWhere((j) => j.terjawab == 'Y');
        } catch (e) {
          answered = null;
        }

        if (answered != null) {
          datapost.add(EdomPostItem(
            idkompetensi: indicator.idkompetensi,
            idsoal: soal.idsoal,
            jawaban: answered.indexpilihan,
            bobotjawaban: answered.value,
          ));
        } else {
          // Not answered
          if (overallValidate) {
            overallValidate = false;
            firstErrorMessage = errorTemplate(indicator.namakompetensi, i + 1);
          }
          
          datapost.add(EdomPostItem(
            idkompetensi: indicator.idkompetensi,
            idsoal: soal.idsoal,
            jawaban: "-",
            bobotjawaban: "-",
          ));
        }
      }
    }

    return EdomValidationResult(
      validate: overallValidate,
      errorMessage: firstErrorMessage,
      payload: datapost,
    );
  }
}
