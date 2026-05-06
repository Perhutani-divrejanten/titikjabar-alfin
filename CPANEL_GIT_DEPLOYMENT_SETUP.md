# 📋 Panduan Setup cPanel Git Version Control Deployment

Dokumen ini menjelaskan langkah demi langkah cara mengubah dari FTP deployment ke cPanel Git Version Control.

---

## 📌 Daftar Isi
1. [Alur Kerja Baru](#alur-kerja-baru)
2. [Setup di GitHub](#setup-di-github)
3. [Setup di cPanel](#setup-di-cpanel)
4. [Testing & Troubleshooting](#testing--troubleshooting)
5. [FAQ](#faq)

---

## 🔄 Alur Kerja Baru

```
┌─────────────────┐
│  Push ke main   │
│   (manual/      │
│   scheduled)    │
└────────┬────────┘
         │
         ▼
┌──────────────────────────────┐
│  GitHub Actions Workflow     │
│  - Clone repo                │
│  - npm install               │
│  - node tools/generate.js    │ ◄── Generate HTML dari Google Sheets
│  - git commit & push         │ ◄── Auto-commit hasil generate
│  - POST webhook ke cPanel    │
└────────┬─────────────────────┘
         │
         ▼
┌──────────────────────────────┐
│  cPanel Git Version Control  │
│  - Terima webhook            │
│  - Pull repo dari GitHub     │
│  - Jalankan post-pull hooks  │
│  - Sync files sesuai .cpanel.yml
└────────┬─────────────────────┘
         │
         ▼
┌──────────────────────────────┐
│  Website Updated! ✓          │
└──────────────────────────────┘
```

---

## 🚀 Setup di GitHub

### Step 1: Pastikan File Workflow Sudah Ada
File `.github/workflows/deploycPanel.yml` sudah dibuat dengan:
- ✅ Trigger: Push ke `main` + Scheduled (11:25 WIB = 04:25 UTC)
- ✅ Menjalankan `node tools/generate.js`
- ✅ Auto-commit hasil generate (skip jika tidak ada perubahan)
- ✅ Kirim webhook ke cPanel

### Step 2: Tambahkan GitHub Secrets
Secrets diperlukan untuk:
1. **CPANEL_WEBHOOK_URL** - URL webhook dari cPanel untuk trigger pull
2. **GOOGLE_SHEETS_API_KEY** - API Key Google Sheets (jika generate.js memerlukan)

**Cara menambahkan Secret:**
1. Buka repository di GitHub.com
2. Klik **Settings** → **Secrets and variables** → **Actions**
3. Klik **New repository secret**
4. Isi nama: `CPANEL_WEBHOOK_URL`
5. Isi value: `https://your-cpanel-domain.com/execute/git_webhook/?token=YOUR_WEBHOOK_TOKEN`
   (URL webhook akan didapatkan dari cPanel, lihat bagian Setup di cPanel)
6. Klik **Add secret**

**Contoh:**
```
Name: CPANEL_WEBHOOK_URL
Value: https://warta.janten.net:2083/execute/git_webhook/?token=abc123def456
```

### Step 3: Pastikan .cpanel.yml di Root Repository
File `.cpanel.yml` sudah disertakan untuk memberitahu cPanel:
- ✅ Direktori deployment (`path: '/'`)
- ✅ File/folder yang disalin (HTML, article/, img/, css/, js/)
- ✅ File/folder yang diabaikan (node_modules, .github, tools, .env, dll)

---

## 🔧 Setup di cPanel

### Prasyarat:
- Akses cPanel dengan privilege admin
- GitHub account dengan access ke repository
- Repo GitHub sudah di-push ke branch `main`

### Step 1: Hubungkan Repository ke cPanel

1. **Login ke cPanel**
   - Buka: `https://your-domain.com:2083` (atau port cPanel Anda)
   - Login dengan username & password cPanel

2. **Buka Git Version Control**
   - Cari **Git Version Control** di cPanel (biasanya di bagian "Software")
   - Atau buka langsung: `https://your-domain.com:2083/frontend/cPanel/git.html`

3. **Clone Repository**
   - Klik **Create** atau **Clone Repository**
   - Isi form:
     ```
     Repository URL: https://github.com/YOUR_USERNAME/YOUR_REPO.git
     Clone Path: /home/USERNAME/public_html/your-project/
     Branch: main
     ```
   - Klik **Create**
   - Tunggu proses clone selesai

### Step 2: Dapatkan Webhook URL dari cPanel

1. Setelah repository berhasil di-clone, klik repository name di daftar
2. Cari bagian **Hooks** atau **Webhooks**
3. Klik **Manage Hooks** atau **View Hooks**
4. Cari webhook URL yang berbentuk:
   ```
   https://your-domain.com/execute/git_webhook/?token=YOUR_TOKEN
   ```
5. **Copy URL ini** - Anda akan memerlukan untuk GitHub Secret

### Step 3: Tambahkan GitHub Webhook ke cPanel (Optional - untuk manual trigger)

Jika ingin GitHub auto-trigger cPanel webhook:
1. Buka repository di GitHub
2. Settings → **Webhooks** → **Add webhook**
3. Isi:
   - **Payload URL:** Webhook URL dari cPanel (dari Step 2)
   - **Content type:** `application/json`
   - **Events:** Pilih **Just the push event**
4. Klik **Add webhook**

Tapi ini **OPTIONAL** karena GitHub Actions workflow kami sudah kirim webhook otomatis.

### Step 4: Konfigurasi Deploy Path di .cpanel.yml

Edit file `.cpanel.yml` di root repository:

```yaml
deployment:
  # Ubah path sesuai struktur hosting Anda:
  
  # Jika deploy ke root (warta.janten.net/):
  path: '/'
  
  # Jika deploy ke subdirektori (warta.janten.net/jejaknegeri/):
  path: '/jejaknegeri'
  
  # Jika deploy ke subdomain terpisah:
  path: '/home/username/public_html/jejaknegeri'
```

**Catat:** Path harus sesuai dengan tempat di mana Anda ingin file di-deploy di server.

---

## ✅ Testing & Troubleshooting

### Test 1: Manual Trigger GitHub Actions

1. Buka repository di GitHub
2. Klik **Actions** tab
3. Pilih workflow **"Deploy to cPanel via Git Version Control"**
4. Klik **Run workflow** dropdown
5. Klik **Run workflow** button
6. Workflow akan berjalan, lihat logs untuk pastikan tidak ada error

**Apa yang harus terjadi:**
- ✅ Checkout repository
- ✅ Install dependencies
- ✅ Generate HTML files
- ✅ Git commit (jika ada perubahan)
- ✅ Git push
- ✅ Webhook request ke cPanel

### Test 2: Verifikasi Webhook URL di GitHub Secret

```bash
# Di terminal lokal Anda
curl -X POST "YOUR_CPANEL_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"action":"pull","timestamp":"2024-01-01T00:00:00Z"}'
```

Jika berhasil, cPanel akan pull repo terbaru.

### Test 3: Check cPanel Git Status

1. Login ke cPanel
2. Buka **Git Version Control**
3. Klik repository name
4. Check apakah branch sudah ter-update ke commit terbaru
5. Verifikasi file sudah ter-copy ke deployment path

### Common Issues & Solutions

#### ❌ Error: "Webhook URL is not set"

**Masalah:** `CPANEL_WEBHOOK_URL` secret belum ditambahkan di GitHub

**Solusi:**
1. Buka GitHub repository → Settings → Secrets and variables → Actions
2. Tambahkan secret baru dengan nama `CPANEL_WEBHOOK_URL`
3. Value: Webhook URL dari cPanel (dari step 2 setup cPanel)
4. Re-run workflow

#### ❌ Error: "fatal: could not read Username for 'https://github.com'"

**Masalah:** Repository private dan GitHub token tidak valid

**Solusi:**
1. Buat Personal Access Token (PAT) di GitHub:
   - Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Generate new token dengan scope `repo` (untuk private repo)
   - Copy token
2. Di cPanel Git Version Control, update repository dengan:
   - URL: `https://YOUR_TOKEN@github.com/YOUR_USERNAME/YOUR_REPO.git`

#### ❌ Error: "Infinite loop - workflow triggered by push terus berjalan"

**Masalah:** GitHub Actions commit mengakhiri workflow lagi

**Solusi:** 
Sudah ditangani di workflow! GitHub otomatis skip webhook jika push dari `github-actions[bot]` user.
Tapi jika ingin extra safe, tambah condition:

```yaml
- name: Push changes to main
  if: steps.commit.outputs.no_changes == 'false' && github.actor != 'dependabot[bot]'
```

#### ❌ File tidak ter-copy ke server setelah webhook

**Masalah:** .cpanel.yml path/include/exclude tidak sesuai

**Solusi:**
1. Edit `.cpanel.yml` - pastikan `path` benar sesuai struktur hosting
2. Check `include` list - pastikan file yang ingin di-copy ada di list
3. Check `exclude` list - pastikan tidak mengexclude file yang ingin di-copy
4. Jalankan manual webhook test (lihat Test 2)
5. Check permission folder di server (pastikan writable)

#### ❌ generate.js error atau tidak berjalan

**Masalah:** Dependencies tidak install atau Google Sheets API key error

**Solusi:**
1. Pastikan `package.json` ada file dependencies yang diperlukan
2. Pastikan `GOOGLE_SHEETS_API_KEY` secret sudah ditambahkan (jika generate.js memerlukan)
3. Test local: 
   ```bash
   npm install
   node tools/generate.js
   ```
4. Cek logs di GitHub Actions untuk error detail

---

## ❓ FAQ

### Q: Berapa lama update website setelah push ke GitHub?

**A:** Biasanya 1-2 menit:
- GitHub Actions workflow: ~30-60 detik
- cPanel pull & sync: ~30 detik
- File propagation: ~30 detik

### Q: Apakah bisa auto-trigger setiap hari?

**A:** Ya! Workflow sudah ada scheduled trigger:
- Setiap hari jam **11:25 WIB** (04:25 UTC)
- Workflow akan jalankan generate.js, commit hasil, dan webhook ke cPanel
- Lihat di `.github/workflows/deploycPanel.yml` - bagian `schedule`

### Q: Bagaimana jika ada error di generate.js?

**A:** Workflow akan gagal dan tidak akan push/webhook:
1. Check GitHub Actions logs untuk detail error
2. Fix error di `tools/generate.js`
3. Push fix ke main
4. Workflow auto-retry sesuai jadwal atau manual trigger

### Q: Bisa deploy ke multiple directory?

**A:** Ada beberapa opsi:

**Opsi 1: Satu repo, multiple paths di .cpanel.yml**
```yaml
# Tapi cPanel standard hanya support satu path per repo
deployment:
  path: '/'
```

**Opsi 2: Multiple repositories**
- Buat repo terpisah untuk setiap project
- Masing-masing repo punya Git Version Control sendiri di cPanel
- Masing-masing repo punya workflow GitHub Actions sendiri

**Opsi 3: Branch terpisah**
- Deploy branch `main` ke `/`
- Deploy branch `jejaknegeri` ke `/jejaknegeri/`
- Masing-masing branch punya workflow deployment sendiri

### Q: Apakah .env file ikut ter-upload ke server?

**A:** **TIDAK!** File `.env` ada di `exclude` list di `.cpanel.yml`, jadi:
- ✅ Aman dari credential exposure
- ✅ .env di server tetap aman
- ⚠️ Pastikan generate.js punya akses ke .env local atau GitHub Secrets

### Q: Bagaimana jika webhook URL berubah?

**A:** 
1. Dapatkan webhook URL baru dari cPanel
2. Update secret di GitHub:
   - Settings → Secrets and variables → Actions
   - Edit `CPANEL_WEBHOOK_URL`
   - Paste webhook URL baru
3. Test manual trigger workflow

### Q: Apakah file lama di server akan dihapus?

**A:** **TIDAK!** Deployment mode di .cpanel.yml adalah safe mode:
- Hanya file di `include` list yang di-update
- File lama tidak dihapus
- Jika ingin cleanup, manual delete atau buat custom post-pull hook

### Q: Bisa rollback ke commit sebelumnya?

**A:** Ya, di cPanel:
1. Buka Git Version Control
2. Klik repository name
3. Klik **Commit history**
4. Pilih commit yang ingin di-rollback
5. Klik **Checkout** atau **Reset**

---

## 📞 Support & Resources

- **cPanel Git Documentation:** https://docs.cpanel.net/whm/git-version-control/
- **GitHub Actions Docs:** https://docs.github.com/en/actions
- **GitHub Webhooks:** https://docs.github.com/en/webhooks-and-events/webhooks

---

## 🎯 Checklist Setup Lengkap

- [ ] File `.github/workflows/deploycPanel.yml` sudah dibuat
- [ ] File `.cpanel.yml` sudah ada di root repository
- [ ] GitHub Secret `CPANEL_WEBHOOK_URL` sudah ditambahkan
- [ ] GitHub Secret `GOOGLE_SHEETS_API_KEY` sudah ditambahkan (jika perlu)
- [ ] Repository GitHub sudah ter-connect ke cPanel Git Version Control
- [ ] Webhook URL dari cPanel sudah dicopy dan disimpan
- [ ] `deployment.path` di `.cpanel.yml` sudah sesuai dengan struktur hosting
- [ ] Test workflow manual trigger - semua steps berhasil
- [ ] Test webhook trigger ke cPanel - file ter-update di server
- [ ] Check logs untuk memastikan tidak ada error

---

**Jika ada pertanyaan atau error, check logs di:**
- GitHub: Repository → Actions → Workflow logs
- cPanel: Git Version Control → Repository logs

Good luck! 🚀
