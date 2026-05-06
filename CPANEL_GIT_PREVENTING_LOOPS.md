# 🛡️ Preventing Infinite Loops & Best Practices

Panduan lengkap untuk mencegah infinite loop dan optimize deployment workflow.

---

## 🔄 Bagaimana Infinite Loop Bisa Terjadi?

```
Scenario: GitHub Actions Push → Webhook Trigger → GitHub Actions Again (Infinite!)

1. Developer push ke main
   ↓
2. GitHub Actions workflow dimulai
   ↓
3. generate.js menghasilkan file baru
   ↓
4. Workflow: git commit + push hasil generate
   ↓
5. Push #4 BISA memicu workflow lagi? ❌ NO (GitHub sudah prevent ini!)
   ↓
6. Tapi ada edge case tertentu bisa trigger...
```

---

## ✅ Solusi Anti-Infinite Loop (Sudah Diterapkan)

### Solusi 1: GitHub Actions Bot User (✓ IMPLEMENTED)

GitHub otomatis skip workflow jika push dari `github-actions[bot]`:

```yaml
# File: .github/workflows/deploycPanel.yml
- name: Configure git
  run: |
    git config --global user.name "github-actions[bot]"
    git config --global user.email "github-actions[bot]@users.noreply.github.com"
```

**Bagaimana cara kerjanya:**
- Workflow push menggunakan user `github-actions[bot]`
- GitHub melihat push dari bot user
- GitHub **SKIP** trigger webhook/workflow untuk push dari actions
- ✓ Infinite loop prevented!

### Solusi 2: Check for Changes (✓ IMPLEMENTED)

Tidak commit jika tidak ada perubahan:

```yaml
- name: Check for changes and commit
  id: commit
  run: |
    if git diff --quiet; then
      echo "no_changes=true" >> $GITHUB_OUTPUT  # No changes = skip commit
    else
      echo "no_changes=false" >> $GITHUB_OUTPUT # Changes exist = commit
      git add -A
      git commit -m "Auto-generate..."
    fi

- name: Push changes to main
  if: steps.commit.outputs.no_changes == 'false'
  run: git push origin main  # Only push if there are changes
```

**Keuntungan:**
- ✓ Tidak commit jika tidak ada file baru/berubah
- ✓ Tidak push jika tidak ada commit
- ✓ Kurangi unnecessary webhook calls

### Solusi 3: Ignore Generated Files (Recommended)

Jika generate.js menghasilkan file yang sama setiap run, add ke `.gitignore`:

```bash
# .gitignore
# Generated files (jangan track jika tidak berubah)
articles_temp.json
*.tmp
```

**TAPI:** Jika ingin track generated files (recommended untuk consistency):
- Lakukan git add & commit
- GitHub bot user otomatis prevent re-trigger
- Safe! ✓

---

## 🎯 Best Practices Implementation

### 1. Generate File yang Predictable

Pastikan `generate.js` menghasilkan file dengan:
- ✓ Deterministic output (sama input = sama output)
- ✓ No timestamp/random data (kecuali intentional)
- ✓ Consistent formatting (JSON indentation, dll)

**Contoh BAD:**
```javascript
// ❌ Setiap run generate dengan timestamp berbeda
const article = {
  title: 'News',
  generated_at: new Date()  // Selalu berbeda!
}
```

**Contoh GOOD:**
```javascript
// ✓ Konsisten - timestamp hanya di manifest file
const manifest = {
  articles: articles,
  generated_at: new Date().toISOString(),  // Optional metadata
  version: '1.0'
}

// Artikel sendiri stabil
const articles = [
  { title: 'News', content: '...' }  // Deterministic
]
```

### 2. Optimize generate.js untuk Scheduled Runs

Jika workflow dijadwalkan daily, optimize untuk:

