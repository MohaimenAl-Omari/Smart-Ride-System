<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ContactMessage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ContactController extends Controller
{
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email'   => 'required|email|max:180',
            'subject' => 'required|string|max:180',
            'message' => 'required|string|max:4000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status'  => false,
                'message' => $validator->errors()->first(),
                'errors'  => $validator->errors(),
            ], 400);
        }

        $message = ContactMessage::create([
            'user_id' => $request->user()?->id,
            'email'   => $request->email,
            'subject' => $request->subject,
            'message' => $request->message,
            'status'  => 'new',
        ]);

        return response()->json([
            'status'  => true,
            'message' => 'Thanks! Your message has been received.',
            'data'    => $message,
        ]);
    }
}
