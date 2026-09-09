# Implementation Plan — Migrasi Fitur EDOM (Evaluasi Dosen / Edom)

> **Legacy:** `MOBILE-SMARTMHS` (Kotlin) · **Target:** `smartmahsiswaflutter` (Flutter)
> Dibuat: 2026-09-09 · Status: **NOT STARTED** (menu grid "EDOM" sudah ada, navigasi belum tersambung; dialog `cekeval` di offers masih TODO)

---

## 0. Sumber Legacy & Ringkasan Fitur

| Komponen Legacy | File |
|---|---|
| List Semester Evaluasi | `activity/edom/PilihSemesterEvaluasiActivity.kt` + `adapter/SemesterEvalAdapter.kt` + `model/SemesterEdomResponse.kt` + `layout/view_semester_eval.xml` |
| List Mata Kuliah Evaluasi | `activity/edom/PilihMakulEvaluasiActivity.kt` + `adapter/MakulEvalAdapter.kt` + `model/MakulEdomResponse.kt` + `layout/view_makul_eval.xml` |
| Penilaian Evaluasi | `activity/edom/PenilaianMakulEvaluasiActivity.kt` + `adapter/{Evalindikator,EvalSoal,EvalJawaban}Adapter.kt` + `model/{ListSoalEvalResponse,EvalPostformatdata,PostEvalResponse,PostEncData}.kt` |
| Endpoint API | `retrofit/ApiEndpoint.kt` baris 424–456 |
| Validasi saran | `form_validation/CustomValidation.kt` → `seterrorvalidation_on_saran()` (min 8 karakter) |
| Kode fitur subsripsi | `jni/api-keys.c` → `getkodeactivityed()` = **`ed@118`** |

Fitur WAJIB (sesuai permintaan):
1. **List Semester Evaluasi** — kartu per semester + badge status (Selesai / Proses Pengisian / Belum Mengisi) + tombol "Isi / Detail Evaluasi".
2. **List Mata Kuliah Evaluasi** — kartu per MK: nama dosen, **foto dosen**, **rating dosen** (bintang), **komentar** yang diberikan (jika ada), tombol **Riwayat** (aktif hanya jika sudah selesai) & tombol **Isi/Pengisian** (aktif hanya jika belum selesai).
3. **Halaman penilaian evaluasi** — chip indikator kompetensi + pager soal (1 soal per halaman) + pilihan jawaban radio; **wajib semua pertanyaan terjawab** dan **komentar (kesan & pesan) minimal 8 karakter** sebelum submit; mode **Riwayat** (read-only, jawaban terisi dari server).

Prinsip: bisnis proses 100% sama dengan legacy; gaya UI mengikuti halaman Flutter existing (AppBar gradient, kartu radius 24, `ErrorStateWidget`, notifikasi via `AppNotifications`).

---

## 1. Pemetaan API (Terverifikasi dari Source Legacy)

Semua endpoint di **URL baru (APIV2)** = `AppConstants.baseUrl` (default `ApiService`). NIM di-hash **apa adanya** (TIDAK ada filter digits — sama seperti KRS/PMK). `language` plain.

### 1.1 Tabel Endpoint

| Fitur | Method | Endpoint | Parameter | Enkripsi param | Response |
|---|---|---|---|---|---|
| List Semester | GET | `Edomservices/list_semester_evaluasi` | `unim` (hash) + `language` (plain) | BNI-hash | Plain JSON |
| List Makul | GET | `Edomservices/list_makul_evaluasi` | `unim` (hash), `thsms` (hash) + `language` | BNI-hash | Plain JSON |
| List Soal | GET | `Edomservices/list_soal_evaluasi` | `ideval` (hash) + `language` | BNI-hash | Plain JSON |
| Simpan Evaluasi | POST | `Edomservices/simpan_eval_dosen` | **JSON body** `{"data": "<hash>"}` | BNI-hash | Plain JSON |

