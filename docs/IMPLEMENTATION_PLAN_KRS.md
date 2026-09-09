# Implementation Plan — Migrasi Fitur KRS (Lihat KRS & Input KRS)

> **Legacy:** `MOBILE-SMARTMHS` (Kotlin) · **Target:** `smartmahsiswaflutter` (Flutter)
> Dibuat: 2026-09-09 · Status: **IMPLEMENTED (Task 1–10 selesai, `flutter analyze` bersih, 15 test KRS lulus)** — tersisa pengujian device (§12)

---

## 0. Sumber Legacy & Ringkasan Fitur

| Komponen Legacy | File |
|---|---|
| Sub menu KRS | `activity/krs/SubMenuKrsActivity.kt` + `layout/activity_sub_menu_krs.xml` |
| Lihat KRS | `activity/krs/KrsMKActivity.kt` + `layout/activity_krs_mkactivity.xml` + `adapter/KrsMhs.kt` + `model/KRSMKMhs.kt` |
| Input KRS | `activity/krs/InputKrsMKActivity.kt` + `layout/activity_input_krs_mkactivity.xml` + `adapter/KrsMKAdapterParentMakul.kt` + `adapter/KrsMKAdapterChilditemJadwal.kt` + `model/{KrsMKgetResponse,KrsMKpostResponse,KrsMKformatdata,KrsMKpilihjadwal}.kt` |
| Endpoint API | `retrofit/ApiEndpoint.kt` (baris 128–163) |
| Kode fitur subsripsi | `jni/api-keys.c` → `getkodeactivitykrs()` = **`krs@115`** |

Fitur yang WAJIB ada (sesuai permintaan):
1. **Lihat KRS** — daftar mata kuliah yang sudah diambil semester berjalan (+ info semester & total SKS).
2. **Input KRS** — pilih jadwal kelas per mata kuliah (satu jadwal per mata kuliah), lalu submit.
3. **Tolak bentrok jadwal saat Input KRS** — validasi overlap hari+jam terhadap pilihan mata kuliah lain, muncul snackbar merah dan pilihan DITOLAK.

Prinsip: **bisnis proses 100% sama dengan legacy**, gaya UI mengikuti halaman Flutter yang sudah ada (lihat `input_offers_page.dart`, `sub_menu_offers_page.dart`, `current_bills_page.dart`).

---

## 1. Pemetaan API (Terverifikasi dari Source Legacy)

Ketiga endpoint ada di **URL baru (APIV2)**: `https://akademik2.uinsalatiga.ac.id/smartmobile/APIV2/` — sudah menjadi `AppConstants.baseUrl` default di `ApiService` (tidak perlu `baseUrlLegacy`).

### 1.1 Tabel Endpoint

| Fitur | Method | Endpoint | Parameter | Enkripsi param | Response |
|---|---|---|---|---|---|
| Lihat KRS | GET | `krsservices/krs` | `unim`, **`kdpst`**, **`kdjen`** (hash) + `language` (plain) | BNI-hash | **Plain JSON** |
| List MK Input KRS | GET | `krsservices/list_krs_mk` | `unim`, **`kode_pst`**, **`kode_jen`** (hash) + `language` (plain) | BNI-hash | **Plain JSON** |
| Submit Input KRS | POST | `krsservices/input_krs_mata_kuliah` | form: `unim`, `kode_pst`, `kode_jen`, **`data_input_krs_mk`** (hash dari string JSON array) + `language` (plain) | BNI-hash | **Plain JSON** |

> ⚠️ **Perbedaan nama param antar endpoint (jangan tertukar!):**
> - `krsservices/krs` (Lihat KRS) memakai **`kdpst`** / **`kdjen`**.
> - `krsservices/list_krs_mk` & `krsservices/input_krs_mata_kuliah` (Input KRS) memakai **`kode_pst`** / **`kode_jen`**.

> ⚠️ **NIM di-hash APA ADANYA** (legacy KRS/PMK tidak melakukan filter digits-only — beda dengan modul tagihan). Jangan panggil `nimDigits()` di sini.

### 1.2 Headers

`Authorization` + `SMART-API-KEY` sudah terpasang global di `ApiService._dio` — tidak ada perubahan.

### 1.3 Payload Submit (field = JSON key persis)

