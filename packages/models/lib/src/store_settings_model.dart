import 'package:cloud_firestore/cloud_firestore.dart';

const String _defaultTerms = '''
1. Acceptance of Terms
By using GroceryGo, you agree to these Terms of Service. Please read them carefully before using our quick commerce grocery platform.

2. Service Guarantee
GroceryGo provides fresh grocery delivery from local dealers and partners. Delivery estimates are target goals subject to local weather and traffic conditions.

3. Pricing and Payments
All prices include applicable taxes. We reserve the right to modify prices or promotional discounts at any time prior to order confirmation.

4. Customer Refunds
Refund claims for damaged, incorrect, or expired items are processed instantly to the GroceryGo wallet within 24 hours of delivery.
''';

const String _defaultPrivacy = '''
1. Data Collection
GroceryGo collects user account details, address data, and order history solely to provide hyper-local delivery services and customer support.

2. Payment Security
All payment information is encrypted and securely processed by PCI-DSS compliant payment gateway providers. We do not store raw credit card numbers.

3. Location Rights
Location permissions are required to identify nearby dark stores and calculate accurate real-time GPS delivery routes.
''';

class StoreSettingsModel {
  final String id; // 'global' for Admin or dealerId for Dealer
  final double baseDeliveryFee;
  final double quickDeliveryFee;
  final double scheduledDeliveryFee;
  final double freeDeliveryThreshold;
  final bool isFreeDeliveryEnabled;

  // Dynamic Admin Customizable Platform Details
  final String appName;
  final String supportEmail;
  final String supportPhone;
  final String vendorHelplinePhone;
  final String whatsappSupportPhone;
  final String vendorSupportEmail;
  final double minOrderValue;
  final String appVersion;
  final String termsOfService;
  final String privacyPolicy;

  // Dynamic Gateway & System Controls
  final bool isCodEnabled;
  final bool isOnlinePaymentEnabled;
  final bool isWalletEnabled;
  final bool isMaintenanceMode;
  final bool requireDriverDocVerification;

  // Admin Official Bank & UPI Payment Details
  final String adminUpiId;
  final String adminPayeeName;
  final String adminAccountNumber;
  final String adminIfscCode;
  final String adminBankName;
  final String estimatedDeliveryTime;

  const StoreSettingsModel({
    required this.id,
    this.baseDeliveryFee = 40.0,
    this.quickDeliveryFee = 40.0,
    this.scheduledDeliveryFee = 0.0,
    this.freeDeliveryThreshold = 500.0,
    this.isFreeDeliveryEnabled = true,
    this.appName = 'GroceryGo',
    this.supportEmail = 'support@grocerygo.com',
    this.supportPhone = '1800-476-2379',
    this.vendorHelplinePhone = '1800-889-988',
    this.whatsappSupportPhone = '+919876543210',
    this.vendorSupportEmail = 'partners@grocerygo.com',
    this.minOrderValue = 100.0,
    this.appVersion = '1.0.0 (Build #42)',
    this.termsOfService = _defaultTerms,
    this.privacyPolicy = _defaultPrivacy,
    this.isCodEnabled = true,
    this.isOnlinePaymentEnabled = true,
    this.isWalletEnabled = true,
    this.isMaintenanceMode = false,
    this.requireDriverDocVerification = true,
    this.adminUpiId = 'groceryadmin@upi',
    this.adminPayeeName = 'GroceryGo Admin',
    this.adminAccountNumber = '987654321012',
    this.adminIfscCode = 'HDFC0001234',
    this.adminBankName = 'HDFC Bank',
    this.estimatedDeliveryTime = '20 to 30 minutes',
  });

