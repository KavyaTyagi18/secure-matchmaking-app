
/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; 
import 'dart:convert'; 
import 'package:encrypt/encrypt.dart' as encrypt; 
import 'inbox_screen.dart'; 

// ================= COLORS & THEME =================
const Color darkPurpleBackground = Color(0xFF0F0015);
const Color midPurpleBackground = Color(0xFF3B0040);
const Color primaryPink = Color(0xFFFF4081);

// ================= GLOBAL AES ENCRYPTION HELPERS =================
final _key = encrypt.Key.fromUtf8('my32charslongsecretkeyforaes256!'); 
final _iv = encrypt.IV.fromUtf8('1234567890123456'); 
final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

String encryptAES(String text) {
  return _encrypter.encrypt(text, iv: _iv).base64;
}

String decryptAES(String encryptedBase64) {
  try {
    return _encrypter.decrypt64(encryptedBase64, iv: _iv);
  } catch (e) {
    return "[Decryption Error]"; 
  }
}

// ================= NEW: FULL SCREEN IMAGE VIEWER =================
class FullScreenImage extends StatelessWidget {
  final String imageProvider; 

  const FullScreenImage({super.key, required this.imageProvider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: Hero(
          tag: imageProvider, // Tag matches the tapped image
          child: imageProvider.startsWith('http')
              ? Image.network(imageProvider, fit: BoxFit.contain)
              : Image.memory(base64Decode(imageProvider), fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class MatchingFeedScreen extends StatefulWidget {
  const MatchingFeedScreen({super.key});

  @override
  State<MatchingFeedScreen> createState() => _MatchingFeedScreenState();
}

class _MatchingFeedScreenState extends State<MatchingFeedScreen> with WidgetsBindingObserver {
  String selectedLocation = 'Global';
  String selectedGender = 'All';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateOnlineStatus(true); 
    _setupInAppNotificationListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateOnlineStatus(false); 
    _messageSubscription?.cancel(); 
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateOnlineStatus(true);
    } else {
      _updateOnlineStatus(false);
    }
  }

  void _updateOnlineStatus(bool isOnline) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }

  void _setupInAppNotificationListener() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    _messageSubscription = FirebaseFirestore.instance
        .collectionGroup('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) async { 
      if (snapshot.docs.isNotEmpty) {
        var doc = snapshot.docs.first;
        var data = doc.data();
        
        if (data['senderId'] != currentUserId && data['timestamp'] != null) {
          DateTime msgTime = (data['timestamp'] as Timestamp).toDate();
          if (DateTime.now().difference(msgTime).inSeconds < 60) {
              var senderDoc = await FirebaseFirestore.instance.collection('users').doc(data['senderId']).get();
              var receiverDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
              
              String senderName = senderDoc.data()?['name'] ?? "Someone";
              String receiverName = receiverDoc.data()?['name'] ?? "User";
              String? senderImageUrl = senderDoc.data()?['imageUrl'];

              _showTopNotification(
                "$senderName has sent a message to $receiverName",
                data['senderId'],
                senderName,
                senderImageUrl,
              );
          }
        }
      }
    });
  }