```json
[
  {
    "kode_mk": "...", "nodos": "...", "sks_mk": 2,
    "jadwal_hari": "...", "jadwal_jam": "...",
    "jadwal_kelas": "...", "jadwal_ruang": "...", "isacc": "..."
  }
]
```

- Hanya item terpilih dengan **`isacc != "Y"`** yang ikut dikirim (legacy `create_data_post()` — MK yang sudah disetujui dosen wali TIDAK dikirim ulang).
- String JSON ini di-hash (`BniEncryption.hashData(json, cidV2, secretKeyV2)`) lalu dikirim sebagai field `data_input_krs_mk` — identik pola `submitPenawaran`.

### 1.4 Mapping Error (identik pola offers/legacy)

| Kondisi | Hasil |
|---|---|
| HTTP 200 | parse body (`success`, `message`, dst.) |
| non-200 | `success=false`, `message='error {code} {statusMessage}'` |
| GET gagal koneksi | `success=false`, `message=null` → state **noInternet** |
| POST gagal koneksi | `success=false`, `message='error {e}'` → dialog gagal (legacy `onFailure` menampilkan `"error {t}"`) |

### 1.5 Metode Baru di `api_service.dart`

```dart
Future<KrsResponse> getKrs({required String nim, required String kdjen, required String kdpst, String language = 'id'});          // GET krsservices/krs — param kdpst/kdjen
Future<KrsListResponse> getKrsList({required String nim, required String kdjen, required String kdpst, String language = 'id'}); // GET krsservices/list_krs_mk — param kode_pst/kode_jen
Future<KrsPostResponse> submitKrs({required String nim, required String kdjen, required String kdpst, required String dataJson, String language = 'id'}); // POST — param kode_pst/kode_jen
```

Ikuti persis pola `getPenawaranList` / `submitPenawaran` (queryParameters untuk GET; `Options(contentType: Headers.formUrlEncodedContentType)` untuk POST).

---

## 2. Model Data (Baru — field = JSON key persis legacy)

### 2.1 `krs_response.dart` (Lihat KRS — dari `KRSMKMhs.kt`)

```
KrsResponse:
  success: bool
  message: String?
  jatah_sks: int?              (tidak dipakai UI legacy — tetap dimodelkan)
  semester_berjalan: String?
  data: List<KrsItemMakul>?

KrsItemMakul:
  kode_mk: String
  paket_semester: int
  kelas: String
  makul: String
  sks: String                  ⚠️ STRING di response legacy (diparse toInt saat menjumlah)
  ruang: String
  waktu: String
  dosen: String
```

### 2.2 `krs_list_response.dart` (Input KRS — dari `KrsMKgetResponse.kt` + `KrsMKpostResponse.kt`)

```
KrsListResponse:               (juga dipakai sbg data response POST)
  success: bool
  message: String?
  waktu_mulai: String?
  waktu_selesai: String?
  data: List<KrsMataKuliah>?

KrsMataKuliah:
  kode_mk: String
  makul: String
  sks_mk: int
  semester_mk: int
  item_jadwal: List<KrsJadwal>

KrsJadwal:
  kode_mk: String
  makul: String
  dosen: String
  nodos: String?
  waktu: String
  kuota: int
  jmlh_peserta: int
  selected: String             (mutable "Y"/"T" — state server: sudah diambil mhs ini)
  issaved: String              ("Y" bila jadwal ini tersimpan oleh mhs)
  isacc: String                ("Y" bila sudah disetujui dosen wali)
  sks_mk: int
  jadwal_hari: String
  jadwal_jam: String           (format "HH.mm-HH.mm" / "HH,mm-HH,mm")
  jadwal_kelas: String
  jadwal_ruang: String

KrsPostResponse:
  success: bool
  message: String
  tgl_input: String
  data: List<KrsMataKuliah>?   (list terbaru setelah submit)
```

### 2.3 `krs_input_item.dart` (payload POST — dari `KrsMKformatdata.kt`)

```
KrsInputItem: kode_mk, nodos, sks_mk, jadwal_hari, jadwal_jam, jadwal_kelas, jadwal_ruang, isacc
  + toJson() dengan key persis di atas (untuk jsonEncode list)
```

---

## 3. Arsitektur & Struktur Folder

Feature-first + `setState` (tanpa BLoC/Provider) — konsisten project.

