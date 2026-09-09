# Implementation Plan — Migrasi Fitur Tagihan, Riwayat Pembayaran & Metode Pembayaran

> **Legacy:** `MOBILE-SMARTMHS` (Kotlin) · **Target:** `smartmahsiswaflutter` (Flutter)
> Dibuat: 2026-09-09 · Status: **IMPLEMENTED (Task 1–8 selesai, `flutter analyze` bersih)** — tersisa pengujian device (§7)

---

## 0. Hasil Audit — Kondisi Saat Ini

Modul `lib/features/bills/` **sudah ada sebagian** hasil migrasi sebelumnya. Hasil audit:

| Komponen | Status | Catatan |
|---|---|---|
| Model `tuition_bill_response.dart` | ✅ Sesuai legacy | Field `semester`, `item_tagihan[].namatagihan/jumlah` cocok |
| Model `payment_history_response.dart` | ✅ Sesuai legacy | `semester, namatagihan, jumlah, tanggalbayar, melalui, link_kuitansi` cocok |
| Model `payment_method_response.dart` | ✅ Sesuai legacy | `nama_metode, norek, deskripsi, link_logo, tata_cara, biaya_adm` cocok |
| `ApiService.getTuitionBills` | ⚠️ Perlu fix | Mengirim field `language` — legacy **TIDAK** mengirimnya |
| `ApiService.getPaymentHistory` | ⚠️ Perlu fix | Mengirim field `language` — legacy **TIDAK** mengirimnya |
| `ApiService.getPaymentMethods` | ✅ Sesuai | Legacy memang mengirim `language` (`getIdLanguage()`) |
| Base URL | ✅ Sesuai | Ketiga endpoint pakai **legacy** `…/smartmobile/smartmhs/` (via `Constanta.getbseurlmain()` → `endPoint`) |
| `current_bills_page.dart` | ⚠️ Perlu revisi | Banyak teks hardcoded (belum l10n), state error belum lengkap, belum ada menu Riwayat di action bar |
| `payment_history_page.dart` | ⚠️ Perlu revisi | Kuitansi dibuka via browser — legacy **mengunduh PDF**; teks hardcoded |
| `select_payment_method_page.dart` | ⚠️ Perlu revisi | Judul & empty state hardcoded |
| `payment_instruction_page.dart` | ⚠️ Perlu revisi | **`deskripsi` tidak ditampilkan** (legacy menampilkan); beberapa label hardcoded |
| NIM digits-only | ❌ Belum | Legacy: `nim.filter { it.isDigit() }` — Flutter kirim nim mentah |
| State error/no-internet | ❌ Belum | Legacy membedakan 3 state (lihat §4.1) |

---

## 1. Pemetaan API (Verifikasi dari Source Legacy)

### 1.1 Tabel Endpoint

| Fitur | Method | Endpoint | Base URL | Parameter (form-encoded) | Enkripsi param? | Enkripsi response? |
|---|---|---|---|---|---|---|
| Daftar Tagihan | POST | `tagihanmhs` | **Legacy** `…/smartmobile/smartmhs/` | `unim`, `kdjen`, `kdpst` | ❌ Plain | ❌ Plain JSON |
| Riwayat Pembayaran | POST | `rekappembayaran` | **Legacy** `…/smartmobile/smartmhs/` | `unim`, `kdjen`, `kdpst` | ❌ Plain | ❌ Plain JSON |
| Metode Pembayaran | POST | `tatacarapembayaran` | **Legacy** `…/smartmobile/smartmhs/` | `unim`, `language` | ❌ Plain | ❌ Plain JSON |
| Download Kuitansi | GET (file) | URL dinamis dari field `link_kuitansi` | Ditentukan server (absolut) | — | — | File PDF |

> ⚠️ **Jangan samakan dengan modul lain** (login/khs/jadwal pakai **APIV2** + BNI encryption). Modul tagihan **seluruhnya plain** — response langsung di-parse Gson di legacy tanpa decrypt.

### 1.2 Headers (identik ketiga endpoint)

