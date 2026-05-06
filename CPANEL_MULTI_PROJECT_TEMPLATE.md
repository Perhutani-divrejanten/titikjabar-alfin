# 🚀 Template & Setup Guide untuk Multiple Projects

Panduan untuk menggunakan template deployment ini di multiple projects dengan struktur yang sama.

---

## 📋 Struktur Multi-Project

```
GitHub Organization/Account
├── Project 1: /portalnegeri/
│   ├── .github/workflows/deploycPanel.yml
│   ├── .cpanel.yml
│   ├── tools/generate.js
│   └── ...
├── Project 2: /jejaknegeri/
│   ├── .github/workflows/deploycPanel.yml
│   ├── .cpanel.yml
│   ├── tools/generate.js
│   └── ...
└── Project 3: /titikjabar/
    ├── .github/workflows/deploycPanel.yml
    ├── .cpanel.yml
    ├── tools/generate.js
    └── ...
```

---

## 🔧 Setup untuk Project Baru

### Step 1: Copy Template Files

Untuk setiap project baru, copy 2 file ini:

1. **Copy workflow file:**
   ```bash
   # Dari existing project
   cp existing-project/.github/workflows/deploycPanel.yml \
      new-project/.github/workflows/deploycPanel.yml
   ```

2. **Copy .cpanel.yml template:**
   ```bash
   cp existing-project/.cpanel.yml new-project/.cpanel.yml
   ```

### Step 2: Customize .cpanel.yml

Edit `new-project/.cpanel.yml` - ubah deployment path:

```yaml
deployment:
  # Ubah path sesuai project
  path: '/new-project'  # ← UBAH INI
  build_dir: '.'

# include & exclude biasanya sama untuk semua project
include:
  - index.html
  - article/
  - img/
  - css/
  - js/
  - articles.json
  - netlify.toml

exclude:
  - .git
  - .github
  - node_modules
  - tools
  - scripts
  - ...
```

### Step 3: Setup cPanel untuk Project Baru

1. **Login ke cPanel**
2. **Git Version Control → Create**
3. **Clone repository:**
   - URL: `https://github.com/YOUR_USERNAME/new-project.git`
   - Clone Path: `/home/USERNAME/public_html/new-project/`
   - Branch: `main`
4. **Dapatkan webhook URL** - copy dari Manage Hooks

### Step 4: Add GitHub Secret untuk Project

**Per project**, tambahkan secret baru:

- **Repository:** `new-project`
- **Settings → Secrets and variables → Actions**
- **New repository secret:**
  - Name: `CPANEL_WEBHOOK_URL`
  - Value: Webhook URL dari cPanel (hasil step 3)

### Step 5: Commit & Push

```bash
git add .github/
git add .cpanel.yml
git commit -m "Setup: Add cPanel Git deployment"
git push origin main
```

---

## 🔄 Workflow yang Sama untuk Semua Project

File `.github/workflows/deploycPanel.yml` **bisa identik** untuk semua project karena:

✓ Trigger pada push `main` & scheduled (universal)
✓ Generate.js path sama (`tools/generate.js`)
✓ cPanel webhook URL menggunakan secret (unique per project)
✓ .cpanel.yml handle path-specific configuration

**Kecuali perlu customize, jangan ubah workflow!**

---

## 🎯 Variasi Setup

### Scenario A: Same Subdirectory untuk Berbagai Content

```
Project: warta.janten.net/news/
- Artikel dari Google Sheet A

Project: warta.janten.net/blog/
- Artikel dari Google Sheet B

Project: warta.janten.net/updates/
- Artikel dari Google Sheet C
```

**Setup:**
- 3 separate repositories
- Masing-masing punya webhook unique
- Masing-masing punya cPanel Git Version Control
- .cpanel.yml path berbeda untuk masing-masing

### Scenario B: Multiple Subdomain

```
Project 1: jejaknegeri.warta.janten.net
Project 2: portal.warta.janten.net
Project 3: berita.warta.janten.net
```

