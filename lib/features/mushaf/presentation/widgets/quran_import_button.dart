
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/app_database.dart';
import '../../data/quran_import_service.dart';
import '../cubit/mushaf_reader_cubit.dart';

class QuranImportButton extends StatefulWidget {
  const QuranImportButton({super.key});

  @override
  State<QuranImportButton> createState() => _QuranImportButtonState();
}

class _QuranImportButtonState extends State<QuranImportButton> {
  bool _isImporting = false;

  Future<void> _confirmImport() async {
    if (_isImporting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('استيراد نص المصحف'),
          content: const Text(
            'سيتم فحص ملف المصحف ثم استيراد السور والآيات '
                'إلى قاعدة البيانات الحالية.\n\n'
                'لن تُستبدل بيانات موجودة. تأكد من أن الملف '
                'كامل ومن المصدر الذي اخترته.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('بدء الاستيراد'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isImporting = true);

    try {
      final service = QuranImportService(AppDatabase.instance);
      final importedCount = await service.importFromAsset();

      if (!mounted) return;

      await context.read<MushafReaderCubit>().loadSurahs();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم استيراد $importedCount آية بنجاح.',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر استيراد المصحف: $error'),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'استيراد المصحف',
      onPressed: _isImporting ? null : _confirmImport,
      icon: _isImporting
          ? const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      )
          : const Icon(Icons.download_outlined),
    );
  }
}