  void _showTopNotification(String displayMessage, String sId, String sName, String? sImageUrl) {
    OverlayState? overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 15,
        right: 15,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: primaryPink,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble, color: Colors.white),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    displayMessage,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    overlayEntry.remove();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                      receiverId: sId,
                      receiverName: sName,
                      receiverImageUrl: sImageUrl,
                    )));
                  },
                  child: const Text("VIEW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [darkPurpleBackground, midPurpleBackground],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Meet-Cute Feed', 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          actions: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: primaryPink),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const InboxScreen()));
              },
            ),
            IconButton(
              icon: const Icon(Icons.person_outline, color: primaryPink, size: 28),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          ],
        ),
        endDrawer: Drawer(
          backgroundColor: midPurpleBackground,
          child: currentUser != null 
              ? UserDrawer(uid: currentUser.uid) 
              : const Center(child: Text("Signed Out", style: TextStyle(color: Colors.white))),
        ),
        body: currentUser == null 
          ? const Center(child: CircularProgressIndicator()) 
          : StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text("Error: Check Firestore Rules", style: TextStyle(color: Colors.white)));
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: primaryPink));

            final allDocs = snapshot.data!.docs;
            Set<String> locationsSet = {'Global'};
            Set<String> gendersSet = {'All'};

            for (var doc in allDocs) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['location'] != null) locationsSet.add(data['location']);
              if (data['gender'] != null) gendersSet.add(data['gender']);
            }

            final filteredDocs = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final isNotMe = doc.id != currentUser.uid;
              final locOk = selectedLocation == 'Global' || data['location'] == selectedLocation;
              final genOk = selectedGender == 'All' || data['gender'] == selectedGender;
              return isNotMe && locOk && genOk;
            }).toList();

            return Column(
              children: [
                _buildDropdown('Location', locationsSet.toList(), selectedLocation, Icons.location_on, (v) => setState(() => selectedLocation = v)),
                _buildDropdown('Gender', gendersSet.toList(), selectedGender, Icons.person, (v) => setState(() => selectedGender = v)),
                Expanded(
                  child: filteredDocs.isEmpty 
                    ? const Center(child: Text("No real users found", style: TextStyle(color: Colors.white54)))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 12, mainAxisSpacing: 12,
                        ),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final data = filteredDocs[index].data() as Map<String, dynamic>;
                          data['uid'] = filteredDocs[index].id; 
                          return ProfileCard(userData: data);
                        },
                      ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, IconData icon, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : items.first,
        dropdownColor: midPurpleBackground,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label, labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: primaryPink),
          filled: true, fillColor: darkPurpleBackground.withOpacity(0.4),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) => onChanged(v!),
      ),
    );
  }
}

// ================= SIDEBAR & OTHER CLASSES =================
class UserDrawer extends StatelessWidget {
  final String? uid;
  const UserDrawer({super.key, this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!.data() as Map<String, dynamic>;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: darkPurpleBackground),
              accountName: Text(data['name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(data['email'] ?? ''),
              // UPDATED: Added GestureDetector for Full Screen view of your own photo
              currentAccountPicture: GestureDetector(
                onTap: () {
                  if (data['imageUrl'] != null && data['imageUrl'] != "") {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => FullScreenImage(imageProvider: data['imageUrl'])
                    ));
                  }
                },
                child: Hero(
                  tag: data['imageUrl'] ?? 'own_profile',
                  child: CircleAvatar(
                    backgroundColor: primaryPink,
                    backgroundImage: (data['imageUrl'] != null && data['imageUrl'] != "")
                        ? (data['imageUrl'].startsWith('http') 
                            ? NetworkImage(data['imageUrl']) 
                            : MemoryImage(base64Decode(data['imageUrl']))) as ImageProvider
                        : null,
                    child: (data['imageUrl'] == null || data['imageUrl'] == "") 
                        ? const Icon(Icons.person, color: Colors.white) : null,
                  ),
                ),
              ),
            ),
            _drawerTile(Icons.cake, "Age: ${data['age'] ?? 'N/A'}"),
            _drawerTile(Icons.location_on, "Lives in: ${data['location'] ?? 'N/A'}"),
            _drawerTile(Icons.height, "Height: ${data['height'] ?? 'N/A'} cm"),
            _drawerTile(Icons.work, "Job: ${data['occupation'] ?? 'Not Specified'}"),
            _drawerTile(Icons.favorite, "Looking for: ${data['lookingFor'] ?? 'N/A'}"),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text("Logout", style: TextStyle(color: Colors.white)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _drawerTile(IconData icon, String text) {
    return ListTile(
      leading: Icon(icon, color: primaryPink, size: 20),
      title: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
    );
  }
}

class ProfileCard extends StatelessWidget {
  final Map<String, dynamic> userData;
  const ProfileCard({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileDetailScreen(userData: userData))),
      child: Container(
        decoration: BoxDecoration(color: midPurpleBackground.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: (userData['imageUrl'] != null && userData['imageUrl'] != "") 
                  ? (userData['imageUrl'].startsWith('http') 
                      ? Image.network(userData['imageUrl'], fit: BoxFit.cover, width: double.infinity)
                      : Image.memory(base64Decode(userData['imageUrl']), fit: BoxFit.cover, width: double.infinity))
                  : const Center(child: Icon(Icons.person, size: 50, color: Colors.white24)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(userData['name'] ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                  Text('${userData['age'] ?? ''}', style: const TextStyle(color: primaryPink)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileDetailScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  const ProfileDetailScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkPurpleBackground,
      appBar: AppBar(backgroundColor: Colors.transparent, title: Text(userData['name'] ?? 'Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (userData['imageUrl'] != null) 
              // UPDATED: Added GestureDetector for Full Screen view of others' photos (like Anjali)
              GestureDetector(
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(
                      builder: (_) => FullScreenImage(imageProvider: userData['imageUrl'])
                    ));
                },
                child: Hero(
                  tag: userData['imageUrl'],
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20), 
                    child: userData['imageUrl'].startsWith('http')
                      ? Image.network(userData['imageUrl'])
                      : Image.memory(base64Decode(userData['imageUrl'])),
                  ),
                ),
              ),
            const SizedBox(height: 25),
            _infoSection("Basic Info", [
              "Age: ${userData['age'] ?? 'N/A'}",
              "Gender: ${userData['gender'] ?? 'N/A'}",
              "Location: ${userData['location'] ?? 'N/A'}",
              "Height: ${userData['height'] ?? 'N/A'} cm",
            ]),
            _infoSection("Lifestyle & Professional", [
              "Occupation: ${userData['occupation'] ?? 'Not Specified'}",
              "Smoking: ${userData['smoking'] ?? 'Not specified'}",
              "Drinking: ${userData['drinking'] ?? 'Not specified'}",
              "Vibe: ${userData['vibe'] ?? 'Not specified'}",
              "Looking For: ${userData['lookingFor'] ?? 'N/A'}",
            ]),
            const Text('Interests', style: TextStyle(color: primaryPink, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: (userData['interests'] as List<dynamic>? ?? []).map((e) => Chip(backgroundColor: midPurpleBackground, label: Text(e.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)))).toList(),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.chat_bubble_rounded),
              label: Text('Chat with ${userData['name'] ?? 'User'}'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryPink, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                  receiverName: userData['name'] ?? 'User', 
                  receiverImageUrl: userData['imageUrl'],
                  receiverId: userData['uid'], 
                )));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoSection(String title, List<String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: primaryPink, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...details.map((detail) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(detail, style: const TextStyle(color: Colors.white, fontSize: 16)))),
        const SizedBox(height: 20),
      ],
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String receiverName;
  final String? receiverImageUrl;
  final String receiverId;