```
lib/features/krs/
├── data/
│   ├── models/
│   │   ├── krs_response.dart          # BARU — Lihat KRS (§2.1)
│   │   ├── krs_list_response.dart     # BARU — Input KRS get+post (§2.2)
│   │   └── krs_input_item.dart        # BARU — payload POST (§2.3)
│   └── krs_conflict_checker.dart      # BARU — pure function cek bentrok (§5.4)
└── presentation/
    └── pages/
        ├── sub_menu_krs_page.dart     # BARU — 2 menu (pola SubMenuOffersPage)
        ├── view_krs_page.dart         # BARU — Lihat KRS
        └── input_krs_page.dart        # BARU — Input KRS + tolak bentrok

lib/core/network/api_service.dart      # REVISI: +3 metode (§1.5)
lib/core/utils/subscription_gate.dart  # BARU (opsional, §6): dialog subsripsi non-blocking
lib/features/home/presentation/widgets/main_menu_grid.dart # REVISI: onTap menu KRS (§8)
lib/l10n/app_{id,en,ar}.arb            # REVISI: +13 key baru (§7)
test/krs_conflict_checker_test.dart    # BARU (§10)
test/krs_navigation_test.dart          # BARU (§10)
```

---

## 4. State Management

Pola sama dengan `input_offers_page.dart` — enum privat per halaman:

```dart
enum _KrsLoadState { loading, success, noData, serverError, noInternet }
```

Mapping dari `showdata()`/`show_data()` legacy (KRS & Input KRS identik):

| Kondisi response | State |
|---|---|
| `success == true && data != null` | `success` — list (bila kosong: info card tetap tampil + list kosong, sama legacy) |
| `success == true && data == null` | jatuh ke cabang error legacy → `message != null` ? `serverError` : `noInternet` |
| `success == false && message != null` | `serverError` (tampilkan `message`) |
| `success == false && message == null` | `noInternet` |

Loading = `SpinKitThreeBounce` (konsisten app-wide, pengganti shimmer legacy). Error/empty state pakai `ErrorStateWidget` (`lib/features/bills/presentation/widgets/error_state_widget.dart`). Refresh pakai `RefreshIndicator` (setara SwipeRefreshLayout legacy) — selalu `AlwaysScrollableScrollPhysics` agar pull-to-refresh tetap jalan di semua state.

**Semua load API dipicu via `Future.microtask(() => _loadX())` di `initState`** (context sudah siap) — konsisten permintaan & halaman lain.

---

## 5. Rencana Screen-by-Screen (Bisnis Proses = Legacy)

### 5.1 `sub_menu_krs_page.dart` — Sub Menu KRS

Sumber: `SubMenuKrsActivity.kt` + `activity_sub_menu_krs.xml`. **Duplikasi pola `sub_menu_offers_page.dart`** (gradient AppBar `[0xFF003D82, 0xFF0056B3]`, 2 kartu putih radius 24 + ikon kotak primary-10% + chevron).

- [ ] AppBar title: `l10n.krsSubmenuTitle` ("Sub Menu KRS").
- [ ] Kartu 1: ikon `Icons.menu_book_rounded` (setara `ic_books_primary`) + label `l10n.viewKrsTitle` ("Kartu Rencana Studi") → push `ViewKrsPage`.
- [ ] Kartu 2: ikon `Icons.bookmark_add_rounded` (setara `ic_baseline_bookmark_add_24`) + label `l10n.inputKrsTitle` ("Input KRS") → push `InputKrsPage`.

### 5.2 `view_krs_page.dart` — Lihat KRS

Sumber: `KrsMKActivity.kt` + `KrsMhs.kt` + `activity_krs_mkactivity.xml` + `view_krs_mhs.xml`.

- [ ] `initState` → `Future.microtask(() => _loadKrs())`.
- [ ] Ambil user session → `nim`, `kodeJen`, `kodePst` (nim apa adanya). `language = Localizations.localeOf(context).languageCode`.
- [ ] Panggil `getKrs(...)` → **param `kdpst`/`kdjen`** (§1.1).
- [ ] **Kartu Informasi** (kartu putih radius 24, pola `_buildInfoCard` offers; header "Informasi" + ikon info):
  - `KRS Semester` : `semester_berjalan ?? user.semester.toString()` (fallback persis legacy).
  - `Jumlah SKS disetujui` : total = `data.fold(0, (a, e) => a + int.parse(e.sks))` (legacy `PerhitunganAkademik().count_sks`).
  - Divider + teks peringatan bold: `l10n.krsNote` ("Untuk melihat KRS semester sebelumnya silahkan akses menu KHS").