```javascript
// tools/generate.js

const fs = require('fs');
const path = require('path');

// Cek jika ada cache/last-generated file
function hasChanges() {
  // Bandingkan dengan cached version
  const oldArticles = getCachedArticles();
  const newArticles = generateArticlesFromSheets();
  
  // Return true jika ada perubahan
  return JSON.stringify(oldArticles) !== JSON.stringify(newArticles);
}

// Hanya generate jika ada perubahan data
async function main() {
  console.log('🔍 Checking for changes...');
  
  if (!hasChanges()) {
    console.log('✓ No changes detected, skipping generation');
    process.exit(0);  // Exit cleanly, no error
  }
  
  console.log('📝 Changes detected, generating files...');
  
  // Generate article HTML
  const articles = await generateArticlesFromSheets();
  
  // Write files
  for (const article of articles) {
    writeArticleFile(article);
  }
  
  console.log(`✓ Generated ${articles.length} articles`);
}

main().catch(err => {
  console.error('❌ Error:', err.message);
  process.exit(1);
});
```

### 3. Safe Git Commit Strategy

```yaml
# .github/workflows/deploycPanel.yml

- name: Configure git
  run: |
    git config --global user.name "github-actions[bot]"
    git config --global user.email "github-actions[bot]@users.noreply.github.com"
    # Prevent push if already synced
    git config --global push.default simple

- name: Commit changes
  id: commit
  run: |
    # Only stage tracked files + new articles
    git add article/*.html
    git add articles.json
    
    # Check if there are staged changes
    if git diff --cached --quiet; then
      echo "no_changes=true" >> $GITHUB_OUTPUT
      exit 0
    fi
    
    echo "no_changes=false" >> $GITHUB_OUTPUT
    
    # Commit with meaningful message
    git commit -m "🤖 Auto-generate articles from Google Sheets

$(date -u +'%Y-%m-%d %H:%M:%S UTC')
Commit: $(git rev-parse --short HEAD)
Trigger: ${{ github.event_name }}"

- name: Push to main
  if: steps.commit.outputs.no_changes == 'false'
  run: |
    git push origin main
```

---

## 🔐 Preventing Malicious Loops

### Rate Limiting

Jika cPanel webhook bisa trigger, add rate limit:

```yaml
# .github/workflows/deploycPanel.yml

- name: Check last webhook time
  id: rate_limit
  run: |
    LAST_WEBHOOK=$(cat .last_webhook || echo 0)
    CURRENT_TIME=$(date +%s)
    DIFF=$((CURRENT_TIME - LAST_WEBHOOK))
    
    # Only allow webhook setiap 5 menit
    if [ $DIFF -lt 300 ]; then
      echo "rate_limited=true" >> $GITHUB_OUTPUT
      exit 0
    fi
    
    echo "rate_limited=false" >> $GITHUB_OUTPUT
    echo $CURRENT_TIME > .last_webhook
    git add .last_webhook

- name: Trigger webhook (rate limited)
  if: steps.rate_limit.outputs.rate_limited == 'false'
  run: |
    curl -X POST "${{ secrets.CPANEL_WEBHOOK_URL }}" ...
```

### Webhook Idempotency

Pastikan webhook handler bisa handle duplicate calls:

```yaml
# .cpanel.yml atau post-pull script

post_pull:
  - command: |
      #!/bin/bash
      WEBHOOK_LOG=".cpanel_webhook.log"
      
      # Skip jika sudah pull dalam 5 menit terakhir
      if [ -f "$WEBHOOK_LOG" ]; then
        LAST_PULL=$(stat -f %m "$WEBHOOK_LOG" 2>/dev/null || stat -c %Y "$WEBHOOK_LOG")
        CURRENT=$(date +%s)
        DIFF=$((CURRENT - LAST_PULL))
        
        if [ $DIFF -lt 300 ]; then
          echo "Webhook called too soon, skipping"
          exit 0
        fi
      fi
      
      # Do the actual pull
      git pull origin main
      touch "$WEBHOOK_LOG"
```

---

## 📊 Monitoring & Alerting

### GitHub Actions: Get Workflow Insights

```bash
# Check workflow runs
gh workflow list --all

# Check latest run
gh run list --limit 5

# Get run details
gh run view RUN_ID --log
```

### cPanel: Monitor Git Operations