  const ChatScreen({super.key, required this.receiverName, required this.receiverId, this.receiverImageUrl});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  
  StreamSubscription? _realTimeSeenListener;

  @override
  void initState() {
    super.initState();
    _setupRealTimeSeenListener();
  }

  @override
  void dispose() {
    _realTimeSeenListener?.cancel();
    super.dispose();
  }

  void _setupRealTimeSeenListener() {
    String chatRoomId = getChatRoomId(currentUserId, widget.receiverId);
    
    _realTimeSeenListener = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .where('senderId', isEqualTo: widget.receiverId)
        .where('isSeen', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({'isSeen': true});
      }
    });
  }

  String getChatRoomId(String user1, String user2) {
    List<String> ids = [user1, user2];
    ids.sort();
    return ids.join("_");
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    String chatRoomId = getChatRoomId(currentUserId, widget.receiverId);
    String messageText = _messageController.text.trim();

    String encryptedText = encryptAES(messageText);

    await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).collection('messages').add({
      'senderId': currentUserId,
      'text': encryptedText, 
      'timestamp': FieldValue.serverTimestamp(),
      'isSeen': false,
    });

    await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).set({
      'chatRoomId': chatRoomId,
      'users': [currentUserId, widget.receiverId],
      'lastMessage': encryptedText, 
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'receiverName': widget.receiverName,
      'receiverImageUrl': widget.receiverImageUrl,
    }, SetOptions(merge: true));

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    String chatRoomId = getChatRoomId(currentUserId, widget.receiverId);

    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [darkPurpleBackground, midPurpleBackground])),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(widget.receiverId).snapshots(),
            builder: (context, snapshot) {
              bool isOnline = false;
              if (snapshot.hasData && snapshot.data!.exists) {
                isOnline = (snapshot.data!.data() as Map<String, dynamic>)['isOnline'] ?? false;
              }
              return Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 18, 
                        backgroundImage: (widget.receiverImageUrl != null && widget.receiverImageUrl != "")
                            ? (widget.receiverImageUrl!.startsWith('http') 
                                ? NetworkImage(widget.receiverImageUrl!) 
                                : MemoryImage(base64Decode(widget.receiverImageUrl!))) as ImageProvider
                            : null,
                        child: (widget.receiverImageUrl == null || widget.receiverImageUrl == "") ? const Icon(Icons.person) : null
                      ),
                      if (isOnline)
                        Positioned(
                          right: 0, bottom: 0,
                          child: Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.5)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.receiverName, style: const TextStyle(fontSize: 16)),
                      Text(isOnline ? "Online" : "Offline", style: TextStyle(fontSize: 11, color: isOnline ? Colors.greenAccent : Colors.white54)),
                    ],
                  ),
                ],
              );
            }
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatRoomId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final messages = snapshot.data!.docs;

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(15),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var msgData = messages[index].data() as Map<String, dynamic>;
                      bool isMe = msgData['senderId'] == currentUserId;
                      bool isSeen = msgData['isSeen'] ?? false;

                      String decryptedText = decryptAES(msgData['text']);

                      return Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe ? primaryPink : Colors.white24, 
                                borderRadius: BorderRadius.circular(15)
                              ),
                              child: Text(decryptedText, style: const TextStyle(color: Colors.white)),
                            ),
                          ),
                          if (isMe && isSeen)
                            const Padding(
                              padding: EdgeInsets.only(right: 5, bottom: 5),
                              child: Text("Seen", style: TextStyle(color: Colors.white54, fontSize: 10)),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(15),
      color: Colors.black26,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "Type a message...", hintStyle: TextStyle(color: Colors.white54), border: InputBorder.none),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: primaryPink),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }


}*/
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; 
import 'dart:convert'; 
import 'package:encrypt/encrypt.dart' as encrypt; 
import 'inbox_screen.dart'; 