> ⚠️ **POST berbeda dari modul lain**: bukan form-urlencoded melainkan **JSON body** (`@Headers("Content-Type: application/json")` + `@Body PostEncData`) dengan satu field `data` = BNI-hash dari JSON `verEvalPost`.

### 1.2 Mapping Error (PERHATIAN — beda dari modul lain!)

Legacy EDOM pada `onFailure` membangun `message = "error ${t.message}"` (**tidak pernah null**) → state no-internet tidak pernah muncul; semua kegagalan tampil sebagai pesan error "error …":

| Kondisi | Hasil |
|---|---|
| HTTP 200 | parse body |
| non-200 | `success=false`, `message='error {code} {message}'` |
| Gagal koneksi (GET) | `success=false`, `message='error {e}'` → **serverError** (bukan noInternet) |
| POST gagal body null | `message` fallback `notif_error_response_api` ("Periksa koneksimu, Tidak dapat terhubung ke server") |
| POST gagal koneksi | `message='error {e}'` |

### 1.3 Payload Submit (field = nama properti Gson legacy, PERSIS)

JSON `verEvalPost` yang di-hash lalu dikirim sebagai `data`:

```json
{
  "nim": "...",
  "validate": true,
  "errorvalidatemessage": "",
  "language": "id",
  "datapost": [
    { "idkompetensi": "...", "idsoal": "...", "jawaban": "<indexpilihan>", "bobotjawaban": "<value>" }
  ],
  "saran": "...",
  "ideval": "..."
}
```

- **Semua soal ikut dikirim**; soal yang belum dijawab tetap masuk `datapost` dengan `jawaban: "-"`, `bobotjawaban: "-"`.
- `validate` = semua soal terjawab; `errorvalidatemessage` = pesan soal pertama yang belum dijawab (string kosong bila valid).
- Response POST: `{success, message, rating: double?, komentar: string}`.

### 1.4 Metode Baru di `api_service.dart`

```dart
Future<EdomSemestersResponse> getEdomSemesters({required String nim, String language = 'id'});
Future<EdomCoursesResponse> getEdomCourses({required String nim, required String thsms, String language = 'id'});
Future<EdomQuestionsResponse> getEdomQuestions({required String ideval, String language = 'id'});
Future<EdomPostResponse> submitEdomEvaluation({required String dataJson}); // POST JSON {"data": hash}
```

GET → pola `getKrsList` (queryParameters, hash param, plain language) TAPI catch → `message='error {e}'` (bukan null). POST → `_dio.post(..., data: {'data': BniEncryption.hashData(dataJson, cidV2, secretKeyV2)})` dengan `Options(contentType: Headers.jsonContentType)`.

---

## 2. Model Data (Baru — field = JSON key persis legacy)

### 2.1 `edom_semester_response.dart`

```
EdomSemestersResponse: success: bool, message: String?, data: EdomPeriode?
EdomPeriode: thsmt_pengisian: String, data_tahun: List<EdomItemSemester>
EdomItemSemester: thsms: String, semester: String,
                  kodeStatusEval: int (mutable), keteranganStatus: String (mutable)
```

### 2.2 `edom_makul_response.dart`

```
EdomCoursesResponse: success, message, data: List<EdomMakulEval>?
EdomMakulEval: ideval, namamkeval, kdmkeval, kelasmkeval, doseneval,
               urlfotodoseneval, rating: double, komentar: String,
               statusEval: String (mutable "0"|"1"|"2")
```

### 2.3 `edom_soal_response.dart`

```
EdomQuestionsResponse: success, message, data: List<EdomIndikator>?
EdomIndikator: idkompetensi, namakompetensi, itemsoal: List<EdomSoal>
EdomSoal: idsoal, idkompetensi, pertanyaan, urlimage: String?,
          itemjawaban: List<EdomJawaban>
EdomJawaban: pilihan, indexpilihan, terjawab: String (mutable "Y"/"N"), value
```

