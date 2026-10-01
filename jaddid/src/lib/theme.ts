import { useColorScheme } from 'react-native';
import type { Status } from './dates';

const light = {
  bg: '#F5F3EE',
  card: '#FFFFFF',
  text: '#16211E',
  muted: '#5F6B67',
  border: '#E3DED3',
  primary: '#0E5E4E',
  primaryText: '#FFFFFF',
  gold: '#B8892B',
  chip: '#ECE7DC',
  danger: '#B42318',
  status: {
    expired: { bg: '#FDE8E7', fg: '#B42318' },
    urgent: { bg: '#FFEBD9', fg: '#B54708' },
    soon: { bg: '#FEF6D8', fg: '#8A6100' },
    ok: { bg: '#E3F4EC', fg: '#0E6B47' },
  } as Record<Status, { bg: string; fg: string }>,
};

const dark: typeof light = {
  bg: '#0F1614',
  card: '#18221F',
  text: '#ECF1EF',
  muted: '#9AA8A3',
  border: '#2A3632',
  primary: '#3FB295',
  primaryText: '#0B1512',
  gold: '#D9AE55',
  chip: '#22302C',
  danger: '#F97066',
  status: {
    expired: { bg: '#3A1714', fg: '#FDA29B' },
    urgent: { bg: '#3A2412', fg: '#FDB022' },
    soon: { bg: '#332B10', fg: '#FEC84B' },
    ok: { bg: '#12302A', fg: '#6CE9A6' },
  },
};

export type Theme = typeof light;

export function useTheme(): Theme {
  return useColorScheme() === 'dark' ? dark : light;
}

export const STATUS_LABEL: Record<Status, string> = {
  expired: 'منتهي',
  urgent: 'عاجل',
  soon: 'قريب',
  ok: 'ساري',
};
