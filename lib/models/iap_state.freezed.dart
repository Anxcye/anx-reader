// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'iap_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IapState {
  bool get isInitialized;
  bool get isAvailable;
  IAPStatus get status;
  DateTime? get trialStartDate;
  int get trialDaysLeft;
  DateTime? get purchaseDate;
  DateTime get lastChecked;
  bool get isOriginalUser;
  IapPurchaseFlowStatus get purchaseFlowStatus;
  String? get errorMessage;
  bool get isRefreshing;
  bool get isRestoring;
  bool get isPurchasing;
  List<ProductDetails> get products;
  String get storeName;

  /// Create a copy of IapState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $IapStateCopyWith<IapState> get copyWith =>
      _$IapStateCopyWithImpl<IapState>(this as IapState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is IapState &&
            (identical(other.isInitialized, isInitialized) ||
                other.isInitialized == isInitialized) &&
            (identical(other.isAvailable, isAvailable) ||
                other.isAvailable == isAvailable) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.trialStartDate, trialStartDate) ||
                other.trialStartDate == trialStartDate) &&
            (identical(other.trialDaysLeft, trialDaysLeft) ||
                other.trialDaysLeft == trialDaysLeft) &&
            (identical(other.purchaseDate, purchaseDate) ||
                other.purchaseDate == purchaseDate) &&
            (identical(other.lastChecked, lastChecked) ||
                other.lastChecked == lastChecked) &&
            (identical(other.isOriginalUser, isOriginalUser) ||
                other.isOriginalUser == isOriginalUser) &&
            (identical(other.purchaseFlowStatus, purchaseFlowStatus) ||
                other.purchaseFlowStatus == purchaseFlowStatus) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.isRefreshing, isRefreshing) ||
                other.isRefreshing == isRefreshing) &&
            (identical(other.isRestoring, isRestoring) ||
                other.isRestoring == isRestoring) &&
            (identical(other.isPurchasing, isPurchasing) ||
                other.isPurchasing == isPurchasing) &&
            const DeepCollectionEquality().equals(other.products, products) &&
            (identical(other.storeName, storeName) ||
                other.storeName == storeName));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isInitialized,
      isAvailable,
      status,
      trialStartDate,
      trialDaysLeft,
      purchaseDate,
      lastChecked,
      isOriginalUser,
      purchaseFlowStatus,
      errorMessage,
      isRefreshing,
      isRestoring,
      isPurchasing,
      const DeepCollectionEquality().hash(products),
      storeName);

  @override
  String toString() {
    return 'IapState(isInitialized: $isInitialized, isAvailable: $isAvailable, status: $status, trialStartDate: $trialStartDate, trialDaysLeft: $trialDaysLeft, purchaseDate: $purchaseDate, lastChecked: $lastChecked, isOriginalUser: $isOriginalUser, purchaseFlowStatus: $purchaseFlowStatus, errorMessage: $errorMessage, isRefreshing: $isRefreshing, isRestoring: $isRestoring, isPurchasing: $isPurchasing, products: $products, storeName: $storeName)';
  }
}

/// @nodoc
abstract mixin class $IapStateCopyWith<$Res> {
  factory $IapStateCopyWith(IapState value, $Res Function(IapState) _then) =
      _$IapStateCopyWithImpl;
  @useResult
  $Res call(
      {bool isInitialized,
      bool isAvailable,
      IAPStatus status,
      DateTime? trialStartDate,
      int trialDaysLeft,
      DateTime? purchaseDate,
      DateTime lastChecked,
      bool isOriginalUser,
      IapPurchaseFlowStatus purchaseFlowStatus,
      String? errorMessage,
      bool isRefreshing,
      bool isRestoring,
      bool isPurchasing,
      List<ProductDetails> products,
      String storeName});
}

/// @nodoc
class _$IapStateCopyWithImpl<$Res> implements $IapStateCopyWith<$Res> {
  _$IapStateCopyWithImpl(this._self, this._then);

  final IapState _self;
  final $Res Function(IapState) _then;