- [ ] **Kartu item MK** per baris (header biru `AppColors.primary` + isi putih, sesuai `view_krs_mhs.xml`):
  - Header (teks putih): `{makul}`.
  - Grid 2 kolom label→nilai: `Kode MK` : `kode_mk` · `Paket Semester` : `paket_semester` · `SKS` : `sks` · `Kelas` : `kelas` · `Dosen` : `dosen` · `Jadwal` : `"{waktu} ({ruang})"`.
- [ ] `RefreshIndicator` → re-load (setara SwipeRefreshLayout).
- [ ] State §4 (`ErrorStateWidget`, ikon noData `Icons.description_rounded`).

### 5.3 `input_krs_page.dart` — Input KRS (INTI)

Sumber: `InputKrsMKActivity.kt` + `KrsMKAdapterParentMakul.kt` + `KrsMKAdapterChilditemJadwal.kt`.

#### 5.3.1 Load & struktur state

- [ ] `initState` → `Future.microtask(() => _loadKrsMk())`; `language` dari locale.
- [ ] `getKrsList(...)` → **param `kode_pst`/`kode_jen`**.
- [ ] State seleksi (pengganti static list legacy `pilihan_jadwal` / `value_kdkmk`) — **satu jadwal per mata kuliah**:
  ```dart
  // key = index mata kuliah (parent), value = index jadwal terpilih
  final Map<int, int> _selected = {};
  List<KrsMataKuliah> get _makul => _list?.data ?? [];
  ```
- [ ] Saat load/refresh → `_selected.clear()` (legacy me-reset static list saat refresh/back/onStop).
- [ ] **Auto-check saat load** (setara bind legacy): untuk tiap mata kuliah, bila ada jadwal dengan `selected == "Y"` → `_selected[i] = indexJadwal` (state server = sudah diambil). Dijalankan setelah parse sukses, sebelum render.

#### 5.3.2 Kartu Informasi (pola offers, konten legacy)

- [ ] Header "Informasi"; baris `Tanggal mulai pengisian KRS :` → `waktu_mulai`; `Tanggal akhir pengisian KRS :` → `waktu_selesai`.
- [ ] Divider + peringatan bold: `l10n.krsInputWarning` ("KRS yang sudah di setujui oleh dosen wali tidak dapat diubah kembali!") — warna `AppColors.danger`/amber agar terbaca sebagai warning.

#### 5.3.3 Kartu Mata Kuliah + baris jadwal (aturan legacy WAJIB)

Header kartu (biru primary, teks putih): `{makul} ({sks_mk} SKS)` · `Kode MK : {kode_mk}` · `Semester MK : {semester_mk}` (setara `view_krs_mk.xml`).

Setiap jadwal (`item_jadwal`) dirender sebagai baris selectable (setara `view_krs_jadwal_mk.xml`):

- [ ] Baris 1: `{dosen}` (+ badge **"Disetujui"** hijau/`Icons.bookmark_added_rounded` bila `selected == "Y" && isacc == "Y"` — legacy `statusacc`).
- [ ] Baris 2 (3 kolom): `Kelas : {jadwal_kelas}` · `Kuota : {kuota}` · `Sisa : {sisa}` dengan
  `sisa = selected == "Y" ? kuota - (jmlh_peserta + 1) : kuota - jmlh_peserta` (persis legacy — pilihan sendiri dihitung).
- [ ] Baris 3 chip waktu (bg primary, teks putih): bila `(jadwal_hari == null && jadwal_jam == null) || (jadwal_hari == "" && jadwal_jam == "")` → `l10n.notScheduled` ("Tidak Dijadwalkan"), selain itu tampilkan `{waktu}`.
- [ ] Checkbox di kanan (visual status terpilih; `CheckBox` non-interactive — tap lewat `InkWell` baris penuh, persis legacy `checkboxkrs.clickable=false`).
- [ ] **Baris DISABLED** (IgnorePointer + opacity) bila: `(jmlh_peserta >= kuota && issaved == "T") || isacc == "Y"` — penuh & bukan milik sendiri, atau sudah disetujui.
- [ ] **Tap baris aktif** → `_onTapJadwal(makulIndex, jadwalIndex)` (§5.3.4).

#### 5.3.4 Algoritma TOLAK BENTROK JADWAL (wajib port persis)

