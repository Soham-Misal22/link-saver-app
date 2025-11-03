// lib/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Create a private constructor
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'linksaver.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // This function runs only the first time the database is created.
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        user_id TEXT NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE links (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folder_id INTEGER NOT NULL,
        url TEXT NOT NULL,
        title TEXT,
        thumbnail_url TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        user_id TEXT NOT NULL,
        FOREIGN KEY (folder_id) REFERENCES folders (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_folders_user ON folders(user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_links_user ON links(user_id)');
  }

  // Handle database upgrades
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE links (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          folder_id INTEGER NOT NULL,
          url TEXT NOT NULL,
          title TEXT,
          thumbnail_url TEXT,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (folder_id) REFERENCES folders (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 3) {
      // Add thumbnail_url column if upgrading from versions without it
      await db.execute('ALTER TABLE links ADD COLUMN thumbnail_url TEXT');
    }
    if (oldVersion < 4) {
      // Add per-user scoping
      await db.execute('ALTER TABLE folders ADD COLUMN user_id TEXT');
      await db.execute('ALTER TABLE links ADD COLUMN user_id TEXT');
      // Mark legacy rows with a placeholder so they don't appear for signed-in users
      await db.execute("UPDATE folders SET user_id = COALESCE(user_id, 'legacy')");
      await db.execute("UPDATE links SET user_id = COALESCE(user_id, 'legacy')");
      await db.execute('CREATE INDEX IF NOT EXISTS idx_folders_user ON folders(user_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_links_user ON links(user_id)');
    }
  }

  // Function to get all folders from the database.
  Future<List<Map<String, dynamic>>> getFolders(String userId) async {
    Database db = await instance.database;
    return await db.query(
      'folders',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name',
    );
  }

  // Function to add a new folder to the database.
  Future<int> add(Map<String, dynamic> folder) async {
    Database db = await instance.database;
    return await db.insert('folders', folder);
  }

  // Function to add a link to a folder
  Future<int> addLinkToFolder(int folderId, String url, {required String userId, String? title, String? thumbnailUrl}) async {
    Database db = await instance.database;
    return await db.insert('links', {
      'folder_id': folderId,
      'url': url,
      'title': title,
      'thumbnail_url': thumbnailUrl,
      // Save precise local timestamp in milliseconds since epoch for robust sorting/parsing
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'user_id': userId,
    });
  }

  // Function to get all links in a folder
  Future<List<Map<String, dynamic>>> getLinksInFolder(int folderId, {required String userId}) async {
    Database db = await instance.database;
    return await db.query(
      'links',
      where: 'folder_id = ? AND user_id = ?',
      whereArgs: [folderId, userId],
      // Sort by epoch millis if stored as integer or numeric string; otherwise fall back to SQL datetime
      orderBy: "COALESCE(CAST(created_at AS INTEGER), (strftime('%s', created_at) * 1000)) DESC, id DESC",
    );
  }

  // Function to delete a link
  Future<int> deleteLink(int linkId) async {
    Database db = await instance.database;
    return await db.delete(
      'links',
      where: 'id = ?',
      whereArgs: [linkId],
    );
  }

  // Function to delete a folder and all its links
  Future<int> deleteFolder(int folderId) async {
    Database db = await instance.database;
    return await db.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [folderId],
    );
  }
}
