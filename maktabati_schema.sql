-- ============================================================
-- مكتبتي — قاعدة بيانات النظام (Supabase / PostgreSQL)
-- الصق هذا الكود بالكامل في SQL Editor داخل مشروعك على Supabase واضغط Run
-- ============================================================

-- الإعدادات العامة (اسم المكتبة، العملة، سعر الساعة الإضافية...)
create table if not exists settings (
  id int primary key default 1,
  name text default 'مكتبتي',
  tagline text default 'مساحتك الهادئة للقراءة والتركيز والدراسة',
  about text default '"مكتبتي" مساحة قراءة ودراسة هادئة، صممت لتمنحك بيئة مريحة للتركيز.',
  currency text default 'ج.س',
  overtime_rate numeric default 12,
  constraint single_row check (id = 1)
);

-- مدد الحجز وأسعارها
create table if not exists durations (
  id text primary key,
  label text not null,
  hours numeric not null,
  price numeric not null,
  sort int default 0
);

-- الباقات المخصصة
create table if not exists packages (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  price numeric not null
);

-- المقاعد
create table if not exists seats (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  status text not null default 'available' -- available | maintenance
);

-- العملاء (رقم الجوال هو المعرف الأساسي)
create table if not exists customers (
  phone text primary key,
  name text not null,
  email text,
  first_visit timestamptz default now(),
  visits int default 0,
  total_hours numeric default 0,
  total_spent numeric default 0,
  last_visit timestamptz
);

-- الحجوزات
create table if not exists bookings (
  id uuid primary key default gen_random_uuid(),
  customer_phone text references customers(phone) on delete cascade,
  customer_name text,
  date date not null,
  time text not null,
  duration_id text,
  duration_label text,
  hours numeric,
  price numeric,
  people int default 1,
  seat_id uuid references seats(id) on delete set null,
  status text not null default 'Pending', -- Pending|Confirmed|Checked-in|Completed|Cancelled
  created_at timestamptz default now()
);

-- تسجيل الدخول والخروج
create table if not exists checkins (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid references bookings(id) on delete set null,
  customer_phone text,
  customer_name text,
  seat_id uuid references seats(id) on delete set null,
  entry_at timestamptz not null default now(),
  exit_at timestamptz,
  planned_hours numeric,
  planned_price numeric,
  actual_hours numeric default 0,
  final_price numeric default 0,
  status text not null default 'active' -- active | completed
);

-- المنتجات
create table if not exists products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  emoji text default '🧃',
  price numeric not null,
  stock int default 0,
  sold int default 0
);

-- عمليات البيع (POS)
create table if not exists orders (
  id uuid primary key default gen_random_uuid(),
  customer_phone text,
  staff text,
  total numeric not null default 0,
  created_at timestamptz default now()
);

-- تفاصيل المنتجات داخل كل عملية بيع
create table if not exists order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references orders(id) on delete cascade,
  product_id uuid references products(id) on delete set null,
  name text,
  qty int not null default 1,
  price numeric not null
);

-- حسابات الموظفين والصلاحيات
create table if not exists staff (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  username text unique not null,
  pin text not null,
  role text not null default 'Employee' -- Admin | Manager | Employee
);

-- الإشعارات
create table if not exists notifications (
  id uuid primary key default gen_random_uuid(),
  type text,
  message text,
  created_at timestamptz default now(),
  read boolean default false
);

-- ============================================================
-- فتح الوصول عبر anon key (النظام يتحكم بالدخول داخلياً عبر شاشة الموظفين
-- وليس عبر Supabase Auth، لذلك نمنح صلاحية كاملة لمفتاح anon هنا).
-- ============================================================
alter table settings enable row level security;
alter table durations enable row level security;
alter table packages enable row level security;
alter table seats enable row level security;
alter table customers enable row level security;
alter table bookings enable row level security;
alter table checkins enable row level security;
alter table products enable row level security;
alter table orders enable row level security;
alter table order_items enable row level security;
alter table staff enable row level security;
alter table notifications enable row level security;

create policy "allow all - settings" on settings for all using (true) with check (true);
create policy "allow all - durations" on durations for all using (true) with check (true);
create policy "allow all - packages" on packages for all using (true) with check (true);
create policy "allow all - seats" on seats for all using (true) with check (true);
create policy "allow all - customers" on customers for all using (true) with check (true);
create policy "allow all - bookings" on bookings for all using (true) with check (true);
create policy "allow all - checkins" on checkins for all using (true) with check (true);
create policy "allow all - products" on products for all using (true) with check (true);
create policy "allow all - orders" on orders for all using (true) with check (true);
create policy "allow all - order_items" on order_items for all using (true) with check (true);
create policy "allow all - staff" on staff for all using (true) with check (true);
create policy "allow all - notifications" on notifications for all using (true) with check (true);

-- ============================================================
-- بيانات أولية (نفس الإعدادات الافتراضية للنظام)
-- ============================================================
insert into settings (id,name,tagline,about,currency,overtime_rate)
values (1,'مكتبتي','مساحتك الهادئة للقراءة والتركيز والدراسة',
        '"مكتبتي" مساحة قراءة ودراسة هادئة، صممت لتمنحك بيئة مريحة للتركيز.','ج.س',12)
on conflict (id) do nothing;

insert into durations (id,label,hours,price,sort) values
 ('d_hour','ساعة',1,20,1),
 ('d_2h','ساعتان',2,35,2),
 ('d_3h','3 ساعات',3,50,3),
 ('d_4h','4 ساعات',4,60,4),
 ('d_day','اليوم كامل',10,80,5),
 ('d_week','الأسبوع',70,300,6),
 ('d_month','الشهر',300,900,7)
on conflict (id) do nothing;

insert into seats (code) values
 ('A01'),('A02'),('A03'),('A04'),('A05'),
 ('A06'),('A07'),('A08'),('A09'),('A10'),
 ('B01'),('B02'),('B03'),('B04')
on conflict do nothing;

insert into products (name,emoji,price,stock) values
 ('مياه','💧',2,120),
 ('قهوة','☕',8,80),
 ('لاتيه','🥛',12,60),
 ('شاي','🍵',6,70),
 ('سناك','🍪',5,100),
 ('عصير طبيعي','🧃',10,40)
on conflict do nothing;

insert into staff (name,username,pin,role) values
 ('عبدالله الحربي','admin','1234','Admin'),
 ('سارة القحطاني','manager','1111','Manager'),
 ('فهد العتيبي','employee','0000','Employee')
on conflict (username) do nothing;

-- انتهى — راجع تبويب Table Editor في Supabase للتأكد أن كل الجداول ظهرت
