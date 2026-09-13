import '../../core/localization/voice_language.dart';
import '../../models/cold_storage_unit.dart';
import '../../models/status_level.dart';
import '../../models/storage_analytics.dart';
import '../../models/produce_batch.dart';
import '../../models/alert_item.dart';

class NaturalVoiceGenerator {
  /// 1. Home Screen Chamber Status Speech
  static String generateUnitOverview({
    required ColdStorageUnit unit,
    required VoiceLanguage language,
  }) {
    final reading = unit.reading;
    final status = unit.status;

    switch (language) {
      case VoiceLanguage.hindi:
        if (status == StatusLevel.good) {
          return 'नमस्ते किसान भाई। आपका ${unit.name}, ${unit.village} में सामान्य रूप से काम कर रहा है। '
              'तापमान ${reading.temperature.toStringAsFixed(1)} डिग्री और नमी ${reading.humidity.toInt()} प्रतिशत पर बहुत अच्छी है। '
              'बैटरी ${reading.battery} प्रतिशत है और सोलर पावर चालू है। '
              'पीसीएम कोल्ड बैकअप में ${reading.formattedPcmHours} समय बचा है। '
              'आपकी फसल पूरी तरह सुरक्षित है। किसी कार्रवाई की आवश्यकता नहीं है।';
        } else if (!reading.gridPower) {
          return 'ध्यान दें किसान भाई। ${unit.name} में बिजली चली गई है। '
              'लेकिन चिंता की कोई बात नहीं है, पीसीएम कोल्ड बैकअप में अभी ${reading.formattedPcmHours} का सुरक्षित बैकअप है। '
              'तापमान ${reading.temperature.toStringAsFixed(1)} डिग्री है और फसल सुरक्षित है। दरवाजा बंद रखें।';
        } else {
          return 'सावधान किसान भाई। ${unit.name} में तापमान ${reading.temperature.toStringAsFixed(1)} डिग्री सेल्सियस हो गया है, जो बहुत अधिक है। '
              '${reading.doorOpen ? "चैंबर का दरवाजा खुला हुआ है। " : ""}'
              'कृपया तुरंत स्टोरेज का दरवाजा और बिजली सप्लाई जांचें।';
        }

      case VoiceLanguage.assamese:
        if (status == StatusLevel.good) {
          return 'নমস্কাৰ কৃষক বন্ধু। আপোনাৰ ${unit.village} স্থিত ${unit.name} সম্পূর্ণ স্বাভাবিকভাৱে চলি আছে। '
              'উত্তাপ ${reading.temperature.toStringAsFixed(1)} ডিগ্ৰী আৰু আৰ্দ্ৰতা ${reading.humidity.toInt()} শতাংশত সঠিক অৱস্থাত আছে। '
              'বেটাৰী ${reading.battery} শতাংশ আৰু সৌৰ শক্তি সক্ৰিয় হৈ আছে। '
              'পিচিএম বেকআপত ${reading.formattedPcmHours} সময় মজুত আছে। '
              'আপোনাৰ শস্য সম্পূর্ণ নিৰাপদ। কোনো চিন্তাৰ প্ৰয়োজন নাই।';
        } else if (!reading.gridPower) {
          return 'মনোযোগ দিয়ক। ${unit.name} ত বিজুলী সংযোগ বিচ্ছিন্ন হৈছে। '
              'কিন্তু পিচিএম থাৰ্মেল বেকআপত ${reading.formattedPcmHours} সময় আছে। শস্য এতিয়াও সুৰক্ষিত। দুৱাৰ বন্ধ ৰাখক।';
        } else {
          return 'সাৱধান হওক! ${unit.name} ত উত্তাপ বৃদ্ধি পাই ${reading.temperature.toStringAsFixed(1)} ডিগ্ৰী হৈছে। '
              '${reading.doorOpen ? "কোল্ড ষ্টোৰেজৰ দুৱাৰখন খোলা আছে। " : ""}'
              'অনুগ্ৰহ কৰি অতি সোনকালে দুৱাৰখন পৰীক্ষা কৰি বন্ধ কৰক।';
        }

      case VoiceLanguage.khasi:
        if (status == StatusLevel.good) {
          return 'Khublei nongrep. Ka ${unit.name} jong phi ha ${unit.village} ka trei bha. '
              'Ka jingshit ka long ${reading.temperature.toStringAsFixed(1)} degree bad ka humidity ${reading.humidity.toInt()} percent. '
              'Ka battery ka don ${reading.battery} percent bad ka solar power ka trei bha. '
              'Ka mar rep jong phi ka shngain. Ym donkam ban leh eiei.';
        } else {
          return 'Sngewbha pynleit jingmut! Ka jingshit ha ${unit.name} ka la kiew sha ${reading.temperature.toStringAsFixed(1)} degree. '
              'Sngewbha leit khmih ia ka jingkhang bad ka bording.';
        }

      case VoiceLanguage.manipuri:
        if (status == StatusLevel.good) {
          return 'Khurumjari loumi ebanba. Nahakki ${unit.village} da leiba ${unit.name} asi phana chatthari. '
              'Temperature ${reading.temperature.toStringAsFixed(1)} degree amasung humidity ${reading.humidity.toInt()} percent oiri. '
              'Battery ${reading.battery} percent amasung solar power chatli. '
              'Nahakki potthok yamna thungna kanna lei. Kari amatta touruba nattre.';
        } else {
          return 'Yengbiro! ${unit.name} da temperature ${reading.temperature.toStringAsFixed(1)} degree da kanglei. '
              'Chamber thong hangduna leiba yai. Hannadana thong thingjinbiro.';
        }

      case VoiceLanguage.english:
        if (status == StatusLevel.good) {
          return 'Your ${unit.name} in ${unit.village} is working normally. '
              'Temperature and humidity are good at ${reading.temperature.toStringAsFixed(1)} degrees and ${reading.humidity.toInt()} percent. '
              'Battery is ${reading.battery} percent and solar power is active. '
              'PCM cold backup has ${reading.formattedPcmHours} remaining. '
              'Your produce is safe. No action is needed.';
        } else if (!reading.gridPower) {
          return 'Power outage alert. Grid power is offline in ${unit.name}, but cold storage is running securely on backup. '
              'PCM thermal reserve has ${reading.formattedPcmHours} remaining. '
              'Produce is safe. Please keep chamber doors closed.';
        } else {
          return 'Attention farmer. The temperature in ${unit.name} is elevated at ${reading.temperature.toStringAsFixed(1)} degrees celsius. '
              '${reading.doorOpen ? "The chamber door is currently open. " : ""}'
              '${unit.recommendedAction}';
        }
    }
  }

