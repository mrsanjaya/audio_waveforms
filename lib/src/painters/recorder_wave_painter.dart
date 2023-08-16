import 'package:flutter/material.dart';

import '/src/base/label.dart';
import '../base/utils.dart';

///This will paint the waveform
///
///Addtional Information to play around
///
///this gives location of first wave from right to left when scrolling
///
///-totalBackDistance.dx + dragOffset.dx + (spacing * i)
///
///this gives location of first wave from left to right when scrolling
///
///-totalBackDistance.dx + dragOffset.dx
class RecorderWavePainter extends CustomPainter {
  final List<double> waveData;
  final Color waveColor;
  final bool showMiddleLine;
  final double spacing;
  final double initialPosition;
  final bool showTop;
  final bool showBottom;
  final double bottomPadding;
  final StrokeCap waveCap;
  final Color middleLineColor;
  final double middleLineThickness;
  final Offset totalBackDistance;
  final Offset dragOffset;
  final double waveThickness;
  final VoidCallback pushBack;
  final bool callPushback;
  final bool extendWaveform;
  final bool showDurationLabel;
  final bool showHourInDuration;
  final double updateFrequecy;
  final Paint _wavePaint;
  final Paint _linePaint;
  final Paint _durationLinePaint;
  final TextStyle durationStyle;
  final Color durationLinesColor;
  final double durationTextPadding;
  final double durationLinesHeight;
  final double labelSpacing;
  final Shader? gradient;
  final bool shouldClearLabels;
  final VoidCallback revertClearLabelCall;
  final Function(int) setCurrentPositionDuration;
  final bool shouldCalculateScrolledPosition;
  final double scaleFactor;
  final Duration currentlyRecordedDuration;

  RecorderWavePainter({
    required this.waveData,
    required this.waveColor,
    required this.showMiddleLine,
    required this.spacing,
    required this.initialPosition,
    required this.showTop,
    required this.showBottom,
    required this.bottomPadding,
    required this.waveCap,
    required this.middleLineColor,
    required this.middleLineThickness,
    required this.totalBackDistance,
    required this.dragOffset,
    required this.waveThickness,
    required this.pushBack,
    required this.callPushback,
    required this.extendWaveform,
    required this.updateFrequecy,
    required this.showHourInDuration,
    required this.showDurationLabel,
    required this.durationStyle,
    required this.durationLinesColor,
    required this.durationTextPadding,
    required this.durationLinesHeight,
    required this.labelSpacing,
    required this.gradient,
    required this.shouldClearLabels,
    required this.revertClearLabelCall,
    required this.setCurrentPositionDuration,
    required this.shouldCalculateScrolledPosition,
    required this.scaleFactor,
    required this.currentlyRecordedDuration,
  })  : _wavePaint = Paint()
          ..color = waveColor
          ..strokeWidth = waveThickness
          ..strokeCap = waveCap,
        _linePaint = Paint()
          ..color = middleLineColor
          ..strokeWidth = middleLineThickness,
        _durationLinePaint = Paint()
          ..strokeWidth = 3
          ..color = durationLinesColor;
  var _labelPadding = 0.0;

  final List<Label> _labels = [];
  static const durationBuffer = 5;

  @override
  void paint(Canvas canvas, Size size) {
    if (shouldClearLabels) {
      _labels.clear();
      pushBack();
      revertClearLabelCall();
    }
    for (var i = 0; i < waveData.length; i++) {
      ///wave gradient
      if (gradient != null) _waveGradient();

      if (((spacing * i) + dragOffset.dx + spacing >
              size.width / (extendWaveform ? 1 : 2) + totalBackDistance.dx) &&
          callPushback) {
        pushBack();
      }

      ///draws waves
      _drawWave(canvas, size, i);

      ///duration labels
      if (showDurationLabel) {
        _addLabel(canvas, i, size);
        _drawTextInRange(canvas, i, size);
      }
    }

    ///middle line
    if (showMiddleLine) _drawMiddleLine(canvas, size);

    ///calculates scrolled position with respect to duration
    if (shouldCalculateScrolledPosition) _setScrolledDuration(size);
  }

  @override
  bool shouldRepaint(RecorderWavePainter oldDelegate) => true;

  void _drawTextInRange(Canvas canvas, int i, Size size) {
    if (_labels.isNotEmpty && i < _labels.length) {
      final label = _labels[i];
      final content = label.content;
      final offset = label.offset;
      final halfWidth = size.width / 2;
      final textSpan = TextSpan(
        text: content,
        style: durationStyle,
      );

      if (offset.dx > -halfWidth && offset.dx < halfWidth * 3) {
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(minWidth: 0, maxWidth: halfWidth * 2);
        textPainter.paint(canvas, offset);
      }
    }
  }

  void _addLabel(Canvas canvas, int i, Size size) {
    final labelDuration = Duration(seconds: i);
    final durationLineDx = _labelPadding + dragOffset.dx - totalBackDistance.dx;

    if (labelDuration <
        Duration(
            seconds: currentlyRecordedDuration.inSeconds + durationBuffer)) {
      canvas.drawLine(
          Offset(durationLineDx, size.height),
          Offset(durationLineDx, size.height + durationLinesHeight),
          _durationLinePaint);
      _labels.add(
        Label(
          content: showHourInDuration
              ? labelDuration.toHHMMSS()
              : labelDuration.inSeconds.toMMSS(),
          offset: Offset(
              durationLineDx - durationTextPadding, size.height + labelSpacing),
        ),
      );
    }
    _labelPadding += spacing * updateFrequecy;
  }

  void _drawMiddleLine(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      _linePaint,
    );
  }

  void _drawWave(Canvas canvas, Size size, int i) {
    final halfWidth = size.width / 2;
    final dx =
        -totalBackDistance.dx + dragOffset.dx + (spacing * i) - initialPosition;
    final upperDy = (size.height) -
        (showTop ? (waveData[i] * scaleFactor) : 0) -
        bottomPadding;
    final lowerDy = size.height +
        (showBottom ? waveData[i] * scaleFactor : 0) -
        bottomPadding;
    if (dx > -halfWidth && dx < halfWidth * 2) {
      canvas.drawLine(Offset(dx, upperDy), Offset(dx, lowerDy), _wavePaint);
    }
  }

  void _waveGradient() {
    _wavePaint.shader = gradient;
  }

  void _setScrolledDuration(Size size) {
    setCurrentPositionDuration(
        (((-totalBackDistance.dx + dragOffset.dx - (size.width / 2)) /
                    (spacing * updateFrequecy)) *
                1000)
            .abs()
            .toInt());
  }
}
