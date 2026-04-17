import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yumbook_app/models/transaction_model.dart';
import 'package:yumbook_app/state/transaction_store.dart';

enum TransactionFilter {
  all,
  reservation,
  refund,
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  static const Color _bg = Colors.white;
  static const Color _textDark = Color(0xFF383838);
  static const Color _border = Color(0xFFE5E5E5);

  TransactionFilter _filter = TransactionFilter.all;

  List<TransactionModel> _applyFilter(List<TransactionModel> items) {
    switch (_filter) {
      case TransactionFilter.all:
        return items;
      case TransactionFilter.reservation:
        return items
            .where((e) => e.type == TransactionType.reservation)
            .toList();
      case TransactionFilter.refund:
        return items.where((e) => e.type == TransactionType.refund).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: TransactionStore.instance,
      builder: (context, _) {
        final items = TransactionStore.instance.items;
        final filteredItems = _applyFilter(items);

        return Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 20),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.pop(context),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              size: 30,
                              color: _textDark,
                            ),
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          'Transactions',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SegmentedFilter(
                    selected: _filter,
                    onChanged: (value) {
                      setState(() {
                        _filter = value;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: filteredItems.isEmpty
                        ? const _EmptyTransactions()
                        : ListView.separated(
                            itemCount: filteredItems.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, color: _border),
                            itemBuilder: (context, index) {
                              return _TransactionRow(item: filteredItems[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SegmentedFilter extends StatelessWidget {
  final TransactionFilter selected;
  final ValueChanged<TransactionFilter> onChanged;

  const _SegmentedFilter({
    required this.selected,
    required this.onChanged,
  });

  static const Color _segBg = Color(0x1E767680);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _segBg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          _segment(
            label: 'All',
            value: TransactionFilter.all,
          ),
          _segment(
            label: 'Reservation',
            value: TransactionFilter.reservation,
          ),
          _segment(
            label: 'Refund',
            value: TransactionFilter.refund,
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required String label,
    required TransactionFilter value,
  }) {
    final isSelected = selected == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 20,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionModel item;

  const _TransactionRow({required this.item});

  static const Color _textDark = Color(0xFF383838);
  static const Color _textGray = Color(0xFF6E6E6E);

  @override
  Widget build(BuildContext context) {
    final iconBg = switch (item.type) {
      TransactionType.refund => const Color(0xFFE0F2E0),
      TransactionType.failed => const Color(0xFFF8DCDC),
      TransactionType.reservation => const Color(0xFFE5E5E5),
    };

    final icon = switch (item.type) {
      TransactionType.refund => Icons.arrow_downward_rounded,
      TransactionType.failed => Icons.close_rounded,
      TransactionType.reservation => Icons.arrow_upward_rounded,
    };

    final dateText = DateFormat('MM.dd.yyyy').format(item.createdAt);
    final cardLabel = '${item.cardBrand}••••${item.cardLast4}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 24,
              color: const Color(0xFF6E6E6E),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: SizedBox(
              height: 58,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.subtitle.isEmpty
                        ? item.title
                        : '${item.title}\n${item.subtitle}',
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        width: 18,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'MC',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          cardLabel,
                          style: const TextStyle(
                            color: _textGray,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 78,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.trailingText,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  dateText,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: _textGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  static const Color _textDark = Color(0xFF383838);
  static const Color _textGray = Color(0xFF6E6E6E);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 42,
            color: _textGray,
          ),
          SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: TextStyle(
              color: _textDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Your reservation charges and refunds will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textGray,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}