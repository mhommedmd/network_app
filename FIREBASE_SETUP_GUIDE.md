# Firebase Phone Authentication - Complete Setup Guide

## Overview

This guide provides step-by-step instructions for setting up Firebase Phone Authentication for the **network_app** Flutter project connected to **firebase-networkapp** Firebase project.

## ✅ What's Been Implemented

### 1. New Files Created
- **`lib/features/auth/presentation/pages/otp_verification_page.dart`**
  - Beautiful OTP input screen with 6-digit code entry
  - Auto-focus and navigation between input fields
  - Resend OTP functionality with 60-second countdown
  - Error handling and user feedback

### 2. Modified Files
- **`lib/features/auth/presentation/pages/register_page.dart`**
  - Added OTP verification step after phone number entry
  - Automatic OTP sending when moving from step 1
  - Verification required before completing registration

- **`lib/core/providers/auth_provider.dart`**
  - Modified `register()` function to verify OTP before account creation
  - Links phone number to account after creation
  - Existing functions utilized:
    - `sendRegistrationOtp()`: Send OTP code
    - `verifyRegistrationOtp()`: Verify OTP code
    - `resetRegistrationOtpState()`: Reset OTP state

- **`lib/core/router/app_router.dart`**
  - Added `/otp-verification` route
  - Added to public routes list

## 🔧 Firebase Console Setup

### Step 1: Enable Phone Authentication

1. Open Firebase Console: https://console.firebase.google.com
2. Select your project: **`firebase-networkapp`**
3. Navigate to **Authentication** → **Sign-in method**
4. Enable **Phone** from the providers list
5. Click **Save**

### Step 2: Configure SHA-1 for Android (Critical!)

Phone Authentication requires SHA-1 fingerprints to work on Android devices.

#### Get SHA-1 Fingerprint

**On Windows:**
```powershell
cd android
.\gradlew signingReport
```

**On Mac/Linux:**
```bash
cd android
./gradlew signingReport
```

Look for the SHA-1 under `Task :app:signingReport`:
```
Variant: debug
Config: debug
Store: C:\Users\YourName\.android\debug.keystore
Alias: AndroidDebugKey
MD5: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
SHA-256: ...
Valid until: ...
```

#### Add SHA-1 to Firebase

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Select your Android app
3. Scroll down to **SHA certificate fingerprints**
4. Click **Add fingerprint**
5. Paste your SHA-1
6. Click **Save**
7. Download the updated **google-services.json**
8. Replace it in `android/app/google-services.json`

### Step 3: Upgrade to Blaze Plan (Required!)

Phone Authentication is NOT available on the free Spark plan.

1. Go to **Firebase Console** → **Project Settings** → **Usage and billing**
2. Click **Modify plan**
3. Select **Blaze** (Pay as you go)
4. Add payment method
5. Set budget alerts (recommended: $5-10/month)

**Pricing:**
- SMS costs vary by country (~$0.02 - $0.05 per message for Yemen)
- First 10K verifications/month have reduced rates
- Details: https://firebase.google.com/pricing#authentication

### Step 4: Add Test Phone Numbers (Optional - For Development)

1. In Firebase Console → **Authentication** → **Sign-in method**
2. Scroll to **Phone numbers for testing**
3. Add test numbers with custom codes:
   - Phone: `+967777777777`
   - Code: `123456`

## 📱 How It Works (Flow)

### 1. User Opens Registration Screen
```dart
RegisterPage()
```
- User selects account type (Network Owner / POS Vendor)
- Enters phone number
- Enters password and confirmation

### 2. Send OTP
```dart
authProvider.sendRegistrationOtp(phone)
```
- Taps "Next" button
- Firebase sends SMS with 6-digit code
- Uses `verifyPhoneNumber` from `firebase_auth`

### 3. OTP Verification Screen
```dart
OtpVerificationPage(
  phoneNumber: phone,
  verificationType: OtpVerificationType.registration,
)
```
- User navigates to verification screen
- Enters 6-digit code
- Can resend after 60 seconds

### 4. Verify OTP
```dart
authProvider.verifyRegistrationOtp(phone, otpCode)
```
- Validates the code against Firebase
- Stores `PhoneAuthCredential` on success

### 5. Complete Registration
```dart
authProvider.register(...)
```
- User proceeds to complete account details
- On "Finish Registration":
  1. Creates account with Email/Password
  2. Links phone number using `PhoneAuthCredential`
  3. Saves user data to Firestore

## 🔒 Security

