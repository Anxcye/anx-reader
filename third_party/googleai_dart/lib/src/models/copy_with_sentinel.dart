/// Sentinel value used in copyWith methods to distinguish between
/// "keep existing value" and "set to null".
///
/// When a parameter in copyWith is set to this value (the default),
/// the original field value is retained. To explicitly set a field to null,
/// pass `null` instead.
const unsetCopyWithValue = Object();
