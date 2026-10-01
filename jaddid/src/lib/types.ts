import type { CountryCode, DocTypeId } from './gcc';

export type DocItem = {
  id: string;
  type: DocTypeId;
  country: CountryCode;
  /** صاحب المستند: أنا، أحد أفراد العائلة، أو موظف */
  owner: string;
  /** رقم المستند (اختياري) */
  number?: string;
  /** تاريخ الانتهاء بصيغة YYYY-MM-DD */
  expiry: string;
  /** أيام التذكير قبل الانتهاء */
  reminders: number[];
  notes?: string;
  notificationIds?: string[];
  createdAt: number;
};

export type DocInput = Omit<DocItem, 'id' | 'notificationIds' | 'createdAt'>;