| Header | Nilai (legacy) | Nilai Flutter (sudah benar) |
|---|---|---|
| `Authorization` | `Decrypter().decrypt(getuserpassapi())` | `AppConstants.authHeader` = `Basic c21hcnRtaHM6ZHhqbjczamNkamxrTA==` ✅ |
| `SMART-API-KEY` | `Decrypter().decrypt(getapikeys())` | `AppConstants.apiKey` = `Dxj78123WerLpx12LbvmqwT56` ✅ |

Header sudah terpasang global di `ApiService._dio` — **tidak perlu perubahan**.

### 1.3 Perbaikan Wajib di `api_service.dart`

1. **Hapus** parameter `language` dari `getTuitionBills` & `getPaymentHistory` (legacy tidak mengirim).
2. **Filter NIM digits-only** di caller (atau di service): `nim.replaceAll(RegExp(r'\D'), '')`.
3. `getPaymentMethods` tetap kirim `language` = `Localizations.localeOf(context).languageCode` (pola yang sudah dipakai halaman lain; legacy hanya punya `id`/`en`, Flutter menambah `ar`).
4. Non-200 atau exception → jangan return `null` mentah; bungkus agar UI bisa membedakan **error server** vs **no internet** (legacy membangun response `success=false, message="error {code}"` / `message=null`).

---

## 2. Arsitektur & Struktur Folder (Mengikuti Pola Existing)

Project memakai **feature-first + setState** (tanpa BLoC/Provider) — rencana ini menjaga konsistensi tersebut.

```
lib/features/bills/
├── data/
│   └── models/                          # ✅ SUDAH ADA (3 file, sesuai legacy)
│       ├── tuition_bill_response.dart
│       ├── payment_history_response.dart
│       └── payment_method_response.dart
└── presentation/
    ├── pages/
    │   ├── current_bills_page.dart      # REVISI: action-bar riwayat, state lengkap, l10n, nim filter
    │   ├── payment_history_page.dart    # REVISI: download kuitansi (bukan open browser), l10n
    │   ├── select_payment_method_page.dart # REVISI: l10n, state lengkap
    │   └── payment_instruction_page.dart   # REVISI: tambah deskripsi, l10n
    └── widgets/
        └── error_state_widget.dart      # BARU: reusable (no-data / error-msg / no-internet)

lib/core/network/api_service.dart        # REVISI: §1.3
lib/core/utils/app_constants.dart       # Tidak berubah
lib/l10n/app_{id,en,ar}.arb             # REVISI: tambah ±17 key baru (§5)
lib/features/home/presentation/widgets/main_menu_grid.dart # REVISI: lihat §6
```

---

## 3. State Management

Tanpa library baru — pola `setState` + **state enum** agar state legacy (3 kemungkinan tampilan gagal) bisa direpresentasikan persis:

```dart
enum BillsLoadState { loading, success, noData, serverError, noInternet }
```

Pemetaan dari logika `show_data()` legacy:

| Kondisi response legacy | State | Tampilan |
|---|---|---|
| `success == true && data != null` | `success` | List + bottom bar total + tombol Lanjutkan (aktif) |
| `success == true && data == null` | `noData` | Animasi not-found + teks `text_keterangan_tagihan_tidak_ada` ("Tidak ada tagihan yang harus dibayar") |
| `success == false && message != null` | `serverError` | Animasi not-found + tampilkan `message` (mis. "error 500 …" atau pesan API) |
| onFailure (koneksi) | `noInternet` | Animasi no-internet + teks `notif_error_connection` |

> Flutter-style: ganti Lottie/shimmer legacy dengan ikon besar + teks (pola empty-state halaman schedule yang sudah ada), loading tetap `SpinKitThreeBounce` (konsisten app-wide).

---

## 4. Rencana Screen-by-Screen (Bisnis Proses = Legacy)

### 4.1 `current_bills_page.dart` — Daftar Tagihan
Sumber legacy: `TagihanFragment.kt` + `fragment_tagihan.xml` + adapter parent/child.

