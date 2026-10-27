import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';

import '../../features/dashboard/domain/dashboard_report.dart';
import '../../features/products/domain/product_financials.dart';
import '../theme/app_theme.dart';
import '../utils/br_formatters.dart';
import 'finance_widgets.dart';
import 'premium_finance.dart';

Duration _duration(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 220);
TextStyle _caption(BuildContext context) => TextStyle(
  fontSize: 11,
  color: AppTheme.secondaryTextColor.resolveFrom(context),
);

/// Exact source values remain available without touching individual chart marks.
class FinancialDataButton extends StatelessWidget {
  const FinancialDataButton({
    required this.title,
    required this.entries,
    super.key,
  });
  final String title;
  final List<({String label, String value})> entries;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Valores de $title',
    child: CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.centerLeft,
      onPressed: () => openFinancePage<void>(
        context,
        CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Valores do gráfico'),
          ),
          child: SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: entries.length + 1,
              itemBuilder: (context, index) => index == 0
                  ? SectionHeading(title)
                  : LabeledAmount(
                      label: entries[index - 1].label,
                      amount: entries[index - 1].value,
                    ),
            ),
          ),
        ),
      ),
      child: const Text('Ver valores'),
    ),
  );
}

class FinancialLineChart extends StatelessWidget {
  const FinancialLineChart({
    required this.series,
    this.unit,
    this.emptyMessage = 'Sem histórico neste período.',
    super.key,
  });
  final List<ValueSeries> series;
  final String? unit;
  final String emptyMessage;
  String _value(Decimal value) =>
      unit == null ? money(value) : 'R\$ ${localizedDecimal(value, 6)}/$unit';
  @override
  Widget build(BuildContext context) {
    final visible = series
        .where((item) => item.points.any((point) => point.value != null))
        .toList();
    if (visible.isEmpty) {
      return FinanceEmptyState(
        message: emptyMessage,
        icon: CupertinoIcons.chart_bar,
      );
    }
    final dates =
        visible
            .expand((item) => item.points.map((point) => point.date))
            .toList()
          ..sort();
    final start = dates.first;
    final span = math.max(1, dates.last.difference(start).inDays);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${BrFormatters.date(dates.first)} — ${BrFormatters.date(dates.last)}',
          style: _caption(context),
        ),
        const SizedBox(height: 18),
        Semantics(
          label:
              'Gráfico de evolução. ${visible.map((item) => '${item.label}: ${item.points.where((point) => point.value != null).map((point) => '${BrFormatters.date(point.date)} ${_value(point.value!)}').join('; ')}').join('. ')}',
          child: SizedBox(
            height: 210,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: span.toDouble(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: CupertinoColors.separator
                        .resolveFrom(context)
                        .withValues(alpha: 0.2),
                    strokeWidth: 1,
                    dashArray: [4, 5],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: math.max(1, (span / 3).ceil()).toDouble(),
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          BrFormatters.date(
                            start.add(Duration(days: value.toInt())),
                          ).substring(0, 5),
                          style: _caption(context),
                        ),
                      ),
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (spots) => [
                      for (final spot in spots)
                        LineTooltipItem(
                          '${visible[spot.barIndex].label}\n${BrFormatters.date(start.add(Duration(days: spot.x.round())))} · ${_value(Decimal.parse(spot.y.toString()))}',
                          const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.white,
                          ),
                        ),
                    ],
                  ),
                ),
                lineBarsData: [
                  for (var index = 0; index < visible.length; index++)
                    LineChartBarData(
                      spots: [
                        for (final point in visible[index].points)
                          point.value == null
                              ? FlSpot.nullSpot
                              : FlSpot(
                                  point.date
                                      .difference(start)
                                      .inDays
                                      .toDouble(),
                                  point.value!.toDouble(),
                                ),
                      ],
                      color: FinancePalette
                          .chartColors[index %
                              FinancePalette.chartColors.length]
                          .resolveFrom(context),
                      barWidth: 2.5,
                      isCurved: false,
                      isStepLineChart: true,
                      dotData: FlDotData(
                        show: visible[index].points.length <= 8,
                      ),
                      belowBarData: BarAreaData(
                        show: visible.length == 1,
                        color: FinancePalette
                            .chartColors[index %
                                FinancePalette.chartColors.length]
                            .resolveFrom(context)
                            .withValues(alpha: 0.08),
                      ),
                    ),
                ],
              ),
              duration: _duration(context),
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < visible.length; index++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Icon(
                    CupertinoIcons.circle_fill,
                    size: 9,
                    color: FinancePalette
                        .chartColors[index % FinancePalette.chartColors.length]
                        .resolveFrom(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${visible[index].label} · último valor disponível: ${_value(visible[index].points.lastWhere((point) => point.value != null).value!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryTextColor.resolveFrom(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        FinancialDataButton(
          title: 'Evolução',
          entries: [
            for (final item in series)
              for (final point in item.points)
                (
                  label: '${item.label} · ${BrFormatters.date(point.date)}',
                  value: point.value == null
                      ? 'Indisponível'
                      : _value(point.value!),
                ),
          ],
        ),
      ],
    );
  }
}

class CashFlowChart extends StatelessWidget {
  const CashFlowChart({required this.report, super.key});
  final DashboardReport report;
  @override
  Widget build(BuildContext context) {
    if (!report.hasPayments) {
      return const FinanceEmptyState(
        message: 'Registre entradas e saídas pagas para acompanhar o caixa.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            Text(
              '↑ Entradas',
              style: TextStyle(
                fontSize: 13,
                color: FinancePalette.income.resolveFrom(context),
              ),
            ),
            Text(
              '↓ Saídas',
              style: TextStyle(
                fontSize: 13,
                color: FinancePalette.expense.resolveFrom(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Semantics(
          label:
              'Entradas e saídas pagas por ${report.grouping}. ${report.buckets.map((bucket) => '${BrFormatters.date(bucket.date)}: entradas ${BrFormatters.currencyFromCents(bucket.income)}, saídas ${BrFormatters.currencyFromCents(bucket.expenses)}').join('. ')}',
          child: SizedBox(
            height: 210,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: CupertinoColors.separator
                        .resolveFrom(context)
                        .withValues(alpha: 0.2),
                    strokeWidth: 1,
                    dashArray: [4, 5],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 ||
                            index >= report.buckets.length ||
                            index %
                                    math.max(
                                      1,
                                      (report.buckets.length / 4).ceil(),
                                    ) !=
                                0) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            BrFormatters.date(report.buckets[index].date)
                                .substring(0, 5),
                            style: _caption(context),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final bucket = report.buckets[group.x];
                      return BarTooltipItem(
                        '${BrFormatters.date(bucket.date)}\n${rodIndex == 0 ? 'Entradas' : 'Saídas'}: ${BrFormatters.currencyFromCents(rodIndex == 0 ? bucket.income : bucket.expenses)}',
                        const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.white,
                        ),
                      );
                    },
                  ),
                ),
                barGroups: [
                  for (var index = 0; index < report.buckets.length; index++)
                    BarChartGroupData(
                      x: index,
                      barsSpace: 3,
                      barRods: [
                        BarChartRodData(
                          toY: report.buckets[index].income / 100,
                          width: report.buckets.length > 14 ? 3 : 8,
                          color: FinancePalette.income.resolveFrom(context),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: report.buckets[index].expenses / 100,
                          width: report.buckets.length > 14 ? 3 : 8,
                          color: FinancePalette.expense.resolveFrom(context),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                ],
              ),
              duration: _duration(context),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Toque nas barras para ver os valores. Agrupado por ${report.grouping}.',
          style: _caption(context),
        ),
        FinancialDataButton(
          title: 'Entradas e saídas',
          entries: [
            for (final bucket in report.buckets) ...[
              (
                label: '${BrFormatters.date(bucket.date)} · Entradas',
                value: BrFormatters.currencyFromCents(bucket.income),
              ),
              (
                label: '${BrFormatters.date(bucket.date)} · Saídas',
                value: BrFormatters.currencyFromCents(bucket.expenses),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class ExpensesDonut extends StatefulWidget {
  const ExpensesDonut({required this.categories, super.key});
  final List<RankedAmount> categories;
  @override
  State<ExpensesDonut> createState() => _ExpensesDonutState();
}

class _ExpensesDonutState extends State<ExpensesDonut> {
  String? _selectedId;
  @override
  void didUpdateWidget(covariant ExpensesDonut oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.categories.any((item) => item.id == _selectedId)) {
      _selectedId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return const FinanceEmptyState(
        message: 'Nenhuma despesa paga no período.',
        icon: CupertinoIcons.chart_pie,
      );
    }
    final total = widget.categories.fold<int>(
      0,
      (sum, item) => sum + item.cents,
    );
    final selected = widget.categories
        .where((item) => item.id == _selectedId)
        .firstOrNull;
    return Column(
      children: [
        Semantics(
          label:
              'Despesas por categoria. ${widget.categories.map((item) => '${item.label}: ${BrFormatters.currencyFromCents(item.cents)}').join('. ')}',
          child: SizedBox(
            height: 210,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 55,
                sectionsSpace: 3,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    final index = response?.touchedSection?.touchedSectionIndex;
                    setState(
                      () => _selectedId =
                          event.isInterestedForInteractions &&
                              index != null &&
                              index >= 0 &&
                              index < widget.categories.length
                          ? widget.categories[index].id
                          : null,
                    );
                  },
                ),
                sections: [
                  for (var index = 0; index < widget.categories.length; index++)
                    PieChartSectionData(
                      value: widget.categories[index].cents.toDouble(),
                      color: FinancePalette
                          .chartColors[index %
                              FinancePalette.chartColors.length]
                          .resolveFrom(context),
                      radius: _selectedId == widget.categories[index].id
                          ? 43
                          : 35,
                      showTitle: false,
                    ),
                ],
              ),
              duration: _duration(context),
            ),
          ),
        ),
        for (var index = 0; index < widget.categories.length; index++)
          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 4),
            onPressed: () =>
                setState(() => _selectedId = widget.categories[index].id),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Icon(
                    CupertinoIcons.circle_fill,
                    size: 10,
                    color: FinancePalette
                        .chartColors[index % FinancePalette.chartColors.length]
                        .resolveFrom(context),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: LabeledAmount(
                    label:
                        '${widget.categories[index].label} · ${localizedDecimal(roundedDivision(Decimal.fromInt(widget.categories[index].cents * 100), Decimal.fromInt(total), 1), 1)}%',
                    amount: BrFormatters.currencyFromCents(
                      widget.categories[index].cents,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (selected != null)
          Text(
            'Selecionado: ${selected.label} · ${BrFormatters.currencyFromCents(selected.cents)}',
            style: _caption(context),
          ),
        FinancialDataButton(
          title: 'Despesas por categoria',
          entries: [
            for (final category in widget.categories)
              (
                label: category.label,
                value: BrFormatters.currencyFromCents(category.cents),
              ),
          ],
        ),
      ],
    );
  }
}
