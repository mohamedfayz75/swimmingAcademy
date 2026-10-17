import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dialogs.dart';
import '../../../core/utils/formatters.dart';
import '../models/expense_model.dart';
import '../providers/dashboard_provider.dart';

class ExpensesManagementScreen extends ConsumerStatefulWidget {
  const ExpensesManagementScreen({super.key});

  @override
  ConsumerState<ExpensesManagementScreen> createState() => _ExpensesManagementScreenState();
}

class _ExpensesManagementScreenState extends ConsumerState<ExpensesManagementScreen> {
  DateTime _currentDate = DateTime.now();

  String get _currentMonthYear =>
      '${_currentDate.month.toString().padLeft(2, '0')}-${_currentDate.year}';

  void _previousMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month - 1);
    });
    ref.read(selectedMonthYearProvider.notifier).state = _currentMonthYear;
  }

  void _nextMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + 1);
    });
    ref.read(selectedMonthYearProvider.notifier).state = _currentMonthYear;
  }

  void _showExpenseDialog({ExpenseModel? existingExpense}) {
    final isEditing = existingExpense != null;
    final categoryController = TextEditingController(text: existingExpense?.category ?? '');
    final amountController =
        TextEditingController(text: isEditing ? existingExpense.amount.toStringAsFixed(0) : '');
    final notesController = TextEditingController(text: existingExpense?.notes ?? '');
    DateTime selectedDate = existingExpense?.date.toDate() ?? DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(isEditing ? Icons.edit : Icons.add_shopping_cart, color: AppTheme.accentTeal),
              const SizedBox(width: 8),
              Text(
                isEditing ? 'تعديل المصروف' : 'تسجيل مصروف جديد',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'بند المصروف (كتابة حرة) *',
                    hintText: 'مثلاً: كلور، كهرباء، صيانة سباكة، إيجار...',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ المدفوع (ج.م) *',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 12),
                // Date Picker field
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: AppTheme.primaryBlue),
                            const SizedBox(width: 8),
                            Text('تاريخ الفاتورة:', style: GoogleFonts.cairo(fontSize: 13)),
                          ],
                        ),
                        Text(
                          '${selectedDate.year}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.day.toString().padLeft(2, '0')}',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'بيان وتفاصيل إضافية (اختياري)',
                    hintText: 'تفاصيل الفاتورة، اسم المورد أو الشخص المستلم...',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final category = categoryController.text.trim();
                final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                if (category.isEmpty) {
                  AppDialogs.showWarningSnackBar(context, 'يرجى كتابة بند المصروف');
                  return;
                }
                if (amount <= 0) {
                  AppDialogs.showWarningSnackBar(context, 'يرجى كتابة مبلغ صحيح أكبر من الصفر');
                  return;
                }

                final monthYearStr =
                    '${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}';

                if (isEditing) {
                  final updated = existingExpense.copyWith(
                    category: category,
                    amount: amount,
                    date: Timestamp.fromDate(selectedDate),
                    notes: notesController.text.trim(),
                    monthYear: monthYearStr,
                  );
                  await ref.read(dashboardRepositoryProvider).updateExpense(updated);
                  if (mounted) {
                    Navigator.pop(ctx);
                    AppDialogs.showSuccessSnackBar(context, 'تم تعديل المصروف بنجاح');
                  }
                } else {
                  final newExpense = ExpenseModel(
                    id: 'EXP-${DateTime.now().millisecondsSinceEpoch}',
                    category: category,
                    amount: amount,
                    date: Timestamp.fromDate(selectedDate),
                    notes: notesController.text.trim(),
                    monthYear: monthYearStr,
                  );
                  await ref.read(dashboardRepositoryProvider).addExpense(newExpense);
                  if (mounted) {
                    Navigator.pop(ctx);
                    AppDialogs.showSuccessSnackBar(context, 'تم تسجيل المصروف بنجاح');
                  }
                }

                ref.invalidate(monthlyExpensesStreamProvider(_currentMonthYear));
                ref.invalidate(monthlyAccountingProvider(_currentMonthYear));
              },
              child: Text(isEditing ? 'حفظ التعديل' : 'حفظ المصروف'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteExpense(ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text('حذف المصروف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف مصروف "${expense.category}" بمبلغ ${AppFormatters.formatCurrency(expense.amount)}؟\nسيتم تعديل الحسابات فوراً.',
          style: GoogleFonts.cairo(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(dashboardRepositoryProvider).deleteExpense(expense.id);
              ref.invalidate(monthlyExpensesStreamProvider(_currentMonthYear));
              ref.invalidate(monthlyAccountingProvider(_currentMonthYear));
              if (mounted) {
                Navigator.pop(ctx);
                AppDialogs.showSuccessSnackBar(context, 'تم حذف المصروف بنجاح');
              }
            },
            child: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(monthlyExpensesStreamProvider(_currentMonthYear));

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل وإدارة المصروفات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'إضافة مصروف',
            onPressed: () => _showExpenseDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExpenseDialog(),
        backgroundColor: AppTheme.accentTeal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'تسجيل مصروف جديد',
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Month navigation bar
          Container(
            color: AppTheme.primaryBlue,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                  tooltip: 'الشهر السابق',
                  onPressed: _previousMonth,
                ),
                Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'مصروفات شهر: $_currentMonthYear',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                  tooltip: 'الشهر القادم',
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          // Total expenses summary header
          expensesAsync.when(
            data: (expenses) {
              final total = expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إجمالي المصروفات لشهر $_currentMonthYear',
                          style: GoogleFonts.cairo(color: Colors.red.shade900, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppFormatters.formatCurrency(total),
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${expenses.length} فواتير مسجلة',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Expenses List
          Expanded(
            child: expensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'لا توجد مصروفات مسجلة لشهر $_currentMonthYear',
                          style: GoogleFonts.cairo(fontSize: 15, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showExpenseDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('تسجيل أول مصروف الآن'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: expenses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final exp = expenses[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade50,
                          child: Icon(Icons.receipt_long, color: Colors.red.shade700),
                        ),
                        title: Text(
                          exp.category,
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              AppFormatters.formatTimestamp(exp.date),
                              style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted),
                            ),
                            if (exp.notes.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                exp.notes,
                                style: GoogleFonts.cairo(fontSize: 12, color: Colors.blueGrey.shade700),
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppFormatters.formatCurrency(exp.amount),
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 4),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: AppTheme.textMuted),
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _showExpenseDialog(existingExpense: exp);
                                } else if (val == 'delete') {
                                  _confirmDeleteExpense(exp);
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.edit, color: Colors.blue, size: 20),
                                      const SizedBox(width: 8),
                                      Text('تعديل المصروف', style: GoogleFonts.cairo(fontSize: 13)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete, color: Colors.red, size: 20),
                                      const SizedBox(width: 8),
                                      Text('حذف المصروف', style: GoogleFonts.cairo(color: Colors.red, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('خطأ في تحميل المصروفات: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
