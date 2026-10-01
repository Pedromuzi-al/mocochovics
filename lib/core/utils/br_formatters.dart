import 'package:intl/intl.dart';

abstract final class BrFormatters {
  static final _integer = NumberFormat.decimalPattern('pt_BR');
  static final _date = DateFormat('dd/MM/yyyy', 'pt_BR');

  static String currencyFromCents(int cents) {
    final absolute = cents.abs();
    final decimal = (absolute % 100).toString().padLeft(2, '0');
    return '${cents < 0 ? '-' : ''}R\$\u00a0${_integer.format(absolute ~/ 100)},$decimal';
  }

  static String date(DateTime value) => _date.format(value);
}