  /// 2. Detailed Technical Diagnostic Briefing
  static String generateDetailedDiagnostics({
    required ColdStorageUnit unit,
    required StorageAnalytics analytics,
    required VoiceLanguage language,
  }) {
    if (language == VoiceLanguage.hindi) {
      return 'तकनीकी डायग्नोस्टिक रिपोर्ट, ${unit.name} के लिए। '
          'पिछले 24 घंटे का औसत तापमान ${analytics.avgTemp.toStringAsFixed(1)} डिग्री दर्ज किया गया है। '
          'न्यूनतम तापमान ${analytics.minTemp.toStringAsFixed(1)} और अधिकतम ${analytics.maxTemp.toStringAsFixed(1)} डिग्री रहा। '
          'सोलर जनरेशन पीक ${analytics.peakSolarWatts.toInt()} वाट दर्ज हुआ। '
          'पीसीएम रिजर्व में ${unit.reading.formattedPcmHours} का बैकअप शेष है। '
          'माइक्रोकंट्रोलर और कंप्रेसर स्वास्थ्य उत्तम है।';
    } else if (language == VoiceLanguage.assamese) {
      return 'কাৰিকৰী বিশ্লেষণ প্ৰতিবেদন, ${unit.name} ৰ বাবে। '
          'বিগত ২৪ ঘণ্টাত গড় উত্তাপ ${analytics.avgTemp.toStringAsFixed(1)} ডিগ্ৰী আছিল। '
          'সৌৰ শক্তিৰ সৰ্বোচ্চ উৎপাদন ${analytics.peakSolarWatts.toInt()} ৱাট। '
          'পিচিএম সংৰক্ষিত শক্তি এতিয়াও ${unit.reading.formattedPcmHours} বাকী আছে। '
          'কম্প্ৰেছৰ আৰু ছেঞ্চৰসমূহ সঠিকভাৱে কাৰ্যক্ষম হৈ আছে।';
    }

    return 'Technical diagnostic briefing for ${unit.name}. '
        'Average 24-hour temperature is ${analytics.avgTemp.toStringAsFixed(1)} degrees celsius, '
        'with a minimum of ${analytics.minTemp.toStringAsFixed(1)} degrees and maximum of ${analytics.maxTemp.toStringAsFixed(1)} degrees. '
        'Solar peak was ${analytics.peakSolarWatts.toInt()} watts. '
        'Phase change thermal backup currently has ${unit.reading.formattedPcmHours} remaining. '
        'All controller, compressor, and sensor health checks are nominal.';
  }

  /// 3. Produce Batch Health Speech
  static String generateProduceReport({
    required ProduceBatch batch,
    required double currentTemp,
    required int remainingDays,
    required VoiceLanguage language,
  }) {
    if (language == VoiceLanguage.hindi) {
      return 'फसल रिपोर्ट: ${batch.cropProfile.name}, बैच ${batch.batchId}। '
          'भंडारण मात्रा ${batch.quantityKg.toInt()} किलोग्राम है, जो ${batch.storageAgeDays} दिनों से रखी है। '
          'सुरक्षित भंडारण अवधि में लगभग $remainingDays दिन शेष हैं। '
          'वर्तमान थोक अनुमानित मूल्य ₹${batch.estimatedMarketValue.toInt()} है।';
    }

    return 'Produce health report for ${batch.cropProfile.name}, Batch ${batch.batchId} in ${batch.unitName}. '
        'Stored quantity is ${batch.quantityKg.toInt()} kilograms. '
        'It has been stored for ${batch.storageAgeDays} days, with approximately $remainingDays days remaining in the optimal window. '
        'Current chamber temperature is ${currentTemp.toStringAsFixed(1)} degrees celsius. '
        'Estimated wholesale market value is ${batch.estimatedMarketValue.toInt()} rupees.';
  }