// ================= COLORS & THEME =================
const Color darkPurpleBackground = Color(0xFF0F0015);
const Color midPurpleBackground = Color(0xFF3B0040);
const Color primaryPink = Color(0xFFFF4081);

// ================= GLOBAL AES ENCRYPTION HELPERS =================
final _key = encrypt.Key.fromUtf8('my32charslongsecretkeyforaes256!'); 
final _iv = encrypt.IV.fromUtf8('1234567890123456'); 
final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

String encryptAES(String text) {
  return _encrypter.encrypt(text, iv: _iv).base64;
}

String decryptAES(String encryptedBase64) {
  try {
    return _encrypter.decrypt64(encryptedBase64, iv: _iv);
  } catch (e) {
    return "[Decryption Error]"; 
  }
}

// ================= NEW: FULL SCREEN IMAGE VIEWER =================
class FullScreenImage extends StatelessWidget {
  final String imageProvider; 

  const FullScreenImage({super.key, required this.imageProvider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: Hero(
          tag: imageProvider, // Tag matches the tapped image
          child: imageProvider.startsWith('http')
              ? Image.network(imageProvider, fit: BoxFit.contain)
              : Image.memory(base64Decode(imageProvider), fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class MatchingFeedScreen extends StatefulWidget {
  const MatchingFeedScreen({super.key});

  @override
  State<MatchingFeedScreen> createState() => _MatchingFeedScreenState();
}

class _MatchingFeedScreenState extends State<MatchingFeedScreen> with WidgetsBindingObserver {
  String selectedLocation = 'Global';
  String selectedGender = 'All';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateOnlineStatus(true); 
    _setupInAppNotificationListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateOnlineStatus(false); 
    _messageSubscription?.cancel(); 
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateOnlineStatus(true);
    } else {
      _updateOnlineStatus(false);
    }
  }

  void _updateOnlineStatus(bool isOnline) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }

  void _setupInAppNotificationListener() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    _messageSubscription = FirebaseFirestore.instance
        .collectionGroup('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) async { 
      if (snapshot.docs.isNotEmpty) {
        var doc = snapshot.docs.first;
        var data = doc.data();
        
        if (data['senderId'] != currentUserId && data['timestamp'] != null) {
          DateTime msgTime = (data['timestamp'] as Timestamp).toDate();
          if (DateTime.now().difference(msgTime).inSeconds < 60) {
              var senderDoc = await FirebaseFirestore.instance.collection('users').doc(data['senderId']).get();
              var receiverDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
              
              String senderName = senderDoc.data()?['name'] ?? "Someone";
              String receiverName = receiverDoc.data()?['name'] ?? "User";
              String? senderImageUrl = senderDoc.data()?['imageUrl'];

              _showTopNotification(
                "$senderName has sent a message to $receiverName",
                data['senderId'],
                senderName,
                senderImageUrl,
              );
          }
        }
      }
    });
  }

