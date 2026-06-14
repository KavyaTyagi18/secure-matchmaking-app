/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'matching_feed.dart'; // ChatScreen ke liye path check karein

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: darkPurpleBackground,
      appBar: AppBar(
        title: const Text('Your Messages'),
        backgroundColor: midPurpleBackground,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Sirf wahi chat rooms dikhayega jisme current user shamil hai
        stream: FirebaseFirestore.instance.collection('chats').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // Filter chats that belong to the current user
          final myChats = snapshot.data!.docs.where((doc) => doc.id.contains(currentUserId)).toList();

          if (myChats.isEmpty) {
            return const Center(child: Text("No messages yet", style: TextStyle(color: Colors.white70)));
          }

          return ListView.builder(
            itemCount: myChats.length,
            itemBuilder: (context, index) {
              String roomId = myChats[index].id;
              // Dusre user ki ID nikalna
              String otherUserId = roomId.replaceFirst(currentUserId, "").replaceFirst("_", "");

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const SizedBox.shrink();
                  var userData = userSnapshot.data!.data() as Map<String, dynamic>;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: userData['imageUrl'] != null ? NetworkImage(userData['imageUrl']) : null,
                      child: userData['imageUrl'] == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(userData['name'] ?? 'User', style: const TextStyle(color: Colors.white)),
                    subtitle: const Text("Tap to view message", style: TextStyle(color: Colors.pinkAccent, fontSize: 12)),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          receiverName: userData['name'],
                          receiverId: otherUserId,
                          receiverImageUrl: userData['imageUrl'],
                        ),
                      ));
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}*/
/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:encrypt/encrypt.dart' as encrypt; // NEW: Required for AES
import 'matching_feed.dart'; // ChatScreen ke liye path check karein


// Move this to the top of inbox_screen.dart
final _key = encrypt.Key.fromUtf8('my32charslongsecretkeyforaes256!'); 
final _iv = encrypt.IV.fromLength(16);
final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

String decryptAES(String? encryptedBase64) {
  if (encryptedBase64 == null || encryptedBase64.isEmpty) return "";
  try {
    return _encrypter.decrypt64(encryptedBase64, iv: _iv);
  } catch (e) {
    return "[Decryption Error]"; 
  }
}

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: darkPurpleBackground,
      appBar: AppBar(
        title: const Text('Your Messages'),
        backgroundColor: midPurpleBackground,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Sirf wahi chat rooms dikhayega jisme current user shamil hai
        stream: FirebaseFirestore.instance.collection('chats').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // Filter chats that belong to the current user
          final myChats = snapshot.data!.docs.where((doc) => doc.id.contains(currentUserId)).toList();

          if (myChats.isEmpty) {
            return const Center(child: Text("No messages yet", style: TextStyle(color: Colors.white70)));
          }

          return ListView.builder(
            itemCount: myChats.length,
            itemBuilder: (context, index) {
              String roomId = myChats[index].id;
              var chatData = myChats[index].data() as Map<String, dynamic>; // Get chat data
              
              // Dusre user ki ID nikalna
              String otherUserId = roomId.replaceFirst(currentUserId, "").replaceFirst("_", "");

              // --- DECRYPT THE LAST MESSAGE FOR THE SUBTITLE ---
              String encryptedLastMsg = chatData['lastMessage'] ?? "";
              String displayMsg = decryptAES(encryptedLastMsg);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const SizedBox.shrink();
                  var userData = userSnapshot.data!.data() as Map<String, dynamic>;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: userData['imageUrl'] != null ? NetworkImage(userData['imageUrl']) : null,
                      child: userData['imageUrl'] == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(userData['name'] ?? 'User', style: const TextStyle(color: Colors.white)),
                    // UPDATED SUBTITLE: Now shows the real message instead of "Tap to view"
                    subtitle: Text(
                      displayMsg.isEmpty ? "Tap to view message" : displayMsg, 
                      style: const TextStyle(color: Colors.pinkAccent, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          receiverName: userData['name'],
                          receiverId: otherUserId,
                          receiverImageUrl: userData['imageUrl'],
                        ),
                      ));
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}*/
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:encrypt/encrypt.dart' as encrypt; 
import 'matching_feed.dart'; 

// ================= GLOBAL AES ENCRYPTION HELPERS =================
// 1. Key must be exactly 32 characters
final _key = encrypt.Key.fromUtf8('my32charslongsecretkeyforaes256!'); 
// 2. FIXED IV (This fixes the Decryption Error)
final _iv = encrypt.IV.fromUtf8('1234567890123456'); 
final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

String decryptAES(String? encryptedBase64) {
  if (encryptedBase64 == null || encryptedBase64.isEmpty) return "";
  try {
    return _encrypter.decrypt64(encryptedBase64, iv: _iv);
  } catch (e) {
    return "[Decryption Error]"; 
  }
}

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: darkPurpleBackground,
      appBar: AppBar(
        title: const Text('Your Messages'),
        backgroundColor: midPurpleBackground,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chats').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final myChats = snapshot.data!.docs.where((doc) => doc.id.contains(currentUserId)).toList();

          if (myChats.isEmpty) {
            return const Center(child: Text("No messages yet", style: TextStyle(color: Colors.white70)));
          }

          return ListView.builder(
            itemCount: myChats.length,
            itemBuilder: (context, index) {
              String roomId = myChats[index].id;
              var chatData = myChats[index].data() as Map<String, dynamic>; 
              
              String otherUserId = roomId.replaceFirst(currentUserId, "").replaceFirst("_", "");

              // --- DECRYPT THE LAST MESSAGE FOR THE SUBTITLE ---
              String encryptedLastMsg = chatData['lastMessage'] ?? "";
              String displayMsg = decryptAES(encryptedLastMsg);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const SizedBox.shrink();
                  var userData = userSnapshot.data!.data() as Map<String, dynamic>;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: userData['imageUrl'] != null ? NetworkImage(userData['imageUrl']) : null,
                      child: userData['imageUrl'] == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(userData['name'] ?? 'User', style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      displayMsg.isEmpty ? "Tap to view message" : displayMsg, 
                      style: const TextStyle(color: Colors.pinkAccent, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          receiverName: userData['name'],
                          receiverId: otherUserId,
                          receiverImageUrl: userData['imageUrl'],
                        ),
                      ));
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}