Implementasi sebagai **pure function** di `krs_conflict_checker.dart` agar bisa di-unit-test:

```dart
/// Mengembalikan nama_makul yang bentrok, atau null jika aman.
String? findConflict({
  required Iterable<({String? hari, String? jam, String? namaMakul})> selected, // pilihan saat ini (makul LAIN)
  required String? targetHari,
  required String? targetJam,
  required String targetNamaMakul,
})
```

Aturan (port 1:1 dari `KrsMKAdapterChilditemJadwal.check()`):

1. Bandingkan **hanya terhadap pilihan makul LAIN** (`row.nama_makul != jadwal.makul`).
2. Syarat prasyarat: `row.jadwal_hari == target.jadwal_hari` DAN `row.jadwal_hari != ""` DAN `target.jadwal_hari != null` DAN `row.jadwal_jam != ""` DAN `target.jadwal_jam != null`.
3. Parse jam: split `"-"` → kedua sisi harus menghasilkan 2 bagian; ganti `[,.]` dengan `:` (contoh `"07.30-09.10"` / `"07,30-09,10"` → `07:30`/`09:10`); parse format `HH:mm`.
4. **Bentrok bila** (`A` = terpilih baru, `B` = tersimpan):
   ```
   (A.start >= B.start && A.start < B.end)   // mulai di tengah jadwal B
   || (A.end > B.start && A.end < B.end)      // selesai di tengah jadwal B
   || (A.start <= B.start && A.end >= B.end)  // melingkupi penuh B
   ```
5. Return `nama_makul` baris pertama yang bentrok.

Perilaku `_onTapJadwal` (port dari click listener legacy):

```
bila jadwal target sedang TIDAK terpilih (selected state "T"):
    conflict = findConflict(...) terhadap semua pilihan makul lain
    bila conflict != null →
        TAMPILKAN SNACKBAR MERAH ATAS: l10n.scheduleConflict(conflict)
        (ikon error_outline, background AppColors.danger, behavior floating,
         posisi atas → bungkus ScaffoldMessenger; pilihan DITOLAK — return)
bila tidak bentrok:
    toggle:
      - bila jadwal ini adalah pilihan saat ini di makul tersebut → hapus pilihan makul (uncheck)
      - else → set _selected[makulIndex] = jadwalIndex  (otomatis mengganti jadwal lain
        pada makul yang sama — perilaku radio legacy: jadwal lain di-set "T")
```

> Snackbar legacy: gravity TOP, background merah, ikon `ic_outline_error_outline_24`, teks `"Gagal,terjadi benturan jadwal dengan mata kuliah {makul}"`. Padanannya Flutter: `ScaffoldMessenger.showSnackBar` + `SnackBarBehavior.floating` + warna danger + `Icon` error di content.

#### 5.3.5 Bottom bar (pola offers, konten legacy)

- [ ] Hanya tampil saat state `success` (setara tombol disabled legacy saat loading).
- [ ] Teks kecil: `l10n.krsTotalLabel` ("Jumlah KRS Mata Kuliah"); teks bold: `l10n.selectedCoursesCount(nMakul, nSks)` — `nMakul = _selected.length`, `nSks = Σ sks_mk jadwal terpilih`.
- [ ] Tombol **Simpan** (`l10n.save`): enabled ⇔ ada ≥1 item payload (`_postPayload().isNotEmpty`).
- [ ] ⚠️ Tombol di dalam `Row` → override `minimumSize: const Size(0, 48)` (gotcha theme global — lihat plan Tagihan §4.1).

#### 5.3.6 Submit (port `api_post_krsmk` + `create_data_post`)

- [ ] Payload = `jsonEncode([KrsInputItem...])` dari semua jadwal terpilih dengan **`isacc != "Y"`** (MK disetujui tidak dikirim ulang).
- [ ] Klik Simpan → dialog loading non-dismissible (`SpinKitThreeBounce` + `l10n.pleaseWait`, setara animasi flying_plane) → `submitKrs(...)`.
- [ ] Response sukses (`success=true`) → dialog sukses (ikon check hijau, `message`) → OK → **ganti `_list.data` dengan `response.data`** (list terbaru, jadwal yang tersimpan kini `selected="Y"`), `_selected.clear()`, jalankan ulang auto-check (§5.3.1) — persis legacy yang re-bind adapter dari `data` POST.
- [ ] Response gagal → dialog gagal (ikon cancel merah, `message`).
- [ ] Tutup dialog loading dengan `Navigator.of(context, rootNavigator: true).pop()` sebelum menampilkan hasil (pola offers).