  /// Create a copy of IapState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isInitialized = null,
    Object? isAvailable = null,
    Object? status = null,
    Object? trialStartDate = freezed,
    Object? trialDaysLeft = null,
    Object? purchaseDate = freezed,
    Object? lastChecked = null,
    Object? isOriginalUser = null,
    Object? purchaseFlowStatus = null,
    Object? errorMessage = freezed,
    Object? isRefreshing = null,
    Object? isRestoring = null,
    Object? isPurchasing = null,
    Object? products = null,
    Object? storeName = null,
  }) {
    return _then(_self.copyWith(
      isInitialized: null == isInitialized
          ? _self.isInitialized
          : isInitialized // ignore: cast_nullable_to_non_nullable
              as bool,
      isAvailable: null == isAvailable
          ? _self.isAvailable
          : isAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as IAPStatus,
      trialStartDate: freezed == trialStartDate
          ? _self.trialStartDate
          : trialStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      trialDaysLeft: null == trialDaysLeft
          ? _self.trialDaysLeft
          : trialDaysLeft // ignore: cast_nullable_to_non_nullable
              as int,
      purchaseDate: freezed == purchaseDate
          ? _self.purchaseDate
          : purchaseDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastChecked: null == lastChecked
          ? _self.lastChecked
          : lastChecked // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isOriginalUser: null == isOriginalUser
          ? _self.isOriginalUser
          : isOriginalUser // ignore: cast_nullable_to_non_nullable
              as bool,
      purchaseFlowStatus: null == purchaseFlowStatus
          ? _self.purchaseFlowStatus
          : purchaseFlowStatus // ignore: cast_nullable_to_non_nullable
              as IapPurchaseFlowStatus,
      errorMessage: freezed == errorMessage
          ? _self.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      isRefreshing: null == isRefreshing
          ? _self.isRefreshing
          : isRefreshing // ignore: cast_nullable_to_non_nullable
              as bool,
      isRestoring: null == isRestoring
          ? _self.isRestoring
          : isRestoring // ignore: cast_nullable_to_non_nullable
              as bool,
      isPurchasing: null == isPurchasing
          ? _self.isPurchasing
          : isPurchasing // ignore: cast_nullable_to_non_nullable
              as bool,
      products: null == products
          ? _self.products
          : products // ignore: cast_nullable_to_non_nullable
              as List<ProductDetails>,
      storeName: null == storeName
          ? _self.storeName
          : storeName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _IapState extends IapState {
  const _IapState(
      {required this.isInitialized,
      required this.isAvailable,
      required this.status,
      this.trialStartDate,
      required this.trialDaysLeft,
      this.purchaseDate,
      required this.lastChecked,
      required this.isOriginalUser,
      required this.purchaseFlowStatus,
      this.errorMessage,
      required this.isRefreshing,
      required this.isRestoring,
      required this.isPurchasing,
      required final List<ProductDetails> products,
      required this.storeName})
      : _products = products,
        super._();

  @override
  final bool isInitialized;
  @override
  final bool isAvailable;
  @override
  final IAPStatus status;
  @override
  final DateTime? trialStartDate;
  @override
  final int trialDaysLeft;
  @override
  final DateTime? purchaseDate;
  @override
  final DateTime lastChecked;
  @override
  final bool isOriginalUser;
  @override
  final IapPurchaseFlowStatus purchaseFlowStatus;
  @override
  final String? errorMessage;
  @override
  final bool isRefreshing;
  @override
  final bool isRestoring;
  @override
  final bool isPurchasing;
  final List<ProductDetails> _products;
  @override
  List<ProductDetails> get products {
    if (_products is EqualUnmodifiableListView) return _products;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_products);
  }

  @override
  final String storeName;

  /// Create a copy of IapState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$IapStateCopyWith<_IapState> get copyWith =>
      __$IapStateCopyWithImpl<_IapState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _IapState &&
            (identical(other.isInitialized, isInitialized) ||
                other.isInitialized == isInitialized) &&
            (identical(other.isAvailable, isAvailable) ||
                other.isAvailable == isAvailable) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.trialStartDate, trialStartDate) ||
                other.trialStartDate == trialStartDate) &&
            (identical(other.trialDaysLeft, trialDaysLeft) ||
                other.trialDaysLeft == trialDaysLeft) &&
            (identical(other.purchaseDate, purchaseDate) ||
                other.purchaseDate == purchaseDate) &&
            (identical(other.lastChecked, lastChecked) ||
                other.lastChecked == lastChecked) &&
            (identical(other.isOriginalUser, isOriginalUser) ||
                other.isOriginalUser == isOriginalUser) &&
            (identical(other.purchaseFlowStatus, purchaseFlowStatus) ||
                other.purchaseFlowStatus == purchaseFlowStatus) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.isRefreshing, isRefreshing) ||
                other.isRefreshing == isRefreshing) &&
            (identical(other.isRestoring, isRestoring) ||
                other.isRestoring == isRestoring) &&
            (identical(other.isPurchasing, isPurchasing) ||
                other.isPurchasing == isPurchasing) &&
            const DeepCollectionEquality().equals(other._products, _products) &&
            (identical(other.storeName, storeName) ||
                other.storeName == storeName));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isInitialized,
      isAvailable,
      status,
      trialStartDate,
      trialDaysLeft,
      purchaseDate,
      lastChecked,
      isOriginalUser,
      purchaseFlowStatus,
      errorMessage,
      isRefreshing,
      isRestoring,
      isPurchasing,
      const DeepCollectionEquality().hash(_products),
      storeName);

  @override
  String toString() {
    return 'IapState(isInitialized: $isInitialized, isAvailable: $isAvailable, status: $status, trialStartDate: $trialStartDate, trialDaysLeft: $trialDaysLeft, purchaseDate: $purchaseDate, lastChecked: $lastChecked, isOriginalUser: $isOriginalUser, purchaseFlowStatus: $purchaseFlowStatus, errorMessage: $errorMessage, isRefreshing: $isRefreshing, isRestoring: $isRestoring, isPurchasing: $isPurchasing, products: $products, storeName: $storeName)';
  }
}