  void _showTopNotification(String displayMessage, String sId, String sName, String? sImageUrl) {
    OverlayState? overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 15,
        right: 15,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: primaryPink,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble, color: Colors.white),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    displayMessage,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    overlayEntry.remove();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                      receiverId: sId,
                      receiverName: sName,
                      receiverImageUrl: sImageUrl,
                    )));
                  },
                  child: const Text("VIEW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [darkPurpleBackground, midPurpleBackground],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          // UPDATED: Personalized Welcome Title
          title: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Text('Meet-Cute Feed', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white));
              }
              var userData = snapshot.data!.data() as Map<String, dynamic>;
              String name = userData['name'] ?? 'User';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome, $name', 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                  const Text('to Meet-Cute', 
                    style: TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: primaryPink),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const InboxScreen()));
              },
            ),
            IconButton(
              icon: const Icon(Icons.person_outline, color: primaryPink, size: 28),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          ],
        ),
        endDrawer: Drawer(
          backgroundColor: midPurpleBackground,
          child: currentUser != null 
              ? UserDrawer(uid: currentUser.uid) 
              : const Center(child: Text("Signed Out", style: TextStyle(color: Colors.white))),
        ),
        body: currentUser == null 
          ? const Center(child: CircularProgressIndicator()) 
          : StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text("Error: Check Firestore Rules", style: TextStyle(color: Colors.white)));
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: primaryPink));

            final allDocs = snapshot.data!.docs;
            Set<String> locationsSet = {'Global'};
            Set<String> gendersSet = {'All'};

            for (var doc in allDocs) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['location'] != null) locationsSet.add(data['location']);
              if (data['gender'] != null) gendersSet.add(data['gender']);
            }

            final filteredDocs = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final isNotMe = doc.id != currentUser.uid;
              final locOk = selectedLocation == 'Global' || data['location'] == selectedLocation;
              final genOk = selectedGender == 'All' || data['gender'] == selectedGender;
              return isNotMe && locOk && genOk;
            }).toList();

            return Column(
              children: [
                _buildDropdown('Location', locationsSet.toList(), selectedLocation, Icons.location_on, (v) => setState(() => selectedLocation = v)),
                _buildDropdown('Gender', gendersSet.toList(), selectedGender, Icons.person, (v) => setState(() => selectedGender = v)),
                Expanded(
                  child: filteredDocs.isEmpty 
                    ? const Center(child: Text("No real users found", style: TextStyle(color: Colors.white54)))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 12, mainAxisSpacing: 12,
                        ),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final data = filteredDocs[index].data() as Map<String, dynamic>;
                          data['uid'] = filteredDocs[index].id; 
                          return ProfileCard(userData: data);
                        },
                      ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, IconData icon, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: DropdownButtonFormField<String>(
        initialValue: items.contains(value) ? value : items.first,
        dropdownColor: midPurpleBackground,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label, labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: primaryPink),
          filled: true, fillColor: darkPurpleBackground.withOpacity(0.4),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) => onChanged(v!),
      ),
    );
  }
}

