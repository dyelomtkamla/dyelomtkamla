import { router, useLocalSearchParams } from 'expo-router';
import { useMemo, useState } from 'react';
import { KeyboardAvoidingView, Platform, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Button, Chip, SectionTitle } from '../components/ui';
import { formatHijri, isValidDate, parseISODate, reminderLabel, toISODate } from '../lib/dates';
import {
  COUNTRIES,
  DEFAULT_REMINDERS,
  DOC_TYPES,
  REMINDER_OPTIONS,
  docTypeName,
  type CountryCode,
  type DocTypeId,
} from '../lib/gcc';
import { useStore } from '../lib/store';
import { useTheme } from '../lib/theme';

const ME = 'أنا';

export default function AddDoc() {
  const t = useTheme();
  const insets = useSafeAreaInsets();
  const { id } = useLocalSearchParams<{ id?: string }>();
  const { docs, settings, addDoc, updateDoc, updateSettings } = useStore();
  const editing = id ? docs.find((d) => d.id === id) : undefined;

  const initialDate = editing ? parseISODate(editing.expiry) : null;
  const [type, setType] = useState<DocTypeId>(editing?.type ?? 'residency');
  const [country, setCountry] = useState<CountryCode>(editing?.country ?? settings.defaultCountry);
  const [owner, setOwner] = useState(editing?.owner ?? ME);
  const [number, setNumber] = useState(editing?.number ?? '');
  const [day, setDay] = useState(initialDate ? String(initialDate.getDate()) : '');
  const [month, setMonth] = useState(initialDate ? String(initialDate.getMonth() + 1) : '');
  const [year, setYear] = useState(initialDate ? String(initialDate.getFullYear()) : '');
  const [reminders, setReminders] = useState<number[]>(editing?.reminders ?? DEFAULT_REMINDERS);
  const [notes, setNotes] = useState(editing?.notes ?? '');
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  // أسماء الأشخاص المستخدمة سابقاً لتسريع الإدخال
  const knownOwners = useMemo(
    () => Array.from(new Set([ME, ...docs.map((d) => d.owner)])).slice(0, 8),
    [docs]
  );

  const y = Number(year);
  const m = Number(month);
  const d = Number(day);
  const dateOk = isValidDate(y, m, d);
  const iso = dateOk ? toISODate(new Date(y, m - 1, d)) : null;
  const hijri = iso ? formatHijri(iso) : null;

  const toggleReminder = (r: number) =>
    setReminders((cur) =>
      cur.includes(r) ? cur.filter((x) => x !== r) : [...cur, r].sort((a, b) => b - a)
    );

  const quickYears = (n: number) => {
    const base = new Date();
    base.setFullYear(base.getFullYear() + n);
    setDay(String(base.getDate()));
    setMonth(String(base.getMonth() + 1));
    setYear(String(base.getFullYear()));
  };

  const save = async () => {
    if (!owner.trim()) return setError('اكتب اسم صاحب المستند');
    if (!iso) return setError('تاريخ الانتهاء غير صحيح — تأكد من اليوم والشهر والسنة');
    setError(null);
    setSaving(true);
    const input = {
      type,
      country,
      owner: owner.trim(),
      number: number.trim() || undefined,
      expiry: iso,
      reminders,
      notes: notes.trim() || undefined,
    };
    try {
      if (editing) await updateDoc(editing.id, input);
      else await addDoc(input);
      if (country !== settings.defaultCountry) await updateSettings({ defaultCountry: country });
      router.back();
    } catch {
      setError('تعذّر الحفظ، حاول مرة أخرى');
    } finally {
      setSaving(false);
    }
  };

  const inputStyle = [styles.input, { backgroundColor: t.card, borderColor: t.border, color: t.text }];

  return (
    <KeyboardAvoidingView style={{ flex: 1 }} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
      <ScrollView
        style={{ backgroundColor: t.bg }}
        contentContainerStyle={[styles.container, { paddingBottom: insets.bottom + 32 }]}
        keyboardShouldPersistTaps="handled"
      >
        <SectionTitle>الدولة</SectionTitle>
        <View style={styles.wrap}>
          {COUNTRIES.map((c) => (
            <Chip
              key={c.code}
              label={`${c.flag} ${c.name}`}
              selected={country === c.code}
              onPress={() => setCountry(c.code)}
            />
          ))}
        </View>

        <SectionTitle>نوع المستند</SectionTitle>
        <View style={styles.wrap}>
          {DOC_TYPES.map((dt) => (
            <Chip
              key={dt.id}
              label={`${dt.icon} ${docTypeName(dt.id, country)}`}
              selected={type === dt.id}
              onPress={() => setType(dt.id)}
            />
          ))}
        </View>

        <SectionTitle>صاحب المستند</SectionTitle>
        <View style={styles.wrap}>
          {knownOwners.map((o) => (
            <Chip key={o} label={o} selected={owner === o} onPress={() => setOwner(o)} />
          ))}
        </View>
        <TextInput
          value={owner}
          onChangeText={setOwner}
          placeholder="مثال: أم محمد، السائق، الموظف أحمد"
          placeholderTextColor={t.muted}
          style={inputStyle}
          accessibilityLabel="اسم صاحب المستند"
        />

        <SectionTitle>تاريخ الانتهاء (ميلادي)</SectionTitle>
        <View style={styles.dateRow}>
          <DateField label="اليوم" value={day} onChange={setDay} max={2} style={inputStyle} />
          <DateField label="الشهر" value={month} onChange={setMonth} max={2} style={inputStyle} />
          <DateField label="السنة" value={year} onChange={setYear} max={4} style={inputStyle} wide />
        </View>
        <View style={styles.wrap}>
          <Chip label="بعد سنة" onPress={() => quickYears(1)} />
          <Chip label="بعد سنتين" onPress={() => quickYears(2)} />
          <Chip label="بعد 5 سنوات" onPress={() => quickYears(5)} />
        </View>
        {hijri && <Text style={[styles.hint, { color: t.primary }]}>يوافق: {hijri}</Text>}

        <SectionTitle>ذكّرني</SectionTitle>
        <View style={styles.wrap}>
          {REMINDER_OPTIONS.map((r) => (
            <Chip
              key={r}
              label={reminderLabel(r)}
              selected={reminders.includes(r)}
              onPress={() => toggleReminder(r)}
            />
          ))}
        </View>

        <SectionTitle>رقم المستند (اختياري)</SectionTitle>
        <TextInput
          value={number}
          onChangeText={setNumber}
          placeholder="يُحفظ على جهازك فقط"
          placeholderTextColor={t.muted}
          style={inputStyle}
          accessibilityLabel="رقم المستند"
        />

        <SectionTitle>ملاحظات (اختياري)</SectionTitle>
        <TextInput
          value={notes}
          onChangeText={setNotes}
          placeholder="مثال: يحتاج تأمين طبي قبل التجديد"
          placeholderTextColor={t.muted}
          style={[inputStyle, { minHeight: 80, textAlignVertical: 'top' }]}
          multiline
          accessibilityLabel="ملاحظات"
        />

        {error && <Text style={[styles.error, { color: t.danger }]}>{error}</Text>}

        <Button
          title={saving ? 'جارٍ الحفظ…' : editing ? 'حفظ التعديلات' : 'حفظ وتفعيل التذكير'}
          onPress={save}
          disabled={saving}
          style={{ marginTop: 20 }}
        />
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

function DateField({
  label,
  value,
  onChange,
  max,
  style,
  wide,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  max: number;
  style: object[];
  wide?: boolean;
}) {
  const t = useTheme();
  return (
    <View style={{ flex: wide ? 1.6 : 1 }}>
      <Text style={[styles.fieldLabel, { color: t.muted }]}>{label}</Text>
      <TextInput
        value={value}
        onChangeText={(v) => onChange(v.replace(/[^0-9٠-٩]/g, '').replace(/[٠-٩]/g, (c) => String('٠١٢٣٤٥٦٧٨٩'.indexOf(c))))}
        keyboardType="number-pad"
        maxLength={max}
        style={[...style, { textAlign: 'center' }]}
        accessibilityLabel={label}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { padding: 16, maxWidth: 720, width: '100%', alignSelf: 'center' },
  wrap: { flexDirection: 'row', flexWrap: 'wrap' },
  input: { borderWidth: 1, borderRadius: 12, paddingHorizontal: 14, minHeight: 48, fontSize: 16 },
  dateRow: { flexDirection: 'row', gap: 10, marginBottom: 10 },
  fieldLabel: { fontSize: 12, marginBottom: 4 },
  hint: { fontSize: 14, fontWeight: '600', marginTop: 2 },
  error: { fontSize: 14, fontWeight: '700', marginTop: 16 },
});