#### 5.3.7 Subsripsi (parity legacy)

- [ ] (Lihat §6) Panggil gate subsripsi dengan kode **`krs@115`** sekali di `initState` halaman Input KRS — dialog only, non-blocking (persis legacy `SubscriptionUtils.checkSubscription`).

---

## 6. Gate Subsripsi `krs@115` (opsional-paritas, reusable)

Legacy: `InputKrsMKActivity` memanggil `checkSubscription(kodeactivitykrs)` → dialog muncul bila `modesubscribe == "S" && angkatan >= minangkatansubs && lockfitur.contains("krs@115") && now > batassubscribe` — **tidak memblokir fitur**.

Field sudah tersedia di `LoginData` (`modeSubscribe`, `angkatan`, `minAngkatanSubs`, `lockFitur`, `batasSubscribe`).

- [ ] BARU `lib/core/utils/subscription_gate.dart`: helper `void checkSubscription(BuildContext context, String kodeFitur)` — parse `batasSubscribe` (`yyyy-MM-dd HH:mm:ss`), kondisi di atas, tampilkan dialog info (pola dialog offers, non-barrier `barrierDismissible: true`).
- [ ] Panggil dari `input_krs_page.dart` dengan `kodeFitur = 'krs@115'`.
- [ ] Catatan: modul offers belum memasang gate (`pmk@114`) — bila helper ini jadi, pasang juga di `input_offers_page.dart` sebagai tindak lanjut (di luar scope plan ini).

---

## 7. l10n — Kunci Baru (3 bahasa: id / en / ar)

Template `app_id.arb` → jalankan `flutter gen-l10n`. Placeholder `{course}` pakai format `({course})` di placeholders meta (pola `selectedCoursesCount`).

| Key (baru) | id | en | ar |
|---|---|---|---|
| `krsSubmenuTitle` | Sub Menu KRS | CSS Sub Menu | القائمة الفرعية للخطة الدراسية |
| `viewKrsTitle` | Kartu Rencana Studi | Course Selection Sheet | الخطة الدراسية (KRS) |
| `inputKrsTitle` | Input KRS | Entry CSS | إدخال الخطة الدراسية |
| `krsSemesterLabel` | KRS Semester | CSS Semester | خطة الفصل الدراسي |
| `approvedSksLabel` | Jumlah SKS disetujui | Approved Credits | إجمالي الساعات المعتمدة |
| `krsNote` | Untuk melihat KRS semester sebelumnya silahkan akses menu KHS | To view the previous semester CSS, please access the Study Result menu | لعرض خطة الفصل السابق، يرجى الدخول إلى قائمة نتائج الدراسة (KHS) |
| `krsInputStartLabel` | Tanggal mulai pengisian KRS : | Start date input CSS : | تاريخ بدء إدخال الخطة الدراسية : |
| `krsInputEndLabel` | Tanggal akhir pengisian KRS : | End date input CSS : | تاريخ انتهاء إدخال الخطة الدراسية : |
| `krsInputWarning` | KRS yang sudah di setujui oleh dosen wali tidak dapat diubah kembali! | CSS that has been approved by the guardian lecturer cannot be changed again! | لا يمكن تغيير الخطة الدراسية بعد موافقة المرشد الأكاديمي! |
| `scheduleConflict` ({course}) | Gagal, terjadi benturan jadwal dengan mata kuliah {course} | Failed, there was a schedule conflict with the {course} courses | فشل، يوجد تعارض في الجدول مع مادة {course} |
| `notScheduled` | Tidak Dijadwalkan | Not Scheduled | غير مجدول |
| `classLabel` | Kelas | Class | الشعبة |
| `quotaLabel` | Kuota | Quota | السعة |
| `remainingLabel` | Sisa | Remaining | المتبقي |
| `approvedBadge` | Disetujui | Approved | معتمد |
| `courseCode` | Kode MK | Course Code | رمز المادة |
| `krsTotalLabel` | Jumlah KRS Mata Kuliah | Total KRS Courses | إجمالي مواد الخطة |

**Reuse (sudah ada):** `krs`, `semester`, `save`, `information`, `pleaseWait`, `okButton`, `selectedCoursesCount`, `semesterPackage`, `credit` (SKS), `lecturer` (Dosen), `checkConnection`.