- [ ] `initState` → `Future.microtask(() => _loadBills())` ✅ sudah; pertahankan.
- [ ] Ambil user dari session → `nim` **digits-only**, `kodeJen`, `kodePst`.
- [ ] Grup per semester: header "Semester {n}" + kartu item (`namatagihan` kiri, jumlah IDR kanan) ✅ sudah.
- [ ] Bottom bar: "Total Tagihan" + jumlah (sum semua item — sama dgn `PerhitunganKeuangan.totaltagihan`) + tombol **Lanjutkan** → `SelectPaymentMethodPage(totalAmount)`. Tanpa data → tanpa bottom bar (setara tombol disabled di legacy).
- [ ] **BARU — Action bar menu Riwayat Pembayaran** (menggantikan tab legacy): tombol ikon `history_rounded` bergaya pill putih-transparan **persis pola tombol "Sem X" di `schedule_page.dart`**, `Navigator.push` → `PaymentHistoryPage`.
- [ ] `RefreshIndicator` ✅ sudah (setara SwipeRefreshLayout legacy) — pertahankan.
- [ ] Empty/error state pakai `ErrorStateWidget` + enum §3 (ganti empty state generik saat ini).
- [ ] Semua teks via l10n (hilangkan 'Total Tagihan', 'BELUM LUNAS', 'Tidak ada tagihan aktif').

### 4.2 `payment_history_page.dart` — Riwayat Pembayaran
Sumber legacy: `RekapPembayaranFragment.kt` + `RekapPembayaranAdapter.kt`.

- [ ] Load: `Future.microtask` + nim digits-only + `kdjen`/`kdpst`; tanpa param `language`.
- [ ] Kartu riwayat: badge LUNAS + `tanggalbayar`; judul `{namatagihan}`; jika `semester` tidak kosong → tampilkan info semester & "Melalui : {melalui}" (legacy: `${namatagihan} (Semester ${semester})` dan baris `Melalui`); jumlah IDR.
- [ ] **Tombol Kuitansi → DOWNLOAD (ubah perilaku):**
  1. URL = `link_kuitansi.replaceAll('\\/', '/')` (identik legacy).
  2. Unduh via `dio.download` → simpan `{dirDownloads}/kuitansi_{nim}_semester{semester}.pdf` (Android: folder Download publik bila izin memadai, fallback `getApplicationDocumentsDirectory()`; iOS: documents dir).
  3. Buka/preview dengan `open_filex` (paket sudah di pubspec).
  4. SnackBar progres & sukses ("Mengunduh kuitansi… Periksa di folder Download").
  5. Gagal → snackbar error (jangan crash).
- [ ] `RefreshIndicator` ✅; state 3-macam via enum §3 (legacy: `text_riwayat_pembayaran_tdk_ditemukan` bila `success=false,message!=null`; no-internet bila message null).
- [ ] (Opsional, paritas penuh) legacy me-refresh ulang di `onResume` bila sebelumnya gagal — di Flutter cukup RefreshIndicator, dicatat sebagai deviasi yang disepakati.

### 4.3 `select_payment_method_page.dart` — Pilih Metode
Sumber legacy: `MetodePembayaranActivity.kt` + `MetodePembayaranAdapter.kt`.

- [ ] Load saat create: `Future.microtask` + nim digits-only + `language` (sesuai legacy).
- [ ] Item: logo (`link_logo`, placeholder ikon bank bila gagal) + `nama_metode` → tap → `PaymentInstructionPage(method, totalAmount)`.
- [ ] Terima `totalAmount` (int) dari halaman tagihan — setara `intent.putExtra("jumlah", totaltagihan)`.
- [ ] `RefreshIndicator` ✅; empty/error state + l10n ("Metode Pembayaran", "Tidak ada metode pembayaran tersedia").

### 4.4 `payment_instruction_page.dart` — Detail Tata Cara
Sumber legacy: `DetailMetodePembayaran.kt` + `activity_detail_metode_pembayaran.xml`.

