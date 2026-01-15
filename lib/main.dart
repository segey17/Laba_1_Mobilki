import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: const Color(0xFFEA7A1F), // orange
          secondary: const Color(0xFFEA7A1F),
          surface: const Color(0xFFF5F5F7),
          onSurface: const Color(0xFF1C1F24),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FB),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w600),
        ),
      ),
      home: const CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _display = '0';
  String _input = '';
  double? _operand1;
  String? _operator; // '+', '-', '×', '÷', '^'
  bool _error = false;

  static const Color digitColor = Color(0xFF2E3138);
  static const Color digitPressed = Color(0xFF3A3D45);
  static const Color opColor = Color(0xFFEA7A1F);
  static const Color opPressed = Color(0xFFD56814);
  static const Color eqColor = Color(0xFFE3600A);
  static const Color eqPressed = Color(0xFFCB550A);

  final ScrollController _displayScrollController = ScrollController();

  void _reset() {
    setState(() {
      _display = '0';
      _input = '';
      _operand1 = null;
      _operator = null;
      _error = false;
    });
    _scheduleScrollToEnd();
  }

  void _appendDigit(String d) {
    if (_error) _reset();
    setState(() {

      if (_operator == null && _operand1 != null && _input.isEmpty) {
        _operand1 = null;
      }
      if (d == '.') {
        if (_input.isEmpty) {
          _input = '0.';
        } else if (_input.contains('.')) {

        } else {
          _input += '.';
        }
      } else {

        if (_input == '0') {
          _input = d;
        } else {
          _input += d;
        }
      }
      _display = _input;
    });
    _scheduleScrollToEnd();
  }

  void _setOperator(String op) {
    if (_error) return;
    setState(() {
      if (_input.isEmpty && _operand1 != null) {

        _operator = op;
        _display = '${_format(_operand1!)} $op';
        return;
      }
      if (_input.isEmpty && _operand1 == null) {

        return;
      }
      final value = double.tryParse(_input);
      if (value == null) {
        _setError('Ошибка: неверный ввод');
        return;
      }
      if (_operand1 == null || _operator == null) {
        _operand1 = value;
        _operator = op;
        _input = '';
        _display = '${_format(_operand1!)} $op';
        return;
      }
      final res = _calculate(_operand1!, value, _operator!);
      if (res == null) return;
      _operand1 = res;
      _operator = op;
      _input = '';
      _display = '${_format(_operand1!)} $op';
    });
    _scheduleScrollToEnd();
  }

  void _equals() {
    if (_error) return;
    if (_operator == null) return;
    final value = double.tryParse(_input.isEmpty ? '0' : _input);
    if (value == null || _operand1 == null) {
      _setError('Ошибка: неверный ввод');
      return;
    }
    setState(() {
      final res = _calculate(_operand1!, value, _operator!);
      if (res == null) return;
      _display = _format(res);
      _operand1 = res;
      _operator = null;
      _input = '';
    });
    _scheduleScrollToEnd();
  }

  double? _calculate(double a, double b, String op) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        if (b == 0) {
          _setError('Ошибка: деление на 0');
          return null;
        }
        return a / b;
      case '^':
        final res = math.pow(a, b);
        if (res is num) {
          if (res.isNaN || res.isInfinite) {
            _setError('Ошибка: операция невозможна');
            return null;
          }
          return res.toDouble();
        }
        _setError('Ошибка: операция невозможна');
        return null;
      default:
        _setError('Ошибка: неизвестная операция');
        return null;
    }
  }

  void _setError(String message) {
    setState(() {
      _display = message;
      _input = '';
      _operator = null;
      _operand1 = null;
      _error = true;
    });
    _scheduleScrollToEnd();
  }

  String _format(double value) {
    if (!value.isFinite) return value.toString();
    if (value % 1 == 0) return value.toStringAsFixed(0);

    String s = value.toStringAsPrecision(12);
    if (!s.contains('.') || s.contains('e') || s.contains('E')) return s;

    s = s.replaceAllMapped(RegExp(r'(\.\d*[1-9])0+$'), (m) => m.group(1)!);
    s = s.replaceAll(RegExp(r'\.$'), '');
    return s;
  }

  Widget _displayPanel() {
    const double horizontalPadding = 20.0;
    final TextStyle style = const TextStyle(
      fontSize: 44,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1C1F24),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6)),
            ],
          ),
          child: SingleChildScrollView(
            controller: _displayScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth - horizontalPadding * 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _display,
                  maxLines: 1,
                  softWrap: false,
                  style: style,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _scheduleScrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_displayScrollController.hasClients) return;
      final max = _displayScrollController.position.maxScrollExtent;
      _displayScrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _button(String label, {required Color color, required Color pressedColor, required VoidCallback onTap, int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: CalcButton(
          label: label,
          color: color,
          pressedColor: pressedColor,
          onTap: onTap,
        ),
      ),
    );
  }

  void _backspace() {
    if (_error) {
      _reset();
      return;
    }
    setState(() {
      if (_input.isEmpty && _operator == null && _operand1 != null) {
        _input = _format(_operand1!);
        _operand1 = null;
      }

      if (_input.isNotEmpty) {
        _input = _input.substring(0, _input.length - 1);
      }

      if (_input.isEmpty || _input == '-' || _input == '-0') {
        _input = '';
        if (_operator != null && _operand1 != null) {
          _display = '${_format(_operand1!)} ${_operator!}';
        } else {
          _display = '0';
        }
      } else {
        _display = _input;
      }
    });
    _scheduleScrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _displayPanel(),
              const SizedBox(height: 10),
              Row(
                children: [
                  _button('C', color: Colors.red.shade600, pressedColor: Colors.red.shade700, onTap: _reset),
                  _button('^', color: opColor, pressedColor: opPressed, onTap: () => _setOperator('^')),
                  _button('÷', color: opColor, pressedColor: opPressed, onTap: () => _setOperator('÷')),
                  _button('×', color: opColor, pressedColor: opPressed, onTap: () => _setOperator('×')),
                ],
              ),
              Row(
                children: [
                  _button('7', color: digitColor, pressedColor: digitPressed, onTap: () => _appendDigit('7')),
                  _button('8', color: digitColor, pressedColor: digitPressed, onTap: () => _appendDigit('8')),
                  _button('9', color: digitColor, pressedColor: digitPressed, onTap: () => _appendDigit('9')),
                  _button('-', color: opColor, pressedColor: opPressed, onTap: () => _setOperator('-')),
                ],
              ),
              Row(
                children: [
                  _button('4', color: digitColor, pressedColor: digitPressed, onTap: () => _appendDigit('4')),
                  _button('5', color: digitColor, pressedColor: digitPressed, onTap: () => _appendDigit('5')),
                  _button('6', color: digitColor, pressedColor: digitPressed, onTap: () => _appendDigit('6')),
                  _button('+', color: opColor, pressedColor: opPressed, onTap: () => _setOperator('+')),
                ],
              ),
              Row(
                children: [
                  _button('1', color: digitColor, pressedColor: digitPressed, onTap: () => _appendDigit('1')),
                  _button('2', color: digitColor, pressedColor: digitPressed, onTap: () => _appendDigit('2')),
                  _button('3', color: digitColor, pressedColor: digitPressed, onTap: () => _appendDigit('3')),
                  _button('=', color: eqColor, pressedColor: eqPressed, onTap: _equals),
                ],
              ),
              Row(
                children: [
                  _button('0', color: digitColor, pressedColor: digitPressed, onTap: () => _appendDigit('0'), flex: 2),
                  _button('.', color: digitColor, pressedColor: digitPressed, onTap: () => _appendDigit('.')),
                  _button('←', color: opColor, pressedColor: opPressed, onTap: _backspace),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _displayScrollController.dispose();
    super.dispose();
  }
}

class CalcButton extends StatefulWidget {
  const CalcButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.color,
    required this.pressedColor,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color pressedColor;

  @override
  State<CalcButton> createState() => _CalcButtonState();
}

class _CalcButtonState extends State<CalcButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          height: 64,
          decoration: BoxDecoration(
            color: _pressed ? widget.pressedColor : widget.color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 4)),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