// ================= SIDEBAR & OTHER CLASSES =================
class UserDrawer extends StatelessWidget {
  final String? uid;
  const UserDrawer({super.key, this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!.data() as Map<String, dynamic>;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: darkPurpleBackground),
              accountName: Text(data['name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(data['email'] ?? ''),
              currentAccountPicture: GestureDetector(
                onTap: () {
                  if (data['imageUrl'] != null && data['imageUrl'] != "") {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => FullScreenImage(imageProvider: data['imageUrl'])
                    ));
                  }
                },
                child: Hero(
                  tag: data['imageUrl'] ?? 'own_profile',
                  child: CircleAvatar(
                    backgroundColor: primaryPink,
                    backgroundImage: (data['imageUrl'] != null && data['imageUrl'] != "")
                        ? (data['imageUrl'].startsWith('http') 
                            ? NetworkImage(data['imageUrl']) 
                            : MemoryImage(base64Decode(data['imageUrl']))) as ImageProvider
                        : null,
                    child: (data['imageUrl'] == null || data['imageUrl'] == "") 
                        ? const Icon(Icons.person, color: Colors.white) : null,
                  ),
                ),
              ),
            ),
            _drawerTile(Icons.cake, "Age: ${data['age'] ?? 'N/A'}"),
            _drawerTile(Icons.location_on, "Lives in: ${data['location'] ?? 'N/A'}"),
            _drawerTile(Icons.height, "Height: ${data['height'] ?? 'N/A'} cm"),
            _drawerTile(Icons.work, "Job: ${data['occupation'] ?? 'Not Specified'}"),
            _drawerTile(Icons.favorite, "Looking for: ${data['lookingFor'] ?? 'N/A'}"),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text("Logout", style: TextStyle(color: Colors.white)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _drawerTile(IconData icon, String text) {
    return ListTile(
      leading: Icon(icon, color: primaryPink, size: 20),
      title: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
    );
  }
}

class ProfileCard extends StatelessWidget {
  final Map<String, dynamic> userData;
  const ProfileCard({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileDetailScreen(userData: userData))),
      child: Container(
        decoration: BoxDecoration(color: midPurpleBackground.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: (userData['imageUrl'] != null && userData['imageUrl'] != "") 
                  ? (userData['imageUrl'].startsWith('http') 
                      ? Image.network(userData['imageUrl'], fit: BoxFit.cover, width: double.infinity)
                      : Image.memory(base64Decode(userData['imageUrl']), fit: BoxFit.cover, width: double.infinity))
                  : const Center(child: Icon(Icons.person, size: 50, color: Colors.white24)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(userData['name'] ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                  Text('${userData['age'] ?? ''}', style: const TextStyle(color: primaryPink)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileDetailScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  const ProfileDetailScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkPurpleBackground,
      appBar: AppBar(backgroundColor: Colors.transparent, title: Text(userData['name'] ?? 'Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (userData['imageUrl'] != null) 
              GestureDetector(
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(
                      builder: (_) => FullScreenImage(imageProvider: userData['imageUrl'])
                    ));
                },
                child: Hero(
                  tag: userData['imageUrl'],
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20), 
                    child: userData['imageUrl'].startsWith('http')
                      ? Image.network(userData['imageUrl'])
                      : Image.memory(base64Decode(userData['imageUrl'])),
                  ),
                ),
              ),
            const SizedBox(height: 25),
            _infoSection("Basic Info", [
              "Age: ${userData['age'] ?? 'N/A'}",
              "Gender: ${userData['gender'] ?? 'N/A'}",
              "Location: ${userData['location'] ?? 'N/A'}",
              "Height: ${userData['height'] ?? 'N/A'} cm",
            ]),
            _infoSection("Lifestyle & Professional", [
              "Occupation: ${userData['occupation'] ?? 'Not Specified'}",
              "Smoking: ${userData['smoking'] ?? 'Not specified'}",
              "Drinking: ${userData['drinking'] ?? 'Not specified'}",
              "Vibe: ${userData['vibe'] ?? 'Not specified'}",
              "Looking For: ${userData['lookingFor'] ?? 'N/A'}",
            ]),
            const Text('Interests', style: TextStyle(color: primaryPink, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: (userData['interests'] as List<dynamic>? ?? []).map((e) => Chip(backgroundColor: midPurpleBackground, label: Text(e.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)))).toList(),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.chat_bubble_rounded),
              label: Text('Chat with ${userData['name'] ?? 'User'}'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryPink, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                  receiverName: userData['name'] ?? 'User', 
                  receiverImageUrl: userData['imageUrl'],
                  receiverId: userData['uid'], 
                )));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoSection(String title, List<String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: primaryPink, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...details.map((detail) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(detail, style: const TextStyle(color: Colors.white, fontSize: 16)))),
        const SizedBox(height: 20),
      ],
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String receiverName;
  final String? receiverImageUrl;
  final String receiverId;

