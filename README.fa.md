# قوانین مسیریابی IPهای ایران برای OpenWrt 🇮🇷

[English](./README.md) | **فارسی**

سلام! این پروژه کمک می‌کند ترافیک مقصد ایران را با **luci-app-pbr** در OpenWrt از مسیر دلخواهتان عبور دهید؛ مثلاً مستقیم از اینترنت، جدا از VPN. دو نسخه داریم: آنلاین که فهرست را به‌روز می‌گیرد و آفلاین که همه‌ی IPها را داخل خودش دارد.

## نصب و راه‌اندازی

### ۱. نصب بسته‌های لازم

با SSH به روتر وصل شوید و اجرا کنید:

```sh
opkg update
opkg install luci-app-pbr pbr uclient-fetch
```

### ۲. انتخاب و دریافت اسکریپت

اول مسیر اسکریپت‌های PBR را بسازید:

```sh
mkdir -p /usr/share/pbr
```

**نسخه‌ی آنلاین** — پیشنهاد می‌شود اگر روتر به اینترنت دسترسی دارد:

```sh
uclient-fetch -O /usr/share/pbr/pbr.user.iran.sh \
  https://raw.githubusercontent.com/WhoisGray/openwrt-pbr-iran-rules/main/pbr.user.iran.sh
chmod 755 /usr/share/pbr/pbr.user.iran.sh
```

**نسخه‌ی آفلاین** — بعد از دریافت، برای اجرا به اینترنت نیاز ندارد:

```sh
uclient-fetch -O /usr/share/pbr/pbr.user.iran.offline.sh \
  https://raw.githubusercontent.com/WhoisGray/openwrt-pbr-iran-rules/main/pbr.user.iran.offline.sh
chmod 755 /usr/share/pbr/pbr.user.iran.offline.sh
```

> دریافت اولیه‌ی فایل از اینترنت انجام می‌شود؛ اما نسخه‌ی آفلاین بعد از نصب، مستقل کار می‌کند.

### ۳. معرفی اسکریپت به PBR

در LuCI به **Services > Policy Routing** بروید، اسکریپت انتخابی را به‌عنوان **Custom User File** معرفی و فعال کنید. فقط یکی از دو نسخه را انتخاب کنید:

- آنلاین: `/usr/share/pbr/pbr.user.iran.sh`
- آفلاین: `/usr/share/pbr/pbr.user.iran.offline.sh`

تنظیمات را ذخیره کنید و PBR را از LuCI راه‌اندازی مجدد کنید، یا این دستور را اجرا کنید:

```sh
/etc/init.d/pbr restart
```

## تفاوت نسخه‌ها و به‌روزرسانی

- **آنلاین:** هر بار که اسکریپت اجرا می‌شود، فهرست‌های چند منبع را می‌گیرد. خطای هر منبع به‌تنهایی مشکلی ایجاد نمی‌کند؛ اما فقط IPهایی اعمال می‌شوند که در هر دو گروه منابع اصلی و انجمنی تأیید شده باشند. اگر فهرست قابل‌اعتمادی به دست نیاید، قوانین فعلی دست‌نخورده می‌مانند.
- **آفلاین:** فهرست IPها داخل خود فایل قرار دارد و هنگام اجرا هیچ درخواستی به اینترنت نمی‌فرستد. این snapshot در **۲۰۲۶-۱۱-۱۲** ساخته شده؛ برای تازه‌کردنش باید نسخه‌ی جدید اسکریپت آفلاین را دریافت کنید.
- فهرست آنلاین با اجرای PBR تازه می‌شود. برای به‌روزرسانی خودکار روزانه، این دستور را یک بار در روتر اجرا کنید تا کار زمان‌بندی‌شده برای ساعت ۰۴:۱۵ ثبت شود:

```sh
grep -qF '/usr/share/pbr/pbr.user.iran.sh' /etc/crontabs/root || \
  echo '15 4 * * * /usr/share/pbr/pbr.user.iran.sh >/tmp/pbr-iran-update.log 2>&1' >> /etc/crontabs/root
/etc/init.d/cron restart
```

این زمان‌بندی فقط فهرست IP را به‌روز می‌کند، نه خود اسکریپت را. نسخه‌ی آفلاین به زمان‌بندی نیاز ندارد.

## نکته‌های امنیتی

محتوای منابع فقط به‌عنوان فهرست IP خوانده می‌شود و به‌عنوان کد Shell اجرا نمی‌شود. اسکریپت قالب CIDRها را بررسی می‌کند، موارد تکراری و بازه‌های خصوصی/رزروشده را کنار می‌گذارد و برای نسخه‌ی آنلاین تأیید چندمنبعی می‌خواهد.

این بررسی‌ها ریسک دستکاری یک منبع را کمتر می‌کنند، اما تضمین امنیت کامل نیستند؛ مثلاً در صورت دستکاری هم‌زمان چند منبع یا خود مخزن، همچنان باید محتاط بود. پیشنهاد می‌کنیم به‌روزرسانی خود اسکریپت را دستی و از مخزن اصلی انجام دهید.

## منابع فهرست IP

- [RIPE Stat](https://stat.ripe.net/data/country-resource-list/data.json?resource=IR&v4_format=prefix) — داده‌های ثبت‌شده‌ی منطقه‌ای.
- [IPdeny](https://www.ipdeny.com/ipblocks/data/countries/ir.zone) — فهرست عمومی IP کشورها.
- [MrAriaNet/Get-IP-Iran](https://github.com/MrAriaNet/Get-IP-Iran)
- [farshidmousavii/iran-ip-ranges](https://github.com/farshidmousavii/iran-ip-ranges)

اگر به مشکلی برخوردید یا پیشنهادی برای بهترشدن پروژه دارید، خوشحال می‌شویم در [مخزن GitHub](https://github.com/WhoisGray/openwrt-pbr-iran-rules) مطرحش کنید.

## مجوز

این پروژه با مجوز MIT منتشر شده است.
