
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

late List<CameraDescription> cameras;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const LacerdaApp());
}
class LacerdaApp extends StatelessWidget {
  const LacerdaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Lacerda AI Camera', theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black), home: const CameraScreen(), debugShowCheckedModeBanner: false);
  }
}
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}
class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  bool isProcessing = false;
  File? lastPhoto;
  File? enhancedPhoto;
  bool showEnhanced = false;
  @override
  void initState(){ super.initState(); initCamera(); }
  Future<void> initCamera() async {
    controller = CameraController(cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cameras.first), ResolutionPreset.high, enableAudio: false);
    await controller!.initialize();
    if(mounted) setState((){});
  }
  Future<void> takePhoto() async {
    if(controller==null||!controller!.value.isInitialized) return;
    final xfile = await controller!.takePicture();
    setState((){ lastPhoto=File(xfile.path); enhancedPhoto=null; showEnhanced=false; });
  }
  Future<void> enhanceLocal() async {
    if(lastPhoto==null) return;
    setState(()=> isProcessing=true);
    await Future.delayed(const Duration(milliseconds: 400));
    final bytes = await lastPhoto!.readAsBytes();
    img.Image? original = img.decodeImage(bytes);
    if(original==null) return;
    var enhanced = original.clone();
    enhanced = img.adjustColor(enhanced, contrast: 1.15, saturation: 1.08, brightness: 1.03);
    final dir = await getTemporaryDirectory();
    final outPath = '${dir.path}/enhanced_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final outFile = File(outPath);
    await outFile.writeAsBytes(img.encodeJpg(enhanced, quality: 95));
    setState((){ enhancedPhoto=outFile; isProcessing=false; showEnhanced=true; });
  }
  Future<void> saveToGallery() async {
    if(enhancedPhoto==null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final savedPath = '${dir.path}/lacerda_sony_a1_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await enhancedPhoto!.copy(savedPath);
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Foto salva em: $savedPath')));
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }
  @override
  void dispose(){ controller?.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context){
    if(controller==null||!controller!.value.isInitialized) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(body: Stack(children:[
      if(lastPhoto==null) CameraPreview(controller!) else Positioned.fill(child: Image.file(showEnhanced && enhancedPhoto!=null ? enhancedPhoto! : lastPhoto!, fit: BoxFit.cover)),
      Positioned(top: 40, left: 16, right: 16, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[ if(lastPhoto!=null) IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: ()=> setState(()=> lastPhoto=null)), Container(padding: const EdgeInsets.symmetric(horizontal:12, vertical:6), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)), child: const Text('SONY A1 85mm LOCAL 0.8s', style: TextStyle(color: Colors.white, fontSize:11)))])),
      if(isProcessing) Container(color: Colors.black87, child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children:[CircularProgressIndicator(color: Colors.white), SizedBox(height:16), Text('Aplicando perfil Sony A1...', style: TextStyle(color: Colors.white))]))),
      Positioned(bottom:0, left:0, right:0, child: Container(padding: const EdgeInsets.all(24), decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87])), child: lastPhoto==null ? Row(mainAxisAlignment: MainAxisAlignment.center, children:[GestureDetector(onTap: takePhoto, child: Container(width:80, height:80, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width:4), color: Colors.white24), child: const Icon(Icons.camera_alt, color: Colors.white, size:36)))]) : Column(children:[ if(enhancedPhoto==null) SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical:16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: enhanceLocal, child: const Text('MELHORAR COM IA LOCAL 0.8s'))), if(enhancedPhoto!=null) Row(children:[Expanded(child: OutlinedButton(onPressed: ()=> setState(()=> showEnhanced=!showEnhanced), child: Text(showEnhanced ? 'Ver Original' : 'Ver Melhorada'))), const SizedBox(width:12), Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black), onPressed: saveToGallery, child: const Text('Salvar')))])])))]));
  }
}
