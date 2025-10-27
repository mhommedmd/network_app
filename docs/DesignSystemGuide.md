# دليل نظام التصميم الموحد
## إدارة كروت الإنترنت - MikroTik

هذا الدليل يشرح كيفية استخدام نظام التصميم الجديد المطبق في التطبيق.

## 🎨 نظام الألوان

### الألوان الأساسية
- **Primary (الأساسي)**: `#2563eb` - اللون الأزرق الرئيسي
- **Secondary (الثانوي)**: `#6366f1` - اللون البنفسجي
- **Success (النجاح)**: `#059669` - اللون الأخضر
- **Warning (التحذير)**: `#d97706` - اللون البرتقالي
- **Error (الخطأ)**: `#dc2626` - اللون الأحمر

### الألوان الرمادية
- استخدام الألوان الرمادية مع نبرة زرقاء خفيفة
- من `--app-gray-50` (الأفتح) إلى `--app-gray-900` (الأغمق)

### التدرجات اللونية
- `--gradient-primary`: تدرج أزرق أساسي
- `--gradient-secondary`: تدرج بنفسجي
- `--gradient-success`: تدرج أخضر
- `--gradient-warning`: تدرج برتقالي
- `--gradient-error`: تدرج أحمر

## 🧱 المكونات المحسّنة

### AppButton
```tsx
import AppButton from './components/common/AppButton';

// الاستخدام الأساسي
<AppButton variant="primary" size="md">
  ابدأ البيع
</AppButton>

// مع التأثيرات المتحركة
<AppButton 
  variant="success" 
  size="lg" 
  animated={true}
  gradient={true}
>
  إتمام العملية
</AppButton>
```

#### المتغيرات المتاحة:
- **Variants**: `primary` | `secondary` | `success` | `warning` | `error` | `ghost` | `outline`
- **Sizes**: `sm` | `md` | `lg` | `xl`

### AppCard
```tsx
import { AppCard, AppCardHeader, AppCardContent, AppCardTitle } from './components/common/AppCard';

// بطاقة عادية
<AppCard variant="default" padding="md">
  <AppCardHeader>
    <AppCardTitle>عنوان البطاقة</AppCardTitle>
  </AppCardHeader>
  <AppCardContent>
    محتوى البطاقة
  </AppCardContent>
</AppCard>

// بطاقة زجاجية
<AppCard variant="glass" hover={true} animated={true}>
  محتوى البطاقة الزجاجية
</AppCard>
```

#### المتغيرات المتاحة:
- **Variants**: `default` | `glass` | `gradient` | `elevated`
- **Padding**: `sm` | `md` | `lg`

### AppBadge
```tsx
import AppBadge from './components/common/AppBadge';

// شارة عادية
<AppBadge variant="success" size="md">
  نشط
</AppBadge>

// شارة تحذير
<AppBadge variant="warning" size="sm">
  مخزون منخفض
</AppBadge>
```

#### المتغيرات المتاحة:
- **Variants**: `primary` | `secondary` | `success` | `warning` | `error` | `info` | `neutral`
- **Sizes**: `sm` | `md` | `lg`

## 🎯 متغيرات CSS المتاحة

### الألوان
```css
/* استخدام الألوان في CSS */
.my-element {
  background: var(--app-primary);
  color: var(--app-gray-900);
  border: 1px solid var(--app-gray-200);
}

/* التدرجات */
.gradient-button {
  background: var(--gradient-primary);
  box-shadow: var(--shadow-blue);
}
```

### المقاسات
```css
/* الأزرار */
.custom-button {
  height: var(--button-height-md);
  padding: 0 var(--spacing-xl);
  border-radius: var(--radius-xl);
}

/* البطاقات */
.custom-card {
  padding: var(--card-padding);
  border-radius: var(--radius-2xl);
  box-shadow: var(--shadow-lg);
}
```

### الظلال
```css
/* ظلال متنوعة */
.elevated-card {
  box-shadow: var(--shadow-xl);
}

.primary-shadow {
  box-shadow: var(--shadow-blue);
}

.secondary-shadow {
  box-shadow: var(--shadow-indigo);
}
```

## 🚀 الاستخدام في React Components

