const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

async function getUserFcmToken(userId) {
  try {
    const tokenDoc = await admin.firestore().collection('fcm_tokens').doc(userId).get();
    return tokenDoc.exists ? tokenDoc.data().token : null;
  } catch (error) {
    console.error('Error fetching FCM token:', error);
    return null;
  }
}

exports.sendBookingCreatedNotification = functions.https.onCall(async (data, context) => {
  const { providerId, bookingId, seekerName, serviceName } = data;
  
  const fcmToken = await getUserFcmToken(providerId);
  if (!fcmToken) {
    throw new functions.https.HttpsError('not-found', 'FCM token not found for provider');
  }

  const message = {
    token: fcmToken,
    notification: {
      title: 'New Booking Request',
      body: `${seekerName} has requested a booking for ${serviceName}.`,
    },
    data: {
      type: 'booking_created',
      bookingId: bookingId,
    },
    android: {
      priority: 'high',
      notification: {
        sound: 'default',
        channelId: 'booking_notifications',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
        },
      },
    },
  };

  try {
    await admin.messaging().send(message);
    return { success: true };
  } catch (error) {
    console.error('Error sending notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send notification');
  }
});

exports.sendBookingConfirmedNotification = functions.https.onCall(async (data, context) => {
  const { providerId, bookingId, seekerName, serviceName } = data;
  
  const fcmToken = await getUserFcmToken(providerId);
  if (!fcmToken) {
    throw new functions.https.HttpsError('not-found', 'FCM token not found for provider');
  }

  const message = {
    token: fcmToken,
    notification: {
      title: 'Booking Confirmed',
      body: `Your booking for ${serviceName} with ${seekerName} has been confirmed.`,
    },
    data: {
      type: 'booking_confirmed',
      bookingId: bookingId,
    },
    android: {
      priority: 'high',
      notification: {
        sound: 'default',
        channelId: 'booking_notifications',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
        },
      },
    },
  };

  try {
    await admin.messaging().send(message);
    return { success: true };
  } catch (error) {
    console.error('Error sending notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send notification');
  }
});

exports.sendBookingCancelledNotification = functions.https.onCall(async (data, context) => {
  const { recipientId, bookingId, cancellerName, serviceName, isCancelledByProvider } = data;
  
  const fcmToken = await getUserFcmToken(recipientId);
  if (!fcmToken) {
    throw new functions.https.HttpsError('not-found', 'FCM token not found for recipient');
  }

  const message = {
    token: fcmToken,
    notification: {
      title: 'Booking Cancelled',
      body: isCancelledByProvider 
        ? `${cancellerName} has cancelled your ${serviceName} booking.` 
        : `Your ${serviceName} booking has been cancelled by ${cancellerName}.`,
    },
    data: {
      type: 'booking_cancelled',
      bookingId: bookingId,
    },
    android: {
      priority: 'high',
      notification: {
        sound: 'default',
        channelId: 'booking_notifications',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
        },
      },
    },
  };

  try {
    await admin.messaging().send(message);
    return { success: true };
  } catch (error) {
    console.error('Error sending notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send notification');
  }
});

exports.sendBookingCompletedNotification = functions.https.onCall(async (data, context) => {
  const { seekerId, bookingId, providerName, serviceName } = data;
  
  const fcmToken = await getUserFcmToken(seekerId);
  if (!fcmToken) {
    throw new functions.https.HttpsError('not-found', 'FCM token not found for seeker');
  }

  const message = {
    token: fcmToken,
    notification: {
      title: 'Booking Completed',
      body: `Your ${serviceName} booking with ${providerName} has been completed.`,
    },
    data: {
      type: 'booking_completed',
      bookingId: bookingId,
    },
    android: {
      priority: 'high',
      notification: {
        sound: 'default',
        channelId: 'booking_notifications',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
        },
      },
    },
  };

  try {
    await admin.messaging().send(message);
    return { success: true };
  } catch (error) {
    console.error('Error sending notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send notification');
  }
});

exports.sendBookingAcceptedNotification = functions.https.onCall(async (data, context) => {
  const { seekerId, bookingId, providerName, serviceName } = data;
  
  const fcmToken = await getUserFcmToken(seekerId);
  if (!fcmToken) {
    throw new functions.https.HttpsError('not-found', 'FCM token not found for seeker');
  }

  const message = {
    token: fcmToken,
    notification: {
      title: 'Booking Accepted',
      body: `${providerName} has accepted your ${serviceName} booking.`,
    },
    data: {
      type: 'booking_accepted',
      bookingId: bookingId,
    },
    android: {
      priority: 'high',
      notification: {
        sound: 'default',
        channelId: 'booking_notifications',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
        },
      },
    },
  };

  try {
    await admin.messaging().send(message);
    return { success: true };
  } catch (error) {
    console.error('Error sending notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send notification');
  }
});