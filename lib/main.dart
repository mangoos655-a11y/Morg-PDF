import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:pdf/pdf.dart' as pw_pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MorganPdfProApp());
}

class MorganPdfProApp extends StatefulWidget {
  const MorganPdfProApp({super.key});

  @override
  State<MorganPdfProApp> createState() => _MorganPdfProAppState();
}

class _MorganPdfProAppState extends State<MorganPdfProApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Color _SeedColor = Colors.blue.shade800;
  bool _isArabic = true;
  String? _savedPin;
  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
    _loadAppSettings();
  }

  Future<void> _loadAppSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final t = prefs.getString('theme_mode') ?? 'system';
      _themeMode = t == 'dark' ? ThemeMode.dark : (t == 'light' ? ThemeMode.light : ThemeMode.system);
      _SeedColor = Color(prefs.getInt('theme_color') ?? Colors.blue.shade800.value);
      _isArabic = prefs.getBool('is_arabic') ?? true;
      _savedPin = prefs.getString('app_pin');
      if (_savedPin == null || _savedPin!.isEmpty) _isUnlocked = true;
    });
  }

  void _updateSettings({ThemeMode? mode, Color? color, bool? arabic, String? pin}) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (mode != null) {
        _themeMode = mode;
        prefs.setString('theme_mode', mode == ThemeMode.dark ? 'dark' : (mode == ThemeMode.light ? 'light' : 'system'));
      }
      if (color != null) {
        _SeedColor = color;
        prefs.setInt('theme_color', color.value);
      }
      if (arabic != null) {
        _isArabic = arabic;
        prefs.setBool('is_arabic', arabic);
      }
      if (pin != null) {
        _savedPin = pin.isEmpty ? null : pin;
        prefs.setString('app_pin', pin);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Morgan PDF',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(colorSchemeSeed: _SeedColor, useMaterial3: true, brightness: Brightness.light),
      darkTheme: ThemeData(colorSchemeSeed: _SeedColor, useMaterial3: true, brightness: Brightness.dark),
      builder: (context, child) {
        return Directionality(
          textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: _isUnlocked
              ? child!
              : PinLockScreen(
                  correctPin: _savedPin!,
                  onUnlocked: () => setState(() => _isUnlocked = true),
                ),
        );
      },
      home: MainWorkspace(
        isArabic: _isArabic,
        seedColor: _SeedColor,
        themeMode: _themeMode,
        onUpdateSettings: _updateSettings,
      ),
    );
  }
}