### 2.4 `edom_post_models.dart`

```
EdomPostItem: idkompetensi, idsoal, jawaban, bobotjawaban → toJson key persis
EdomPostData: nim, validate, errorvalidatemessage, language,
              datapost: List<EdomPostItem>, saran, ideval → toJson key persis
EdomPostResponse: success, message, rating: double?, komentar: String
```

---

## 3. Arsitektur & Struktur Folder

```
lib/features/edom/
├── data/
│   ├── models/
│   │   ├── edom_semester_response.dart   # BARU (§2.1)
│   │   ├── edom_makul_response.dart      # BARU (§2.2)
│   │   ├── edom_soal_response.dart       # BARU (§2.3)
│   │   └── edom_post_models.dart         # BARU (§2.4)
│   └── edom_eval_validator.dart          # BARU — pure fn validasi + build payload (§6.3)
└── presentation/
    └── pages/
        ├── edom_semesters_page.dart      # BARU — List Semester Evaluasi
        ├── edom_courses_page.dart        # BARU — List Mata Kuliah Evaluasi
        └── edom_form_page.dart           # BARU — Penilaian evaluasi (pager soal)

lib/core/network/api_service.dart         # REVISI: +4 metode (§1.4)
lib/core/utils/subscription_gate.dart     # REVISI: + ed@118
lib/features/home/presentation/widgets/main_menu_grid.dart  # REVISI: onTap EDOM (§8)
lib/features/offers/presentation/pages/input_offers_page.dart # REVISI: dialog cekeval → navigasi EDOM (§8)
lib/l10n/app_{id,en,ar}.arb               # REVISI: +~16 key (§7)
test/edom_eval_validator_test.dart        # BARU (§9)
test/edom_navigation_test.dart            # BARU (§9)
```

State per halaman: enum privat `{loading, success, serverError}` — **tanpa noInternet** (legacy EDOM selalu menampilkan "error …" saat gagal koneksi, §1.2). Page soal menambah tombol **Coba Lagi** pada state error (legacy `buttoncobalagi` hanya di halaman penilaian).

---

## 4. Rantai Navigasi & Propagasi Hasil (port resultLauncher legacy)

```
Home grid "EDOM" ──► EdomSemestersPage ──► EdomCoursesPage(thsms) ──► EdomFormPage(ideval, {viewOnly})
     ▲                    ▲  pop result         ▲  pop result              │ sukses simpan:
     │                    │                     │                          │ pop {statusEval:'2', rating, komentar}
     └────────────────────┘                     │  update item (jika lama ≠ '2' & berubah):
        update kodestatuseval +                 └── update item statuseval/rating/komentar
        keteranganstatus="Proses Pengisian"         (jika lama ≠ '2' & berubah)
        (jika lama ≠ 2 & berubah)
```

- `EdomFormPage` → `Navigator.pop(context, EdomFormResult(rating, komentar))` **hanya setelah POST sukses** (dialog OK). Keluar via tombol back/konfirmasi → pop **tanpa result** (jawaban tidak disimpan — persis legacy).
- `EdomCoursesPage` → back: `pop(EdomCoursesResult(statusApi, statusEval))` dengan `statusApi` = sukses load terakhir, `statusEval` = `"1"` bila ada item ber-status `"0"`/`"1"`, selain itu `"2"`.
- `EdomSemestersPage` → `await Navigator.push` lalu update item sesuai aturan di atas (keterangan status hard-coded ID legacy → pakai l10n `edomStatusProgress`).

---

## 5. Rencana Screen-by-Screen (Bisnis Proses = Legacy)

### 5.1 `edom_semesters_page.dart` — List Semester Evaluasi

Sumber: `PilihSemesterEvaluasiActivity.kt` + `SemesterEvalAdapter.kt`.