  factory StoreSettingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final baseFee = (data['baseDeliveryFee'] as num?)?.toDouble() ?? 40.0;
    return StoreSettingsModel(
      id: doc.id,
      baseDeliveryFee: baseFee,
      quickDeliveryFee: (data['quickDeliveryFee'] as num?)?.toDouble() ?? baseFee,
      scheduledDeliveryFee: (data['scheduledDeliveryFee'] as num?)?.toDouble() ?? 0.0,
      freeDeliveryThreshold: (data['freeDeliveryThreshold'] as num?)?.toDouble() ?? 500.0,
      isFreeDeliveryEnabled: data['isFreeDeliveryEnabled'] ?? true,
      appName: data['appName'] as String? ?? 'GroceryGo',
      supportEmail: data['supportEmail'] as String? ?? 'support@grocerygo.com',
      supportPhone: data['supportPhone'] as String? ?? '1800-476-2379',
      vendorHelplinePhone: data['vendorHelplinePhone'] as String? ?? '1800-889-988',
      whatsappSupportPhone: data['whatsappSupportPhone'] as String? ?? '+919876543210',
      vendorSupportEmail: data['vendorSupportEmail'] as String? ?? 'partners@grocerygo.com',
      minOrderValue: (data['minOrderValue'] as num?)?.toDouble() ?? 100.0,
      appVersion: data['appVersion'] as String? ?? '1.0.0 (Build #42)',
      termsOfService: data['termsOfService'] as String? ?? _defaultTerms,
      privacyPolicy: data['privacyPolicy'] as String? ?? _defaultPrivacy,
      isCodEnabled: data['isCodEnabled'] ?? true,
      isOnlinePaymentEnabled: data['isOnlinePaymentEnabled'] ?? true,
      isWalletEnabled: data['isWalletEnabled'] ?? true,
      isMaintenanceMode: data['isMaintenanceMode'] ?? false,
      requireDriverDocVerification: data['requireDriverDocVerification'] ?? true,
      adminUpiId: data['adminUpiId'] as String? ?? 'groceryadmin@upi',
      adminPayeeName: data['adminPayeeName'] as String? ?? 'GroceryGo Admin',
      adminAccountNumber: data['adminAccountNumber'] as String? ?? '987654321012',
      adminIfscCode: data['adminIfscCode'] as String? ?? 'HDFC0001234',
      adminBankName: data['adminBankName'] as String? ?? 'HDFC Bank',
      estimatedDeliveryTime: data['estimatedDeliveryTime'] as String? ?? '20 to 30 minutes',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'baseDeliveryFee': baseDeliveryFee,
        'quickDeliveryFee': quickDeliveryFee,
        'scheduledDeliveryFee': scheduledDeliveryFee,
        'freeDeliveryThreshold': freeDeliveryThreshold,
        'isFreeDeliveryEnabled': isFreeDeliveryEnabled,
        'appName': appName,
        'supportEmail': supportEmail,
        'supportPhone': supportPhone,
        'vendorHelplinePhone': vendorHelplinePhone,
        'whatsappSupportPhone': whatsappSupportPhone,
        'vendorSupportEmail': vendorSupportEmail,
        'minOrderValue': minOrderValue,
        'appVersion': appVersion,
        'termsOfService': termsOfService,
        'privacyPolicy': privacyPolicy,
        'isCodEnabled': isCodEnabled,
        'isOnlinePaymentEnabled': isOnlinePaymentEnabled,
        'isWalletEnabled': isWalletEnabled,
        'isMaintenanceMode': isMaintenanceMode,
        'requireDriverDocVerification': requireDriverDocVerification,
        'adminUpiId': adminUpiId,
        'adminPayeeName': adminPayeeName,
        'adminAccountNumber': adminAccountNumber,
        'adminIfscCode': adminIfscCode,
        'adminBankName': adminBankName,
        'estimatedDeliveryTime': estimatedDeliveryTime,
      };

  StoreSettingsModel copyWith({
    String? id,
    double? baseDeliveryFee,
    double? quickDeliveryFee,
    double? scheduledDeliveryFee,
    double? freeDeliveryThreshold,
    bool? isFreeDeliveryEnabled,
    String? appName,
    String? supportEmail,
    String? supportPhone,
    String? vendorHelplinePhone,
    String? whatsappSupportPhone,
    String? vendorSupportEmail,
    double? minOrderValue,
    String? appVersion,
    String? termsOfService,
    String? privacyPolicy,
    bool? isCodEnabled,
    bool? isOnlinePaymentEnabled,
    bool? isWalletEnabled,
    bool? isMaintenanceMode,
    bool? requireDriverDocVerification,
    String? adminUpiId,
    String? adminPayeeName,
    String? adminAccountNumber,
    String? adminIfscCode,
    String? adminBankName,
    String? estimatedDeliveryTime,
  }) {
    return StoreSettingsModel(
      id: id ?? this.id,
      baseDeliveryFee: baseDeliveryFee ?? this.baseDeliveryFee,
      quickDeliveryFee: quickDeliveryFee ?? this.quickDeliveryFee,
      scheduledDeliveryFee: scheduledDeliveryFee ?? this.scheduledDeliveryFee,
      freeDeliveryThreshold: freeDeliveryThreshold ?? this.freeDeliveryThreshold,
      isFreeDeliveryEnabled: isFreeDeliveryEnabled ?? this.isFreeDeliveryEnabled,
      appName: appName ?? this.appName,
      supportEmail: supportEmail ?? this.supportEmail,
      supportPhone: supportPhone ?? this.supportPhone,
      vendorHelplinePhone: vendorHelplinePhone ?? this.vendorHelplinePhone,
      whatsappSupportPhone: whatsappSupportPhone ?? this.whatsappSupportPhone,
      vendorSupportEmail: vendorSupportEmail ?? this.vendorSupportEmail,
      minOrderValue: minOrderValue ?? this.minOrderValue,
      appVersion: appVersion ?? this.appVersion,
      termsOfService: termsOfService ?? this.termsOfService,
      privacyPolicy: privacyPolicy ?? this.privacyPolicy,
      isCodEnabled: isCodEnabled ?? this.isCodEnabled,
      isOnlinePaymentEnabled: isOnlinePaymentEnabled ?? this.isOnlinePaymentEnabled,
      isWalletEnabled: isWalletEnabled ?? this.isWalletEnabled,
      isMaintenanceMode: isMaintenanceMode ?? this.isMaintenanceMode,
      requireDriverDocVerification: requireDriverDocVerification ?? this.requireDriverDocVerification,
      adminUpiId: adminUpiId ?? this.adminUpiId,
      adminPayeeName: adminPayeeName ?? this.adminPayeeName,
      adminAccountNumber: adminAccountNumber ?? this.adminAccountNumber,
      adminIfscCode: adminIfscCode ?? this.adminIfscCode,
      adminBankName: adminBankName ?? this.adminBankName,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
    );
  }
}
