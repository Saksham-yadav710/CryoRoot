import '../../models/mandi_market.dart';

class MarketDataService {
  static List<MandiQuote> getQuotesForCrop(String cropId) {
    switch (cropId) {
      case 'CROP-ORANGE':
      case 'CROP-KHASI-MANDARIN':
        return const [
          MandiQuote(
            marketName: 'Shillong Iewduh Market (Bara Bazar)',
            state: 'Meghalaya',
            district: 'East Khasi Hills',
            currentPricePerKg: 80.0,
            changeLast7DaysPerKg: 6.0,
            projectedPrice7DaysPerKg: 98.0,
            distanceKm: 140.0,
            transportCostPerKg: 2.5,
          ),
          MandiQuote(
            marketName: 'Guwahati Pamohi Wholesale APMC',
            state: 'Assam',
            district: 'Kamrup Metro',
            currentPricePerKg: 75.0,
            changeLast7DaysPerKg: 4.0,
            projectedPrice7DaysPerKg: 92.0,
            distanceKm: 165.0,
            transportCostPerKg: 3.0,
          ),
          MandiQuote(
            marketName: 'Tezpur Regulated Market',
            state: 'Assam',
            district: 'Sonitpur',
            currentPricePerKg: 68.0,
            changeLast7DaysPerKg: 2.0,
            projectedPrice7DaysPerKg: 78.0,
            distanceKm: 25.0,
            transportCostPerKg: 0.8,
          ),
        ];

      case 'CROP-BHUT-JOLOKIA':
      case 'CROP-KING-CHILLI':
        return const [
          MandiQuote(
            marketName: 'Guwahati Pamohi Wholesale APMC',
            state: 'Assam',
            district: 'Kamrup Metro',
            currentPricePerKg: 380.0,
            changeLast7DaysPerKg: 25.0,
            projectedPrice7DaysPerKg: 440.0,
            distanceKm: 165.0,
            transportCostPerKg: 5.0,
          ),
          MandiQuote(
            marketName: 'Imphal Khwairamband Bazar',
            state: 'Manipur',
            district: 'Imphal West',
            currentPricePerKg: 400.0,
            changeLast7DaysPerKg: 30.0,
            projectedPrice7DaysPerKg: 460.0,
            distanceKm: 310.0,
            transportCostPerKg: 9.0,
          ),
        ];

      case 'CROP-ASSAM-LEMON':
      case 'CROP-KAJI-NEMU':
        return const [
          MandiQuote(
            marketName: 'Guwahati Pamohi Wholesale APMC',
            state: 'Assam',
            district: 'Kamrup Metro',
            currentPricePerKg: 65.0,
            changeLast7DaysPerKg: 5.0,
            projectedPrice7DaysPerKg: 78.0,
            distanceKm: 165.0,
            transportCostPerKg: 2.2,
          ),
          MandiQuote(
            marketName: 'Tezpur Regulated Market',
            state: 'Assam',
            district: 'Sonitpur',
            currentPricePerKg: 58.0,
            changeLast7DaysPerKg: 3.0,
            projectedPrice7DaysPerKg: 68.0,
            distanceKm: 25.0,
            transportCostPerKg: 0.8,
          ),
        ];

      case 'CROP-TOMATO':
        return const [
          MandiQuote(
            marketName: 'Guwahati Pamohi Wholesale APMC',
            state: 'Assam',
            district: 'Kamrup Metro',
            currentPricePerKg: 32.0,
            changeLast7DaysPerKg: -3.0,
            projectedPrice7DaysPerKg: 28.0,
            distanceKm: 165.0,
            transportCostPerKg: 1.5,
          ),
          MandiQuote(
            marketName: 'Tezpur Regulated Market',
            state: 'Assam',
            district: 'Sonitpur',
            currentPricePerKg: 30.0,
            changeLast7DaysPerKg: -2.0,
            projectedPrice7DaysPerKg: 26.0,
            distanceKm: 25.0,
            transportCostPerKg: 0.5,
          ),
        ];

      case 'CROP-GINGER':
        return const [
          MandiQuote(
            marketName: 'Shillong Iewduh Market (Bara Bazar)',
            state: 'Meghalaya',
            district: 'East Khasi Hills',
            currentPricePerKg: 65.0,
            changeLast7DaysPerKg: 8.0,
            projectedPrice7DaysPerKg: 82.0,
            distanceKm: 140.0,
            transportCostPerKg: 2.0,
          ),
          MandiQuote(
            marketName: 'Guwahati Pamohi Wholesale APMC',
            state: 'Assam',
            district: 'Kamrup Metro',
            currentPricePerKg: 60.0,
            changeLast7DaysPerKg: 6.0,
            projectedPrice7DaysPerKg: 76.0,
            distanceKm: 165.0,
            transportCostPerKg: 2.2,
          ),
        ];

      default:
        return const [
          MandiQuote(
            marketName: 'Guwahati Pamohi Wholesale APMC',
            state: 'Assam',
            district: 'Kamrup Metro',
            currentPricePerKg: 25.0,
            changeLast7DaysPerKg: 2.0,
            projectedPrice7DaysPerKg: 30.0,
            distanceKm: 165.0,
            transportCostPerKg: 1.2,
          ),
          MandiQuote(
            marketName: 'Tezpur Regulated Market',
            state: 'Assam',
            district: 'Sonitpur',
            currentPricePerKg: 22.0,
            changeLast7DaysPerKg: 1.0,
            projectedPrice7DaysPerKg: 25.0,
            distanceKm: 25.0,
            transportCostPerKg: 0.5,
          ),
        ];
    }
  }
}