- [ ] `initState` → `Future.microtask(() => _loadSemesters())`; param `unim`(hash nim as-is) + `language`.
- [ ] Gate subsripsi `ed@118` (dialog only) sekali di initState.
- [ ] `RefreshIndicator` (padanan SwipeRefreshLayout) → reload.
- [ ] Item kartu (radius 24, shadow lembut):
  - Header area berwarna (gradient primary, setara ilustrasi `evalbg` legacy) + judul **"Semester {semester}"**.
  - Badge status pill sesuai `kodeStatusEval`: `2` → hijau "Selesai" · `1` → amber "Proses Pengisian" · `0` → merah "Belum Mengisi" (warna solid + teks putih, setara circle_object legacy).
  - Tombol teks primary **"Isi / Detail Evaluasi"** → push `EdomCoursesPage(itemSemester, index)` (await result, §4).
- [ ] Error state: `ErrorStateWidget(serverError, message)`; loading `SpinKitThreeBounce` dalam `ListView` + `AlwaysScrollableScrollPhysics`.

### 5.2 `edom_courses_page.dart` — List Mata Kuliah Evaluasi

Sumber: `PilihMakulEvaluasiActivity.kt` + `MakulEvalAdapter.kt` + `view_makul_eval.xml`.

- [ ] Terima `EdomItemSemester` + index (untuk result chain §4).
- [ ] `Future.microtask` load `getEdomCourses(nim, thsms, language)` — `thsms` di-hash.
- [ ] Gate subsripsi `ed@118`.
- [ ] `RefreshIndicator` → reload.
- [ ] Item kartu per MK:
  - **Foto dosen** lingkaran (`urlfotodoseneval`) — `Image.network` + `errorBuilder` fallback ikon `person_rounded` abu (setara placeholder/error Glide legacy).
  - Nama MK (`namamkeval`) bold + **badge status** transparan ber-teks berwarna: `2` hijau "Selesai" · `1` biru "Proses Pengisian" · `0` amber "Belum Mengisi".
  - Nama dosen (`doseneval`).
  - **Rating dosen**: baris 5 ikon bintang kecil terisi sesuai `rating` (non-interaktif — setara `ratingBarStyleSmall` legacy; tanpa angka).
  - **Komentar** (`komentar`) — tampil hanya bila tidak kosong/null (legacy VISIBLE/GONE).
  - Dua tombol di kanan-bawah:
    - **Riwayat** — enabled HANYA `statusEval == "2"` → push `EdomFormPage(makul, viewOnly: true)` (tanpa index — tidak mengubah data).
    - **Isi Penilaian** — enabled HANYA `statusEval != "2"` → push `EdomFormPage(makul, index)` await result → update item `statusEval/rating/komentar` bila lama ≠ `"2"` dan berubah (§4).
- [ ] Status computed untuk pop result dihalaman ini dihitung saat back (WillPopScope/PopScope + tombol back AppBar).

### 5.3 `edom_form_page.dart` — Penilaian Evaluasi (INTI)

Sumber: `PenilaianMakulEvaluasiActivity.kt` + adapter indikator/soal/jawaban.

#### 5.3.1 Struktur & load

