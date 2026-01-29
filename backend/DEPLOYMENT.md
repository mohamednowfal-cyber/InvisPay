# InvisPay Backend KYC - Quick Deployment Guide

## Prerequisites

1. **Firebase CLI**
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

2. **Firebase Project**
   - Create project at https://console.firebase.google.com
   - Enable Firestore Database
   - Enable Firebase Storage
   - Enable Cloud Functions

## Step 1: Initialize Firebase (One-time)

```bash
cd d:\Invispay
firebase init

# Select:
# - Firestore (configure security rules)
# - Storage (configure security rules)
# - Functions (JavaScript, use existing code)
```

## Step 2: Deploy Security Rules

```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage:rules
```

**Verify**: Check Firebase Console → Firestore → Rules tab

## Step 3: Deploy Cloud Functions

```bash
cd backend/cloud_functions
npm install
firebase deploy --only functions
```

**Expected Output**:
```
✔ functions[processKycSubmission] Successful create operation
✔ functions[verifyKyc] Successful create operation
✔ functions[getKycStatus] Successful create operation
```

## Step 4: Test KYC Flow

### Test 1: Submit KYC from App
1. Run InvisPay app
2. Sign up new user
3. Navigate to KYC Submission
4. Fill form and submit
5. Check Firestore Console → `users/{uid}` → Verify `kycData` exists

### Test 2: Verify Cloud Function Triggered
```bash
firebase functions:log --only processKycSubmission
```

Look for: `KYC submission received for user: {userId}`

### Test 3: Manual Verification (Admin)
```javascript
// From Firebase Console → Functions → verifyKyc → Test
{
  "data": {
    "userId": "USER_UID_HERE",
    "approved": true
  }
}
```

### Test 4: Check Status Update
1. Open Firestore Console
2. Navigate to `users/{userId}`
3. Verify `kycStatus` changed to `verified`
4. Check `reviewedAt` timestamp exists

## Step 5: Monitor

### View Logs
```bash
# All functions
firebase functions:log

# Specific function
firebase functions:log --only processKycSubmission

# Real-time
firebase functions:log --follow
```

### Check Firestore Usage
Firebase Console → Firestore → Usage tab

### Check Storage Usage
Firebase Console → Storage → Usage tab

## Troubleshooting

### Issue: Security Rules Not Applied
**Solution**: 
```bash
firebase deploy --only firestore:rules --force
```

### Issue: Cloud Function Not Triggering
**Check**:
1. Function deployed: `firebase functions:list`
2. Firestore trigger path correct: `users/{userId}`
3. Logs for errors: `firebase functions:log`

### Issue: Document Upload Fails
**Check**:
1. Storage rules deployed: `firebase deploy --only storage:rules`
2. File size < 5MB
3. File type is image or PDF
4. User authenticated

### Issue: KYC Status Not Updating
**Check**:
1. Cloud Function logs for errors
2. Firestore Security Rules allow backend writes
3. User document exists in Firestore

## Production Checklist

- [ ] Deploy Firestore Security Rules
- [ ] Deploy Storage Security Rules
- [ ] Deploy Cloud Functions
- [ ] Set up Firebase project billing (for Cloud Functions)
- [ ] Configure custom domain (optional)
- [ ] Set up monitoring alerts
- [ ] Implement admin dashboard for manual KYC review
- [ ] Integrate third-party KYC verification API
- [ ] Set up backup and disaster recovery
- [ ] Configure data retention policies
- [ ] Implement audit logging
- [ ] Add custom claims for admin users

## Cost Estimation (Monthly)

### Free Tier Limits
- Cloud Functions: 2M invocations, 400K GB-seconds
- Firestore: 50K reads, 20K writes, 1GB storage
- Storage: 5GB, 1GB downloads

### Typical Usage (1000 users)
- KYC submissions: ~1000/month
- Status checks: ~10K/month
- Document storage: ~500MB
- **Estimated cost**: $0-5/month (within free tier)

### Scale (10K users)
- KYC submissions: ~10K/month
- Status checks: ~100K/month
- Document storage: ~5GB
- **Estimated cost**: $10-20/month

## Support Resources

- **Firebase Documentation**: https://firebase.google.com/docs
- **Cloud Functions Guide**: https://firebase.google.com/docs/functions
- **Security Rules**: https://firebase.google.com/docs/rules
- **Firebase Console**: https://console.firebase.google.com