- [ ] Ringkasan (Card 1): `Tagihan` | `Biaya Admin` | **`Total Bayar`** (= tagihan + biaya adm, bold) — urutan & label sama legacy.
- [ ] Kartu bank (Card 2): logo + `{nama_metode} (Verifikasi Otomatis)`; label `Nomor Pembayaran`; `norek` (warna primary) + tombol **Salin/Copy** → `Clipboard` + snackbar `text_no_pemb_berhasil_disalin`; **tambahkan `deskripsi`** (hilang di versi sekarang).
- [ ] Card 3: judul `Petunjuk Pembayaran` + WebView `loadHtmlString(tata_cara)` (HTML dari API) ✅ sudah; pertahankan font-size 14 setara legacy.
- [ ] Semua label via l10n (hilangkan 'No. Pembayaran / VA', 'Tata Cara Pembayaran', 'Nomor pembayaran berhasil disalin', 'Verifikasi Otomatis').

### 4.5 Integrasi Home Menu
- [ ] `main_menu_grid.dart`: entri "Tagihan" tetap → `CurrentBillsPage` (satu pintu, setara legacy `binding.tagihan` → `TagihanActivity`).
- [ ] **Keputusan (rekomendasi): hapus** entri terpisah "Riwayat Pembayaran" dari grid — akses riwayat kini *hanya* via action bar halaman Tagihan, sesuai instruksi "jadikan menu di header action bar saja". Grid tetap 8 item (tidak perlu "show all").
- [ ] `SubscriptionUtils.checkSubscription` (ads/langganan legacy) **tidak dimigrasikan** — tidak ada sistem iklan/langganan di app Flutter (deviasi disengaja & terdokumentasi).

---

## 5. Localization — Key Baru (id / en / ar)

Terjemahan id/en diambil dari `values-in/strings.xml` & `values/strings.xml` legacy. **Arab tidak ada di legacy** → diterjemahkan baru (konsisten gaya `app_ar.arb`).

| Key | id (legacy) | en (legacy) | ar (baru) |
|---|---|---|---|
| `totalBills` | Total Tagihan | Total Bills | إجمالي الفواتير |
| `noActiveBills` | Tidak ada tagihan yang harus dibayar | There are no bills to pay | لا توجد فواتير مستحقة الدفع |
| `billStatusUnpaid` | BELUM LUNAS | UNPAID | غير مدفوعة |
| `billStatusPaid` | LUNAS | PAID | مدفوعة |
| `noPaymentHistoryFound` | Riwayat Pembayaran Tidak Ditemukan | Payment History Not Found | لا يوجد سجل دفع |
| `paymentMethod` | Metode Pembayaran | Payment Method | طريقة الدفع |
| `noPaymentMethods` | Tidak ada metode pembayaran tersedia | No payment methods available | لا توجد طرق دفع متاحة |
| `paymentNumber` | Nomor Pembayaran | Payment Number | رقم الدفع |
| `adminFee` | Biaya Admin | Admin fee | رسوم إدارية |
| `totalPay` | Total Bayar | Total Payment | المجموع للدفع |
| `automaticVerification` | Verifikasi Otomatis | Automatic Verification | تحقق تلقائي |
| `paymentInstructions` (ada, lengkapi id/ar bila belum) | Petunjuk Pembayaran | Payment Instructions | تعليمات الدفع |
| `paymentNumberCopied` | Nomor pembayaran berhasil disalin | Payment number successfully copied | تم نسخ رقم الدفع |
| `via` | Melalui | Via | عبر |
| `downloadReceipt` | Unduh Kuitansi | Download Receipt | تنزيل الإيصال |
| `downloadingReceipt` | Mengunduh kuitansi… Periksa di folder Download | Downloading receipt… Check the Download folder | جارٍ تنزيل الإيصال… تحقق من مجلد التنزيلات |
| `cantOpenReceipt` | Tidak dapat membuka kuitansi | Cannot open receipt | لا يمكن فتح الإيصال |
| `checkConnection` | Periksa koneksimu, Tidak dapat terhubung ke jaringan | Check your connection, Unable connect to network | تحقق من اتصالك، تعذر الاتصال بالشبكة |

Placeholder ber-parameter: `historyItemDetail` → `"{name} (Semester {semester})"` / `"{name} (Semester {semester})"` / `"{name} (الفصل الدراسي {semester})"`.

