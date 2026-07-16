import '../../core/constants/app_constants.dart';
import '../../services/database_service.dart';
import '../model/notification_model.dart';

class NotificationRepository {
  final DatabaseService _databaseService;

  NotificationRepository(this._databaseService);

  Future<List<AppNotification>> getNotifications() async {
    final db = await _databaseService.database;
    final result = await db.query(
      AppConstants.notificationsTable,
      orderBy: 'timestamp DESC',
    );
    return result.map((m) => AppNotification.fromMap(m)).toList();
  }

  Future<int> getUnreadCount() async {
    final db = await _databaseService.database;
    final result = await db.query(
      AppConstants.notificationsTable,
      where: 'is_read = ?',
      whereArgs: [0],
    );
    return result.length;
  }

  Future<void> addNotification(AppNotification notification) async {
    final db = await _databaseService.database;
    await db.insert(
      AppConstants.notificationsTable,
      {
        'title': notification.title,
        'body': notification.body,
        'type': notification.type,
        'is_read': notification.isRead ? 1 : 0,
        'timestamp': notification.timestamp.toIso8601String(),
      },
    );
  }

  Future<void> markAsRead(int id) async {
    final db = await _databaseService.database;
    await db.update(
      AppConstants.notificationsTable,
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAllAsRead() async {
    final db = await _databaseService.database;
    await db.update(
      AppConstants.notificationsTable,
      {'is_read': 1},
    );
  }

  Future<void> deleteNotification(int id) async {
    final db = await _databaseService.database;
    await db.delete(
      AppConstants.notificationsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAll() async {
    final db = await _databaseService.database;
    await db.delete(AppConstants.notificationsTable);
  }
}
