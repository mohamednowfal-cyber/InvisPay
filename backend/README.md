# InvisPay Backend - KYC Workflow

## Overview

This backend implementation provides **secure, backend-controlled KYC verification** for the InvisPay fintech application using Firebase services.

## Architecture

### Components

1. **Firestore Security Rules** (`firestore.rules`)
   - Prevents frontend tampering with `kycStatus`
   - Enforces user-scoped access control
   - Protects sensitive fields

2. **Storage Security Rules** (`storage.rules`)
   - Secures KYC document uploads
   - Enforces file size limits (5MB for KYC docs)
   - Restricts file types (images and PDFs only)
   - Prevents unauthorized access

3. **Cloud Functions** (`cloud_functions/on_kyc_submit.js`)
   - `processKycSubmission`: Auto-triggered on KYC data updates
   - `verifyKyc`: Admin-callable function for manual verification
   - `getKycStatus`: User-callable function to fetch KYC status

## Security Features

### Frontend Restrictions
- ✅ Users **cannot** modify `kycStatus` field
- ✅ Users **cannot** modify `createdAt` timestamp
- ✅ Users **can only** access their own data
- ✅ Document uploads are user-scoped and validated

### Backend Control
- ✅ Only Cloud Functions can update `kycStatus`
- ✅ All status changes are timestamped
- ✅ Failed submissions include failure reasons
- ✅ Admin verification requires authentication

## KYC Data Model

```javascript
{
  "users/{userId}": {
    "uid": "string",
    "email": "string",
    "displayName": "string",
    "mobile": "string",
    "kycStatus": "pending" | "verified" | "failed",  // Backend-only
    "kycFailureReason": "string | null",              // Backend-only
    "reviewedAt": "timestamp | null",                 // Backend-only
    "reviewedBy": "string | null",                    // Backend-only
    "kycData": {
      "idType": "string",
      "idNumber": "string",
      "document": "string (storage path)",
      "submittedAt": "timestamp"
    },
    "createdAt": "timestamp"
  }
}
```

## Deployment

### Prerequisites
```bash
npm install -g firebase-tools
firebase login
```

### Deploy Security Rules
```bash
# From project root
firebase deploy --only firestore:rules
firebase deploy --only storage:rules
```

### Deploy Cloud Functions
```bash
# From cloud_functions directory
cd backend/cloud_functions
npm install
firebase deploy --only functions
```

## Cloud Functions

### 1. processKycSubmission (Auto-triggered)
**Trigger**: Firestore `users/{userId}` document update

**Purpose**: Validates KYC submissions and performs automated checks

**Flow**:
1. Detects new KYC submission (checks for `submittedAt` timestamp)
2. Validates required fields (`idType`, `idNumber`, `document`)
3. Performs automated checks (placeholder for third-party API integration)
4. Updates `kycStatus` to `verified` or `failed`
5. Logs all actions for audit trail

**Production Integration Points**:
- Integrate with KYC verification APIs (Onfido, Jumio, Stripe Identity)
- Implement document OCR and validation
- Check against sanctions lists (OFAC, PEP)
- Perform liveness detection for selfies

### 2. verifyKyc (Admin-callable)
**Type**: HTTPS Callable Function

**Purpose**: Manual KYC verification by admin users

**Parameters**:
```javascript
{
  "userId": "string",
  "approved": boolean,
  "reason": "string (optional, required if rejected)"
}
```

**Security**: Requires authentication (add custom claims for admin role in production)

**Usage**:
```javascript
// From admin dashboard
const verifyKyc = firebase.functions().httpsCallable('verifyKyc');
await verifyKyc({ userId: 'abc123', approved: true });
```

### 3. getKycStatus (User-callable)
**Type**: HTTPS Callable Function

**Purpose**: Fetch KYC status for authenticated user

**Returns**:
```javascript
{
  "kycStatus": "pending" | "verified" | "failed",
  "kycFailureReason": "string | null",
  "submittedAt": "timestamp | null",
  "reviewedAt": "timestamp | null"
}
```

## Error Handling

All Cloud Functions implement comprehensive error handling:
- ✅ Validation errors return descriptive messages
- ✅ Processing errors update `kycStatus` to `failed`
- ✅ All errors are logged for debugging
- ✅ No unhandled exceptions (app never crashes)

## Testing

### Local Emulator
```bash
cd backend/cloud_functions
npm install
firebase emulators:start --only functions,firestore,storage
```

### Test KYC Submission
1. Submit KYC data from Flutter app
2. Check Cloud Function logs: `firebase functions:log`
3. Verify status update in Firestore Console

## Production Considerations

### Third-Party KYC Integration
Replace the placeholder logic in `processKycSubmission` with:
- **Onfido**: Document verification + facial recognition
- **Jumio**: ID verification + liveness detection
- **Stripe Identity**: Simplified KYC for payments
- **Sumsub**: Comprehensive KYC/AML solution

### Admin Dashboard
Create a web admin panel to:
- View pending KYC submissions
- Review uploaded documents
- Approve/reject manually
- View audit logs

### Compliance
- Store all KYC data encrypted at rest
- Implement data retention policies
- Maintain audit logs for regulatory compliance
- Implement GDPR/data deletion workflows

## Monitoring

### Cloud Function Logs
```bash
firebase functions:log --only processKycSubmission
```

### Firestore Usage
Monitor in Firebase Console:
- Document reads/writes
- Storage usage
- Function invocations

## Cost Optimization

- Cloud Functions: Free tier covers 2M invocations/month
- Firestore: Free tier covers 50K reads, 20K writes/day
- Storage: Free tier covers 5GB

For production scale, implement:
- Batch processing for KYC reviews
- Caching for status checks
- Storage lifecycle policies for old documents

## Support

For issues or questions:
1. Check Cloud Function logs
2. Verify Security Rules deployment
3. Test with Firebase Emulator
4. Review Firestore Console for data integrity