> en untuk istilah "KRS" mengikuti legacy yang memakai "CSS (Course Selection Sheet)"; judul halaman tetap bisa tampil "KRS" di grid (key `krs` sudah ada).

---

## 8. Wiring Menu Utama

`lib/features/home/presentation/widgets/main_menu_grid.dart`:

- [ ] Import `sub_menu_krs_page.dart`.
- [ ] Tambah cabang `else if (menu['label'] == l10n.krs)` → `Navigator.push(... SubMenuKrsPage())` (item KRS sudah ada di grid, hanya belum punya onTap).

---

## 9. Konsistensi Desain (wajib mengikuti halaman existing)

- AppBar: `toolbarHeight: 70`, bg `0xFF003D82`, `flexibleSpace` gradient `[0xFF003D82 → 0xFF0056B3]`, back `arrow_back_ios_new_rounded` putih, title putih bold 18 — pola semua halaman.
- Background `AppColors.background`; kartu putih `BorderRadius.circular(24)` + shadow lembut.
- Loading `SpinKitThreeBounce(color: AppColors.primary, size: 30)` dalam `ListView` + `AlwaysScrollableScrollPhysics` (agar RefreshIndicator tetap aktif).
- Semua load via `Future.microtask`; semua refresh via `RefreshIndicator` (padanan SwipeRefreshLayout).
- Error/empty: `ErrorStateWidget` + enum §4.
- Gotcha lint (dari memo repo): `ListView` tidak const; `Directory` tidak const; tombol dalam `Row` override `minimumSize: Size(0, 48)`.

---

## 10. Testing

- [ ] `test/krs_conflict_checker_test.dart` (unit, pure function):
  - overlap penuh (`07.00-09.00` vs `07.00-09.00`) → bentrok;
  - mulai di tengah (`08.00-10.00` vs `07.00-09.00`) → bentrok;
  - berakhir di tengah (`06.00-08.00` vs `07.00-09.00`) → bentrok;
  - melingkupi (`06.00-10.00` vs `07.00-09.00`) → bentrok;
  - **berdampingan (`09.00-11.00` vs `07.00-09.00`) → TIDAK bentrok** (batas pakai `<`/`>` ketat);
  - hari berbeda → aman; makul sama → tidak dicek; format koma `07,30-09,10` terparse; `null`/`""` → aman.
- [ ] `test/krs_navigation_test.dart` (widget, pola `bills_navigation_test.dart`): mock `SharedPreferences` sesi → buka `SubMenuKrsPage` → tap kartu Lihat KRS → halaman terbuka → back → tap kartu Input KRS → halaman terbuka → back.

---

## 11. Urutan Task

| # | Task | File |
|---|---|---|
| 1 | Model 3 file (§2) | `lib/features/krs/data/models/*` |
| 2 | Conflict checker (§5.3.4) | `lib/features/krs/data/krs_conflict_checker.dart` |
| 3 | Metode API 3 (§1.5) | `lib/core/network/api_service.dart` |
| 4 | Kunci l10n 3 bahasa + `flutter gen-l10n` (§7) | `lib/l10n/app_{id,en,ar}.arb` |
| 5 | `SubMenuKrsPage` (§5.1) | `lib/features/krs/presentation/pages/sub_menu_krs_page.dart` |
| 6 | `ViewKrsPage` Lihat KRS (§5.2) | `.../view_krs_page.dart` |
| 7 | `InputKrsPage` Input KRS + tolak bentrok + submit (§5.3) | `.../input_krs_page.dart` |
| 8 | Gate subsripsi `krs@115` (§6) | `lib/core/utils/subscription_gate.dart` |
| 9 | Wiring menu grid (§8) | `main_menu_grid.dart` |
| 10 | Tests (§10) + verifikasi | `test/krs_*` |

## 12. Verifikasi Akhir

1. `flutter gen-l10n` — tidak ada error placeholder.
2. `flutter analyze` — bersih (tanpa error baru).
3. `flutter test` — semua lulus.
4. Uji device: pilih 2 jadwal bentrok → snackbar merah & pilihan ditolak; pilih jadwal berdampingan jam tepat → boleh; MK `isacc=Y` terkunci + badge Disetujui; submit sukses → list ter-refresh otomatis (MK tersimpan tercentang).
