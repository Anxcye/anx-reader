/// Configuration item type enumeration.
/// Defines the UI component type for a configuration field.
enum ConfigItemType {
  text('text input'),
  password('password input'),
  number('number input'),
  range('range slider'),
  select('select'),
  radio('radio'),
  checkbox('checkbox'),
  toggle('toggle'),
  tip('tip');

  const ConfigItemType(this.label);
  final String label;
}

/// Configuration item model.
/// Represents a single configurable field for a service provider.
class ConfigItem {
  final String key;
  final String label;
  final String? description;
  final ConfigItemType type;
  final dynamic defaultValue;
  final List<Map<String, dynamic>>? options;
  final String? link;
  // Range slider specific properties
  final double? min;
  final double? max;
  final double? step;
  final String? unit;

  ConfigItem({
    required this.key,
    required this.label,
    this.description,
    required this.type,
    this.defaultValue,
    this.options,
    this.link,
    this.min,
    this.max,
    this.step,
    this.unit,
  });

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'description': description,
      'type': type.name,
      'defaultValue': defaultValue,
      'options': options,
      'link': link,
      'min': min,
      'max': max,
      'step': step,
      'unit': unit,
    };
  }
}
