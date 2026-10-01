// حالة التطبيق: المستندات + الإعدادات، محفوظة على الجهاز.
import AsyncStorage from '@react-native-async-storage/async-storage';
import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { cancelReminders, scheduleReminders } from './notifications';
import type { DocInput, DocItem } from './types';
import { daysUntil } from './dates';

const DOCS_KEY = 'jaddid.docs.v1';
const SETTINGS_KEY = 'jaddid.settings.v1';

/** حد النسخة المجانية — بعده تظهر شاشة الاشتراك */
export const FREE_LIMIT = 5;

export type Settings = {
  isPro: boolean;
  defaultCountry: DocInput['country'];
};

const DEFAULT_SETTINGS: Settings = { isPro: false, defaultCountry: 'SA' };

type Store = {
  ready: boolean;
  docs: DocItem[];
  settings: Settings;
  canAddMore: boolean;
  addDoc: (input: DocInput) => Promise<DocItem>;
  updateDoc: (id: string, input: DocInput) => Promise<void>;
  removeDoc: (id: string) => Promise<void>;
  updateSettings: (patch: Partial<Settings>) => Promise<void>;
};

const StoreContext = createContext<Store | null>(null);

function newId() {
  return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
}

export function sortByUrgency(docs: DocItem[]): DocItem[] {
  return [...docs].sort((a, b) => daysUntil(a.expiry) - daysUntil(b.expiry));
}

export function StoreProvider({ children }: { children: ReactNode }) {
  const [ready, setReady] = useState(false);
  const [docs, setDocs] = useState<DocItem[]>([]);
  const [settings, setSettings] = useState<Settings>(DEFAULT_SETTINGS);

  useEffect(() => {
    (async () => {
      try {
        const [rawDocs, rawSettings] = await Promise.all([
          AsyncStorage.getItem(DOCS_KEY),
          AsyncStorage.getItem(SETTINGS_KEY),
        ]);
        if (rawDocs) setDocs(JSON.parse(rawDocs));
        if (rawSettings) setSettings({ ...DEFAULT_SETTINGS, ...JSON.parse(rawSettings) });
      } catch {
        // بيانات تالفة: نبدأ من جديد بدلاً من تعطل التطبيق
      } finally {
        setReady(true);
      }
    })();
  }, []);

  const persist = useCallback(async (next: DocItem[]) => {
    setDocs(next);
    await AsyncStorage.setItem(DOCS_KEY, JSON.stringify(next));
  }, []);

  const addDoc = useCallback(
    async (input: DocInput) => {
      const doc: DocItem = { ...input, id: newId(), createdAt: Date.now() };
      doc.notificationIds = await scheduleReminders(doc).catch(() => []);
      await persist([...docs, doc]);
      return doc;
    },
    [docs, persist]
  );

  const updateDoc = useCallback(
    async (id: string, input: DocInput) => {
      const existing = docs.find((d) => d.id === id);
      if (!existing) return;
      await cancelReminders(existing.notificationIds);
      const doc: DocItem = { ...existing, ...input };
      doc.notificationIds = await scheduleReminders(doc).catch(() => []);
      await persist(docs.map((d) => (d.id === id ? doc : d)));
    },
    [docs, persist]
  );

  const removeDoc = useCallback(
    async (id: string) => {
      const existing = docs.find((d) => d.id === id);
      await cancelReminders(existing?.notificationIds);
      await persist(docs.filter((d) => d.id !== id));
    },
    [docs, persist]
  );

  const updateSettings = useCallback(
    async (patch: Partial<Settings>) => {
      const next = { ...settings, ...patch };
      setSettings(next);
      await AsyncStorage.setItem(SETTINGS_KEY, JSON.stringify(next));
    },
    [settings]
  );

  const value = useMemo<Store>(
    () => ({
      ready,
      docs,
      settings,
      canAddMore: settings.isPro || docs.length < FREE_LIMIT,
      addDoc,
      updateDoc,
      removeDoc,
      updateSettings,
    }),
    [ready, docs, settings, addDoc, updateDoc, removeDoc, updateSettings]
  );

  return <StoreContext.Provider value={value}>{children}</StoreContext.Provider>;
}

export function useStore(): Store {
  const ctx = useContext(StoreContext);
  if (!ctx) throw new Error('useStore must be used inside StoreProvider');
  return ctx;
}