**Setup:**
- Hosting bisa at root atau subdirectory
- .cpanel.yml path sesuai domain/subdirectory
- GitHub Secret unique per repository

### Scenario C: Single Repository Multi-Deploy

Jika ingin satu repo deploy ke multiple directory:

```yaml
# .github/workflows/deploycPanel-multiple.yml

jobs:
  deploy-portalnegeri:
    runs-on: ubuntu-latest
    steps:
      # ... generate & commit ...
      - name: Trigger cPanel - Portal Negeri
        run: curl -X POST "${{ secrets.CPANEL_WEBHOOK_URL_PORTALNEGERI }}" ...

  deploy-jejaknegeri:
    runs-on: ubuntu-latest
    steps:
      # ... generate & commit ...
      - name: Trigger cPanel - Jejak Negeri
        run: curl -X POST "${{ secrets.CPANEL_WEBHOOK_URL_JEJAKNEGERI }}" ...
```

**Tapi RECOMMENDED:** Separate repositories untuk clarity.

---

## 📊 GitHub Secrets Management

### Penamaan Convention untuk Multi-Project

Jika butuh organize secrets:

```
CPANEL_WEBHOOK_URL_PORTALNEGERI
CPANEL_WEBHOOK_URL_JEJAKNEGERI
CPANEL_WEBHOOK_URL_TITIKJABAR

GOOGLE_SHEETS_API_KEY_PORTALNEGERI (jika berbeda per project)
GOOGLE_SHEETS_API_KEY_JEJAKNEGERI
GOOGLE_SHEETS_API_KEY_TITIKJABAR
```

### Organization-Level Secrets (GitHub Enterprise)

Jika menggunakan GitHub Enterprise bisa share secrets di organization level:

1. **Organization Settings → Secrets**
2. **Add organization secret:**
   - Name: `GOOGLE_SHEETS_API_KEY_PROD`
   - Value: Shared API key
3. **Access di workflow:**
   ```yaml
   - name: Generate
     env:
      GOOGLE_SHEETS_API_KEY: ${{ secrets.GOOGLE_SHEETS_API_KEY_PROD }}
     run: node tools/generate.js
   ```

---

## 🔄 Maintenance & Updates

### Saat Update Workflow (misalnya fix bug)

Jika ada bug fix di workflow, apply ke semua projects:

```bash
# 1. Update di Project 1 & test
# 2. Copy ke semua project lain
for project in project2 project3 project4; do
  cp project1/.github/workflows/deploycPanel.yml \
     $project/.github/workflows/deploycPanel.yml
  cd $project
  git add .github/workflows/deploycPanel.yml
  git commit -m "Update: Sync workflow fix from project1"
  git push origin main
  cd ..
done
```

### Monitoring Semua Project

Create dashboard untuk monitor:

```bash
#!/bin/bash
# monitor-all-projects.sh

PROJECTS=(
  "https://github.com/user/portalnegeri"
  "https://github.com/user/jejaknegeri"
  "https://github.com/user/titikjabar"
)

for project in "${PROJECTS[@]}"; do
  echo "Checking $project..."
  
  # Get latest workflow run
  LATEST_RUN=$(curl -s "$project/actions/runs?per_page=1" | jq '.workflow_runs[0]')
  
  STATUS=$(echo $LATEST_RUN | jq -r '.conclusion')
  TIMESTAMP=$(echo $LATEST_RUN | jq -r '.updated_at')
  
  echo "  Status: $STATUS"
  echo "  Updated: $TIMESTAMP"
  echo ""
done
```

---

## 📝 Documentation Setup untuk Team

Jika punya team yang maintain multiple projects:

### 1. Create Wiki/Docs

```
docs/
├── DEPLOYMENT.md (general guide)
├── SETUP_NEW_PROJECT.md (step-by-step)
├── TROUBLESHOOTING.md (solutions)
└── FAQ.md (common questions)
```

