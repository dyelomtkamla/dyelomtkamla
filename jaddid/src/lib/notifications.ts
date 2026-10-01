// جدولة تذكيرات محلية على الجهاز — تعمل بدون إنترنت وبدون خادم.
import * as Notifications from 'expo-notifications';
import { Platform } from 'react-native';
import { addDays, parseISODate, reminderLabel } from './dates';
import { docTypeName } from './gcc';
import type { DocItem } from './types';

const CHANNEL_ID = 'renewals';
const REMIND_HOUR = 9; // التذكير الساعة 9 صباحاً بالتوقيت المحلي

const supported = Platform.OS === 'ios' || Platform.OS === 'android';

export function configureNotifications() {
  if (!supported) return;
  Notifications.setNotificationHandler({
    handleNotification: async () => ({
      shouldShowBanner: true,
      shouldShowList: true,
      shouldPlaySound: true,
      shouldSetBadge: false,
    }),
  });
  if (Platform.OS === 'android') {
    Notifications.setNotificationChannelAsync(CHANNEL_ID, {
      name: 'تذكيرات التجديد',
      importance: Notifications.AndroidImportance.HIGH,
    }).catch(() => {});
  }
}

export async function ensurePermission(): Promise<boolean> {
  if (!supported) return false;
  const current = await Notifications.getPermissionsAsync();
  if (current.granted) return true;
  if (!current.canAskAgain) return false;
  const next = await Notifications.requestPermissionsAsync();
  return next.granted;
}

export async function cancelReminders(ids: string[] | undefined) {
  if (!supported || !ids?.length) return;
  await Promise.all(
    ids.map((id) => Notifications.cancelScheduledNotificationAsync(id).catch(() => {}))
  );
}

/** يجدول تذكيرات المستند ويعيد معرفاتها لتخزينها مع المستند */
export async function scheduleReminders(doc: DocItem): Promise<string[]> {
  if (!supported) return [];
  if (!(await ensurePermission())) return [];

  const expiry = parseISODate(doc.expiry);
  const title = `${docTypeName(doc.type, doc.country)} — ${doc.owner}`;
  const now = Date.now();
  const ids: string[] = [];

  for (const offset of doc.reminders) {
    const when = addDays(expiry, -offset);
    when.setHours(REMIND_HOUR, 0, 0, 0);
    if (when.getTime() <= now) continue;

    const body =
      offset === 0
        ? 'ينتهي اليوم! جدّده الآن لتجنب الغرامات.'
        : `ينتهي ${reminderLabel(offset).replace('قبل', 'بعد')}. ابدأ التجديد الآن.`;

    const id = await Notifications.scheduleNotificationAsync({
      content: { title, body, data: { docId: doc.id } },
      trigger: {
        type: Notifications.SchedulableTriggerInputTypes.DATE,
        date: when,
        channelId: CHANNEL_ID,
      },
    });
    ids.push(id);
  }
  return ids;
}