- [ ] Param: `EdomMakulEval makul`, `int? index` (null = mode riwayat), derived `viewOnly = index == null`.
- [ ] `Future.microtask` load `getEdomQuestions(ideval, language)` — `ideval` di-hash.
- [ ] Gate subsripsi `ed@118`.
- [ ] AppBar custom: tombol back → `exit_confirm` (§5.3.5); foto dosen kecil + nama dosen.
- [ ] Header halaman: foto dosen lingkaran + `doseneval` (fallback ikon person).
- [ ] **Chip indikator** horizontal (`namakompetensi` per `EdomIndikator`): chip aktif = stroke primary solid (setara `bg_rounded_stroke_primary_button`), tidak aktif stroke tipis; tap → pindah indikator + reset ke soal pertama indikator itu.
- [ ] **Pager soal** (`PageView`, 1 soal per halaman, `PageScrollPhysics`): nomor soal (`{n}. {pertanyaan}`), gambar soal opsional (`urlimage` bila tidak kosong — `Image.network`), daftar **jawaban radio** (indexpilihan + pilihan, ikon lingkaran/centang). `viewOnly` → semua interaksi disabled (IgnorePointer).
- [ ] **Progress** `LinearProgressIndicator` + teks indeks global `"{current} / {total}"`; offset global soal = jumlah soal indikator sebelumnya (padanan `numstartindex` legacy). `max` progress = total soal − 1.
- [ ] Tombol **Prev**: bukan soal pertama indikator → soal sebelumnya; sebaliknya → indikator sebelumnya pada soal TERAKHIRNYA (padanan `prev_data`).
- [ ] Tombol **Next**: bukan soal terakhir indikator → soal berikutnya; sebaliknya bila indikator terakhir → **selesai** (§5.3.3); bukan indikator terakhir → indikator berikutnya soal pertama (`next_data`). Mode `viewOnly` di soal terakhir indikator terakhir → Next disabled (legacy).
- [ ] ⚠️ **Deviasi disetujui**: legacy hanya me-render soal bila jumlah indikator > 1 (indikator tunggal → pager kosong, bug). Flutter harus menampilkan soal untuk jumlah indikator berapa pun.
- [ ] State error: `ErrorStateWidget` + tombol **Coba Lagi** → reload (legacy `buttoncobalagi`).

#### 5.3.2 Interaksi jawaban (port `EvalJawabanAdapter`)

- [ ] Tap jawaban → tandai `terjawab = "Y"` untuk jawaban itu dan `"N"` untuk semua jawaban lain pada soal yang sama (radio per soal; boleh toggle-off kembali — legacy memungkinkan Y→N saat tap ulang).
- [ ] `viewOnly` → tidak ada tap.

#### 5.3.3 Validasi & payload (port `create_data_post`) — pure function §6.3

- [ ] Next di soal terakhir indikator terakhir (dan bukan `viewOnly`) → validasi SEMUA soal semua indikator:
  - Semua terjawab → lanjut dialog saran.
  - Ada yang belum → dialog error merah: **"Silahkan lengkapi jawaban pada indikator {namakompetensi} nomor {nosoal}"** (soal pertama yang kosong) — tetap build payload dengan "-" (payload hanya dikirim setelah valid + saran).
- [ ] **Dialog Kesan Pesan** (judul `edomImpressionTitle`): instruksi `edomImpressionInstruction`, TextField multiline, isi awal = saran tersimpan (dipertahankan bila dialog dibuka ulang — `saransaved` legacy), validasi **minimal 8 karakter** → error `edomImpressionMinError`; OK → build `EdomPostData` → `jsonEncode` → hash → submit.

#### 5.3.4 Submit (port `apiposteval`)

- [ ] Dialog loading non-dismissible: "Menyimpan jawaban anda" + tombol disabled "Mohon tunggu" (setara flying_plane).
- [ ] `submitEdomEvaluation(dataJson)`; sukses (`success && message != null`) → dialog sukses (ikon check hijau + `message` + rating bintang hasil `response.rating`) → OK → pop `EdomFormResult(rating, komentar)` (statusEval="2").
- [ ] Gagal → dialog error merah (`message` fallback `errorResponseApi`).
- [ ] Notifikasi & dialog mengikuti komponen terpadu (`AppNotifications` untuk snackbar; dialog pola offers).

#### 5.3.5 Keluar tanpa simpan (port `exit_confirm`)

- [ ] Back (AppBar / sistem) saat BUKAN `viewOnly` → dialog konfirmasi: judul **"Apakah anda yakin?"**, pesan **"Jika anda keluar sekarang jawaban tidak akan disimpan"**, tombol OK (primary) keluar tanpa result, Batal tetap.
- [ ] `viewOnly` → langsung pop tanpa dialog.

### 5.4 Validator — `edom_eval_validator.dart` (pure, testable)

