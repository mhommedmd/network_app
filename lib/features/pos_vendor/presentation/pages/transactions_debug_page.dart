import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/toast/toast.dart';

/// صفحة تشخيص المعاملات - للمطورين فقط
class TransactionsDebugPage extends StatefulWidget {
  const TransactionsDebugPage({
    required this.networkId,
    super.key,
  });

  final String networkId;

  @override
  State<TransactionsDebugPage> createState() => _TransactionsDebugPageState();
}

class _TransactionsDebugPageState extends State<TransactionsDebugPage> {
  final _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _allTransactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  bool _isLoading = true;
  String? _vendorId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      _vendorId = authProvider.user?.id ?? '';

      if (_vendorId!.isEmpty) {
        setState(() {
          _error = 'Vendor ID is empty';
          _isLoading = false;
        });
        return;
      }

      // تحميل جميع المعاملات
      final allSnapshot = await _firestore.collection('transactions').get();

      _allTransactions = allSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      // فلترة المعاملات
      _filteredTransactions = _allTransactions.where((t) {
        return t['vendorId'] == _vendorId && t['networkId'] == widget.networkId;
      }).toList();

      // ترتيب حسب التاريخ
      _filteredTransactions.sort((a, b) {
        final aDate = (a['date'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final bDate = (b['date'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    CustomToast.info(
      context,
      'تم نسخه إلى الحافظة',
      title: 'تم النسخ',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تشخيص المعاملات'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        SizedBox(height: 16.h),
                        Text(
                          'خطأ',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          _error!,
                          style: TextStyle(fontSize: 14.sp),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: EdgeInsets.all(16.w),
                  children: [
                    // معلومات الاستعلام
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🔍 معلومات الاستعلام',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            _buildInfoRow('Vendor ID', _vendorId ?? ''),
                            _buildInfoRow('Network ID', widget.networkId),
                            _buildInfoRow(
                              'All Transactions',
                              '${_allTransactions.length}',
                            ),
                            _buildInfoRow(
                              'Filtered Transactions',
                              '${_filteredTransactions.length}',
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // المعاملات المفلترة
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '✅ معاملات هذا المتجر مع هذه الشبكة',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            if (_filteredTransactions.isEmpty)
                              Text(
                                'لا توجد معاملات',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey,
                                ),
                              )
                            else
                              ..._filteredTransactions.map((t) {
                                return _buildTransactionCard(t, true);
                              }),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // جميع المعاملات
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📋 جميع المعاملات (${_allTransactions.length})',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            if (_allTransactions.isEmpty)
                              Text(
                                'لا توجد معاملات في النظام',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.red,
                                ),
                              )
                            else
                              ..._allTransactions.take(10).map((t) {
                                final isMatch = t['vendorId'] == _vendorId &&
                                    t['networkId'] == widget.networkId;
                                return _buildTransactionCard(t, isMatch);
                              }),
                            if (_allTransactions.length > 10)
                              Padding(
                                padding: EdgeInsets.only(top: 8.h),
                                child: Text(
                                  '... و ${_allTransactions.length - 10} معاملة أخرى',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () => _copyToClipboard(value),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () => _copyToClipboard(value),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction, bool isMatch) {
    final type = transaction['type'] as String? ?? '';
    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0;
    final status = transaction['status'] as String? ?? '';
    final vendorId = transaction['vendorId'] as String? ?? '';
    final networkId = transaction['networkId'] as String? ?? '';
    final date = (transaction['date'] as Timestamp?)?.toDate();
    final description = transaction['description'] as String? ?? '';

    final vendorMatch = vendorId == _vendorId;
    final networkMatch = networkId == widget.networkId;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isMatch
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.05),
        border: Border.all(
          color: isMatch ? Colors.green : Colors.grey,
          width: isMatch ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                type == 'charge' ? Icons.arrow_upward : Icons.arrow_downward,
                color: type == 'charge' ? Colors.red : Colors.green,
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  type == 'charge' ? 'شحن (مدين)' : 'دفعة (دائن)',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${amount.toStringAsFixed(0)} ر.ي',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: type == 'charge' ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            description,
            style: TextStyle(fontSize: 12.sp),
          ),
          SizedBox(height: 8.h),
          _buildDetailRow(
            'Vendor ID',
            vendorId,
            vendorMatch,
          ),
          _buildDetailRow(
            'Network ID',
            networkId,
            networkMatch,
          ),
          _buildDetailRow(
            'Status',
            status,
            status == 'completed',
          ),
          if (date != null)
            _buildDetailRow(
              'Date',
              '${date.year}-${date.month}-${date.day} ${date.hour}:${date.minute}',
              true,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isMatch) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          isMatch
              ? const Icon(Icons.check_circle, color: Colors.green, size: 12)
              : const Icon(Icons.cancel, color: Colors.red, size: 12),
          SizedBox(width: 4.w),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11.sp,
                fontFamily: 'monospace',
                color: isMatch ? Colors.black : Colors.red,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
