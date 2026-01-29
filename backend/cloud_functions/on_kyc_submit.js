const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

/**
 * Cloud Function: Process KYC Submission
 * 
 * Triggered when a user updates their KYC data in Firestore.
 * This function validates the submission and can perform automated checks.
 * 
 * For production, this would integrate with third-party KYC verification services
 * (e.g., Onfido, Jumio, Stripe Identity) or implement custom ML-based verification.
 */
exports.processKycSubmission = functions.firestore
    .document('users/{userId}')
    .onUpdate(async (change, context) => {
        const userId = context.params.userId;
        const beforeData = change.before.data();
        const afterData = change.after.data();

        // Check if kycData was updated
        const kycDataBefore = beforeData.kycData || {};
        const kycDataAfter = afterData.kycData || {};

        // If kycData hasn't changed, skip processing
        if (JSON.stringify(kycDataBefore) === JSON.stringify(kycDataAfter)) {
            return null;
        }

        // If kycData was just submitted (has submittedAt timestamp)
        if (kycDataAfter.submittedAt && !kycDataBefore.submittedAt) {
            console.log(`KYC submission received for user: ${userId}`);

            try {
                // Validate required fields
                const { idType, idNumber, document } = kycDataAfter;

                if (!idType || !idNumber || !document) {
                    console.error(`Invalid KYC data for user ${userId}`);

                    // Update status to failed
                    await change.after.ref.update({
                        kycStatus: 'failed',
                        kycFailureReason: 'Missing required fields',
                        reviewedAt: admin.firestore.FieldValue.serverTimestamp()
                    });

                    return null;
                }

                // In a real implementation, you would:
                // 1. Call third-party KYC verification API
                // 2. Perform document analysis
                // 3. Check against sanctions lists
                // 4. Verify identity information

                // For demo purposes, we'll simulate a basic check
                // In production, remove this and integrate with real KYC provider

                // Simulate processing delay
                console.log(`Processing KYC for user ${userId}...`);

                // Auto-approve for demo (REMOVE IN PRODUCTION)
                // In production, this should be manual review or API-based verification
                const shouldAutoApprove = false; // Set to false for manual review

                if (shouldAutoApprove) {
                    await change.after.ref.update({
                        kycStatus: 'verified',
                        reviewedAt: admin.firestore.FieldValue.serverTimestamp()
                    });
                    console.log(`KYC auto-approved for user ${userId}`);
                } else {
                    // Keep status as 'pending' for manual review
                    console.log(`KYC submission queued for manual review: ${userId}`);

                    // Optionally, send notification to admin dashboard
                    // await notifyAdminOfNewKycSubmission(userId, kycDataAfter);
                }

                return null;
            } catch (error) {
                console.error(`Error processing KYC for user ${userId}:`, error);

                // Update status to failed
                await change.after.ref.update({
                    kycStatus: 'failed',
                    kycFailureReason: 'Processing error',
                    reviewedAt: admin.firestore.FieldValue.serverTimestamp()
                });

                return null;
            }
        }

        return null;
    });

/**
 * Cloud Function: Manual KYC Verification (Admin-triggered)
 * 
 * This function can be called by admin users to manually verify or reject KYC.
 * In production, this would be protected by Firebase Authentication custom claims.
 */
exports.verifyKyc = functions.https.onCall(async (data, context) => {
    // Check if request is from authenticated admin
    // In production, verify custom claims: context.auth.token.admin === true
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'User must be authenticated'
        );
    }

    const { userId, approved, reason } = data;

    if (!userId) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'userId is required'
        );
    }

    try {
        const userRef = admin.firestore().collection('users').doc(userId);
        const userDoc = await userRef.get();

        if (!userDoc.exists) {
            throw new functions.https.HttpsError(
                'not-found',
                'User not found'
            );
        }

        // Update KYC status
        await userRef.update({
            kycStatus: approved ? 'verified' : 'failed',
            kycFailureReason: approved ? null : (reason || 'Verification failed'),
            reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
            reviewedBy: context.auth.uid
        });

        console.log(`KYC ${approved ? 'approved' : 'rejected'} for user ${userId} by ${context.auth.uid}`);

        return {
            success: true,
            message: `KYC ${approved ? 'approved' : 'rejected'} successfully`
        };
    } catch (error) {
        console.error('Error verifying KYC:', error);
        throw new functions.https.HttpsError('internal', 'Failed to verify KYC');
    }
});

/**
 * Cloud Function: Get KYC Status
 * 
 * Allows users to fetch their own KYC status.
 * This is redundant if using Firestore listeners, but useful for REST API clients.
 */
exports.getKycStatus = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'User must be authenticated'
        );
    }

    const userId = context.auth.uid;

    try {
        const userDoc = await admin.firestore().collection('users').doc(userId).get();

        if (!userDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'User not found');
        }

        const userData = userDoc.data();

        return {
            kycStatus: userData.kycStatus || 'pending',
            kycFailureReason: userData.kycFailureReason || null,
            submittedAt: userData.kycData?.submittedAt || null,
            reviewedAt: userData.reviewedAt || null
        };
    } catch (error) {
        console.error('Error fetching KYC status:', error);
        throw new functions.https.HttpsError('internal', 'Failed to fetch KYC status');
    }
});
