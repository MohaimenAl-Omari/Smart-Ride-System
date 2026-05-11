<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ContactMessage;
use Illuminate\Http\Request;

/**
 * Admin-side handling for "Contact us" submissions.
 *
 * Wired to the F-table feature "Management reports" (admin handles user
 * reports and complaints). Provides:
 *   - paginated list filtered by status / search term
 *   - status update (new → in_progress → resolved)
 *
 * Read-only otherwise; deleting messages is intentionally not exposed
 * because the team usually wants to keep an audit trail of complaints.
 */
class ContactController extends Controller
{
    public function index(Request $request)
    {
        $status = $request->input('status', 'all');
        $search = trim((string) $request->input('q', ''));

        $query = ContactMessage::query()->with('user:id,name,email,role');

        if (in_array($status, ['new', 'in_progress', 'resolved'])) {
            $query->where('status', $status);
        }
        if ($search !== '') {
            $query->where(function ($q) use ($search) {
                $q->where('subject', 'like', "%{$search}%")
                    ->orWhere('message', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            });
        }

        $messages = $query->orderByDesc('id')->paginate(15)->withQueryString();

        $counts = [
            'new'         => ContactMessage::where('status', 'new')->count(),
            'in_progress' => ContactMessage::where('status', 'in_progress')->count(),
            'resolved'    => ContactMessage::where('status', 'resolved')->count(),
        ];

        return view('admin.contact_messages', compact('messages', 'status', 'search', 'counts'));
    }

    public function updateStatus(Request $request, ContactMessage $message)
    {
        $validated = $request->validate([
            'status' => 'required|in:new,in_progress,resolved',
        ]);

        $message->update(['status' => $validated['status']]);

        return redirect()
            ->route('admin.contact', request()->only(['status', 'q', 'page']))
            ->with('status', "Message #{$message->id} marked as {$validated['status']}.");
    }
}
