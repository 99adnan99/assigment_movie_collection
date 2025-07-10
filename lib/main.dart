import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pengesan Hutang',
      theme: isDarkMode
          ? ThemeData.dark().copyWith(
              primaryColor: Colors.teal,
              scaffoldBackgroundColor: Colors.grey[900],
              appBarTheme: AppBarTheme(backgroundColor: Colors.teal),
              floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: Colors.tealAccent),
              cardColor: Colors.grey[850],
              textTheme: ThemeData.dark().textTheme.apply(bodyColor: Colors.white),
            )
          : ThemeData(
              primarySwatch: Colors.blue,
              scaffoldBackgroundColor: Colors.grey[100],
              appBarTheme: AppBarTheme(backgroundColor: Colors.blueAccent),
              floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: Colors.blueAccent),
              cardColor: Colors.white,
              bottomNavigationBarTheme: BottomNavigationBarThemeData(
                backgroundColor: Colors.blueGrey[900],
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.grey,
              ),
            ),
      home: MainScreen(toggleTheme: toggleTheme, isDarkMode: isDarkMode),
    );
  }
}

class MainScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const MainScreen({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1;
  Map<String, bool> expandedItems = {};

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      expandedItems.clear();
    });
  }

  void _showOptions(BuildContext context, String docId) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: widget.isDarkMode ? Colors.grey[800] : Colors.teal[100],
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Ubah Suai'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddDebtScreen(docId: docId),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Hapus'),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Pengesahan'),
                    content: Text('Hapus hutang?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Tidak'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Ya'),
                      ),
                    ],
                  ),
                );
                if (confirm != true) return;
                await FirebaseFirestore.instance.collection('debts').doc(docId).delete();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Berjaya'),
                    content: Text('Hutang telah dihapus'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK'),
                      )
                    ],
                  ),
                ).then((_) => Navigator.pop(context));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pengesan Hutang'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('debts').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final allDebts = snapshot.data!.docs;

          final filteredDebts = _selectedIndex == 0
              ? allDebts.where((doc) => doc['type'] == 0).toList()
              : _selectedIndex == 2
                  ? allDebts.where((doc) => doc['type'] == 1).toList()
                  : allDebts;

          return ListView.builder(
            itemCount: filteredDebts.length,
            itemBuilder: (context, index) {
              var debt = filteredDebts[index];
              var docId = debt.id;
              var isExpanded = expandedItems[docId] ?? false;
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                margin: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                color: widget.isDarkMode
                    ? (debt['type'] == 0 ? Colors.green.shade900 : Colors.red.shade900)
                    : (debt['type'] == 0 ? Colors.green[100] : Colors.red[100]),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: debt['type'] == 0 ? Colors.green : Colors.red,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        debt['name'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: widget.isDarkMode ? Colors.white : null,
                        ),
                      ),
                      subtitle: Text(
                        "Jumlah: RM ${debt['amount'] ?? ''}",
                        style: TextStyle(
                          fontSize: 16,
                          color: widget.isDarkMode ? Colors.white70 : null,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.more_vert),
                        onPressed: () => _showOptions(context, docId),
                      ),
                      onTap: () {
                        setState(() {
                          expandedItems[docId] = !isExpanded;
                        });
                      },
                    ),
                    if (isExpanded)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Divider(color: widget.isDarkMode ? Colors.white24 : Colors.grey),
                              Text("Tarikh: ${debt['date'] ?? ''}", style: TextStyle(color: widget.isDarkMode ? Colors.white : null)),
                              Text("Sebab: ${debt['reason'] ?? ''}", style: TextStyle(color: widget.isDarkMode ? Colors.white : null)),
                              Text("Jenis: ${debt['type'] == 0 ? 'Penghutang' : 'Hutang'}", style: TextStyle(color: widget.isDarkMode ? Colors.white : null)),
                            ],
                          ),
                        ),
                      )
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddDebtScreen()),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.arrow_forward), label: 'Penghutang'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Kenalan'),
          BottomNavigationBarItem(icon: Icon(Icons.arrow_back), label: 'Hutang'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class AddDebtScreen extends StatefulWidget {
  final String? docId;
  const AddDebtScreen({super.key, this.docId});

  @override
  _AddDebtScreenState createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  int _type = 0;
  TextEditingController amountController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.docId != null) {
      FirebaseFirestore.instance.collection('debts').doc(widget.docId!).get().then((doc) {
        var data = doc.data();
        if (data != null) {
          setState(() {
            _type = data['type'];
            amountController.text = data['amount'];
            nameController.text = data['name'];
            dateController.text = data['date'];
            reasonController.text = data['reason'];
          });
        }
      });
    }
  }

  void _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  void _saveDebt() async {
    if (amountController.text.isEmpty || nameController.text.isEmpty || dateController.text.isEmpty || reasonController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Ralat'),
          content: Text('Sila masukkan nilai dalam semua medan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            )
          ],
        ),
      );
      return;
    }
    final data = {
      'type': _type,
      'amount': amountController.text,
      'name': nameController.text,
      'date': dateController.text,
      'reason': reasonController.text,
    };
    if (widget.docId != null) {
      await FirebaseFirestore.instance.collection('debts').doc(widget.docId!).update(data);
    } else {
      await FirebaseFirestore.instance.collection('debts').add(data);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.docId == null ? 'Tambah Hutang' : 'Kemaskini Hutang'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: RadioListTile(value: 0, groupValue: _type, onChanged: (val) => setState(() => _type = val as int), title: Text('Penghutang'))),
                Expanded(child: RadioListTile(value: 1, groupValue: _type, onChanged: (val) => setState(() => _type = val as int), title: Text('Hutang'))),
              ],
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Jumlah dalam RM',
                prefixIcon: Icon(Icons.monetization_on),
              ),
            ),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nama Kenalan',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            TextField(
              controller: dateController,
              readOnly: true,
              onTap: _pickDate,
              decoration: InputDecoration(
                labelText: 'Tarikh',
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Sebab',
                prefixIcon: Icon(Icons.note),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveDebt,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Sahkan'),
            )
          ],
        ),
      ),
    );
  }
}