  /// 4. Actionable Alert Speech
  static String generateAlertSpeech({
    required AlertItem alert,
    required VoiceLanguage language,
  }) {
    if (language == VoiceLanguage.hindi) {
      return 'चेतावनी! ${alert.title}, ${alert.unitName} में। '
          'संभावित कारण: ${alert.possibleCause}। '
          'सुझाव: ${alert.recommendedAction}';
    } else if (language == VoiceLanguage.assamese) {
      return 'সতৰ্কবাণী! ${alert.title}, ${alert.unitName} ত। '
          'কাৰণ: ${alert.possibleCause}। '
          'পৰামৰ্শ: ${alert.recommendedAction}';
    }

    return 'Attention farmer. ${alert.title} in ${alert.unitName}. '
        'Possible cause: ${alert.possibleCause}. '
        'Recommended action: ${alert.recommendedAction}';
  }

  /// 5. Market Sell-or-Store Decision Speech
  static String generateMarketDecisionSpeech({
    required String cropName,
    required String decisionLabel,
    required String mandiName,
    required double currentPrice,
    required double projectedPrice,
    required double expectedGain,
    required VoiceLanguage language,
  }) {
    if (language == VoiceLanguage.hindi) {
      return 'बाजार निर्णय: $cropName के लिए सुझाव है $decisionLabel। '
          '$mandiName में वर्तमान भाव ₹${currentPrice.toInt()} प्रति किलो है और 7 दिनों में ₹${projectedPrice.toInt()} तक जाने का अनुमान है। '
          'अनुमानित लाभ लगभग ₹${expectedGain.toInt()} होगा।';
    } else if (language == VoiceLanguage.assamese) {
      return 'বজাৰ পৰামৰ্শ: $cropName ৰ বাবে $decisionLabel কৰাটো লাভজনক। '
          '$mandiName ত বর্তমান মূল্য প্রতি কেজিত ₹${currentPrice.toInt()} আৰু ৭ দিনত ₹${projectedPrice.toInt()} হোৱাৰ আশা আছে।';
    } else if (language == VoiceLanguage.khasi) {
      return 'Ka jingiarap iew: Na ka bynta $cropName, ngi ai jingmut $decisionLabel. '
          'Ka dor ha $mandiName ka long ₹${currentPrice.toInt()} shi kilo bad kan kiew sha ka ₹${projectedPrice.toInt()}.';
    } else if (language == VoiceLanguage.manipuri) {
      return 'Market pamel: $cropName gi damak $decisionLabel touba phani. '
          '$mandiName da houjikti kg da ₹${currentPrice.toInt()} oiri amasung ₹${projectedPrice.toInt()} da leigani khalli.';
    }

    return 'Market Decision Advisory for $cropName: Recommendation is to $decisionLabel. '
        'Current price at $mandiName is ${currentPrice.toInt()} rupees per kilogram, projected to reach ${projectedPrice.toInt()} rupees in 7 days. '
        'Estimated net gain is approximately ${expectedGain.toInt()} rupees after cold storage costs.';
  }

  /// 6. Cold Chain Transport Speech
  static String generateTransitAdvisorySpeech({
    required String cropName,
    required String destinationMandi,
    required double currentTemp,
    required double batteryOrPcmHours,
    required String statusLabel,
    required VoiceLanguage language,
  }) {
    if (language == VoiceLanguage.hindi) {
      return 'कोल्ड-चेन परिवहन रिपोर्ट: $cropName की खेप $destinationMandi के लिए रास्ते में है। '
          'तापमान ${currentTemp.toStringAsFixed(1)} डिग्री सेल्सियस है और $batteryOrPcmHours घंटे का कोल्ड बैकअप बचा है। '
          'स्थिति: $statusLabel।';
    } else if (language == VoiceLanguage.assamese) {
      return 'কোল্ড-চেইন পৰিবহন খবৰ: $cropName ৰ যোগান $destinationMandi লৈ গৈ আছে। '
          'উত্তাপ ${currentTemp.toStringAsFixed(1)} ডিগ্ৰী আৰু $batteryOrPcmHours ঘণ্টাৰ বেকআপ আছে। '
          'অৱস্থা: $statusLabel।';
    }

    return 'Cold chain transport report: Consignment of $cropName is in transit to $destinationMandi. '
        'Current temperature is ${currentTemp.toStringAsFixed(1)} degrees celsius with ${batteryOrPcmHours.toStringAsFixed(1)} hours of cold reserve remaining. '
        'Status is $statusLabel.';
  }
}
