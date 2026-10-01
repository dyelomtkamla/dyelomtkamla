import { router, useLocalSearchParams } from 'expo-router';
import { useState } from 'react';
import { Alert, Linking, Platform, ScrollView, StyleSheet, Text, View } from 'react-native';
import { Button, StatusBadge } from '../../components/ui';
import { daysUntil, formatGregorian, formatHijri, reminderLabel, remainingLabel, statusOf } from '../../lib/dates';
import { docTypeName, getCountry, getDocType } from '../../lib/gcc';
import { useStore } from '../../lib/store';
import { useTheme } from '../../lib/theme';

export default function DocDetails() {
  const t = useTheme();
  const { id } = useLocalSearchParams<{ id: string }>();
  const { docs, removeDoc } = useStore();
  const doc = docs.find((d) => d.id === id);
  // على الويب لا توجد نوافذ تأكيد، فنطلب ضغطة ثانية للتأكيد
  const [armed, setArmed] = useState(false);

  if (!doc) {
    return (
      <View style={[styles.center, { backgroundColor: t.bg }]}>
        <Text style={{ color: t.muted, fontSize: 16 }}>المستند غير موجود</Text>
        <Button title="العودة" variant="ghost" onPress={() => router.back()} style={{ marginTop: 16 }} />
      </View>
    );
  }

  const type = getDocType(doc.type);
  const country = getCountry(doc.country);
  const days = daysUntil(doc.expiry);
  const s = statusOf(days);
  const hijri = formatHijri(doc.expiry);

  const confirmDelete = () => {
    const doIt = async () => {
      await removeDoc(doc.id);
      router.back();
    };
    if (Platform.OS === 'web') {
      if (armed) doIt();
      else setArmed(true);
      return;
    }
    Alert.alert('حذف المستند', 'سيتم حذف المستند وإلغاء تذكيراته.', [
      { text: 'إلغاء', style: 'cancel' },
      { text: 'حذف', style: 'destructive', onPress: doIt },
    ]);
  };

  return (
    <ScrollView style={{ backgroundColor: t.bg }} contentContainerStyle={styles.container}>
      <View style={[styles.hero, { backgroundColor: t.status[s].bg }]}>
        <Text style={styles.heroIcon}>{type.icon}</Text>
        <Text style={[styles.heroTitle, { color: t.text }]}>{docTypeName(doc.type, doc.country)}</Text>
        <Text style={[styles.heroOwner, { color: t.muted }]}>
          {doc.owner} · {country.flag} {country.name}
        </Text>
        <Text style={[styles.heroDays, { color: t.status[s].fg }]}>{remainingLabel(days)}</Text>
        <StatusBadge days={days} />
      </View>

      <View style={[styles.card, { backgroundColor: t.card, borderColor: t.border }]}>
        <Row label="تاريخ الانتهاء" value={formatGregorian(doc.expiry)} />
        {hijri && <Row label="بالهجري" value={hijri} />}
        {doc.number && <Row label="رقم المستند" value={doc.number} />}
        <Row
          label="التذكيرات"
          value={doc.reminders.length ? doc.reminders.map(reminderLabel).join('، ') : 'بدون تذكير'}
        />
        {doc.notes && <Row label="ملاحظات" value={doc.notes} />}
      </View>

      <View style={[styles.tip, { backgroundColor: t.card, borderColor: t.gold }]}>
        <Text style={[styles.tipTitle, { color: t.gold }]}>💡 نصيحة</Text>
        <Text style={[styles.tipBody, { color: t.text }]}>{type.tip}</Text>
      </View>

      <Button
        title={`التجديد عبر ${country.portal}`}
        onPress={() => Linking.openURL(country.portalUrl)}
        style={{ marginTop: 16 }}
      />
      <Button
        title="تعديل / تحديث التاريخ بعد التجديد"
        variant="ghost"
        onPress={() => router.push({ pathname: '/add', params: { id: doc.id } })}
        style={{ marginTop: 10 }}
      />
      <Button title={armed ? 'اضغط مرة أخرى لتأكيد الحذف' : 'حذف المستند'} variant="danger" onPress={confirmDelete} style={{ marginTop: 10 }} />
    </ScrollView>
  );
}

function Row({ label, value }: { label: string; value: string }) {
  const t = useTheme();
  return (
    <View style={[styles.row, { borderBottomColor: t.border }]}>
      <Text style={[styles.rowLabel, { color: t.muted }]}>{label}</Text>
      <Text style={[styles.rowValue, { color: t.text }]}>{value}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  container: { padding: 16, paddingBottom: 40, maxWidth: 720, width: '100%', alignSelf: 'center' },
  hero: { borderRadius: 20, padding: 22, alignItems: 'center', gap: 4, marginBottom: 14 },
  heroIcon: { fontSize: 44 },
  heroTitle: { fontSize: 22, fontWeight: '800' },
  heroOwner: { fontSize: 15 },
  heroDays: { fontSize: 26, fontWeight: '800', marginVertical: 6 },
  card: { borderRadius: 16, borderWidth: 1, paddingHorizontal: 16 },
  row: { paddingVertical: 12, borderBottomWidth: StyleSheet.hairlineWidth, gap: 2 },
  rowLabel: { fontSize: 13 },
  rowValue: { fontSize: 16, fontWeight: '600' },
  tip: { borderRadius: 16, borderWidth: 1, padding: 16, marginTop: 14 },
  tipTitle: { fontWeight: '800', marginBottom: 6 },
  tipBody: { fontSize: 15, lineHeight: 24 },
});
