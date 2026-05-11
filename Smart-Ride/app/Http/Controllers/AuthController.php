<?php

namespace App\Http\Controllers;

use App\Models\DriverCertificate;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users,email',
            'phone'    => 'required|unique:users,phone',
            'password' => 'required|min:6',
            'role'     => 'in:passenger,driver',
            'city'     => 'nullable|string|max:120',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status'  => false,
                'message' => $validator->errors()->first(),
                'errors'  => $validator->errors(),
            ], 400);
        }

        $user = User::registerUser($request->all());

        $token = '';
        if ($user->is_active) {
            $token = $user->refreshApiToken();
        }

        return response()->json([
            'status'  => true,
            'message' => $user->role === 'driver'
                ? 'Driver registered. Awaiting admin approval.'
                : 'User registered successfully',
            'token'   => $token,
            'user'    => $user,
        ]);
    }

    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email'    => 'required|email',
            'password' => 'required',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status'  => false,
                'message' => $validator->errors()->first(),
                'errors'  => $validator->errors(),
            ], 400);
        }

        $result = User::loginUser($request->email, $request->password);

        if ($result === null) {
            return response()->json([
                'status'  => false,
                'message' => 'Invalid credentials',
            ], 401);
        }
        if ($result === 'pending') {
            return response()->json([
                'status'  => false,
                'message' => 'Your driver account is pending admin approval',
            ], 403);
        }
        if ($result === 'inactive') {
            return response()->json([
                'status'  => false,
                'message' => 'Account is deactivated',
            ], 403);
        }

        $user  = $result;
        $token = $user->refreshApiToken();

        return response()->json([
            'status'  => true,
            'message' => 'Login successful',
            'token'   => $token,
            'user'    => $user,
        ]);
    }

    public function logout(Request $request)
    {
        $user = $request->user();
        if ($user) {
            $user->forceFill(['api_token' => null])->save();
        }

        return response()->json([
            'status'  => true,
            'message' => 'Logged out successfully',
        ]);
    }

    public function me(Request $request)
    {
        return response()->json([
            'status' => true,
            'user'   => $request->user(),
        ]);
    }

    public function uploadCertificates(Request $request)
    {
        $request->validate([
            'user_id'        => 'required|exists:users,id',
            'license'        => 'required|file',
            'non_conviction' => 'required|file',
            'medical'        => 'required|file',
        ]);

        $license = $request->file('license')->store('certificates');
        $non     = $request->file('non_conviction')->store('certificates');
        $medical = $request->file('medical')->store('certificates');

        DriverCertificate::updateOrCreate(
            ['user_id' => $request->user_id],
            [
                'license_path'        => $license,
                'non_conviction_path' => $non,
                'medical_path'        => $medical,
            ]
        );

        return response()->json([
            'status'  => true,
            'message' => 'Certificates uploaded',
        ]);
    }

    /**
     * Update the authenticated user's profile.
     *
     * Accepts any subset of: name, email, phone, city, password,
     * current_password (required to change password), profile_image
     * (multipart upload). Validation runs inside the controller per
     * project conventions; persistence sits in the model.
     */
    public function updateProfile(Request $request)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json([
                'status'  => false,
                'message' => 'Unauthenticated.',
            ], 401);
        }

        $validator = Validator::make($request->all(), [
            'name'             => 'nullable|string|max:255',
            'email'            => 'nullable|email|unique:users,email,' . $user->id,
            'phone'            => 'nullable|string|unique:users,phone,' . $user->id,
            'city'             => 'nullable|string|max:120',
            'password'         => 'nullable|min:6',
            'current_password' => 'required_with:password',
            'profile_image'    => 'nullable|image|max:4096', // up to 4 MB
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status'  => false,
                'message' => $validator->errors()->first(),
                'errors'  => $validator->errors(),
            ], 400);
        }

        // Verify current password if user is changing it
        if ($request->filled('password')) {
            if (!Hash::check($request->current_password, $user->password)) {
                return response()->json([
                    'status'  => false,
                    'message' => 'Current password is incorrect.',
                ], 400);
            }
        }

        // Handle image upload
        if ($request->hasFile('profile_image')) {
            // Delete old file if it lives on the public disk
            if ($user->image && !preg_match('#^https?://#', $user->image)) {
                Storage::disk('public')->delete($user->image);
            }
            $path = $request->file('profile_image')->store('avatars', 'public');
            $user->image = $path;
        }

        if ($request->filled('name'))  $user->name  = $request->name;
        if ($request->filled('email')) $user->email = $request->email;
        if ($request->filled('phone')) $user->phone = $request->phone;
        if ($request->filled('city'))  $user->city  = $request->city;
        if ($request->filled('password')) {
            $user->password = Hash::make($request->password);
        }

        $user->save();

        return response()->json([
            'status'  => true,
            'message' => 'Profile updated successfully.',
            'user'    => $user->fresh(),
        ]);
    }
}
