const { onRequest } = require('firebase-functions/v2/https');
const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

// Initialize Firebase Admin SDK
initializeApp();
const db = getFirestore();

/**
 * Simple test function to verify deployment works
 */
exports.helloWorld = onRequest((req, res) => {
    res.json({ message: "Hello from InvisPay Cloud Functions!" });
});

/**
 * Cloud Function: Process KYC Submission
 */
exports.processKycSubmission = onDocumentUpdated('users/{userId}', async (event) => {
    const userId = event.params.userId;
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    // Check if kycData was updated
    const kycDataBefore = beforeData.kycData || {};
    const kycDataAfter = afterData.kycData || {};

    // If kycData hasn't changed, skip processing
    if (JSON.stringify(kycDataBefore) === JSON.stringify(kycDataAfter)) {
        return null;
    }

    // If kycData was just submitted
    if (kycDataAfter.submittedAt && !kycDataBefore.submittedAt) {
        console.log(`KYC submission received for user: ${userId}`);

        try {
            const { idType, idNumber, document } = kycDataAfter;

            if (!idType || !idNumber || !document) {
                console.error(`Invalid KYC data for user ${userId}`);

                await event.data.after.ref.update({
                    kycStatus: 'failed',
                    kycFailureReason: 'Missing required fields',
                    reviewedAt: FieldValue.serverTimestamp()
                });

                return null;
            }

            console.log(`Processing KYC for user ${userId}...`);
            console.log(`KYC submission queued for manual review: ${userId}`);

            return null;
        } catch (error) {
            console.error(`Error processing KYC for user ${userId}:`, error);

            await event.data.after.ref.update({
                kycStatus: 'failed',
                kycFailureReason: 'Processing error',
                reviewedAt: FieldValue.serverTimestamp()
            });

            return null;
        }
    }

    return null;
});

/**
 * Cloud Function: Manual KYC Verification
 */
exports.verifyKyc = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { userId, approved, reason } = request.data;

    if (!userId) {
        throw new HttpsError('invalid-argument', 'userId is required');
    }

    try {
        const userRef = db.collection('users').doc(userId);
        const userDoc = await userRef.get();

        if (!userDoc.exists) {
            throw new HttpsError('not-found', 'User not found');
        }

        await userRef.update({
            kycStatus: approved ? 'verified' : 'failed',
            kycFailureReason: approved ? null : (reason || 'Verification failed'),
            reviewedAt: FieldValue.serverTimestamp(),
            reviewedBy: request.auth.uid
        });

        console.log(`KYC ${approved ? 'approved' : 'rejected'} for user ${userId}`);

        return {
            success: true,
            message: `KYC ${approved ? 'approved' : 'rejected'} successfully`
        };
    } catch (error) {
        console.error('Error verifying KYC:', error);
        throw new HttpsError('internal', 'Failed to verify KYC');
    }
});

/**
 * Cloud Function: Get KYC Status
 */
exports.getKycStatus = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const userId = request.auth.uid;

    try {
        const userDoc = await db.collection('users').doc(userId).get();

        if (!userDoc.exists) {
            throw new HttpsError('not-found', 'User not found');
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
        throw new HttpsError('internal', 'Failed to fetch KYC status');
    }
});
