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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // This function runs only the first time the database is created.
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE links (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folder_id INTEGER NOT NULL,
        url TEXT NOT NULL,
        title TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (folder_id) REFERENCES folders (id) ON DELETE CASCADE
      )
    ''');
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
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (folder_id) REFERENCES folders (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  // Function to get all folders from the database.
  Future<List<Map<String, dynamic>>> getFolders() async {
    Database db = await instance.database;
    return await db.query('folders', orderBy: 'name');
  }

  // Function to add a new folder to the database.
  Future<int> add(Map<String, dynamic> folder) async {
    Database db = await instance.database;
    return await db.insert('folders', folder);
  }

  // Function to add a link to a folder
  Future<int> addLinkToFolder(int folderId, String url, {String? title}) async {
    Database db = await instance.database;
    return await db.insert('links', {
      'folder_id': folderId,
      'url': url,
      'title': title,
    });
  }

  // Function to get all links in a folder
  Future<List<Map<String, dynamic>>> getLinksInFolder(int folderId) async {
    Database db = await instance.database;
    return await db.query(
      'links',
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: 'created_at DESC',
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