Gunakan key existing bila sudah ada & maknanya sama: `bills`, `paymentHistory`, `tuitionFee`, `receipt`, `proceed`, `copySuccess`→ganti `paymentNumberCopied` (lebih spesifik), `connError`→ganti `checkConnection` (teks legacy persis).

---

## 6. Urutan Kerja (Task Sequence)

| # | Task | File | Estimasi |
|---|---|---|---|
| 1 | Fix API service (hapus `language` di tagihan&riwayat, error mapping, nim filter helper) | `api_service.dart` | 0.5h |
| 2 | Tambah key l10n ×3 bahasa + regenerate | `app_*.arb` | 1h |
| 3 | Widget `ErrorStateWidget` (3 state) | `…/bills/presentation/widgets/` | 0.5h |
| 4 | Revisi `current_bills_page` (action-bar riwayat, state enum, l10n) | page | 1.5h |
| 5 | Revisi `payment_history_page` (download kuitansi dio+open_filex, l10n, state) | page | 2h |
| 6 | Revisi `select_payment_method_page` (l10n, state) | page | 0.5h |
| 7 | Revisi `payment_instruction_page` (deskripsi, label l10n, salin) | page | 1h |
| 8 | Home menu grid: hapus entri riwayat terpisah | `main_menu_grid.dart` | 0.25h |
| 9 | Test device Android + iOS, jalankan checklist §7 | — | 2h |

---

## 7. Testing Plan (Checklist Paritas Legacy)

### 7.1 Fungsional
- [ ] Buka halaman Tagihan dari menu Home → API POST `smartmhs/tagihanmhs` terkirim dgn `unim` digits-only, tanpa `language` (verifikasi via log dio).
- [ ] Tagihan tampil ter-group per semester; jumlah per item & total = legacy (bandingkan dgn app lama akun yang sama).
- [ ] Tanpa tagihan → tampil "Tidak ada tagihan yang harus dibayar", tidak ada bottom bar.
- [ ] Tagihan ada → bottom bar total + tombol Lanjutkan aktif → masuk halaman metode.
- [ ] Tombol riwayat di action bar (gaya pill seperti jadwal) → buka Riwayat Pembayaran.
- [ ] Riwayat: data tampil; item dengan semester kosong **tidak** menampilkan "(Semester …)".
- [ ] Kuitansi: file terunduh `kuitansi_{nim}_semester{n}.pdf`, terbuka via viewer; URL identik dgn legacy (`\/`→`/`).
- [ ] Metode: list sesuai bahasa (language param); tap metode → detail: tagihan+admin=total, norek, salin→snackbar, deskripsi tampil, tata cara HTML render di WebView.
- [ ] Total Bayar di detail = total tagihan + biaya admin metode terpilih.

### 7.2 State & Resiliensi
- [ ] Airplane mode saat load → state no-internet (teks koneksi legacy) di ketiga halaman list.
- [ ] Server balas non-200 / `success=false` + message → pesan error tampil (bukan empty state generik).
- [ ] Swipe-to-refresh berfungsi di Tagihan, Riwayat, Metode (setara SwipeRefreshLayout legacy).
- [ ] RefreshIndicator berhenti setelah load selesai/gagal.
- [ ] Kembali dari metode/detail → tidak crash, tidak dobel request.

### 7.3 i18n
- [ ] Ganti bahasa ID/EN/AR → SEMUA teks modul tagihan berubah (tidak ada hardcoded).
- [ ] Layout AR (RTL) tidak pecah pada 4 halaman.

### 7.4 Integrasi & Regresi
- [ ] Login → Home → Tagihan flow normal di Android & iOS.
- [ ] Modul lain (Jadwal, Pengumuman) tidak terdampak perubahan `ApiService`.
- [ ] `flutter analyze` bersih; tidak ada error kompilasi.

### 7.5 Catatan Deviasi yang Disetujui
1. Shimmer+Lottie legacy → SpinKit + ikon (konsistensi design system Flutter).
2. `SubscriptionUtils` (ads) tidak dimigrasikan.
3. Auto-retry saat `onResume` legacy → digantikan pull-to-refresh.
4. DownloadManager Android → dio+open_filex (cross-platform), nama file & URL tetap identik.