  const ChatScreen({super.key, required this.receiverName, required this.receiverId, this.receiverImageUrl});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  
  StreamSubscription? _realTimeSeenListener;

  @override
  void initState() {
    super.initState();
    _setupRealTimeSeenListener();
  }

  @override
  void dispose() {
    _realTimeSeenListener?.cancel();
    super.dispose();
  }

  void _setupRealTimeSeenListener() {
    String chatRoomId = getChatRoomId(currentUserId, widget.receiverId);
    
    _realTimeSeenListener = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .where('senderId', isEqualTo: widget.receiverId)
        .where('isSeen', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({'isSeen': true});
      }
    });
  }

  String getChatRoomId(String user1, String user2) {
    List<String> ids = [user1, user2];
    ids.sort();
    return ids.join("_");
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    String chatRoomId = getChatRoomId(currentUserId, widget.receiverId);
    String messageText = _messageController.text.trim();

    String encryptedText = encryptAES(messageText);

    await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).collection('messages').add({
      'senderId': currentUserId,
      'text': encryptedText, 
      'timestamp': FieldValue.serverTimestamp(),
      'isSeen': false,
    });

    await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).set({
      'chatRoomId': chatRoomId,
      'users': [currentUserId, widget.receiverId],
      'lastMessage': encryptedText, 
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'receiverName': widget.receiverName,
      'receiverImageUrl': widget.receiverImageUrl,
    }, SetOptions(merge: true));

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    String chatRoomId = getChatRoomId(currentUserId, widget.receiverId);

    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [darkPurpleBackground, midPurpleBackground])),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(widget.receiverId).snapshots(),
            builder: (context, snapshot) {
              bool isOnline = false;
              if (snapshot.hasData && snapshot.data!.exists) {
                isOnline = (snapshot.data!.data() as Map<String, dynamic>)['isOnline'] ?? false;
              }
              return Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 18, 
                        backgroundImage: (widget.receiverImageUrl != null && widget.receiverImageUrl != "")
                            ? (widget.receiverImageUrl!.startsWith('http') 
                                ? NetworkImage(widget.receiverImageUrl!) 
                                : MemoryImage(base64Decode(widget.receiverImageUrl!))) as ImageProvider
                            : null,
                        child: (widget.receiverImageUrl == null || widget.receiverImageUrl == "") ? const Icon(Icons.person) : null
                      ),
                      if (isOnline)
                        Positioned(
                          right: 0, bottom: 0,
                          child: Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.5)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.receiverName, style: const TextStyle(fontSize: 16)),
                      Text(isOnline ? "Online" : "Offline", style: TextStyle(fontSize: 11, color: isOnline ? Colors.greenAccent : Colors.white54)),
                    ],
                  ),
                ],
              );
            }
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatRoomId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final messages = snapshot.data!.docs;

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(15),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var msgData = messages[index].data() as Map<String, dynamic>;
                      bool isMe = msgData['senderId'] == currentUserId;
                      bool isSeen = msgData['isSeen'] ?? false;

                      String decryptedText = decryptAES(msgData['text']);

                      return Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe ? primaryPink : Colors.white24, 
                                borderRadius: BorderRadius.circular(15)
                              ),
                              child: Text(decryptedText, style: const TextStyle(color: Colors.white)),
                            ),
                          ),
                          if (isMe && isSeen)
                            const Padding(
                              padding: EdgeInsets.only(right: 5, bottom: 5),
                              child: Text("Seen", style: TextStyle(color: Colors.white54, fontSize: 10)),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(15),
      color: Colors.black26,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "Type a message...", hintStyle: TextStyle(color: Colors.white54), border: InputBorder.none),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: primaryPink),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}