### Production Mode
```dart
if (!kDebugMode && !_registrationOtpVerified) {
  throw Exception('Phone verification required');
}
```
- OTP verification is **mandatory**
- Cannot be bypassed

### Debug/Development Mode
```dart
if (kDebugMode) {
  return bypassRegistrationOtpForTesting(phone);
}
```
- OTP verification can be bypassed
- For faster testing

## 🧪 Testing

### Testing in Debug Mode
1. Run app in Debug mode
2. Register with any phone number
3. OTP verification is automatically bypassed

### Testing with Test Phone Numbers
1. Add test number in Firebase Console
2. Use the test number during registration
3. Enter the custom code you defined

### Testing in Production
1. Use a real Yemeni phone number (+967...)
2. Receive actual SMS from Firebase
3. Enter the code from the SMS

## 🌍 Phone Number Format

The app supports **Yemeni phone numbers** only:

- **Input format:** `777123456` (9 digits)
- **Converted to:** `+967777123456` (E.164 format)
- **Valid prefixes:** 777, 773, 770, 771, 772, 774, 775, 776

```dart
String _formatPhoneToE164(String phone) {
  final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
  if (cleaned.length == 9) {
    return '+967$cleaned';
  }
  if (cleaned.startsWith('967')) {
    return '+$cleaned';
  }
  if (cleaned.startsWith('+967')) {
    return cleaned;
  }
  return '+967$cleaned';
}
```

## 📊 Firebase Quotas & Limits

### Spark Plan (Free)
- ❌ Phone Authentication NOT supported
- Only Email/Password and Anonymous auth

### Blaze Plan (Pay-as-you-go)
- ✅ Phone Authentication supported
- First 10K verifications/month: Reduced rate
- After 10K: Full rate per SMS
- SMS costs vary by country

### Rate Limits
- **Per IP:** 100 SMS per hour
- **Per phone number:** 5 SMS per hour
- Configurable in Firebase Console

## ⚠️ Common Issues & Solutions

### Issue 1: "This app is not authorized to use Firebase Authentication"
**Solution:** Add SHA-1 fingerprint to Firebase Console

### Issue 2: "An internal error has occurred"
**Solution:** 
- Verify Phone Authentication is enabled
- Check if project is on Blaze plan
- Ensure SHA-1 is correctly added

### Issue 3: SMS not received
**Solution:**
- Check phone number format (+967...)
- Verify SMS quota not exceeded
- Check Firebase Console logs
- Verify billing is active

### Issue 4: "Invalid phone number"
**Solution:**
- Use valid Yemeni number (+967...)
- Check number has 9 digits after +967
- Ensure number is not blocked

## 📝 Files Modified Summary

```
network_app/
├── lib/
│   ├── features/
│   │   └── auth/
│   │       └── presentation/
│   │           └── pages/
│   │               ├── register_page.dart ✏️ MODIFIED
│   │               └── otp_verification_page.dart ✨ NEW
│   └── core/
│       ├── providers/
│       │   └── auth_provider.dart ✏️ MODIFIED
│       └── router/
│           └── app_router.dart ✏️ MODIFIED
├── FIREBASE_PHONE_AUTH_SETUP.md ✨ NEW
└── FIREBASE_SETUP_GUIDE.md ✨ NEW
```

## 🚀 Pre-Production Checklist

Before deploying to production:

- [ ] ✅ Phone Authentication enabled in Firebase
- [ ] ✅ SHA-1 fingerprints added (debug + release)
- [ ] ✅ Firebase project upgraded to Blaze Plan
- [ ] ⚠️ Budget alerts configured
- [ ] ⚠️ Rate limiting configured
- [ ] ⚠️ Firebase App Check enabled
- [ ] ⚠️ reCAPTCHA configured (web only)
- [ ] ⚠️ Analytics and monitoring enabled
- [ ] ⚠️ Error reporting configured
- [ ] ⚠️ Terms of Service and Privacy Policy updated

## 📞 Support

For issues:
1. Check SHA-1 is correctly added
2. Verify Phone Authentication is enabled
3. Ensure project is on Blaze Plan
4. Review logs in Firebase Console → Authentication → Usage
5. Check billing status

## 📚 Additional Resources

- Firebase Phone Auth Docs: https://firebase.google.com/docs/auth/android/phone-auth
- Flutter FirebaseAuth Package: https://pub.dev/packages/firebase_auth
- Firebase Pricing: https://firebase.google.com/pricing
- Firebase Support: https://firebase.google.com/support

---

**Implementation Date:** November 2, 2025
**Project:** network_app
**Firebase Project:** firebase-networkapp
**Implemented By:** AI Assistant

