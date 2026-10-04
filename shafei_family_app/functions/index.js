// يرسل إشعاراً لكل العائلة عند إضافة مناسبة جديدة.
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const TYPE_LABELS = {
  wedding: "فرح",
  engagement: "خطوبة",
  condolence: "عزاء",
  birth: "مولود / عقيقة",
  other: "مناسبة",
};

exports.notifyNewEvent = onDocumentCreated("events/{eventId}", async (event) => {
  const e = event.data && event.data.data();
  if (!e) return;

  const label = TYPE_LABELS[e.type] || "مناسبة";
  const date = e.date.toDate().toLocaleDateString("ar-EG", {
    weekday: "long", day: "numeric", month: "long", timeZone: "Africa/Cairo",
  });

  await getMessaging().send({
    topic: "family",
    notification: {
      title: `${label} جديد: ${e.title}`,
      body: `${date} — أضافها ${e.createdByName || "أحد أفراد العائلة"}`,
    },
    data: { eventId: event.params.eventId },
  });
});