/// @nodoc
abstract mixin class _$IapStateCopyWith<$Res>
    implements $IapStateCopyWith<$Res> {
  factory _$IapStateCopyWith(_IapState value, $Res Function(_IapState) _then) =
      __$IapStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool isInitialized,
      bool isAvailable,
      IAPStatus status,
      DateTime? trialStartDate,
      int trialDaysLeft,
      DateTime? purchaseDate,
      DateTime lastChecked,
      bool isOriginalUser,
      IapPurchaseFlowStatus purchaseFlowStatus,
      String? errorMessage,
      bool isRefreshing,
      bool isRestoring,
      bool isPurchasing,
      List<ProductDetails> products,
      String storeName});
}

/// @nodoc
class __$IapStateCopyWithImpl<$Res> implements _$IapStateCopyWith<$Res> {
  __$IapStateCopyWithImpl(this._self, this._then);

  final _IapState _self;
  final $Res Function(_IapState) _then;

  /// Create a copy of IapState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? isInitialized = null,
    Object? isAvailable = null,
    Object? status = null,
    Object? trialStartDate = freezed,
    Object? trialDaysLeft = null,
    Object? purchaseDate = freezed,
    Object? lastChecked = null,
    Object? isOriginalUser = null,
    Object? purchaseFlowStatus = null,
    Object? errorMessage = freezed,
    Object? isRefreshing = null,
    Object? isRestoring = null,
    Object? isPurchasing = null,
    Object? products = null,
    Object? storeName = null,
  }) {
    return _then(_IapState(
      isInitialized: null == isInitialized
          ? _self.isInitialized
          : isInitialized // ignore: cast_nullable_to_non_nullable
              as bool,
      isAvailable: null == isAvailable
          ? _self.isAvailable
          : isAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as IAPStatus,
      trialStartDate: freezed == trialStartDate
          ? _self.trialStartDate
          : trialStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      trialDaysLeft: null == trialDaysLeft
          ? _self.trialDaysLeft
          : trialDaysLeft // ignore: cast_nullable_to_non_nullable
              as int,
      purchaseDate: freezed == purchaseDate
          ? _self.purchaseDate
          : purchaseDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastChecked: null == lastChecked
          ? _self.lastChecked
          : lastChecked // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isOriginalUser: null == isOriginalUser
          ? _self.isOriginalUser
          : isOriginalUser // ignore: cast_nullable_to_non_nullable
              as bool,
      purchaseFlowStatus: null == purchaseFlowStatus
          ? _self.purchaseFlowStatus
          : purchaseFlowStatus // ignore: cast_nullable_to_non_nullable
              as IapPurchaseFlowStatus,
      errorMessage: freezed == errorMessage
          ? _self.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      isRefreshing: null == isRefreshing
          ? _self.isRefreshing
          : isRefreshing // ignore: cast_nullable_to_non_nullable
              as bool,
      isRestoring: null == isRestoring
          ? _self.isRestoring
          : isRestoring // ignore: cast_nullable_to_non_nullable
              as bool,
      isPurchasing: null == isPurchasing
          ? _self.isPurchasing
          : isPurchasing // ignore: cast_nullable_to_non_nullable
              as bool,
      products: null == products
          ? _self._products
          : products // ignore: cast_nullable_to_non_nullable
              as List<ProductDetails>,
      storeName: null == storeName
          ? _self.storeName
          : storeName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
