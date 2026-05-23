<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Manages the user's notification inbox.
 *
 * Routes (all require api.auth middleware):
 *   GET    /api/notifications               → list (last 60, newest first)
 *   POST   /api/notifications/mark-all-read → mark every unread as read
 *   POST   /api/notifications/{id}/read     → mark single notification as read
 *   DELETE /api/notifications/{id}          → delete one notification
 *
 * Notifications are delivered via DB polling — no Firebase required.
 * The Flutter app calls GET /api/notifications every 30 seconds.
 */
class NotificationController extends Controller
{
    // ---------------------------------------------------------------
    // List
    // ---------------------------------------------------------------

    /**
     * GET /notifications
     * Returns the last 60 notifications newest-first with unread count.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $notifications = AppNotification::where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->limit(60)
            ->get();

        $unreadCount = $notifications->where('is_read', false)->count();

        return response()->json([
            'status'        => true,
            'unread_count'  => $unreadCount,
            'notifications' => $notifications,
        ]);
    }

    // ---------------------------------------------------------------
    // Mark as read
    // ---------------------------------------------------------------

    /**
     * POST /notifications/mark-all-read
     * Marks every unread notification for this user as read.
     */
    public function markAllRead(Request $request): JsonResponse
    {
        $user = $request->user();

        AppNotification::where('user_id', $user->id)
            ->where('is_read', false)
            ->update(['is_read' => true]);

        return response()->json([
            'status'  => true,
            'message' => 'All notifications marked as read.',
        ]);
    }

    /**
     * POST /notifications/{notification}/read
     * Marks a single notification as read. Only the owner may do this.
     */
    public function markRead(Request $request, AppNotification $notification): JsonResponse
    {
        if ($notification->user_id !== $request->user()->id) {
            return response()->json(['status' => false, 'message' => 'Forbidden'], 403);
        }

        $notification->update(['is_read' => true]);

        return response()->json([
            'status'  => true,
            'message' => 'Notification marked as read.',
        ]);
    }

    // ---------------------------------------------------------------
    // Delete
    // ---------------------------------------------------------------

    /**
     * DELETE /notifications/{notification}
     * Deletes a single notification. Only the owner may do this.
     */
    public function destroy(Request $request, AppNotification $notification): JsonResponse
    {
        if ($notification->user_id !== $request->user()->id) {
            return response()->json(['status' => false, 'message' => 'Forbidden'], 403);
        }

        $notification->delete();

        return response()->json([
            'status'  => true,
            'message' => 'Notification deleted.',
        ]);
    }

}
