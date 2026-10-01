import { Stack } from 'expo-router/stack';
import { router } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import * as Notifications from 'expo-notifications';
import { useEffect } from 'react';
import { I18nManager, Platform } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { configureNotifications } from '../lib/notifications';
import { StoreProvider } from '../lib/store';
import { useTheme } from '../lib/theme';

// التطبيق عربي بالكامل: اتجاه من اليمين لليسار
I18nManager.allowRTL(true);
I18nManager.forceRTL(true);
if (Platform.OS === 'web' && typeof document !== 'undefined') {
  document.documentElement.dir = 'rtl';
  document.documentElement.lang = 'ar';
}

configureNotifications();

export default function RootLayout() {
  const t = useTheme();

  // فتح المستند مباشرة عند الضغط على الإشعار
  useEffect(() => {
    if (Platform.OS === 'web') return;
    const sub = Notifications.addNotificationResponseReceivedListener((response) => {
      const docId = response.notification.request.content.data?.docId;
      if (typeof docId === 'string') router.push({ pathname: '/doc/[id]', params: { id: docId } });
    });
    return () => sub.remove();
  }, []);

  return (
    <SafeAreaProvider>
      <StoreProvider>
        <StatusBar style="auto" />
        <Stack
          screenOptions={{
            headerStyle: { backgroundColor: t.bg },
            headerTintColor: t.text,
            headerTitleStyle: { fontWeight: '700' },
            headerShadowVisible: false,
            contentStyle: { backgroundColor: t.bg },
          }}
        >
          <Stack.Screen name="index" options={{ headerShown: false }} />
          <Stack.Screen name="add" options={{ title: 'مستند جديد', presentation: 'modal' }} />
          <Stack.Screen name="doc/[id]" options={{ title: 'تفاصيل المستند' }} />
          <Stack.Screen name="pro" options={{ title: 'جدّد برو', presentation: 'modal' }} />
        </Stack>
      </StoreProvider>
    </SafeAreaProvider>
  );
}