1. SSH ke server
2. Check git log:
```bash
cd /path/to/repo
git log --oneline -10
git log --format="%h - %s (%ai)" -5
```

3. Monitor pull frequency:
```bash
# Count pulls per day
git log --since="24 hours ago" | grep -c "^commit"
```

### Alert jika Loop Terdeteksi

```bash
#!/bin/bash
# Script untuk detect loop

THRESHOLD=10  # More than 10 pulls/hour = suspicious

PULLS_THIS_HOUR=$(git log --since="1 hour ago" | grep -c "^commit")

if [ $PULLS_THIS_HOUR -gt $THRESHOLD ]; then
  echo "⚠ WARNING: Possible infinite loop detected!"
  echo "Pulls in last hour: $PULLS_THIS_HOUR"
  
  # Send alert (ngrok, discord webhook, email, dll)
  curl -X POST "$ALERT_WEBHOOK" \
    -d "Infinite loop detected: $PULLS_THIS_HOUR pulls/hour"
fi
```

---

## 🧪 Testing Scenarios

### Scenario 1: Normal Push → Generate → Commit → Webhook

```bash
# 1. Local change
echo "test" > test.txt

# 2. Push
git add test.txt
git commit -m "Test change"
git push origin main

# Expected result:
# ✓ GitHub Actions triggered
# ✓ generate.js runs
# ✓ Auto-commit + push (jika ada perubahan)
# ✓ Webhook ke cPanel
# ✓ cPanel pull + sync
# ✗ No infinite loop (GitHub bot prevent)
```

### Scenario 2: No Changes

```bash
# run generate.js
node tools/generate.js

# Expect:
# ✓ No file changes
# ✓ Skip commit
# ✓ Skip push
# ✓ Skip webhook
# → Workflow completed, no unnecessary actions
```

### Scenario 3: Schedule Trigger (Daily)

```bash
# Every day at 11:25 WIB:
# ✓ Workflow auto-trigger
# ✓ generate.js runs
# → Commit jika ada changes dari Google Sheets
# → Webhook trigger cPanel jika ada perubahan
```

---

## 🔄 Recovery dari Loop (Jika Terjadi)

Jika somehow terjadi infinite loop:

### 1. Stop Immediately

```bash
# Disable workflow di GitHub
- Settings → Actions → General → Disable all actions (temporary)

# Atau disable workflow tertentu:
# Edit .github/workflows/deploycPanel.yml → ubah nama jadi deploycPanel.yml.disabled
```

### 2. Investigate Root Cause

```bash
# Check workflow logs
gh run list --limit 20

# Check git logs untuk pattern
git log --oneline -50

# Check commit messages
git log --format="%h - %s" -10
```

### 3. Fix & Re-enable

```bash
# After fix:
git add .
git commit -m "Fix: Prevent infinite loop by..."
git push origin main

# Re-enable workflow:
# Settings → Actions → Enable all actions

# Manual trigger to test
gh workflow run deploycPanel.yml
```

---

## 📝 Checklist: Safe Deployment

- [ ] GitHub Actions uses `github-actions[bot]` user for commits
- [ ] Workflow checks for changes before commit
- [ ] Only push jika ada changes
- [ ] Only webhook jika ada changes atau scheduled run
- [ ] `.cpanel.yml` properly configured
- [ ] Exclude `.git` folder dari deployment
- [ ] Generate file konsisten & deterministic
- [ ] Test manual trigger - no infinite loop
- [ ] Test scheduled trigger - works correctly
- [ ] Monitor workflow runs untuk suspicious patterns
- [ ] Have recovery plan jika loop terjadi
- [ ] Document monitoring & alerting

---

## 🎯 Summary

**Infinite Loop Prevention Layers:**
1. ✓ GitHub bot user automatically skip re-triggering
2. ✓ Workflow checks for changes before commit
3. ✓ Only push/webhook jika ada perubahan
4. ✓ Rate limiting bisa ditambah extra layer
5. ✓ Idempotent webhook handler

**Result: SAFE & EFFICIENT DEPLOYMENT** 🚀

---

Last Updated: 2024-12-14
