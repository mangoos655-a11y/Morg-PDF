import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MorganPdfApp());
}

class MorganPdfApp extends StatefulWidget {
  const MorganPdfApp({super.key});

  @override
  State<MorganPdfApp> createState() => _MorganPdfAppState();
}

class _MorganPdfAppState extends State<MorganPdfApp> {
  bool _isDarkApp = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Morgan PDF',
      debugShowCheckedModeBanner: false,
      theme: _isDarkApp ? ThemeData.dark() : ThemeData.light(),
      home: HomeScreen(
        onToggleAppTheme: () => setState(() => _isDarkApp = !_isDarkApp),
      ),
    );
  }
}

// تصميم اللوجو (الكتاب الأزرق المفتوح والعدسة المكبرة وكلمة PDF)
class MorganLogo extends StatelessWidget {
  final double size;
  const MorganLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.menu_book_rounded, size: size * 0.85, color: Colors.blue.shade800),
          Positioned(
            right: size * 0.08,
            bottom: size * 0.08,
            child: Container(
              padding: EdgeInsets.all(size * 0.07),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.shade700, width: 3.5),
                boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
              ),
              child: Text(
                'PDF',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: size * 0.17,
                  color: Colors.blue.shade900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleAppTheme;
  const HomeScreen({super.key, required this.onToggleAppTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _recentFiles = [];

  @override
  void initState() {
    super.initState();
    _loadRecentFiles();
  }

  Future<void> _loadRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentFiles = prefs.getStringList('recent_files') ?? [];
    });
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      String path = result.files.single.path!;
      final prefs = await SharedPreferences.getInstance();
      _recentFiles.remove(path);
      _recentFiles.insert(0, path);
      await prefs.setStringList('recent_files', _recentFiles);
      setState(() {});
      if (mounted) _openPdf(path);
    }
  }

  void _openPdf(String path) {
    if (!File(path).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الملف غير موجود أو تم نقله')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PdfViewerScreen(filePath: path)),
    ).then((_) => _loadRecentFiles());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Morgan PDF', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            tooltip: 'تغيير مظهر التطبيق',
            onPressed: widget.onToggleAppTheme,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          const MorganLogo(size: 110),
          const SizedBox(height: 12),
          const Text(
            'قارئ الكتب والمذكرات الذكي - بدون إنترنت',
            style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.folder_open),
            label: const Text('فتح ملف PDF من الجهاز'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('الملفات المفتوحة مؤخراً:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          Expanded(
            child: _recentFiles.isEmpty
                ? const Center(child: Text('لم تقم بفتح أي ملفات بعد'))
                : ListView.builder(
                    itemCount: _recentFiles.length,
                    itemBuilder: (context, index) {
                      final path = _recentFiles[index];
                      final fileName = path.split('/').last;
                      return ListTile(
                        leading: Icon(Icons.picture_as_pdf, color: Colors.blue.shade700, size: 32),
                        title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: FutureBuilder<SharedPreferences>(
                          future: SharedPreferences.getInstance(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const SizedBox();
                            final lastPage = snapshot.data!.getInt('page_$path') ?? 1;
                            return Text('متوقف عند صفحة: $lastPage');
                          },
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            _recentFiles.removeAt(index);
                            await prefs.setStringList('recent_files', _recentFiles);
                            setState(() {});
                          },
                        ),
                        onTap: () => _openPdf(path),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class PdfViewerScreen extends StatefulWidget {
  final String filePath;
  const PdfViewerScreen({super.key, required this.filePath});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  late PdfViewerController _pdfController;
  final FlutterTts _tts = FlutterTts();

  bool _invertPdfColors = false;
  bool _isCroppedZoom = false;
  bool _isHorizontalScroll = false;
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  PdfTextSearchResult _searchResult = PdfTextSearchResult();

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    WakelockPlus.enable(); // منع الشاشة من الانطفاء أثناء المذاكرة
    _restoreLastSession();
  }

  Future<void> _restoreLastSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPage = prefs.getInt('page_${widget.filePath}') ?? 1;
    final savedZoom = prefs.getDouble('zoom_${widget.filePath}') ?? 1.0;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _pdfController.jumpToPage(savedPage);
        _pdfController.zoomLevel = savedZoom;
      }
    });
  }

  Future<void> _saveCurrentState(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('page_${widget.filePath}', page);
    await prefs.setDouble('zoom_${widget.filePath}', _pdfController.zoomLevel);
  }

  Future<void> _saveHighlightedFile() async {
    final List<int> bytes = await _pdfController.saveDocument();
    await File(widget.filePath).writeAsBytes(bytes);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التظليل والتعديلات على الملف بنجاح!')),
      );
    }
  }

  void _openPageNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final currentPage = _pdfController.pageNumber;
    final noteKey = 'note_${widget.filePath}_$currentPage';
    final controller = TextEditingController(text: prefs.getString(noteKey) ?? '');

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ملاحظات صفحة $currentPage'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'اكتب ملخصك أو ملاحظاتك على هذه الصفحة هنا...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up, color: Colors.blue),
            tooltip: 'قراءة الملاحظة صوتياً',
            onPressed: () => _tts.speak(controller.text),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              await prefs.setString(noteKey, controller.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حفظ الملاحظة'),
          ),
        ],
      ),
    );
  }

  void _jumpToPageDialog() {
    final pageCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('الانتقال لصفحة (من 1 إلى ${_pdfController.pageCount})'),
        content: TextField(
          controller: pageCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'اكتب رقم الصفحة'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final p = int.tryParse(pageCtrl.text);
              if (p != null && p >= 1 && p <= _pdfController.pageCount) {
                _pdfController.jumpToPage(p);
              }
              Navigator.pop(context);
            },
            child: const Text('انتقال'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.filePath.split('/').last;

    // فلتر عكس الألوان للوضع الليلي المريح للعين
    const ColorFilter invertFilter = ColorFilter.matrix(<double>[
      -1,  0,  0, 0, 255,
       0, -1,  0, 0, 255,
       0,  0, -1, 0, 255,
       0,  0,  0, 1,   0,
    ]);

    Widget pdfContent = SfPdfViewer.file(
      File(widget.filePath),
      key: _pdfViewerKey,
      controller: _pdfController,
      scrollDirection: _isHorizontalScroll ? PdfScrollDirection.horizontal : PdfScrollDirection.vertical,
      pageLayoutMode: _isHorizontalScroll ? PdfPageLayoutMode.single : PdfPageLayoutMode.continuous,
      onPageChanged: (PdfPageChangedDetails details) => _saveCurrentState(details.newPageNumber),
      onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
        if (details.selectedText != null && details.selectedText!.isNotEmpty) {
          // إمكانية قراءة النص المحدد صوتياً
        }
      },
    );

    if (_invertPdfColors) {
      pdfContent = ColorFiltered(colorFilter: invertFilter, child: pdfContent);
    }

    return Scaffold(
      appBar: AppBar(
        title: _showSearchBar
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'ابحث في الكتاب...', border: InputBorder.none),
                onSubmitted: (val) {
                  _searchResult = _pdfController.searchText(val);
                  setState(() {});
                },
              )
            : Text(fileName, style: const TextStyle(fontSize: 15)),
        actions: [
          if (_showSearchBar) ...[
            IconButton(icon: const Icon(Icons.keyboard_arrow_up), onPressed: () => _searchResult.previousInstance()),
            IconButton(icon: const Icon(Icons.keyboard_arrow_down), onPressed: () => _searchResult.nextInstance()),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _showSearchBar = false;
                  _searchResult.clear();
                });
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'بحث في الملف',
              onPressed: () => setState(() => _showSearchBar = true),
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_border),
              tooltip: 'فهرس الكتاب',
              onPressed: () => _pdfViewerKey.currentState?.openBookmarkView(),
            ),
            IconButton(
              icon: Icon(_invertPdfColors ? Icons.light_mode : Icons.dark_mode),
              tooltip: 'الوضع الليلي للصفحات',
              onPressed: () => setState(() => _invertPdfColors = !_invertPdfColors),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'crop') {
                  setState(() {
                    _isCroppedZoom = !_isCroppedZoom;
                    _pdfController.zoomLevel = _isCroppedZoom ? 1.35 : 1.0;
                  });
                } else if (value == 'scroll') {
                  setState(() => _isHorizontalScroll = !_isHorizontalScroll);
                } else if (value == 'jump') {
                  _jumpToPageDialog();
                } else if (value == 'save') {
                  _saveHighlightedFile();
                } else if (value == 'print') {
                  Share.shareXFiles([XFile(widget.filePath)], text: 'طباعة أو مشاركة الملف');
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'crop',
                  child: Text(_isCroppedZoom ? 'إلغاء تكبير الهوامش' : 'قص/تكبير الهوامش البيضاء'),
                ),
                PopupMenuItem(
                  value: 'scroll',
                  child: Text(_isHorizontalScroll ? 'تقليب رأسي مستمر' : 'تقليب أفقي بالصفحة'),
                ),
                const PopupMenuItem(value: 'jump', child: Text('الانتقال لصفحة محددة')),
                const PopupMenuItem(value: 'save', child: Text('حفظ التظليل على الملف')),
                const PopupMenuItem(value: 'print', child: Text('إرسال للطباعة (NokoPrint)')),
              ],
            ),
          ],
        ],
      ),
      body: pdfContent,
      floatingActionButton: FloatingActionButton.small(
        onPressed: _openPageNotes,
        tooltip: 'ملاحظات هذه الصفحة',
        child: const Icon(Icons.edit_note),
      ),
    );
  }
}
