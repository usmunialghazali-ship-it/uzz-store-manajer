import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(UzzApp());

class UzzApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UZZ STORE MANAJER',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String apiKey = '';
  List vms = [];
  String status = 'Belum terhubung';
  bool loading = false;
  final keyCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _loadKey(); }

  _loadKey() async {
    final p = await SharedPreferences.getInstance();
    setState(() { apiKey = p.getString('apiKey') ?? ''; keyCtrl.text = apiKey; });
  }

  _saveKey() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('apiKey', keyCtrl.text.trim());
    setState(() => apiKey = keyCtrl.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('API Key tersimpan!')));
  }

  _fetchVM() async {
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Isi API Key dulu!')));
      return;
    }
    setState(() { loading = true; status = 'Menghubungkan...'; });
    try {
      final res = await http.get(
        Uri.parse('https://api.biznetgio.com/v1/compute/instances'),
        headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() { vms = data is List ? data : (data['data'] ?? []); status = 'Terhubung - ${vms.length} VM'; });
      } else {
        setState(() { status = 'Gagal: ${res.statusCode} - Mode Demo'; vms = [
          {'name': 'UZZ-STORE-01', 'status': 'ACTIVE', 'ip': '103.XX.XX.1'},
          {'name': 'UZZ-STORE-02', 'status': 'STOPPED', 'ip': '103.XX.XX.2'},
        ]; });
      }
    } catch (e) {
      setState(() { status = 'Mode Demo'; vms = [
        {'name': 'UZZ-STORE-01 (Demo)', 'status': 'ACTIVE', 'ip': '103.XX.XX.1'},
        {'name': 'UZZ-STORE-02 (Demo)', 'status': 'STOPPED', 'ip': '103.XX.XX.2'},
      ]; });
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('UZZ STORE MANAJER'), backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Biznet Gio NEO Lite', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            TextField(controller: keyCtrl, decoration: InputDecoration(labelText: 'API Key Biznet Gio', border: OutlineInputBorder())),
            SizedBox(height: 10),
            Row(children: [
              ElevatedButton(onPressed: _saveKey, child: Text('Simpan Key')),
              SizedBox(width: 8),
              ElevatedButton(onPressed: _fetchVM, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: Text('Cek VM', style: TextStyle(color: Colors.white))),
            ]),
            SizedBox(height: 8),
            Text('Status: $status'),
            if (loading) LinearProgressIndicator(),
          ]))),
          SizedBox(height: 16),
          Text('Daftar VM (${vms.length})', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          ...vms.map((vm) => Card(child: ListTile(
            leading: Icon(Icons.cloud, color: vm['status'] == 'ACTIVE' ? Colors.green : Colors.red),
            title: Text(vm['name'] ?? 'VM'),
            subtitle: Text('IP: ${vm['ip'] ?? '-'} | ${vm['status'] ?? ''}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: Icon(Icons.play_arrow, color: Colors.green), onPressed: () {}),
              IconButton(icon: Icon(Icons.stop, color: Colors.red), onPressed: () {}),
              IconButton(icon: Icon(Icons.restart_alt, color: Colors.orange), onPressed: () {}),
            ]),
          ))).toList(),
          if (vms.isEmpty) Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Belum ada VM. Klik Cek VM.'))),
        ]),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _fetchVM, child: Icon(Icons.refresh)),
    );
  }
}