```dart
class EdomValidationResult {
  final bool validate; final String errorMessage; final List<EdomPostItem> payload;
}
EdomValidationResult buildEdomPayload({
  required List<EdomIndikator> indikators, required String l10n-based errorTemplate(...),
});
```

Aturan: iterate indikator → soal; terjawab → item `{idkompetensi, idsoal, jawaban: indexpilihan, bobotjawaban: value}`; kosong → item `"-"`,`"-"` + `validate=false` + pesan soal kosong PERTAMA. (Error message dibangun di caller dengan l10n placeholder; validator menerima template fn agar tetap pure.)

---

## 6. l10n — Kunci Baru (id / en / ar)

> Legacy hanya punya id & en (tidak ada values-ar) — Arab diterjemahkan baru. EN mengikuti teks legacy.

| Key | id (legacy) | en (legacy) | ar (baru) |
|---|---|---|---|
| `edomSemestersTitle` | Semester Evaluasi | Semester Evaluation | تقييم الفصول الدراسية |
| `edomCoursesTitle` | Mata Kuliah Evaluasi | Evaluation Course | مواد التقييم |
| `edomStatusDone` | Selesai | Finish | مكتمل |
| `edomStatusProgress` | Proses Pengisian | Filling Process | قيد التعبئة |
| `edomStatusNotFilled` | Belum Mengisi | Not Completed | لم يُملأ |
| `edomOpenDetail` | Isi / Detail Evaluasi | Form filling / Evaluation Details | تعبئة / تفاصيل التقييم |
| `edomHistoryButton` | Riwayat | History | السجل |
| `edomFillButton` | Isi Penilaian | Rating | تعبئة التقييم |
| `edomFillAllQuestionsError` ({indicator},{number}) | Silahkan lengkapi jawaban pada indikator {indicator} nomor {number} | Please complete the answers in indicator {indicator} number {number} | يرجى إكمال الإجابة على المؤشر {indicator} رقم {number} |
| `edomImpressionTitle` | Kesan Pesan | Impression | الانطباع والرسالة |
| `edomImpressionInstruction` | Tuliskan komentar,kesan pesan atau saran minimal 8 karakter. Nama anda tidak akan ditampilkan di dashboard dosen | Write comments, impressions, messages or suggestions of at least 8 characters. Your name will not be displayed on the lecturer dashboard | اكتب تعليقًا أو انطباعًا أو اقتراحًا بحد أدنى 8 أحرف. لن يظهر اسمك في لوحة المحاضر |
| `edomImpressionMinError` | Kesan Pesan minimal 8 karakter | Impression of at least 8 characters | الانطباع يجب أن يكون 8 أحرف على الأقل |
| `edomSaving` | Menyimpan jawaban anda | Save your answer | جارٍ حفظ إجابتك |
| `edomExitConfirmTitle` | Apakah anda yakin? | Are you sure? | هل أنت متأكد؟ |
| `edomExitConfirmMessage` | Jika anda keluar sekarang jawaban tidak akan disimpan | If you exit now the answer will not be saved | إذا خرجت الآن فلن يتم حفظ الإجابة |
| `errorResponseApi` | Periksa koneksimu, Tidak dapat terhubung ke server | Check your connection, Unable connect to server | تحقق من اتصالك، تعذر الاتصال بالخادم |
| `tryAgain` | Coba Lagi | Try Again | حاول مرة أخرى |

**Reuse (sudah ada):** `semester`, `pleaseWait`, `okButton`, `cancel`, `save`, `information`, `lecturer`, `checkConnection` (tidak dipakai untuk state — lihat §1.2).

---

## 7. Wiring Menu & Integrasi Offers

