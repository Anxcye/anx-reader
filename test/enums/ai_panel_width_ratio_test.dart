import 'package:anx_reader/enums/ai_panel_width_ratio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AI panel width ratio defaults to half for unknown values', () {
    expect(AiPanelWidthRatio.fromCode('unknown'), AiPanelWidthRatio.half);
    expect(AiPanelWidthRatio.half.factor, 0.5);
  });

  test('AI panel width ratio restores the one-third option', () {
    expect(AiPanelWidthRatio.fromCode('third'), AiPanelWidthRatio.third);
    expect(AiPanelWidthRatio.third.factor, closeTo(1 / 3, 0.0001));
  });
}
