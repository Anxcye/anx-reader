enum DeviceDisplayProfile {
  standard('standard'),
  eInk('eink');

  const DeviceDisplayProfile(this.code);

  final String code;

  static DeviceDisplayProfile fromCode(String? code) => switch (code) {
        'eink' || 'eInk' => eInk,
        _ => standard,
      };
}