- [ ] `main_menu_grid.dart`: onTap menu **EDOM** → push `EdomSemestersPage()` (legacy: home grid → PilihSemesterEvaluasiActivity).
- [ ] `subscription_gate.dart`: tambah `static const String edom = 'ed@118';` di `SubscriptionGateFeatures`; panggil `checkSubscription` di **ketiga** halaman EDOM (legacy memanggil di semua).
- [ ] `input_offers_page.dart` — ganti TODO dialog `cekeval == false`: tombol "Isi Penilaian Dosen" → push `EdomSemestersPage()` lalu pop offers input page (legacy: navigasi ke EDOM + `finish()`).

---

## 8. Konsistensi Desain

- AppBar gradient `[0xFF003D82, 0xFF0056B3]`, back `arrow_back_ios_new_rounded`, title putih bold 18.
- Kartu putih radius 24 + shadow; loading `SpinKitThreeBounce`; error `ErrorStateWidget`; refresh `RefreshIndicator`; load via `Future.microtask`.
- Notifikasi/dialog: `AppNotifications.show(...)` (TIDAK ada SnackBar manual) & dialog radius 24 pola offers.
- Foto dosen: `CircleAvatar` + `Image.network` + fallback ikon `person_rounded` (TIDAK perlu paket baru).
- Rating: baris `Icons.star_rounded` kecil terisi/sebagian (clip setengah bintang via `ShaderMask` bila ingin presisi float) — non-interaktif.
- Gotcha lint: tombol dalam `Row` → `minimumSize: const Size(0, 48)`.

---

## 9. Testing

- [ ] `test/edom_eval_validator_test.dart` (unit):
  - semua soal terjawab → `validate=true`, payload berisi `{jawaban: indexpilihan, bobotjawaban: value}`;
  - satu soal kosong → `validate=false`, error menunjuk indikator & nomor soal pertama yang kosong, payload item kosong = `"-"`,`"-"`;
  - semua soal kosong → error menunjuk soal pertama;
  - soal dengan jawaban toggle-off (Y→N) dihitung belum terjawab.
- [ ] `test/edom_navigation_test.dart` (widget, pola `krs_navigation_test.dart`): mock sesi → buka `EdomSemestersPage` → judul tampil; buka `EdomCoursesPage` via item (API gagal → state error tetap render); buka `EdomFormPage` mode riwayat (viewOnly) → judul/nama dosen tampil, Next di akhir disabled.

---

## 10. Urutan Task

| # | Task | File |
|---|---|---|
| 1 | Model 4 file (§2) | `lib/features/edom/data/models/*` |
| 2 | Validator pure function (§5.4) | `lib/features/edom/data/edom_eval_validator.dart` |
| 3 | Metode API 4 (§1.4) | `lib/core/network/api_service.dart` |
| 4 | Kunci l10n 3 bahasa + `flutter gen-l10n` (§6) | `lib/l10n/app_{id,en,ar}.arb` |
| 5 | `EdomSemestersPage` (§5.1) | `.../edom_semesters_page.dart` |
| 6 | `EdomCoursesPage` (§5.2) | `.../edom_courses_page.dart` |
| 7 | `EdomFormPage` — pager, validasi, saran, submit (§5.3) | `.../edom_form_page.dart` |
| 8 | Gate `ed@118` + wiring menu + integrasi offers (§7) | `subscription_gate.dart`, `main_menu_grid.dart`, `input_offers_page.dart` |
| 9 | Tests (§9) + verifikasi | `test/edom_*` |

## 11. Verifikasi Akhir

1. `flutter gen-l10n` bersih.
2. `flutter analyze` tanpa error baru.
3. `flutter test` lulus (2 gagal pre-existing `bills_realdata_diagnosis_test` di luar scope).
4. Uji device: badge 3 status semester; tombol Riwayat/Isi enable-disable sesuai status; pager soal + chip indikator; submit tanpa jawaban lengkap → error menunjuk soal kosong; saran < 8 karakter ditolak; submit sukses → rating & komentar muncul di kartu MK tanpa reload; keluar tengah pengisian → konfirmasi & jawaban tidak tersimpan; mode riwayat read-only.
