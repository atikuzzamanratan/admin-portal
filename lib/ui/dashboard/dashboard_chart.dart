// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter_redux/flutter_redux.dart';

// Project imports:
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/dashboard/dashboard_selectors.dart';
import 'package:invoiceninja_flutter/ui/app/form_card.dart';
import 'package:invoiceninja_flutter/utils/formatting.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';

class DashboardChart extends StatefulWidget {
  const DashboardChart({
    @required this.data,
    @required this.title,
    @required this.currencyId,
    @required this.onDateSelected,
  });

  final List<ChartDataGroup> data;
  final String title;
  final String currencyId;
  final Function(int, String) onDateSelected;

  static const PERIOD_CURRENT = 'current';
  static const PERIOD_PREVIOUS = 'previous';

  @override
  _DashboardChartState createState() => _DashboardChartState();
}

class _DashboardChartState extends State<DashboardChart> {
  String _selected;
  int _selectedIndex = 0;

  void _onSelectionChanged(charts.SelectionModel model) {
    final selectedDatum = model.selectedDatum;

    DateTime date;
    double total = 0.0;
    final measures = <String, num>{};

    if (selectedDatum.isNotEmpty) {
      date = selectedDatum.first.datum.date;
      selectedDatum
          .where((charts.SeriesDatum datumPair) =>
              datumPair.series.id == DashboardChart.PERIOD_CURRENT)
          .forEach((charts.SeriesDatum datumPair) {
        total += datumPair.datum.amount;
        measures[datumPair.series.displayName] = datumPair.datum.amount;
      });
    }

    setState(() {
      if (date != null) {
        _selected = formatDate(date.toIso8601String(), context) +
            ' • ' +
            formatNumber(total, context, currencyId: widget.currencyId);
      } else {
        _selected = null;
      }
    });

    widget.onDateSelected(_selectedIndex, convertDateTimeToSqlDate(date));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localization = AppLocalization.of(context);
    final state = StoreProvider.of<AppState>(context).state;
    final color = state.prefState.enableDarkMode
        ? charts.MaterialPalette.white
        : charts.MaterialPalette.gray.shade700;

    final series = widget.data[_selectedIndex];
    final settings = state.dashboardUIState.settings;

    final chart = charts.TimeSeriesChart(
      series.chartSeries,
      animate: true,
      selectionModels: [
        charts.SelectionModelConfig(
          type: charts.SelectionModelType.info,
          changedListener: _onSelectionChanged,
        ),
      ],
      behaviors: [
        charts.SeriesLegend(
          outsideJustification: charts.OutsideJustification.endDrawArea,
        ),
        /*
        charts.InitialSelection(selectedDataConfig: [
          charts.SeriesDatumConfig<String>(
              DashboardChart.PERIOD_CURRENT, '...')
        ]),
         */
      ],
      domainAxis: charts.DateTimeAxisSpec(
          renderSpec: charts.SmallTickRendererSpec(
              labelStyle: charts.TextStyleSpec(color: color),
              lineStyle: charts.LineStyleSpec(color: color))),
      primaryMeasureAxis: charts.NumericAxisSpec(
        renderSpec: charts.GridlineRendererSpec(
            labelStyle: charts.TextStyleSpec(color: color),
            lineStyle: charts.LineStyleSpec(color: color)),
      ),
    );

    return FormCard(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(bottom: 24, top: 8),
          child: Text(
            widget.title,
            style: theme.textTheme.headline5,
          ),
        ),
        Divider(height: 1.0),
        LimitedBox(
          maxHeight: settings.enableComparison ? 122 : 102,
          child: ListView(
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            children: widget.data.map((dataGroup) {
              final int index = widget.data.indexOf(dataGroup);
              final bool isSelected = index == _selectedIndex;
              final bool isIncrease = dataGroup.total > dataGroup.previousTotal;
              final String changeAmount = (isIncrease ? '+' : '') +
                  formatNumber(
                      dataGroup.total - dataGroup.previousTotal, context,
                      currencyId: widget.currencyId);
              final changePercent = (isIncrease ? '+' : '') +
                  formatNumber(
                      dataGroup.total != 0 && dataGroup.previousTotal != 0
                          ? round(
                              (dataGroup.total - dataGroup.previousTotal) /
                                  dataGroup.previousTotal *
                                  100,
                              2)
                          : 0.0,
                      context,
                      formatNumberType: FormatNumberType.percent,
                      currencyId: widget.currencyId);
              final String changeString = dataGroup.total == 0 ||
                      dataGroup.previousTotal == 0 ||
                      dataGroup.total == dataGroup.previousTotal
                  ? (settings.enableComparison ? ' ' : '')
                  : '$changeAmount ($changePercent)';

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                    _selected = null;
                  });
                },
                child: Container(
                  color: isSelected ? state.accentColor : theme.cardColor,
                  padding:
                      EdgeInsets.only(left: 16, top: 16, right: 32, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(localization.lookup(dataGroup.name),
                          style: theme.textTheme.headline6.copyWith(
                            color: isSelected ? Colors.white : null,
                          )),
                      SizedBox(height: 4),
                      Text(
                          formatNumber(dataGroup.total, context,
                              currencyId: widget.currencyId),
                          style: theme.textTheme.headline5.copyWith(
                              color: isSelected ? Colors.white : null)),
                      SizedBox(height: 4),
                      changeString.isNotEmpty
                          ? Text(
                              changeString,
                              style: TextStyle(
                                fontSize: 16,
                                color: isSelected
                                    ? Colors.white
                                    : (isIncrease ? Colors.green : Colors.red),
                              ),
                            )
                          : SizedBox(),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Divider(height: 1.0),
        SizedBox(
          height: 240.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ClipRect(
              child: chart,
            ),
          ),
        ),
        Divider(height: 1.0),
        Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Expanded(
                child: Text(
                  localization.average +
                      ': ' +
                      formatNumber(series.average, context,
                          currencyId: widget.currencyId),
                  style: theme.textTheme.headline6,
                ),
              ),
              _selected != null
                  ? Text(
                      _selected,
                      style: theme.textTheme.headline6,
                    )
                  : SizedBox(),
            ],
          ),
        ),
      ],
    );
  }
}
