/// Response wrapper for Mandi Price API
class MandiPriceResponse {
  final int status;
  final List<MandiPriceItem> data;

  MandiPriceResponse({
    required this.status,
    required this.data,
  });

  factory MandiPriceResponse.fromJson(Map<String, dynamic> json) {
    return MandiPriceResponse(
      status: json['status'] ?? 0,
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => MandiPriceItem.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}

/// Individual Mandi Price entry
class MandiPriceItem {
  final String id;
  final String state;
  final String apmc; // Market name
  final String commodity;
  final String minPrice;
  final String modalPrice;
  final String maxPrice;
  final String commodityArrivals;
  final String commodityTraded;
  final String createdAt;
  final String status;
  final String commodityUom; // Unit of measurement (Qui = Quintal)

  MandiPriceItem({
    required this.id,
    required this.state,
    required this.apmc,
    required this.commodity,
    required this.minPrice,
    required this.modalPrice,
    required this.maxPrice,
    required this.commodityArrivals,
    required this.commodityTraded,
    required this.createdAt,
    required this.status,
    required this.commodityUom,
  });

  factory MandiPriceItem.fromJson(Map<String, dynamic> json) {
    return MandiPriceItem(
      id: json['id']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      apmc: json['apmc']?.toString() ?? '',
      commodity: json['commodity']?.toString() ?? '',
      minPrice: json['min_price']?.toString() ?? '',
      modalPrice: json['modal_price']?.toString() ?? '',
      maxPrice: json['max_price']?.toString() ?? '',
      commodityArrivals: json['commodity_arrivals']?.toString() ?? '',
      commodityTraded: json['commodity_traded']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      commodityUom: json['Commodity_Uom']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'state': state,
      'apmc': apmc,
      'commodity': commodity,
      'min_price': minPrice,
      'modal_price': modalPrice,
      'max_price': maxPrice,
      'commodity_arrivals': commodityArrivals,
      'commodity_traded': commodityTraded,
      'created_at': createdAt,
      'status': status,
      'Commodity_Uom': commodityUom,
    };
  }

  // Helper getters
  double? get minPriceValue => double.tryParse(minPrice);
  double? get modalPriceValue => double.tryParse(modalPrice);
  double? get maxPriceValue => double.tryParse(maxPrice);
  double? get arrivalsValue => double.tryParse(commodityArrivals);
  double? get tradedValue => double.tryParse(commodityTraded);

  String get minPriceFormatted => minPriceValue != null ? '₹${minPriceValue!.toStringAsFixed(0)}' : 'N/A';
  String get modalPriceFormatted => modalPriceValue != null ? '₹${modalPriceValue!.toStringAsFixed(0)}' : 'N/A';
  String get maxPriceFormatted => maxPriceValue != null ? '₹${maxPriceValue!.toStringAsFixed(0)}' : 'N/A';
  
  String get unitLabel {
    switch (commodityUom.toLowerCase()) {
      case 'qui':
      case 'quintal':
        return 'Quintal';
      case 'kg':
        return 'Kg';
      case 'ton':
        return 'Ton';
      default:
        return commodityUom.isNotEmpty ? commodityUom : 'Unit';
    }
  }

  String get displayDate {
    try {
      final dateTime = DateTime.parse(createdAt);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
    } catch (e) {
      return createdAt;
    }
  }
}

class MandiPriceModel {
  static const List<String> allStatesMandiPrice = [
    "ANDAMAN AND NICOBAR ISLANDS",
    "ANDHRA PRADESH",
    "ASSAM",
    "BIHAR",
    "CHANDIGARH",
    "CHHATTISGARH",
    "GOA",
    "GUJARAT",
    "HARYANA",
    "HIMACHAL PRADESH",
    "JAMMU AND KASHMIR",
    "JHARKHAND",
    "KARNATAKA",
    "KERALA",
    "MADHYA PRADESH",
    "MAHARASHTRA",
    "NAGALAND",
    "ODISHA",
    "PUDUCHERRY",
    "PUNJAB",
    "RAJASTHAN",
    "TAMIL NADU",
    "TELANGANA",
    "TRIPURA",
    "UTTAR PRADESH",
    "UTTARAKHAND",
    "WEST BENGAL"
  ];
}