### مع CSS-in-JS
```tsx
import { AppColors, AppSizes, CommonStyles } from './components/common/AppDesignSystem';

const MyComponent = () => {
  const cardStyle = {
    ...CommonStyles.defaultCard,
    background: AppColors.gradients.primary,
    padding: AppSizes.cardPaddingLg
  };

  return (
    <div style={cardStyle}>
      محتوى البطاقة
    </div>
  );
};
```

### مع Tailwind CSS Classes
```tsx
const MyComponent = () => {
  return (
    <div className="app-card bg-white">
      <button className="app-button-primary">
        زر أساسي
      </button>
    </div>
  );
};
```

## 🎨 Classes المساعدة في Tailwind

### البطاقات
- `.app-card`: بطاقة عادية
- `.app-card-glass`: بطاقة زجاجية
- `.app-glass-card`: مكون زجاجي

### الأزرار
- `.app-button-primary`: زر أساسي
- `.app-button-secondary`: زر ثانوي

### التدرجات
- `.app-gradient-primary`: خلفية متدرجة أساسية
- `.app-gradient-secondary`: خلفية متدرجة ثانوية
- `.app-gradient-success`: خلفية متدرجة خضراء

### الرؤوس
- `.app-header-blur`: رأس شفاف مع تأثير ضبابي

## 📱 التصميم المتجاوب

### Safe Area Support
```css
/* دعم المنطقة الآمنة في iOS */
.safe-area-pb {
  padding-bottom: calc(1rem + env(safe-area-inset-bottom));
}

.bottom-nav-safe-padding {
  padding-bottom: calc(64px + env(safe-area-inset-bottom, 0px) + 1.5rem);
}
```

### Mobile-First Approach
- جميع المكونات مصممة للهواتف المحمولة أولاً
- استخدام media queries للشاشات الأكبر
- دعم كامل للـ RTL (Right-to-Left) للعربية

## ⚡ أمثلة عملية

### صفحة رئيسية محسّنة
```tsx
import { AppButton, AppCard } from './components/common/AppDesignSystem';

const HomePage = () => {
  return (
    <div className="min-h-screen app-gradient-background">
      {/* Header */}
      <div style={{ background: 'var(--gradient-primary)' }}>
        <h1 className="text-white">الصفحة الرئيسية</h1>
      </div>
      
      {/* Content */}
      <div className="px-6 py-6 space-y-6">
        <AppCard variant="default" hover={true}>
          <AppCardContent>
            <h2>بطاقة تفاعلية</h2>
            <AppButton variant="primary" size="md">
              إجراء
            </AppButton>
          </AppCardContent>
        </AppCard>
      </div>
    </div>
  );
};
```

### نموذج متقدم
```tsx
const AdvancedForm = () => {
  return (
    <AppCard variant="elevated" padding="lg">
      <AppCardHeader>
        <AppCardTitle>نموذج متقدم</AppCardTitle>
      </AppCardHeader>
      
      <AppCardContent>
        <div className="space-y-4">
          <input 
            className="w-full"
            style={{
              padding: AppSizes.spacingMd,
              borderRadius: AppSizes.radiusLg,
              border: `1px solid ${AppColors.gray300}`
            }}
          />
          
          <div className="flex gap-3">
            <AppButton variant="outline" className="flex-1">
              إلغاء
            </AppButton>
            <AppButton variant="primary" className="flex-1">
              حفظ
            </AppButton>
          </div>
        </div>
      </AppCardContent>
    </AppCard>
  );
};
```

## 🛠 إرشادات التطوير

### أفضل الممارسات
1. **استخدم المتغيرات**: دائماً استخدم متغيرات CSS بدلاً من القيم المباشرة
2. **الاتساق**: التزم بنظام الألوان المحدد
3. **التجاوب**: تأكد من التصميم المتجاوب
4. **الوصولية**: استخدم الألوان مع contrast جيد

### تجنب
- استخدام ألوان خارج النظام المحدد
- كتابة CSS مخصص للألوان بدلاً من المتغيرات
- تجاهل التصميم المتجاوب
- استخدام أحجام ثابتة بدلاً من المتغيرات

## 🔄 التحديثات المستقبلية

### مخطط التطوير
1. **Dark Mode**: إضافة دعم للوضع المظلم
2. **Themes**: أنظمة ألوان متعددة
3. **Components**: مكونات جديدة محسّنة
4. **Animations**: تأثيرات متحركة أكثر تطوراً

هذا النظام يضمن تصميماً موحداً ومتسقاً عبر التطبيق كاملاً! 🎨✨