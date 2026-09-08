class Instruction {
  final String title;
  final List<String> steps;

  Instruction({required this.title, required this.steps});
}

class PanduanPembayaran {
  static List<Instruction> get bni => [
        Instruction(
          title: 'ATM BNI',
          steps: [
            'Masukkan kartu ATM dan PIN',
            'Pilih Menu Lainnya > Transfer',
            'Pilih Jenis Rekening asal dan Pilih Ke Rekening BNI',
            'Masukkan Nomor Virtual Account',
            'Konfirmasi Data Pembayaran dan Nominal',
            'Simpan struk sebagai bukti pembayaran',
          ],
        ),
        Instruction(
          title: 'BNI Mobile Banking',
          steps: [
            'Buka aplikasi BNI Mobile Banking',
            'Pilih menu Pembayaran',
            'Pilih menu Biaya Pendidikan',
            'Pilih tab Pembayaran',
            'Pilih Perguruan Tinggi (UIN Salatiga)',
            'Masukkan Nomor Virtual Account',
            'Masukkan Password Transaksi untuk memproses',
          ],
        ),
      ];

  static List<Instruction> get tokopedia => [
        Instruction(
          title: 'Tokopedia',
          steps: [
            'Buka aplikasi atau website Tokopedia',
            'Pilih menu Top Up & Tagihan',
            'Cari dan Pilih menu Biaya Pendidikan',
            'Pilih Instansi (UIN Salatiga)',
            'Masukkan NIM Anda',
            'Klik Bayar dan pilih metode pembayaran yang diinginkan',
            'Transaksi selesai setelah pembayaran diverifikasi',
          ],
        ),
      ];

  static List<Instruction> get indomaret => [
        Instruction(
          title: 'Indomaret / i.Saku',
          steps: [
            'Datangi gerai Indomaret terdekat',
            'Sampaikan kepada kasir ingin melakukan pembayaran UIN Salatiga',
            'Tunjukkan Nomor Virtual Account / Kode Pembayaran ke kasir',
            'Lakukan pembayaran sesuai nominal yang disebutkan',
            'Simpan struk dari kasir sebagai bukti pembayaran yang sah',
          ],
        ),
      ];

  static List<Instruction> get atmBersama => [
        Instruction(
          title: 'ATM Bersama / Bank Lain',
          steps: [
            'Masukkan kartu ATM dan PIN',
            'Pilih menu Transfer > Ke Rekening Bank Lain',
            'Masukkan Kode Bank BNI (009)',
            'Masukkan Nomor Virtual Account Anda',
            'Masukkan nominal transfer sesuai tagihan',
            'Konfirmasi data dan selesaikan transaksi',
          ],
        ),
      ];
}
