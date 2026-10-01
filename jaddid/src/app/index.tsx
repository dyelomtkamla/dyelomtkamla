import { router } from 'expo-router';
import { useMemo, useState } from 'react';
import { ActivityIndicator, FlatList, Pressable, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Chip, DocCard } from '../components/ui';
import { daysUntil, statusOf, type Status } from '../lib/dates';
import { FREE_LIMIT, sortByUrgency, useStore } from '../lib/store';
import { STATUS_LABEL, useTheme } from '../lib/theme';

type Filter = 'all' | Status;

export default function Dashboard() {
  const t = useTheme();
  const insets = useSafeAreaInsets();
  const { ready, docs, settings, canAddMore } = useStore();
  const [filter, setFilter] = useState<Filter>('all');

  const counts = useMemo(() => {
    const c: Record<Status, number> = { expired: 0, urgent: 0, soon: 0, ok: 0 };
    for (const d of docs) c[statusOf(daysUntil(d.expiry))]++;
    return c;
  }, [docs]);

  const visible = useMemo(() => {
    const sorted = sortByUrgency(docs);
    return filter === 'all' ? sorted : sorted.filter((d) => statusOf(daysUntil(d.expiry)) === filter);
  }, [docs, filter]);

  const onAdd = () => router.push(canAddMore ? '/add' : '/pro');

  if (!ready) {
    return (
      <View style={[styles.center, { backgroundColor: t.bg }]}>
        <ActivityIndicator color={t.primary} />
      </View>
    );
  }

  const needAttention = counts.expired + counts.urgent + counts.soon;

  return (
    <View style={{ flex: 1, backgroundColor: t.bg }}>
      <FlatList
        data={visible}
        keyExtractor={(d) => d.id}
        contentContainerStyle={{
          paddingTop: insets.top + 16,
          paddingBottom: insets.bottom + 110,
          paddingHorizontal: 16,
          maxWidth: 720,
          width: '100%',
          alignSelf: 'center',
        }}
        ListHeaderComponent={
          <View>
            <View style={styles.headerRow}>
              <View style={{ flex: 1 }}>
                <Text style={[styles.brand, { color: t.primary }]}>جدّد</Text>
                <Text style={[styles.tagline, { color: t.muted }]}>
                  لا تنسَ تجديد مستنداتك… ولا تدفع غرامة بعد اليوم
                </Text>
              </View>
              <Pressable
                onPress={() => router.push('/pro')}
                accessibilityRole="button"
                accessibilityLabel="الاشتراك المميز"
                style={[styles.proPill, { borderColor: t.gold }]}
              >
                <Text style={[styles.proPillText, { color: t.gold }]}>
                  {settings.isPro ? '★ برو' : '★ ترقية'}
                </Text>
              </Pressable>
            </View>

            {docs.length > 0 && (
              <View style={[styles.summary, { backgroundColor: t.primary }]}>
                <Text style={[styles.summaryBig, { color: t.primaryText }]}>
                  {needAttention > 0 ? `${needAttention} مستند يحتاج انتباهك` : 'كل مستنداتك سارية ✓'}
                </Text>
                <View style={styles.summaryRow}>
                  {(['expired', 'urgent', 'soon', 'ok'] as Status[]).map((s) => (
                    <View key={s} style={styles.summaryCell}>
                      <Text style={[styles.summaryNum, { color: t.primaryText }]}>{counts[s]}</Text>
                      <Text style={[styles.summaryLbl, { color: t.primaryText }]}>{STATUS_LABEL[s]}</Text>
                    </View>
                  ))}
                </View>
              </View>
            )}

            {docs.length > 0 && (
              <View style={styles.filters}>
                <Chip label="الكل" selected={filter === 'all'} onPress={() => setFilter('all')} />
                {(['expired', 'urgent', 'soon', 'ok'] as Status[]).map((s) => (
                  <Chip
                    key={s}
                    label={`${STATUS_LABEL[s]} (${counts[s]})`}
                    selected={filter === s}
                    onPress={() => setFilter(s)}
                  />
                ))}
              </View>
            )}

            {!settings.isPro && docs.length > 0 && (
              <Text style={[styles.quota, { color: t.muted }]}>
                النسخة المجانية: {docs.length} من {FREE_LIMIT} مستندات
              </Text>
            )}
          </View>
        }
        renderItem={({ item }) => (
          <DocCard
            doc={item}
            onPress={() => router.push({ pathname: '/doc/[id]', params: { id: item.id } })}
          />
        )}
        ListEmptyComponent={
          docs.length === 0 ? (
            <View style={[styles.empty, { backgroundColor: t.card, borderColor: t.border }]}>
              <Text style={styles.emptyIcon}>📂</Text>
              <Text style={[styles.emptyTitle, { color: t.text }]}>أضف أول مستند</Text>
              <Text style={[styles.emptyBody, { color: t.muted }]}>
                الإقامة، الهوية، الجواز، الاستمارة، التأمين… سنذكّرك قبل انتهائها بوقت كافٍ — لك
                ولعائلتك ولموظفيك في كل دول الخليج.
              </Text>
            </View>
          ) : (
            <Text style={[styles.emptyBody, { color: t.muted, marginTop: 24 }]}>
              لا توجد مستندات في هذا التصنيف
            </Text>
          )
        }
      />

      <Pressable
        onPress={onAdd}
        accessibilityRole="button"
        accessibilityLabel="إضافة مستند"
        style={({ pressed }) => [
          styles.fab,
          { backgroundColor: t.primary, bottom: insets.bottom + 24, opacity: pressed ? 0.85 : 1 },
        ]}
      >
        <Text style={[styles.fabText, { color: t.primaryText }]}>＋ إضافة مستند</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  headerRow: { flexDirection: 'row', alignItems: 'center', marginBottom: 16 },
  brand: { fontSize: 34, fontWeight: '800' },
  tagline: { fontSize: 14, marginTop: 2 },
  proPill: { borderWidth: 1.5, borderRadius: 18, paddingHorizontal: 12, paddingVertical: 6 },
  proPillText: { fontWeight: '800', fontSize: 13 },
  summary: { borderRadius: 20, padding: 18, marginBottom: 14 },
  summaryBig: { fontSize: 18, fontWeight: '800', marginBottom: 14 },
  summaryRow: { flexDirection: 'row' },
  summaryCell: { flex: 1, alignItems: 'center' },
  summaryNum: { fontSize: 24, fontWeight: '800' },
  summaryLbl: { fontSize: 12, opacity: 0.9 },
  filters: { flexDirection: 'row', flexWrap: 'wrap', marginBottom: 6 },
  quota: { fontSize: 12, marginBottom: 8 },
  empty: { borderRadius: 20, borderWidth: 1, padding: 28, alignItems: 'center', marginTop: 12 },
  emptyIcon: { fontSize: 48, marginBottom: 8 },
  emptyTitle: { fontSize: 20, fontWeight: '800', marginBottom: 8 },
  emptyBody: { fontSize: 15, lineHeight: 24, textAlign: 'center' },
  fab: {
    position: 'absolute',
    alignSelf: 'center',
    paddingHorizontal: 28,
    minHeight: 56,
    borderRadius: 28,
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOpacity: 0.2,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
    elevation: 6,
  },
  fabText: { fontSize: 17, fontWeight: '800' },
});
