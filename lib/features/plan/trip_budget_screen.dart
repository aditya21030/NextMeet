import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/relationship_model.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/flat_components.dart';

/// NextMeet Trip Shared Budget & Expense Splitter Screen
/// Strictly following NextMeet Redesign.pdf (Pages 44-45)
class TripBudgetScreen extends StatefulWidget {
  final String? relId;
  const TripBudgetScreen({super.key, this.relId});

  @override
  State<TripBudgetScreen> createState() => _TripBudgetScreenState();
}

class _TripBudgetScreenState extends State<TripBudgetScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();

  void _showAddExpenseModal(String relId, String myName, String partnerName) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String payer = myName;
    String category = 'General';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.hero)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Add Shared Expense', style: AppTextStyles.title2),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: titleController,
                    style: AppTextStyles.body,
                    decoration: const InputDecoration(
                      hintText: 'What was it for? e.g. Sunset drinks',
                      prefixIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.body,
                    decoration: const InputDecoration(
                      hintText: 'Amount in ₹',
                      prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppColors.primary, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Paid by:', style: AppTextStyles.label.copyWith(color: AppColors.muted)),
                  const SizedBox(height: 8),
                  Row(
                    children: [myName, partnerName].map((name) {
                      final isSelected = payer == name;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            VibrationService.light();
                            setModalState(() => payer = name);
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: name == myName ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                name,
                                style: AppTextStyles.heading.copyWith(
                                  fontSize: 13,
                                  color: isSelected ? Colors.white : AppColors.ink,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    text: 'Save Expense',
                    onPressed: () async {
                      final val = double.tryParse(amountController.text.trim());
                      if (val != null && titleController.text.trim().isNotEmpty) {
                        VibrationService.medium();
                        Navigator.pop(context);
                        try {
                          await _cloudService.addTripExpense(
                            relId,
                            titleController.text.trim(),
                            val,
                            category,
                            paidBy: payer,
                          );
                        } catch (_) {}
                      }
                    },
                  ),
                ],
              ),
            ),
          );
          },
        );
      },
    ).then((_) {
      titleController.dispose();
      amountController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService().currentUser?.uid;

    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, relSnapshot) {
        final rel = relSnapshot.data;
        final relId = widget.relId ?? rel?.id;
        final myName = rel?.getMyName(currentUid) ?? 'You';
        final partnerName = rel?.getPartnerName(currentUid) ?? 'Partner';
        final totalBudget = rel?.tripBudget ?? 50000.0;

        if (relId == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.ink, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text('Trip Budget', style: AppTextStyles.title2.copyWith(fontSize: 18)),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MascotHeart(color: MascotColor.violet, size: 54),
                    const SizedBox(height: 14),
                    Text('No shared trip budget yet', style: AppTextStyles.heading.copyWith(fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(
                      'Connect with your partner to track expenses, split costs, and plan your reunion getaway!',
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: _cloudService.streamExpenses(relId),
              builder: (context, expenseSnapshot) {
                final docs = expenseSnapshot.data?.docs ?? [];

                double myPaid = 0;
                double partnerPaid = 0;
                double totalSpent = 0;

                for (final doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final amt = (data['amount'] as num?)?.toDouble() ?? 0.0;
                  final paidBy = data['paidBy']?.toString() ?? myName;
                  totalSpent += amt;
                  if (paidBy == myName || paidBy == currentUid) {
                    myPaid += amt;
                  } else {
                    partnerPaid += amt;
                  }
                }

                final diff = (partnerPaid - myPaid) / 2;
                final remainingBudget = totalBudget - totalSpent;
                final spentRatio = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;

                return Column(
                  children: [
                    const SizedBox(height: 12),
                    // Top Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border, width: 1.5),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.ink),
                            ),
                          ),
                          Text('Trip Budget & Split', style: AppTextStyles.title2.copyWith(fontSize: 18)),
                          GestureDetector(
                            onTap: () => _showAddExpenseModal(relId, myName, partnerName),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Scrollable Budget Cards
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Hero Total Spent & Remaining Card (Page 44)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppRadius.hero),
                                border: Border.all(color: AppColors.border, width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Total Spent', style: AppTextStyles.caption),
                                      Text(
                                        'Budget: ₹${NumberFormat('#,###').format(totalBudget.toInt())}',
                                        style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '₹${NumberFormat('#,###').format(totalSpent.toInt())}',
                                    style: AppTextStyles.display.copyWith(fontSize: 32, color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: spentRatio,
                                      minHeight: 10,
                                      backgroundColor: AppColors.pinkSoft,
                                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Remaining: ₹${NumberFormat('#,###').format(remainingBudget.toInt())}',
                                        style: AppTextStyles.caption.copyWith(
                                          color: remainingBudget >= 0 ? AppColors.mintText : AppColors.danger,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        '${(spentRatio * 100).toInt()}% used',
                                        style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Split Settlement Summary Card (Page 44)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.partnerSoft,
                                borderRadius: BorderRadius.circular(AppRadius.card),
                                border: Border.all(color: AppColors.border, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.handshake_outlined, color: AppColors.partner, size: 22),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Current Split Balance', style: AppTextStyles.caption.copyWith(color: AppColors.partnerText)),
                                        const SizedBox(height: 2),
                                        Text(
                                          diff == 0
                                              ? 'All settled up! ✨'
                                              : (diff > 0
                                                  ? 'You owe $partnerName ₹${NumberFormat('#,###').format(diff.toInt())}'
                                                  : '$partnerName owes you ₹${NumberFormat('#,###').format(diff.abs().toInt())}'),
                                          style: AppTextStyles.heading.copyWith(fontSize: 15, color: AppColors.ink),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Expenses List Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Recent Expenses', style: AppTextStyles.heading.copyWith(fontSize: 16)),
                                Text('${docs.length} entries', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Expenses List
                            if (docs.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppRadius.card),
                                  border: Border.all(color: AppColors.border, width: 1.5),
                                ),
                                child: Center(
                                  child: Column(
                                    children: [
                                      const MascotHeart(color: MascotColor.butter, size: 48),
                                      const SizedBox(height: 8),
                                      Text('No expenses recorded yet', style: AppTextStyles.heading.copyWith(fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Text('Tap + above to add shared dinners, flights, or stays', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ...docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final title = data['title']?.toString() ?? 'Expense';
                                final amt = (data['amount'] as num?)?.toDouble() ?? 0.0;
                                final paidBy = data['paidBy']?.toString() ?? myName;
                                final cat = data['category']?.toString() ?? 'General';

                                return Dismissible(
                                  key: Key(doc.id),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (_) {
                                    VibrationService.light();
                                    _cloudService.deleteTripExpense(relId, doc.id);
                                  },
                                  background: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(AppRadius.card),
                                    ),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 16),
                                    child: const Icon(Icons.delete_rounded, color: Colors.white),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(AppRadius.card),
                                      border: Border.all(color: AppColors.border, width: 1.5),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: AppColors.pinkSoft,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Center(
                                            child: Icon(Icons.receipt_rounded, color: AppColors.primary, size: 20),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(title, style: AppTextStyles.heading.copyWith(fontSize: 14)),
                                              const SizedBox(height: 2),
                                              Text('Paid by $paidBy • $cat', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '₹${NumberFormat('#,###').format(amt.toInt())}',
                                          style: AppTextStyles.heading.copyWith(fontSize: 15, color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
