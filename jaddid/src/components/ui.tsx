import { Pressable, StyleSheet, Text, View, type PressableProps, type ViewStyle } from 'react-native';
import { daysUntil, formatGregorian, remainingLabel, statusOf } from '../lib/dates';
import { docTypeName, getCountry, getDocType } from '../lib/gcc';
import { STATUS_LABEL, useTheme } from '../lib/theme';
import type { DocItem } from '../lib/types';

export function Chip({
  label,
  selected,
  onPress,
}: {
  label: string;
  selected?: boolean;
  onPress?: () => void;
}) {
  const t = useTheme();
  return (
    <Pressable
      onPress={onPress}
      accessibilityRole="button"
      accessibilityState={{ selected }}
      style={[
        styles.chip,
        { backgroundColor: selected ? t.primary : t.chip, borderColor: selected ? t.primary : t.border },
      ]}
    >
      <Text style={[styles.chipText, { color: selected ? t.primaryText : t.text }]}>{label}</Text>
    </Pressable>
  );
}

export function Button({
  title,
  variant = 'primary',
  style,
  ...rest
}: PressableProps & { title: string; variant?: 'primary' | 'ghost' | 'danger'; style?: ViewStyle }) {
  const t = useTheme();
  const bg = variant === 'primary' ? t.primary : 'transparent';
  const fg = variant === 'primary' ? t.primaryText : variant === 'danger' ? t.danger : t.primary;
  return (
    <Pressable
      accessibilityRole="button"
      {...rest}
      style={({ pressed }) => [
        styles.button,
        { backgroundColor: bg, borderColor: variant === 'primary' ? bg : fg, opacity: pressed ? 0.8 : 1 },
        style,
      ]}
    >
      <Text style={[styles.buttonText, { color: fg }]}>{title}</Text>
    </Pressable>
  );
}

export function StatusBadge({ days }: { days: number }) {
  const t = useTheme();
  const s = statusOf(days);
  return (
    <View style={[styles.badge, { backgroundColor: t.status[s].bg }]}>
      <Text style={[styles.badgeText, { color: t.status[s].fg }]}>{STATUS_LABEL[s]}</Text>
    </View>
  );
}

export function DocCard({ doc, onPress }: { doc: DocItem; onPress: () => void }) {
  const t = useTheme();
  const days = daysUntil(doc.expiry);
  const s = statusOf(days);
  const type = getDocType(doc.type);
  const country = getCountry(doc.country);
  return (
    <Pressable
      onPress={onPress}
      accessibilityRole="button"
      accessibilityLabel={`${docTypeName(doc.type, doc.country)}، ${doc.owner}، ${remainingLabel(days)}`}
      style={({ pressed }) => [
        styles.card,
        { backgroundColor: t.card, borderColor: t.border, opacity: pressed ? 0.85 : 1 },
      ]}
    >
      <View style={[styles.cardStripe, { backgroundColor: t.status[s].fg }]} />
      <Text style={styles.cardIcon}>{type.icon}</Text>
      <View style={styles.cardBody}>
        <Text style={[styles.cardTitle, { color: t.text }]} numberOfLines={1}>
          {docTypeName(doc.type, doc.country)}
        </Text>
        <Text style={[styles.cardSub, { color: t.muted }]} numberOfLines={1}>
          {doc.owner} · {country.flag} {country.name}
        </Text>
        <Text style={[styles.cardSub, { color: t.muted }]}>{formatGregorian(doc.expiry)}</Text>
      </View>
      <View style={styles.cardEnd}>
        <StatusBadge days={days} />
        <Text style={[styles.cardDays, { color: t.status[s].fg }]}>{remainingLabel(days)}</Text>
      </View>
    </Pressable>
  );
}

export function SectionTitle({ children }: { children: string }) {
  const t = useTheme();
  return <Text style={[styles.section, { color: t.muted }]}>{children}</Text>;
}

const styles = StyleSheet.create({
  chip: {
    paddingHorizontal: 14,
    minHeight: 40,
    justifyContent: 'center',
    borderRadius: 20,
    borderWidth: 1,
    marginEnd: 8,
    marginBottom: 8,
  },
  chipText: { fontSize: 14, fontWeight: '600' },
  button: {
    minHeight: 52,
    borderRadius: 14,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 20,
  },
  buttonText: { fontSize: 16, fontWeight: '700' },
  badge: { paddingHorizontal: 10, paddingVertical: 3, borderRadius: 10 },
  badgeText: { fontSize: 12, fontWeight: '700' },
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 16,
    borderWidth: 1,
    padding: 14,
    paddingStart: 18,
    marginBottom: 10,
    overflow: 'hidden',
  },
  cardStripe: { position: 'absolute', start: 0, top: 0, bottom: 0, width: 5 },
  cardIcon: { fontSize: 28, marginEnd: 12 },
  cardBody: { flex: 1, gap: 2 },
  cardTitle: { fontSize: 16, fontWeight: '700' },
  cardSub: { fontSize: 13 },
  cardEnd: { alignItems: 'flex-end', gap: 6, marginStart: 8 },
  cardDays: { fontSize: 13, fontWeight: '700' },
  section: { fontSize: 13, fontWeight: '700', marginTop: 18, marginBottom: 8 },
});