### 2. Create Checklist untuk New Project

```markdown
# New Project Setup Checklist

- [ ] Repository created on GitHub
- [ ] Clone template workflow: deploycPanel.yml
- [ ] Clone template config: .cpanel.yml
- [ ] Edit .cpanel.yml - update deployment path
- [ ] Push to GitHub
- [ ] Create cPanel Git Version Control
- [ ] Get webhook URL from cPanel
- [ ] Add GitHub Secret: CPANEL_WEBHOOK_URL
- [ ] Add GitHub Secret: GOOGLE_SHEETS_API_KEY (if needed)
- [ ] Test manual workflow trigger
- [ ] Test webhook trigger
- [ ] Verify files deployed to server
- [ ] Document deployment path in team wiki
```

### 3. Create Runbook untuk Deployment Troubleshooting

```markdown
# Deployment Troubleshooting Runbook

## Problem: Workflow Failed

1. Check GitHub Actions logs
2. Look for error message
3. Refer to TROUBLESHOOTING.md
4. If GitHub-related error: check secrets
5. If generate.js error: check Google Sheets API
6. If git error: check branch/permissions
```

---

## 🔐 Security for Multiple Projects

### Best Practices

- ✓ Use unique webhook tokens per project
- ✓ Rotate credentials periodically
- ✓ Don't share secrets across projects (unless necessary)
- ✓ Use GitHub organization secrets untuk shared keys
- ✓ Audit GitHub Actions logs regularly
- ✓ Monitor deployment patterns untuk anomalies

### Secret Rotation Procedure

```bash
# 1. Generate new webhook token di cPanel
# 2. Get new URL dari cPanel
# 3. Update GitHub Secret:
#    Settings → Secrets → Edit CPANEL_WEBHOOK_URL
# 4. Paste new URL
# 5. Test manual workflow trigger
# 6. Mark old token as revoked di cPanel (if possible)
```

---

## 📊 Sample Multi-Project Status

```
Project                  Last Deploy      Status    Files Updated
─────────────────────────────────────────────────────────────────
portalnegeri            2024-12-14 11:25  ✓ OK      12 files
jejaknegeri             2024-12-14 11:25  ✓ OK      8 files
titikjabar              2024-12-14 08:30  ✓ OK      15 files
berita                  2024-12-13 11:25  ✓ OK      3 files
```

---

## 🎯 Scaling Considerations

### Jika 5+ Projects

1. **Use GitHub Organization** untuk centralized management
2. **Use GitHub Enterprise** untuk organization-level secrets
3. **Create shared workflow template** di organization
4. **Use status checks API** untuk automated monitoring
5. **Setup dashboard** untuk central visibility

### Automation Tools

```bash
# GitHub CLI untuk automate setup
gh repo clone new-project
gh secret set CPANEL_WEBHOOK_URL --body "WEBHOOK_URL"
gh workflow run deploycPanel.yml

# Atau create script
scripts/setup-new-project.sh PROJECT_NAME WEBHOOK_URL
```

---

## 📚 Reusable Components

Setelah setup semua projects, extract reusable components:

```
templates/
├── workflow-template.yml
├── cpanel-template.yml
├── generate-template.js
└── README.md (how to use templates)

scripts/
├── setup-new-project.sh
├── monitor-all-projects.sh
├── rotate-secrets.sh
└── deploy-all.sh
```

---

## 🎯 Checklist untuk Setup Multiple Projects

- [ ] Template files siap (.github/workflows, .cpanel.yml)
- [ ] Documentation untuk new project setup
- [ ] GitHub Secrets naming convention established
- [ ] cPanel webhook URL obtainable & documented
- [ ] Team trained pada setup process
- [ ] Monitoring dashboard setup
- [ ] Incident response plan (jika loop/error)
- [ ] Regular security audit scheduled
- [ ] Backup/rollback procedure documented

---

**Template ini reusable untuk unlimited projects!** 🎉

Last Updated: 2024-12-14
