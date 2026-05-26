<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;


class NotificationController extends Controller
{
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
