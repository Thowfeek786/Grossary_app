import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:models/models.dart';

class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _users => _db.collection('users');

  Future<void> createUser(UserModel user) async {
    await _users.doc(user.id).set(user.toFirestore());
  }

  Future<void> updateUser(UserModel user) async {
    await _users.doc(user.id).update(user.toFirestore());
  }

  Future<UserModel?> getUserById(String id) async {
    final doc = await _users.doc(id).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel?> getUserStream(String id) {
    return _users.doc(id).snapshots().map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  Stream<List<UserModel>> getUsersByRole(UserRole role) {
    return _users
        .where('role', isEqualTo: role.name)
        .snapshots()
        .map((s) => s.docs.map(UserModel.fromFirestore).toList());
  }

  Stream<List<UserModel>> getAllUsers() {
    return _users
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(UserModel.fromFirestore).toList());
  }

  Future<void> setUserApproval(String userId, bool approved) async {
    await _users.doc(userId).update({'isApproved': approved});
  }

  Future<void> setUserActive(String userId, bool active) async {
    await _users.doc(userId).update({'isActive': active});
  }

  Future<void> updateUserRole(String userId, UserRole role) async {
    await _users.doc(userId).update({'role': role.name});
  }

  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? phone,
    String? photoUrl,
    String? shopName,
    String? shopAddress,
    double? latitude,
    double? longitude,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (shopName != null) updates['shopName'] = shopName;
    if (shopAddress != null) updates['shopAddress'] = shopAddress;
    if (latitude != null) updates['latitude'] = latitude;
    if (longitude != null) updates['longitude'] = longitude;
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _users.doc(userId).update(updates);
  }

  // Address subcollection
  static final Map<String, List<AddressModel>> _addressCache = {};

  CollectionReference _addressCol(String userId) =>
      _users.doc(userId).collection('addresses');

  List<AddressModel> getCachedAddresses(String userId) {
    return _addressCache[userId] ?? [];
  }

  Stream<List<AddressModel>> getAddresses(String userId) {
    return _addressCol(userId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => AddressModel.fromMap(d.data() as Map<String, dynamic>, docId: d.id))
              .toList();
          if (list.isNotEmpty) {
            _addressCache[userId] = list;
          }
          return list;
        });
  }

  Future<String> addAddress(String userId, AddressModel address) async {
    final ref = _addressCol(userId).doc();
    final model = AddressModel.fromMap({...address.toMap(), 'id': ref.id, 'userId': userId});
    await ref.set(model.toMap());
    return ref.id;
  }

  Future<void> updateAddress(String userId, AddressModel address) async {
    await _addressCol(userId).doc(address.id).update(address.toMap());
  }

  Future<void> deleteAddress(String userId, String addressId) async {
    await _addressCol(userId).doc(addressId).delete();
  }

  Future<void> setDefaultAddress(String userId, String addressId) async {
    final batch = _db.batch();
    final addresses = await _addressCol(userId).get();
    for (final doc in addresses.docs) {
      batch.update(doc.reference, {'isDefault': doc.id == addressId});
    }
    await batch.commit();
  }

  Future<void> updatePartnerStats(String userId, {int? deliveries, double? earnings, double? rating}) async {
    final updates = <String, dynamic>{};
    if (deliveries != null) updates['totalDeliveries'] = FieldValue.increment(deliveries);
    if (earnings != null) updates['totalEarnings'] = FieldValue.increment(earnings);
    if (rating != null) updates['rating'] = rating;
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _users.doc(userId).update(updates);
  }
}
