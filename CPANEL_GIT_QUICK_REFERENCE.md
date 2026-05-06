# 🚀 Quick Reference: cPanel Git Deployment

Referensi cepat untuk setup, testing, dan troubleshooting.

---

## 🔑 GitHub Secrets yang Diperlukan

| Secret Name | Value | Contoh |
|-------------|-------|---------|
| `CPANEL_WEBHOOK_URL` | URL webhook dari cPanel | `https://domain.com/execute/git_webhook/?token=abc123` |
| `GOOGLE_SHEETS_API_KEY` | API Key Google Sheets (optional) | `AIzaSyD...` |

**Cara menambahkan di GitHub:**
- Settings → Secrets and variables → Actions → New repository secret

---

## 📊 GitHub Actions Workflow Steps

```
1. Checkout repository
   ↓
2. Setup Node.js 18
   ↓
3. npm install dependencies
   ↓
4. node tools/generate.js (generate HTML dari Google Sheets)
   ↓
5. Configure git (set bot user)
   ↓
6. Check & commit changes (skip jika tidak ada perubahan)
   ↓
7. Push ke branch main
   ↓
8. Trigger webhook ke cPanel
```

---

## 🔧 cPanel Setup Checklist

- [ ] Login ke cPanel
- [ ] Buka **Git Version Control**
- [ ] Klik **Create** → Clone GitHub repository
- [ ] Isi Repository URL: `https://github.com/YOUR_USERNAME/YOUR_REPO.git`
- [ ] Isi Clone Path: `/home/USERNAME/public_html/your-project/`
- [ ] Select Branch: `main`
- [ ] Klik **Create**
- [ ] Tunggu clone selesai
- [ ] Klik repository name → lihat Webhook URL
- [ ] Copy Webhook URL
- [ ] Paste ke GitHub Secret `CPANEL_WEBHOOK_URL`

---

## 🧪 Testing

### Manual Trigger Workflow

```bash
# Di GitHub:
- Actions tab → Select workflow → Run workflow
```

### Test Webhook URL

```bash
curl -X POST "https://your-cpanel-domain/execute/git_webhook/?token=YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action":"pull"}'
```

### Verify Files di Server

```bash
# SSH ke server
ssh username@your-domain.com

# Check file
ls -la /home/username/public_html/your-project/index.html

# Check git log
cd /path/to/repo && git log --oneline -5
```

---

## ⚙️ Konfigurasi .cpanel.yml

**Update deployment path sesuai struktur hosting:**

```yaml
deployment:
  # Root domain
  path: '/'
  
  # Subdirectory
  path: '/jejaknegeri'
  
  # Custom path
  path: '/home/username/public_html/custom'
```

**Include files/folders yang akan di-deploy:**
```yaml
include:
  - index.html
  - article/
  - img/
  - css/
  - js/
```

**Exclude files/folders yang TIDAK akan di-deploy:**
```yaml
exclude:
  - .git
  - node_modules
  - .env
  - .github
  - tools
```

---

## 🔍 Troubleshooting Quick Guide

### ❌ "Permission denied" saat push

```bash
# Solution: Check git config
git config user.name
git config user.email

# Workflow sudah handle ini, tapi jika manual:
git config --global user.name "github-actions[bot]"
git config --global user.email "github-actions[bot]@users.noreply.github.com"
```

### ❌ "Webhook URL not found"

```
✓ Buka GitHub Secret CPANEL_WEBHOOK_URL
✓ Cek format: https://domain/execute/git_webhook/?token=XXX
✓ Cek token valid di cPanel
✓ Cek webhook URL tidak expired
```

### ❌ "File tidak ter-update di server"

```
✓ Check .cpanel.yml path correct
✓ Check include list - file ada?
✓ Check exclude list - file tidak di-exclude?
✓ Check folder permission writable
✓ Manual trigger webhook test
✓ Check cPanel repository logs
```

### ❌ "Infinite loop - workflow keeps running"

```
✓ TIDAK masalah - GitHub skip webhook jika dari actions[bot]
✓ Tapi jika ingin extra safe, cek condition di workflow:
  if: github.actor != 'github-actions[bot]'
```

### ❌ "generate.js error"

```bash
# Test local:
npm install
GOOGLE_SHEETS_API_KEY=... node tools/generate.js

# Check logs di GitHub Actions untuk detail error
```

---

## 📅 Scheduling

Workflow otomatis trigger pada:

| Trigger | Jadwal |
|---------|--------|
| Push ke main | Setiap ada push (manual) |
| Scheduled | Setiap hari **11:25 WIB** (04:25 UTC) |
| Manual trigger | Kapan saja via GitHub UI |

**Untuk ubah jadwal:**
Edit `.github/workflows/deploycPanel.yml`:
```yaml
schedule:
  - cron: '25 04 * * *'  # 04:25 UTC = 11:25 WIB
```

**Cron format:** `minute hour day-of-month month day-of-week`

---

## 📝 Environment Variables

**GitHub Actions dapat akses:**
- `CPANEL_WEBHOOK_URL` - Webhook URL ke cPanel
- `GOOGLE_SHEETS_API_KEY` - API Key Google Sheets
- `GITHUB_TOKEN` - Auto-generated token untuk git push

**Untuk tambah variable baru:**
- Settings → Secrets and variables → Actions → New repository secret/variable

---

## 🔐 Security Best Practices

- ✅ **JANGAN** commit `.env` ke repo
- ✅ **JANGAN** commit `CPANEL_WEBHOOK_URL` ke repo
- ✅ Use GitHub Secrets untuk sensitive data
- ✅ Set `.cpanel.yml` exclude list untuk security-sensitive files
- ✅ Use Personal Access Token dengan minimal scope
- ✅ Rotate webhook tokens periodically
- ✅ Monitor GitHub Actions logs untuk suspicious activity

---

## 🎯 Multi-Project Setup

Jika punya multiple projects dengan struktur sama:

**Project 1: /portalnegeri/**
```
- Repository: github.com/user/portalnegeri
- .github/workflows/deploycPanel.yml ✓
- .cpanel.yml (path: '/portalnegeri') ✓
- Secret: CPANEL_WEBHOOK_URL_PORTALNEGERI
```

**Project 2: /jejaknegeri/**
```
- Repository: github.com/user/jejaknegeri
- .github/workflows/deploycPanel.yml ✓
- .cpanel.yml (path: '/jejaknegeri') ✓
- Secret: CPANEL_WEBHOOK_URL_JEJAKNEGERI
```

**Atau gunakan shared workflow:**
```yaml
# .github/workflows/deploycPanel.yml
env:
  DEPLOY_PATH: '/jejaknegeri'  # Ubah per project
```

---

## 📞 Useful Commands

```bash
# Test GitHub workflow locally (memerlukan act)
act push

# Check git status
git status

# Check git log
git log --oneline -10

# Check last commit
git show HEAD

# Manually trigger webhook
curl -X POST "WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"action":"pull"}'

# Check SSH key untuk GitHub
cat ~/.ssh/id_rsa.pub
```

---

## 🔗 Resources

- [cPanel Git Documentation](https://docs.cpanel.net/whm/git-version-control/)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)
- [GitHub Webhooks](https://docs.github.com/en/webhooks-and-events/webhooks)
- [Cron Expression Reference](https://crontab.guru/)

---

Last Updated: 2024-12-14
