import { router } from 'expo-router';
import { useState } from 'react';
import { Alert, Platform, ScrollView, StyleSheet, Text, View } from 'react-native';
import { Button } from '../components/ui';
import { FREE_LIMIT, useStore } from '../lib/store';
import { useTheme } from '../lib/theme';

// الأسعار مبدئية — الدفع الفعلي يُربط لاحقاً بمشتريات المتجر (App Store / Google Play)
const PLANS = [
  {
    id: 'family',
    name: 'العائلة',
    price: '9.99 ر.س / شهرياً',
    yearly: 'أو 79 ر.س سنوياً',
    features: ['مستندات بلا حدود', 'كل أفراد العائلة والعمالة المنزلية', 'نسخ احتياطي ومزامنة (قريباً)'],
  },
  {
    id: 'business',
    name: 'الأعمال',
    price: '99 ر.س / شهرياً',
    yearly: 'حتى 50 موظفاً',
    features: [
      'متابعة إقامات ورخص عمل الموظفين',
      'السجل التجاري ورخص البلدية',
      'تقارير شهرية وتصدير Excel (قريباً)',
      'أكثر من مستخدم للمنشأة (قريباً)',
    ],
  },
];

export default function Pro() {
  const t = useTheme();
  const { settings, updateSettings } = useStore();
  const [notice, setNotice] = useState<string | null>(null);

  const subscribe = async () => {
    if (__DEV__) {
      // وضع التطوير فقط: تفعيل محلي لتجربة الميزات
      await updateSettings({ isPro: !settings.isPro });
      router.back();
      return;
    }
    const msg = 'الاشتراك سيتوفر قريباً عبر المتجر.';
    if (Platform.OS === 'web') setNotice(msg);
    else Alert.alert('قريباً', msg);
  };

  return (
    <ScrollView style={{ backgroundColor: t.bg }} contentContainerStyle={styles.container}>
      <Text style={[styles.title, { color: t.text }]}>★ جدّد برو</Text>
      <Text style={[styles.sub, { color: t.muted }]}>
        النسخة المجانية تكفي لـ {FREE_LIMIT} مستندات. اشترك لتتابع مستندات عائلتك كاملة، أو موظفي
        منشأتك، بلا حدود.
      </Text>

      {PLANS.map((p) => (
        <View key={p.id} style={[styles.plan, { backgroundColor: t.card, borderColor: t.gold }]}>
          <Text style={[styles.planName, { color: t.gold }]}>{p.name}</Text>
          <Text style={[styles.planPrice, { color: t.text }]}>{p.price}</Text>
          <Text style={[styles.planYearly, { color: t.muted }]}>{p.yearly}</Text>
          {p.features.map((f) => (
            <Text key={f} style={[styles.feature, { color: t.text }]}>
              ✓ {f}
            </Text>
          ))}
        </View>
      ))}

      <Button
        title={settings.isPro ? 'إلغاء التفعيل (وضع التجربة)' : 'اشترك الآن — أول 7 أيام مجاناً'}
        onPress={subscribe}
        style={{ marginTop: 8 }}
      />
      {notice && <Text style={[styles.notice, { color: t.primary }]}>{notice}</Text>}
      <Button title="ليس الآن" variant="ghost" onPress={() => router.back()} style={{ marginTop: 10 }} />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { padding: 16, paddingBottom: 40, maxWidth: 720, width: '100%', alignSelf: 'center' },
  title: { fontSize: 28, fontWeight: '800', marginBottom: 6 },
  sub: { fontSize: 15, lineHeight: 24, marginBottom: 16 },
  plan: { borderRadius: 18, borderWidth: 1.5, padding: 18, marginBottom: 14 },
  planName: { fontSize: 18, fontWeight: '800' },
  planPrice: { fontSize: 22, fontWeight: '800', marginTop: 4 },
  planYearly: { fontSize: 13, marginBottom: 10 },
  notice: { fontSize: 15, fontWeight: '700', textAlign: 'center', marginTop: 10 },
  feature: { fontSize: 15, lineHeight: 26 },
});
