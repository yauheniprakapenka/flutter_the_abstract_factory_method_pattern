import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:number_panel/number_panel.dart';

import '../../../../../passcode.dart';
import '../../../../app/bloc/passcode_bloc/events/events.dart';
import '../../../../app/bloc/passcode_bloc/passcode_bloc.dart';
import '../../../../app/bloc/passcode_bloc/passcode_state.dart';
import '../decorators/animation_width_decorator.dart';
import '../widgets/passcode_indicator.dart';

class PasscodeIndicatorViewWithAnimation extends StatefulWidget {
  const PasscodeIndicatorViewWithAnimation({Key? key}) : super(key: key);

  @override
  State<PasscodeIndicatorViewWithAnimation> createState() => _PasscodeIndicatorViewWithAnimationState();
}

class _PasscodeIndicatorViewWithAnimationState extends State<PasscodeIndicatorViewWithAnimation> with TickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 80);
  var _animationRepeatCounter = 0;

  late final _leftWidthCntrl = AnimationController(duration: _animationDuration, vsync: this);
  late final _rightWidthCntrl = AnimationController(duration: _animationDuration, vsync: this);

  @override
  void dispose() {
    _leftWidthCntrl.dispose();
    _rightWidthCntrl.dispose();
    super.dispose();
  }

  @override
  Widget build(context) {
    return BlocConsumer<NumberPanelBloc, NumberPanelState>(
      listener: (context, numberPanelState) {
        BlocProvider.of<PasscodeBloc>(context).add(RepeatingPasscodeEvent(numberPanelState.currentEnteredPasscode));
      },
      builder: (context, numberPanelState) {
        return BlocBuilder<PasscodeBloc, PasscodeState>(
          builder: (context, passcodeState) {
            if (passcodeState.passcodeResult == PasscodeResult.passcodeNotMatches) {
              _makePasscodeNotMatchesAnimation().whenComplete(() {
                context.read<NumberPanelBloc>().add(ClearNumberPanelStateEvent());
              });
            }

            return AnimationWidthDecorator(
              leftWidthCntrl: _leftWidthCntrl,
              rightWidthCntrl: _rightWidthCntrl,
              child: PasscodeIndicator(
                indicatorLength: UIServiceLocator.instance.get<IPasscodeConfig>().passcodeLength,
                activeIndicatorLength: passcodeState.passcode.repeatedPasscode.length,
                passcodeResult: passcodeState.passcodeResult,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _makePasscodeNotMatchesAnimation() async {
    _resetCounter();
    try {
      const maxAnimationRepeat = 2;
      while (_animationRepeatCounter < maxAnimationRepeat) {
        await _leftWidthCntrl.forward().orCancel;
        await _leftWidthCntrl.reverse().orCancel;
        await _rightWidthCntrl.forward().orCancel;
        await _rightWidthCntrl.reverse().orCancel;
        _animationRepeatCounter++;
      }
    } on Exception catch (e) {
      debugPrint('Passcode ticker exception: ${e.toString()}');
    }
  }

  void _resetCounter() {
    _animationRepeatCounter = 0;
  }
}