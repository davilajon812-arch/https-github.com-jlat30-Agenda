import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../business/presentation/providers/business_providers.dart';
import '../domain/appointment.dart';
import '../domain/income.dart';
import 'providers/agenda_providers.dart';
import 'widgets/payment_method_labels.dart';

/// Ingresos cobrados del día, la semana o el mes.
class IncomeScreen extends ConsumerStatefulWidget {
  const IncomeScreen({super.key});

  @override
  ConsumerState<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends ConsumerState<IncomeScreen> {
  IncomePeriod _period = IncomePeriod.hoy;
  late DateTime _anchor = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final membership = ref.watch(activeBusinessProvider);
    if (membership == null) {
      return Center(child: Text(l10n.errorGeneric));
    }

    final currency = membership.business.currency;
    final query = (
      businessId: membership.business.id,
      period: _period,
      anchor: _anchor,
    );
    final income = ref.watch(incomeProvider(query));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(incomeProvider(query)),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            SegmentedButton<IncomePeriod>(
              segments: [
                ButtonSegment(value: IncomePeriod.hoy, label: Text(l10n.incomeToday)),
                ButtonSegment(
                  value: IncomePeriod.semana,
                  label: Text(l10n.incomeWeek),
                ),
                ButtonSegment(value: IncomePeriod.mes, label: Text(l10n.incomeMonth)),
              ],
              selected: {_period},
              showSelectedIcon: false,
              onSelectionChanged: (value) => setState(() {
                _period = value.first;
                _anchor = DateTime.now();
              }),
            ),
            const SizedBox(height: 16),
            income.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => ErrorView(
                message: l10n.errorGeneric,
                retryLabel: l10n.commonRetry,
                onRetry: () => ref.invalidate(incomeProvider(query)),
              ),
              data: (data) => _IncomeBody(
                summary: data,
                currency: currency,
                period: _period,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomeBody extends StatelessWidget {
  const _IncomeBody({
    required this.summary,
    required this.currency,
    required this.period,
  });

  final IncomeSummary summary;
  final String currency;
  final IncomePeriod period;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final money = NumberFormat.currency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      symbol: '$currency ',
      decimalDigits: 2,
    );

    if (summary.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(
              Icons.payments_outlined,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(l10n.incomeEmpty, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              l10n.incomeEmptyHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.incomeTotal, style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  money.format(summary.total),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.incomeCount(summary.count),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.incomeAverage}: ${money.format(summary.average)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (period == IncomePeriod.semana || period == IncomePeriod.mes) ...[
          const SizedBox(height: 16),
          _BreakdownSection(
            title: l10n.incomeByDay,
            buckets: summary.byDay,
            currency: currency,
            labelBuilder: (bucket) => bucket.date == null
                ? bucket.key
                : DateFormat.MMMEd(
                    Localizations.localeOf(context).toLanguageTag(),
                  ).format(bucket.date!),
            showBars: true,
          ),
        ],
        const SizedBox(height: 16),
        _BreakdownSection(
          title: l10n.incomeByMethod,
          buckets: summary.byMethod,
          currency: currency,
          labelBuilder: (bucket) => _methodLabel(l10n, bucket.key),
        ),
        const SizedBox(height: 16),
        _BreakdownSection(
          title: l10n.incomeByService,
          buckets: summary.byService,
          currency: currency,
          labelBuilder: (bucket) => bucket.key,
        ),
        const SizedBox(height: 16),
        _BreakdownSection(
          title: l10n.incomeByStaff,
          buckets: summary.byStaff,
          currency: currency,
          labelBuilder: (bucket) => bucket.key,
        ),
      ],
    );
  }

  static String _methodLabel(AppLocalizations l10n, String key) {
    return PaymentMethod.fromCode(key)?.label(l10n) ?? l10n.incomeMethodNone;
  }
}

/// Bloque de desglose con barras proporcionales.
class _BreakdownSection extends StatelessWidget {
  const _BreakdownSection({
    required this.title,
    required this.buckets,
    required this.currency,
    required this.labelBuilder,
    this.showBars = false,
  });

  final String title;
  final List<IncomeBucket> buckets;
  final String currency;
  final String Function(IncomeBucket) labelBuilder;
  final bool showBars;

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final money = NumberFormat.currency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      symbol: '$currency ',
      decimalDigits: 2,
    );
    final max = buckets
        .map((bucket) => bucket.amount)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final bucket in buckets)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        labelBuilder(bucket),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      money.format(bucket.amount),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (showBars && max > 0) ...[
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: bucket.amount / max,
                      minHeight: 6,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
