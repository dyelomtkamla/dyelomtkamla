// بيانات دول الخليج وأنواع المستندات الشائعة في كل دولة.

export type CountryCode = 'SA' | 'AE' | 'KW' | 'QA' | 'BH' | 'OM';

export type Country = {
  code: CountryCode;
  name: string;
  flag: string;
  /** المنصة الحكومية الرسمية التي يتم التجديد من خلالها غالباً */
  portal: string;
  portalUrl: string;
};

export const COUNTRIES: Country[] = [
  { code: 'SA', name: 'السعودية', flag: '🇸🇦', portal: 'أبشر', portalUrl: 'https://www.absher.sa' },
  { code: 'AE', name: 'الإمارات', flag: '🇦🇪', portal: 'الهيئة الاتحادية للهوية (ICP)', portalUrl: 'https://icp.gov.ae' },
  { code: 'KW', name: 'الكويت', flag: '🇰🇼', portal: 'سهل', portalUrl: 'https://sahel.gov.kw' },
  { code: 'QA', name: 'قطر', flag: '🇶🇦', portal: 'مطراش', portalUrl: 'https://portal.moi.gov.qa' },
  { code: 'BH', name: 'البحرين', flag: '🇧🇭', portal: 'البوابة الوطنية', portalUrl: 'https://www.bahrain.bh' },
  { code: 'OM', name: 'عُمان', flag: '🇴🇲', portal: 'شرطة عُمان السلطانية', portalUrl: 'https://www.rop.gov.om' },
];

export type DocTypeId =
  | 'residency'
  | 'national_id'
  | 'passport'
  | 'driving_license'
  | 'vehicle_registration'
  | 'car_insurance'
  | 'vehicle_inspection'
  | 'health_insurance'
  | 'work_permit'
  | 'commercial_register'
  | 'municipal_license'
  | 'lease'
  | 'other';

export type DocType = {
  id: DocTypeId;
  icon: string;
  /** الاسم الافتراضي، ويمكن أن يختلف حسب الدولة */
  name: string;
  names?: Partial<Record<CountryCode, string>>;
  /** نصيحة قصيرة تظهر في صفحة المستند */
  tip: string;
  /** هل يتعلق بالشركات (مفيد لباقة الأعمال) */
  business?: boolean;
};

export const DOC_TYPES: DocType[] = [
  {
    id: 'residency',
    icon: '🪪',
    name: 'الإقامة',
    names: { SA: 'الإقامة (هوية مقيم)', AE: 'الإقامة / الهوية الإماراتية', QA: 'بطاقة الإقامة (QID)', KW: 'الإقامة' },
    tip: 'التأخر في تجديد الإقامة قد يترتب عليه غرامات ويؤثر على السفر والخدمات البنكية. ابدأ التجديد قبل الانتهاء بشهر على الأقل.',
  },
  {
    id: 'national_id',
    icon: '🆔',
    name: 'الهوية الوطنية',
    names: { KW: 'البطاقة المدنية', QA: 'البطاقة الشخصية', BH: 'البطاقة الذكية (CPR)', OM: 'البطاقة الشخصية' },
    tip: 'الهوية المنتهية قد تعطل معاملاتك البنكية والحكومية. جدّدها إلكترونياً عبر المنصة الرسمية.',
  },
  {
    id: 'passport',
    icon: '🛂',
    name: 'جواز السفر',
    tip: 'كثير من الدول تشترط صلاحية الجواز 6 أشهر على الأقل عند السفر، فلا تنتظر حتى آخر يوم.',
  },
  {
    id: 'driving_license',
    icon: '🚗',
    name: 'رخصة القيادة',
    tip: 'القيادة برخصة منتهية مخالفة مرورية. جدّد مبكراً وتأكد من سلامة الفحص الطبي إن كان مطلوباً.',
  },
  {
    id: 'vehicle_registration',
    icon: '📄',
    name: 'استمارة / ملكية السيارة',
    names: { SA: 'الاستمارة', AE: 'ملكية المركبة (Mulkiya)', QA: 'استمارة المركبة (Istimara)', KW: 'دفتر السيارة' },
    tip: 'تجديد الاستمارة يتطلب غالباً تأميناً سارياً وفحصاً دورياً — تحقق منهما قبل الموعد.',
  },
  {
    id: 'car_insurance',
    icon: '🛡️',
    name: 'تأمين السيارة',
    tip: 'قارن عروض التأمين قبل الانتهاء بأسبوعين لتحصل على سعر أفضل، ولا تقُد بتأمين منتهٍ.',
  },
  {
    id: 'vehicle_inspection',
    icon: '🔧',
    name: 'الفحص الدوري',
    names: { SA: 'الفحص الدوري (فحص)', QA: 'فحص (Fahes)' },
    tip: 'احجز موعد الفحص مبكراً لتجنب الزحام في آخر الشهر.',
  },
  {
    id: 'health_insurance',
    icon: '🏥',
    name: 'التأمين الصحي',
    tip: 'التأمين الصحي مرتبط بتجديد الإقامة في عدة دول خليجية. تأكد من تجديده أولاً.',
  },
  {
    id: 'work_permit',
    icon: '💼',
    name: 'رخصة العمل / كرت العمل',
    tip: 'رخصة العمل المنتهية قد تعرض صاحب العمل والعامل لغرامات. تابعها مع إقامة الموظف.',
    business: true,
  },
  {
    id: 'commercial_register',
    icon: '🏢',
    name: 'السجل التجاري',
    tip: 'السجل التجاري المنتهي قد يوقف خدمات المنشأة الحكومية. جدّده قبل الانتهاء.',
    business: true,
  },
  {
    id: 'municipal_license',
    icon: '🏪',
    name: 'رخصة البلدية / المحل',
    tip: 'تأكد من سلامة اشتراطات الدفاع المدني قبل تجديد رخصة المحل.',
    business: true,
  },
  {
    id: 'lease',
    icon: '🏠',
    name: 'عقد الإيجار',
    names: { SA: 'عقد الإيجار (إيجار)', AE: 'عقد الإيجار (إيجاري)' },
    tip: 'راجع شروط التجديد مع المالك قبل الانتهاء بـ 60 يوماً على الأقل.',
  },
  {
    id: 'other',
    icon: '📌',
    name: 'مستند آخر',
    tip: 'أضف ملاحظاتك عن خطوات التجديد حتى لا تنساها.',
  },
];

export function getCountry(code: CountryCode): Country {
  return COUNTRIES.find((c) => c.code === code) ?? COUNTRIES[0];
}

export function getDocType(id: DocTypeId): DocType {
  return DOC_TYPES.find((t) => t.id === id) ?? DOC_TYPES[DOC_TYPES.length - 1];
}

export function docTypeName(id: DocTypeId, country: CountryCode): string {
  const t = getDocType(id);
  return t.names?.[country] ?? t.name;
}

/** خيارات التذكير بالأيام قبل تاريخ الانتهاء */
export const REMINDER_OPTIONS = [60, 30, 14, 7, 3, 1, 0];
export const DEFAULT_REMINDERS = [30, 7, 1];