// شاشة القفل برقم سري لحماية الخصوصية
class PinLockScreen extends StatefulWidget {
  final String correctPin;
  final VoidCallback onUnlocked;
  const PinLockScreen({super.key, required this.correctPin, required this.onUnlocked});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final TextEditingController _ctrl = TextEditingController();
  String _error = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 70, color: Colors.blue),
              const SizedBox(height: 16),
              const Text('التطبيق محمي برقم سري (PIN)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _ctrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'أدخل الرقم السري',
                  errorText: _error.isEmpty ? null : _error,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_ctrl.text == widget.correctPin) {
                    widget.onUnlocked();
                  } else {
                    setState(() => _error = 'الرقم السري غير صحيح');
                  }
                },
                child: const Text('دخول'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// اللوجو المدمج (الكتاب الأزرق المفتوح والعدسة المكبرة وكلمة PDF)
class MorganLogo extends StatelessWidget {
  final double size;
  const MorganLogo({super.key, this.size = 90});

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
            right: size * 0.05,
            bottom: size * 0.05,
            child: Container(
              padding: EdgeInsets.all(size * 0.07),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.shade700, width: 3),
                boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
              ),
              child: Text(
                'PDF',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: size * 0.17, color: Colors.blue.shade900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MainWorkspace extends StatefulWidget {
  final bool isArabic;
  final Color seedColor;
  final ThemeMode themeMode;
  final Function({ThemeMode? mode, Color? color, bool? arabic, String? pin}) onUpdateSettings;

  const MainWorkspace({
    super.key,
    required this.isArabic,
    required this.seedColor,
    required this.themeMode,
    required this.onUpdateSettings,
  });

  @override
  State<MainWorkspace> createState() => _MainWorkspaceState();
}

class _MainWorkspaceState extends State<MainWorkspace> {
  static const MethodChannel _intentChannel = MethodChannel('com.morgan.pdf/intent');
  int _navIndex = 0;

  List<String> _recentFiles = [];
  List<String> _favoriteFiles = [];
  Map<String, String> _fileTags = {}; // مسار الملف -> اسم المجلد/الوسم
  List<String> _openTabs = []; // التبويبات المفتوحة حالياً
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadFilesData();
    _checkExternalIntent();
  }

  // فحص إذا تم فتح ملف من تليجرام أو مدير الملفات
  Future<void> _checkExternalIntent() async {
    try {
      final String? initialPath = await _intentChannel.invokeMethod<String>('getInitialFile');
      if (initialPath != null && initialPath.isNotEmpty) {
        _addAndOpenFile(initialPath);
      }
      _intentChannel.setMethodCallHandler((call) async {
        if (call.method == 'onNewFile' && call.arguments != null) {
          final String path = call.arguments as String;
          if (path.isNotEmpty) _addAndOpenFile(path);
        }
      });
    } catch (_) {}
  }

  Future<void> _loadFilesData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentFiles = prefs.getStringList('recent_files') ?? [];
      _favoriteFiles = prefs.getStringList('fav_files') ?? [];
      final tagsList = prefs.getStringList('file_tags') ?? [];
      _fileTags = {
        for (var item in tagsList)
          if (item.contains('||')) item.split('||')[0]: item.split('||')[1]
      };
    });
  }

  Future<void> _saveFilesData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_files', _recentFiles);
    await prefs.setStringList('fav_files', _favoriteFiles);
    await prefs.setStringList(
      'file_tags',
      _fileTags.entries.map((e) => '${e.key}||${e.value}').toList(),
    );
  }

  void _addAndOpenFile(String path) async {
    if (!File(path).existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر قراءة الملف، تأكد من إعطاء صلاحية الملفات للتطبيق')),
        );
      }
      return;
    }
    _recentFiles.remove(path);
    _recentFiles.insert(0, path);
    if (!_openTabs.contains(path)) {
      _openTabs.add(path);
    }
    _activeTabIndex = _openTabs.indexOf(path);
    await _saveFilesData();
    setState(() => _navIndex = 1); // الانتقال لشاشة القارئ والتبويبات
  }

  Future<void> _pickPdfFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      _addAndOpenFile(result.files.single.path!);
    }
  }

  // أداة تحويل الصور أو الكاميرا إلى ملف PDF جديد
  Future<void> _convertImagesToPdf({required bool fromCamera}) async {
    final picker = ImagePicker();
    List<XFile> images = [];
    if (fromCamera) {
      final photo = await picker.pickImage(source: ImageSource.camera);
      if (photo != null) images.add(photo);
    } else {
      images = await picker.pickMultiImage();
    }
    if (images.isEmpty) return;

    final pdf = pw.Document();
    for (var img in images) {
      final bytes = await File(img.path).readAsBytes();
      final pwImage = pw.MemoryImage(bytes);
      pdf.addPage(
        pw.Page(
          pageFormat: pw_pdf.PdfPageFormat.a4,
          build: (pw.Context ctx) => pw.Center(child: pw.Image(pwImage, fit: pw.BoxFit.contain)),
        ),
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final outFile = File('${dir.path}/Scanned_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await outFile.writeAsBytes(await pdf.save());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء ملف الـ PDF بنجاح!')));
    }
    _addAndOpenFile(outFile.path);
  }

  // أداة إنشاء ملف PDF جديد فارغ للملاحظات أو بعلامة مائية
  Future<void> _createCustomPdfDialog() async {
    final titleCtrl = TextEditingController(text: 'مذكرة جديدة');
    final watermarkCtrl = TextEditingController();
    final pagesCtrl = TextEditingController(text: '5');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنشاء ملف PDF / علامة مائية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'عنوان الملف (Header)')),
            TextField(controller: watermarkCtrl, decoration: const InputDecoration(labelText: 'نص العلامة المائية (اختياري)')),
            TextField(controller: pagesCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'عدد الصفحات')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final pdf = pw.Document();
              final count = int.tryParse(pagesCtrl.text) ?? 1;
              for (int i = 1; i <= count; i++) {
                pdf.addPage(
                  pw.Page(
                    pageFormat: pw_pdf.PdfPageFormat.a4,
                    build: (pw.Context c) => pw.Stack(
                      children: [
                        if (watermarkCtrl.text.isNotEmpty)
                          pw.Center(
                            child: pw.Transform.rotate(
                              angle: -0.5,
                              child: pw.Text(
                                watermarkCtrl.text,
                                style: pw.TextStyle(fontSize: 45, color: pw_pdf.PdfColors.grey300),
                              ),
                            ),
                          ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            pw.Text(titleCtrl.text, style: const pw.TextStyle(fontSize: 12, color: pw_pdf.PdfColors.grey700)),
                            pw.Divider(),
                            pw.Spacer(),
                            pw.Divider(),
                            pw.Align(
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text('Page $i of $count', style: const pw.TextStyle(fontSize: 10)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }
              final dir = await getApplicationDocumentsDirectory();
              final f = File('${dir.path}/${titleCtrl.text}_${DateTime.now().millisecondsSinceEpoch}.pdf');
              await f.writeAsBytes(await pdf.save());
              _addAndOpenFile(f.path);
            },
            child: const Text('إنشاء وفتح'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHomeFilesTab(),
      _buildReaderTabsScreen(),
      _buildToolsAndConvertTab(),
      _buildSettingsTab(),
    ];

    return Scaffold(
      body: screens[_navIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (idx) => setState(() => _navIndex = idx),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.folder_copy_outlined), label: 'الملفات'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _openTabs.isNotEmpty,
              label: Text('${_openTabs.length}'),
              child: const Icon(Icons.chrome_reader_mode_outlined),
            ),
            label: 'القارئ والتبويبات',
          ),
          const NavigationDestination(icon: Icon(Icons.build_circle_outlined), label: 'الأدوات والتحويل'),
          const NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'الإعدادات'),
        ],
      ),
    );
  }

  // 1. شاشة الملفات والتنظيم (أخيرة / مفضلة / مجلدات وأوسمة)
  Widget _buildHomeFilesTab() {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              MorganLogo(size: 38),
              SizedBox(width: 10),
              Text('Morgan PDF Pro', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'الأخيرة', icon: Icon(Icons.history)),
              Tab(text: 'المفضلة', icon: Icon(Icons.star_border)),
              Tab(text: 'المجلدات/الأوسمة', icon: Icon(Icons.label_outline)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFileList(_recentFiles),
            _buildFileList(_favoriteFiles),
            _buildTaggedFilesView(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _pickPdfFile,
          icon: const Icon(Icons.file_open),
          label: const Text('فتح ملف PDF'),
        ),
      ),
    );
  }

  Widget _buildFileList(List<String> files) {
    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MorganLogo(size: 95),
            const SizedBox(height: 12),
            const Text('لا توجد ملفات في هذه القائمة بعد'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _pickPdfFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('استعراض ملفات الجهاز'),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final path = files[index];
        final name = path.split('/').last;
        final isFav = _favoriteFiles.contains(path);
        final tag = _fileTags[path];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: ListTile(
            leading: Icon(Icons.picture_as_pdf, color: Colors.blue.shade800, size: 36),
            title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (ctx, snap) {
                final lastPage = snap.data?.getInt('page_$path') ?? 1;
                return Text('آخر صفحة: $lastPage ${tag != null ? " • 📁 $tag" : ""}');
              },
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (val) async {
                if (val == 'fav') {
                  setState(() {
                    isFav ? _favoriteFiles.remove(path) : _favoriteFiles.add(path);
                  });
                  _saveFilesData();
                } else if (val == 'tag') {
                  _assignTagDialog(path);
                } else if (val == 'rename') {
                  _renameFileDialog(path);
                } else if (val == 'share') {
                  Share.shareXFiles([XFile(path)]);
                } else if (val == 'remove') {
                  setState(() {
                    _recentFiles.remove(path);
                    _favoriteFiles.remove(path);
                  });
                  _saveFilesData();
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(value: 'fav', child: Text(isFav ? 'إزالة من المفضلة' : 'إضافة للمفضلة ⭐')),
                const PopupMenuItem(value: 'tag', child: Text('وضع في مجلد / وسم 📁')),
                const PopupMenuItem(value: 'rename', child: Text('إعادة تسمية الملف ✏️')),
                const PopupMenuItem(value: 'share', child: Text('مشاركة أو طباعة 🖨️')),
                const PopupMenuItem(value: 'remove', child: Text('إزالة من القائمة 🗑️')),
              ],
            ),
            onTap: () => _addAndOpenFile(path),
          ),
        );
      },
    );
  }

  Widget _buildTaggedFilesView() {
    if (_fileTags.isEmpty) {
      return const Center(child: Text('اضغط على النقاط الثلاث بجانب أي ملف لإضافته لمجلد مادة (مثل: جراحة، باطنة، أطفال)'));
    }
    final folders = _fileTags.values.toSet().toList();
    return ListView.builder(
      itemCount: folders.length,
      itemBuilder: (ctx, i) {
        final folderName = folders[i];
        final paths = _fileTags.entries.where((e) => e.value == folderName).map((e) => e.key).toList();
        return ExpansionTile(
          leading: const Icon(Icons.folder_special, color: Colors.amber),
          title: Text(folderName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${paths.length} ملفات'),
          children: paths.map((p) => ListTile(
            title: Text(p.split('/').last),
            leading: const Icon(Icons.picture_as_pdf, size: 20),
            onTap: () => _addAndOpenFile(p),
          )).toList(),
        );
      },
    );
  }

  void _assignTagDialog(String path) {
    final ctrl = TextEditingController(text: _fileTags[path] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تحديد مجلد / وسم المادة'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'مثال: جراحة، أطفال، نسا وتوليد...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (ctrl.text.trim().isEmpty) {
                  _fileTags.remove(path);
                } else {
                  _fileTags[path] = ctrl.text.trim();
                }
              });
              _saveFilesData();
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _renameFileDialog(String oldPath) {
    final file = File(oldPath);
    final dir = file.parent.path;
    final ctrl = TextEditingController(text: oldPath.split('/').last.replaceAll('.pdf', ''));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إعادة تسمية الملف'),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              try {
                final newPath = '$dir/${ctrl.text.trim()}.pdf';
                await file.rename(newPath);
                setState(() {
                  final idx = _recentFiles.indexOf(oldPath);
                  if (idx != -1) _recentFiles[idx] = newPath;
                });
                _saveFilesData();
              } catch (_) {}
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  // 2. شاشة القارئ مع التبويبات المتعددة (Multiple Tabs)
  Widget _buildReaderTabsScreen() {
    if (_openTabs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('القارئ السلس')),
        body: Center(
          child: ElevatedButton.icon(
            onPressed: _pickPdfFile,
            icon: const Icon(Icons.add),
            label: const Text('افتح ملف PDF للبدء'),
          ),
        ),
      );
    }

    if (_activeTabIndex >= _openTabs.length) _activeTabIndex = 0;
    final activePath = _openTabs[_activeTabIndex];

    return Column(
      children: [
        // شريط التبويبات العلوي لفتح عدة ملفات في نفس الوقت
        Container(
          color: Theme.of(context).colorScheme.surfaceVariant,
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _openTabs.length + 1,
            itemBuilder: (ctx, i) {
              if (i == _openTabs.length) {
                return IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _pickPdfFile, tooltip: 'فتح تبويب جديد');
              }
              final isSelected = i == _activeTabIndex;
              final name = _openTabs[i].split('/').last;
              return GestureDetector(
                onTap: () => setState(() => _activeTabIndex = i),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        name.length > 18 ? '${name.substring(0, 18)}...' : name,
                        style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => setState(() => _openTabs.removeAt(i)),
                        child: const Icon(Icons.close, size: 15),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: SmoothPdfReaderView(
            key: ValueKey(activePath),
            filePath: activePath,
          ),
        ),
      ],
    );
  }

  // 3. شاشة الأدوات والتحويل وإدارة الصفحات والحماية
  Widget _buildToolsAndConvertTab() {
    return Scaffold(
      appBar: AppBar(title: const Text('أدوات PDF والتحويل والإدارة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildToolSectionTitle('التحويل والمسح الضوئي (Offline)'),
          _buildToolTile(
            icon: Icons.camera_alt_outlined,
            title: 'مسح بالكاميرا إلى PDF (Scanner)',
            subtitle: 'تصوير ملازم أو أوراق وتحويلها فوراً لملف PDF',
            onTap: () => _convertImagesToPdf(fromCamera: true),
          ),
          _buildToolTile(
            icon: Icons.photo_library_outlined,
            title: 'تحويل صور إلى PDF',
            subtitle: 'دمج عدة صور من المعرض في كتاب PDF واحد',
            onTap: () => _convertImagesToPdf(fromCamera: false),
          ),
          _buildToolTile(
            icon: Icons.image_outlined,
            title: 'تصدير صفحات PDF إلى صور عالية الجودة',
            subtitle: 'اختر ملف PDF وحول صفحاته لصور PNG',
            onTap: _exportPdfPageToImage,
          ),
          const Divider(height: 28),
          _buildToolSectionTitle('إدارة الصفحات والإنشاء والنماذج'),
          _buildToolTile(
            icon: Icons.note_add_outlined,
            title: 'إنشاء ملف PDF جديد / علامة مائية / ترقيم صفحات',
            subtitle: 'توليد مذكرة مرقمة مع Header/Footer وعلامة مائية مخصصة',
            onTap: _createCustomPdfDialog,
          ),
          _buildToolTile(
            icon: Icons.compare_arrows,
            title: 'مقارنة ملفين PDF',
            subtitle: 'فحص سريع لعدد الصفحات وحجم الفروقات بين نسختين',
            onTap: _compareTwoPdfs,
          ),
          _buildToolTile(
            icon: Icons.print_outlined,
            title: 'الطباعة المباشرة أو ضغط ومشاركة الملف',
            subtitle: 'إرسال لتطبيق الطباعة (NokoPrint / PrinterShare)',
            onTap: () async {
              if (_openTabs.isNotEmpty) {
                final bytes = await File(_openTabs[_activeTabIndex]).readAsBytes();
                await Printing.layoutPdf(onLayout: (_) async => bytes);
              } else {
                _pickPdfFile();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
    );
  }

  Widget _buildToolTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Future<void> _exportPdfPageToImage() async {
    FilePickerResult? res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (res == null || res.files.single.path == null) return;
    final doc = await pdfx.PdfDocument.openFile(res.files.single.path!);
    final page = await doc.getPage(1);
    final pageImage = await page.render(width: page.width * 2, height: page.height * 2, format: pdfx.PdfPageImageFormat.png);
    await page.close();
    if (pageImage != null) {
      final dir = await getTemporaryDirectory();
      final imgFile = File('${dir.path}/page_1.png');
      await imgFile.writeAsBytes(pageImage.bytes);
      await Share.shareXFiles([XFile(imgFile.path)], text: 'صورة الصفحة الأولى من الملف');
    }
  }

  Future<void> _compareTwoPdfs() async {
    FilePickerResult? r1 = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (r1 == null || r1.files.single.path == null) return;
    FilePickerResult? r2 = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (r2 == null || r2.files.single.path == null) return;

    final f1 = File(r1.files.single.path!);
    final f2 = File(r2.files.single.path!);
    final d1 = await pdfx.PdfDocument.openFile(f1.path);
    final d2 = await pdfx.PdfDocument.openFile(f2.path);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('نتيجة مقارنة الملفين'),
        content: Text(
          'الملف الأول: ${f1.path.split('/').last}\n'
          '• عدد الصفحات: ${d1.pagesCount}\n'
          '• الحجم: ${(f1.lengthSync() / 1024).toStringAsFixed(1)} KB\n\n'
          'الملف الثاني: ${f2.path.split('/').last}\n'
          '• عدد الصفحات: ${d2.pagesCount}\n'
          '• الحجم: ${(f2.lengthSync() / 1024).toStringAsFixed(1)} KB',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق'))],
      ),
    );
  }

  // 4. شاشة الإعدادات الشاملة والتصميم والحماية
  Widget _buildSettingsTab() {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات والتخصيص والحماية')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            leading: MorganLogo(size: 55),
            title: Text('Morgan PDF Pro v2.0', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('تطبيق قراءة ومذاكرة أوفلاين 100% - بدون إعلانات'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('مظهر التطبيق (فاتح / داكن / تلقائي)'),
            trailing: DropdownButton<ThemeMode>(
              value: widget.themeMode,
              onChanged: (m) => widget.onUpdateSettings(mode: m),
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('تلقائي')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('فاتح')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('داكن')),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: const Text('اللون الرئيسي للتطبيق'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Colors.blue.shade800,
                Colors.teal.shade700,
                Colors.indigo.shade700,
                Colors.deepOrange.shade700,
              ].map((c) => GestureDetector(
                onTap: () => widget.onUpdateSettings(color: c),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                ),
              )).toList(),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.language),
            title: const Text('واجهة عربية كاملة (RTL)'),
            subtitle: const Text('التبديل بين العربية والإنجليزية'),
            value: widget.isArabic,
            onChanged: (val) => widget.onUpdateSettings(arabic: val),
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('قفل التطبيق برقم سري (PIN)'),
            subtitle: const Text('حماية كتبك وملفاتك عند فتح التطبيق'),
            onTap: () {
              final ctrl = TextEditingController();
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('تعيين رقم سري (اتركه فارغاً لإلغاء القفل)'),
                  content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'أدخل 4 أرقام')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                    ElevatedButton(
                      onPressed: () {
                        widget.onUpdateSettings(pin: ctrl.text.trim());
                        Navigator.pop(ctx);
                      },
                      child: const Text('حفظ'),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('مسح الكاش والملفات المؤقتة'),
            onTap: () async {
              final dir = await getTemporaryDirectory();
              dir.deleteSync(recursive: true);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تنظيف الكاش بنجاح')));
              }
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// محرك القراءة السلس (Smooth Physics Reader) + التعليقات والرسم الحر والتوقيع
// ============================================================================

class SmoothPdfReaderView extends StatefulWidget {
  final String filePath;
  const SmoothPdfReaderView({super.key, required this.filePath});

  @override
  State<SmoothPdfReaderView> createState() => _SmoothPdfReaderViewState();
}

class StrokePath {
  final List<Offset> points;
  final Color color;
  final double width;
  final bool isHighlighter;
  final bool isRedaction;
  StrokePath({required this.points, required this.color, required this.width, this.isHighlighter = false, this.isRedaction = false});
}

class StickyNoteItem {
  final int page;
  final String text;
  final String author;
  StickyNoteItem({required this.page, required this.text, required this.author});
}

class SmoothPdfReaderView extends StatefulWidget {
  final String filePath;
  const SmoothPdfReaderView({super.key, required this.filePath});

  @override
  State<SmoothPdfReaderView> createState() => _SmoothPdfReaderViewState();
}

class _SmoothPdfReaderViewState extends State<SmoothPdfReaderView> {
  pdfx.PdfDocument? _document;
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _tts = FlutterTts();

  int _totalPages = 0;
  int _currentPage = 1;
  bool _isLoading = true;
  String? _errorMsg;

  // إعدادات العرض والقراءة
  bool _isHorizontal = false;
  bool _isSinglePageMode = false;
  bool _isFullScreen = false;
  bool _isNightInverted = false;
  double _brightnessOverlay = 0.0; // لتقليل السطوع ليلاً
  int _quarterTurns = 0; // تدوير الصفحات (90 درجة)
  Set<int> _userBookmarks = {};

  // أدوات الرسم الحر والتظليل والممحاة والـ Redaction والتوقيع
  String _activeTool = 'none'; // none, pen, highlight, redaction, signature
  Color _penColor = Colors.amber;
  double _penWidth = 4.0;
  final Map<int, List<StrokePath>> _pageStrokes = {};
  final List<StrokePath> _redoStack = [];
  final List<StickyNoteItem> _commentsList = [];

  // كاش صور الصفحات لضمان نعومة الـ Scroll بدون تقطيع
  final Map<int, Uint8List> _renderedPagesCache = {};

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _initDocument();
    _scrollController.addListener(_onScrollChanged);
  }

  void _onScrollChanged() {
    if (!_scrollController.hasClients || _totalPages == 0) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;
    final ratio = _scrollController.offset / maxScroll;
    final calcPage = (ratio * (_totalPages - 1)).round() + 1;
    if (calcPage != _currentPage && calcPage >= 1 && calcPage <= _totalPages) {
      setState(() => _currentPage = calcPage);
      SharedPreferences.getInstance().then((p) => p.setInt('page_${widget.filePath}', _currentPage));
    }
  }

  Future<void> _initDocument({String? password}) async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      _document = await pdfx.PdfDocument.openFile(widget.filePath, password: password);
      _totalPages = _document!.pagesCount;
      final prefs = await SharedPreferences.getInstance();
      final savedPage = prefs.getInt('page_${widget.filePath}') ?? 1;
      final savedBms = prefs.getStringList('bm_${widget.filePath}') ?? [];
      _userBookmarks = savedBms.map((e) => int.tryParse(e) ?? 1).toSet();

      setState(() {
        _currentPage = savedPage.clamp(1, _totalPages);
        _isLoading = false;
      });

      if (_currentPage > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToPage(_currentPage));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMsg = e.toString();
      });
    }
  }

  void _jumpToPage(int page) {
    final target = page.clamp(1, _totalPages);
    setState(() => _currentPage = target);
    if (_scrollController.hasClients && !_isSinglePageMode) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final targetOffset = ((target - 1) / (_totalPages > 1 ? _totalPages - 1 : 1)) * maxScroll;
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 450),
        curve: Curves.decelerate, // حركة توقف ناعمة وهادئة جداً
      );
    }
  }

  Future<Uint8List?> _renderPage(int pageNumber) async {
    if (_renderedPagesCache.containsKey(pageNumber)) {
      return _renderedPagesCache[pageNumber];
    }
    if (_document == null) return null;
    final page = await _document!.getPage(pageNumber);
    final pageImage = await page.render(
      width: page.width * 2.0,
      height: page.height * 2.0,
      format: pdfx.PdfPageImageFormat.jpeg,
      backgroundColor: '#FFFFFF',
    );
    await page.close();
    if (pageImage != null) {
      if (_renderedPagesCache.length > 12) {
        _renderedPagesCache.remove(_renderedPagesCache.keys.first);
      }
      _renderedPagesCache[pageNumber] = pageImage.bytes;
      return pageImage.bytes;
    }
    return null;
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _tts.stop();
    _scrollController.dispose();
    _document?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // في حال كان الملف محمياً بكلمة مرور
    if (_errorMsg != null) {
      final passCtrl = TextEditingController();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_person_outlined, size: 60, color: Colors.amber),
              const SizedBox(height: 12),
              const Text('هذا الملف محمي بكلمة مرور أو يحتاج صلاحية قراءة'),
              const SizedBox(height: 12),
              TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(hintText: 'أدخل كلمة مرور الملف إن وجدت', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => _initDocument(password: passCtrl.text), child: const Text('فتح الملف')),
            ],
          ),
        ),
      );
    }

    const ColorFilter invertMatrix = ColorFilter.matrix(<double>[
      -1,  0,  0, 0, 255,
       0, -1,  0, 0, 255,
       0,  0, -1, 0, 255,
       0,  0,  0, 1,   0,
    ]);

    Widget readerBody = Stack(
      children: [
        // 1. عارض الصفحات بفيزياء التمرير الانسيابي الهادئ (Smooth Deceleration Physics)
        _isSinglePageMode
            ? PageView.builder(
                scrollDirection: _isHorizontal ? Axis.horizontal : Axis.vertical,
                itemCount: _totalPages,
                onPageChanged: (idx) => setState(() => _currentPage = idx + 1),
                itemBuilder: (ctx, idx) => _buildInteractivePageItem(idx + 1),
              )
            : Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                interactive: true,
                thickness: 8,
                radius: const Radius.circular(8),
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: _isHorizontal ? Axis.horizontal : Axis.vertical,
                  // فيزياء تمرير ناعمة جداً تتباطأ بهدوء قبل التوقف
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  cacheExtent: 1800,
                  itemCount: _totalPages,
                  itemBuilder: (ctx, idx) => _buildInteractivePageItem(idx + 1),
                ),
              ),

        // 2. طبقة التحكم في السطوع الليلي لحماية العين
        if (_brightnessOverlay > 0)
          IgnorePointer(
            child: Container(color: Colors.black.withOpacity(_brightnessOverlay)),
          ),

        // 3. عداد الصفحات العائم وأزرار التحكم السريع
        Positioned(
          bottom: 14,
          left: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
            child: InkWell(
              onTap: _showJumpAndThumbnailsSheet,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.grid_view_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text('$_currentPage / $_totalPages', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    if (_isNightInverted) {
      readerBody = ColorFiltered(colorFilter: invertMatrix, child: readerBody);
    }

    return Scaffold(
      appBar: _isFullScreen
          ? null
          : AppBar(
              toolbarHeight: 48,
              title: Text(widget.filePath.split('/').last, style: const TextStyle(fontSize: 14)),
              actions: [
                IconButton(
                  icon: Icon(_userBookmarks.contains(_currentPage) ? Icons.bookmark : Icons.bookmark_border, color: Colors.amber),
                  tooltip: 'إشارة مرجعية لهذه الصفحة',
                  onPressed: () async {
                    setState(() {
                      if (_userBookmarks.contains(_currentPage)) {
                        _userBookmarks.remove(_currentPage);
                      } else {
                        _userBookmarks.add(_currentPage);
                      }
                    });
                    final prefs = await SharedPreferences.getInstance();
                    prefs.setStringList('bm_${widget.filePath}', _userBookmarks.map((e) => '$e').toList());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.rotate_90_degrees_ccw),
                  tooltip: 'تدوير الصفحات',
                  onPressed: () => setState(() => _quarterTurns = (_quarterTurns + 1) % 4),
                ),
                IconButton(
                  icon: Icon(_isNightInverted ? Icons.light_mode : Icons.dark_mode),
                  tooltip: 'الوضع الليلي والسطوع',
                  onPressed: _showNightAndBrightnessDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.draw_outlined),
                  tooltip: 'أدوات التظليل والقلم والتوقيع والتعليقات',
                  onPressed: _showAnnotationToolbarSheet,
                ),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'single') setState(() => _isSinglePageMode = !_isSinglePageMode);
                    if (val == 'dir') setState(() => _isHorizontal = !_isHorizontal);
                    if (val == 'full') setState(() => _isFullScreen = true);
                    if (val == 'thumbs') _showJumpAndThumbnailsSheet();
                    if (val == 'comments') _showCommentsListDialog();
                    if (val == 'tts') _showTtsReaderDialog();
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(value: 'single', child: Text(_isSinglePageMode ? 'تمرير مستمر ناعم (Smooth Scroll)' : 'عرض صفحة بصفحة')),
                    PopupMenuItem(value: 'dir', child: Text(_isHorizontal ? 'تمرير رأسي' : 'تمرير أفقي')),
                    const PopupMenuItem(value: 'full', child: Text('ملء الشاشة الكامل ⛶')),
                    const PopupMenuItem(value: 'thumbs', child: Text('مصغرات الصفحات والفهرس 📑')),
                    const PopupMenuItem(value: 'comments', child: Text('قائمة الملاحظات والتعليقات 💬')),
                    const PopupMenuItem(value: 'tts', child: Text('القارئ الصوتي (TTS) 🔊')),
                  ],
                ),
              ],
            ),
      body: readerBody,
      floatingActionButton: _isFullScreen
          ? FloatingActionButton.small(
              onPressed: () => setState(() => _isFullScreen = false),
              child: const Icon(Icons.fullscreen_exit),
            )
          : (_activeTool != 'none' ? _buildFloatingDrawingControls() : null),
    );
  }

  // بناء كل صفحة مع دعم التكبير (Pinch + Double Tap) والرسم الحر بالقلم والتظليل
  Widget _buildInteractivePageItem(int pageNum) {
    final strokes = _pageStrokes[pageNum] ?? [];

    return FutureBuilder<Uint8List?>(
      future: _renderPage(pageNum),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 520,
            margin: const EdgeInsets.all(8),
            color: Colors.grey.shade200,
            child: Center(child: Text('جاري تحضير صفحة $pageNum...')),
          );
        }

        Widget pageContent = RotatedBox(
          quarterTurns: _quarterTurns,
          child: Stack(
            children: [
              Image.memory(snapshot.data!, fit: BoxFit.contain),
              Positioned.fill(
                child: GestureDetector(
                  onPanStart: _activeTool == 'none'
                      ? null
                      : (details) {
                          setState(() {
                            _pageStrokes.putIfAbsent(pageNum, () => []);
                            _pageStrokes[pageNum]!.add(
                              StrokePath(
                                points: [details.localPosition],
                                color: _activeTool == 'redaction' ? Colors.black : _penColor,
                                width: _activeTool == 'highlight' ? 18.0 : (_activeTool == 'redaction' ? 24.0 : _penWidth),
                                isHighlighter: _activeTool == 'highlight',
                                isRedaction: _activeTool == 'redaction',
                              ),
                            );
                          });
                        },
                  onPanUpdate: _activeTool == 'none'
                      ? null
                      : (details) {
                          setState(() {
                            _pageStrokes[pageNum]!.last.points.add(details.localPosition);
                          });
                        },
                  child: CustomPaint(
                    painter: PageAnnotationPainter(strokes: strokes),
                  ),
                ),
              ),
            ],
          ),
        );

        // دعم التكبير بالقرص (Pinch Zoom) والضغط المزدوج
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
          child: InteractiveViewer(
            panEnabled: _activeTool == 'none',
            scaleEnabled: _activeTool == 'none',
            minScale: 1.0,
            maxScale: 4.5,
            child: pageContent,
          ),
        );
      },
    );
  }

  Widget _buildFloatingDrawingControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'undo_btn',
          tooltip: 'تراجع (Undo)',
          onPressed: () {
            final list = _pageStrokes[_currentPage];
            if (list != null && list.isNotEmpty) {
              setState(() => _redoStack.add(list.removeLast()));
            }
          },
          child: const Icon(Icons.undo),
        ),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          heroTag: 'redo_btn',
          tooltip: 'إعادة (Redo)',
          onPressed: () {
            if (_redoStack.isNotEmpty) {
              setState(() {
                _pageStrokes.putIfAbsent(_currentPage, () => []);
                _pageStrokes[_currentPage]!.add(_redoStack.removeLast());
              });
            }
          },
          child: const Icon(Icons.redo),
        ),
        const SizedBox(width: 8),
        FloatingActionButton.extended(
          heroTag: 'done_draw',
          backgroundColor: Colors.green,
          onPressed: () => setState(() => _activeTool = 'none'),
          icon: const Icon(Icons.check),
          label: const Text('إنهاء الرسم'),
        ),
      ],
    );
  }

  // شريط أدوات التعليقات: تظليل، قلم حر، ممحاة، توقيع، أختام، ملاحظات لاصقة، إخفاء معلومات (Redaction)
  void _showAnnotationToolbarSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            const SizedBox(width: double.infinity, child: Text('أدوات التعليق والتظليل والتوقيع:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            ActionChip(
              avatar: const Icon(Icons.highlight, color: Colors.amber),
              label: const Text('تظليل نص (Highlight)'),
              onPressed: () {
                setState(() {
                  _activeTool = 'highlight';
                  _penColor = Colors.yellow;
                });
                Navigator.pop(ctx);
              },
            ),
            ActionChip(
              avatar: const Icon(Icons.edit, color: Colors.blue),
              label: const Text('قلم رسم حر / خط تحت'),
              onPressed: () {
                setState(() {
                  _activeTool = 'pen';
                  _penColor = Colors.blue.shade700;
                });
                Navigator.pop(ctx);
              },
            ),
            ActionChip(
              avatar: const Icon(Icons.draw, color: Colors.indigo),
              label: const Text('توقيع بخط اليد ✍️'),
              onPressed: () {
                setState(() {
                  _activeTool = 'pen';
                  _penColor = Colors.indigo.shade900;
                  _penWidth = 3.0;
                });
                Navigator.pop(ctx);
              },
            ),
            ActionChip(
              avatar: const Icon(Icons.visibility_off, color: Colors.black),
              label: const Text('إخفاء معلومات (Redaction)'),
              onPressed: () {
                setState(() => _activeTool = 'redaction');
                Navigator.pop(ctx);
              },
            ),
            ActionChip(
              avatar: const Icon(Icons.note_alt_outlined, color: Colors.orange),
              label: const Text('إضافة ملاحظة لاصقة / ختم'),
              onPressed: () {
                Navigator.pop(ctx);
                _addStickyNoteOrStampDialog();
              },
            ),
            ActionChip(
              avatar: const Icon(Icons.cleaning_services, color: Colors.red),
              label: const Text('ممحاة الصفحة الحالية'),
              onPressed: () {
                setState(() => _pageStrokes[_currentPage]?.clear());
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addStickyNoteOrStampDialog() {
    final noteCtrl = TextEditingController();
    final authorCtrl = TextEditingController(text: 'مورجان');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إضافة تعليق أو ختم في صفحة $_currentPage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: authorCtrl, decoration: const InputDecoration(labelText: 'اسم المؤلف')),
            const SizedBox(height: 8),
            TextField(controller: noteCtrl, maxLines: 4, decoration: const InputDecoration(hintText: 'اكتب ملاحظتك أو اختر ختماً جاهزاً...', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: ['مهم للامتحان ✅', 'مراجعة لاحقاً 📌', 'تم الحفظ ⭐'].map((stamp) => ActionChip(
                label: Text(stamp, style: const TextStyle(fontSize: 11)),
                onPressed: () => noteCtrl.text = stamp,
              )).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (noteCtrl.text.isNotEmpty) {
                setState(() {
                  _commentsList.add(StickyNoteItem(page: _currentPage, text: noteCtrl.text, author: authorCtrl.text));
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('حفظ التعليق'),
          ),
        ],
      ),
    );
  }

  void _showCommentsListDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('قائمة كل التعليقات والأختام'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: _commentsList.isEmpty
              ? const Center(child: Text('لا توجد تعليقات مسجلة بعد'))
              : ListView.builder(
                  itemCount: _commentsList.length,
                  itemBuilder: (c, i) {
                    final item = _commentsList[i];
                    return ListTile(
                      leading: CircleAvatar(child: Text('${item.page}')),
                      title: Text(item.text),
                      subtitle: Text('بواسطة: ${item.author}'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _jumpToPage(item.page);
                      },
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق'))],
      ),
    );
  }

  // نافذة مصغرات الصفحات (Thumbnails) والانتقال لصفحة والإشارات المرجعية
  void _showJumpAndThumbnailsSheet() {
    final jumpCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: jumpCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(hintText: 'اكتب رقم الصفحة (1 - $_totalPages)', border: const OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final p = int.tryParse(jumpCtrl.text);
                      if (p != null) {
                        Navigator.pop(ctx);
                        _jumpToPage(p);
                      }
                    },
                    child: const Text('انتقال'),
                  ),
                ],
              ),
              if (_userBookmarks.isNotEmpty) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 6,
                    children: _userBookmarks.map((b) => ActionChip(
                      avatar: const Icon(Icons.bookmark, size: 16, color: Colors.amber),
                      label: Text('صفحة $b'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _jumpToPage(b);
                      },
                    )).toList(),
                  ),
                ),
              ],
              const Divider(height: 20),
              const Text('مصغرات الصفحات (Thumbnails)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.7, crossAxisSpacing: 8, mainAxisSpacing: 8),
                  itemCount: _totalPages,
                  itemBuilder: (c, idx) {
                    final pNum = idx + 1;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _jumpToPage(pNum);
                      },
                      child: GridTile(
                        footer: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.all(2),
                          child: Text('$pNum', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        child: FutureBuilder<Uint8List?>(
                          future: _renderPage(pNum),
                          builder: (c, snap) => snap.hasData
                              ? Image.memory(snap.data!, fit: BoxFit.cover)
                              : Container(color: Colors.grey.shade300, child: const Center(child: Icon(Icons.picture_as_pdf))),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNightAndBrightnessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('الوضع الليلي والسطوع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('عكس ألوان الصفحات للأسود'),
                value: _isNightInverted,
                onChanged: (v) {
                  setState(() => _isNightInverted = v);
                  setDialogState(() {});
                },
              ),
              const SizedBox(height: 10),
              const Text('تعتيم إضافي للشاشة (حماية العين ليلاً):'),
              Slider(
                value: _brightnessOverlay,
                min: 0.0,
                max: 0.75,
                onChanged: (v) {
                  setState(() => _brightnessOverlay = v);
                  setDialogState(() {});
                },
              ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تم'))],
        ),
      ),
    );
  }

  void _showTtsReaderDialog() {
    final ttsCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('القارئ الصوتي الذكي (TTS)'),
        content: TextField(
          controller: ttsCtrl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'ألصق أو اكتب الفقرة المراد سماعها صوتياً...', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => _tts.stop(), child: const Text('إيقاف الصوت')),
          ElevatedButton.icon(
            onPressed: () => _tts.speak(ttsCtrl.text),
            icon: const Icon(Icons.volume_up),
            label: const Text('قراءة الآن'),
          ),
        ],
      ),
    );
  }
}

class PageAnnotationPainter extends CustomPainter {
  final List<StrokePath> strokes;
  PageAnnotationPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      final paint = Paint()
        ..color = s.isHighlighter ? s.color.withOpacity(0.38) : s.color
        ..strokeWidth = s.width
        ..strokeCap = s.isRedaction ? StrokeCap.square : StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < s.points.length - 1; i++) {
        canvas.drawLine(s.points[i], s.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
