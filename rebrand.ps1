# Rebrand script for Titik Jabar
$files = Get-ChildItem -Recurse -Include *.html,*.css,*.json,*.md,*.toml | Where-Object { $_.FullName -notlike "*node_modules*" }

$changes = @{
    "Warta Janten" = "Titik Jabar"
    "wartajanten" = "titikjabar"
    "WartaJanten" = "TitikJabar"
    "wartajanten@gmail.com" = "titikjabar@gmail.com"
    "- Warta Janten" = "- Titik Jabar"
    "facebook.com/wartajanten" = "facebook.com/titikjabar"
    "twitter.com/wartajanten" = "twitter.com/titikjabar"
    "instagram.com/wartajanten" = "instagram.com/titikjabar"
    "youtube.com/wartajanten" = "youtube.com/titikjabar"
    "--primary: #065F46" = "--primary: #0F766E"
    "--dark: #022C22" = "--dark: #134E4A"
    "--secondary: #1E3A5F" = "--secondary: #7F1F1F"
    "wartajanten-article-generator" = "titikjabar-article-generator"
    "Generator artikel otomatis dari Google Sheets untuk Warta Janten" = "Generator artikel otomatis dari Google Sheets untuk Titik Jabar"
    "Warta Janten Team" = "Titik Jabar Team"
}

$encodingChanges = @{
    [char]0x201C = '"'  # "
    [char]0x201D = '"'  # "
    [char]0x2018 = "'"  # '
    [char]0x2019 = "'"  # '
    [char]0x2013 = "-"  # –
    [char]0x2014 = "-"  # —
    [char]0xFFFD = " "  # replacement char
    [char]0xA0 = " "    # nbsp
}

$modifiedFiles = @()

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $original = $content

    # Branding changes
    foreach ($key in $changes.Keys) {
        $content = $content -replace [regex]::Escape($key), $changes[$key]
    }

    # Encoding fixes
    foreach ($key in $encodingChanges.Keys) {
        $content = $content -replace [regex]::Escape($key), $encodingChanges[$key]
    }

    # Special for navbar-brand
    $content = $content -replace '<span style="font-weight: bold; color: #[0-9A-Fa-f]{6}; font-size: 24px; letter-spacing: -0.5px;">WARTA<span style="color: #[0-9A-Fa-f]{6}; font-weight: normal; font-size: 18px; margin-left: 2px;">JANTEN</span></span>', '<span style="font-weight: bold; color: #0F766E; font-size: 24px; letter-spacing: -0.5px;">TITIK<span style="color: #7F1F1F; font-weight: normal; font-size: 18px; margin-left: 2px;">JABAR</span></span>'

    # Remove logo.png references
    $content = $content -replace '<img[^>]*src="[^"]*logo\.png"[^>]*>', ''
    $content = $content -replace 'img src="\.\./img/logo\.png"', ''

    if ($content -ne $original) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8
        $modifiedFiles += $file.FullName
    }
}

# Count by type
$mainPages = $modifiedFiles | Where-Object { $_ -match '\\(index|news|contact|search|login|register)\.html$' }
$articlePages = $modifiedFiles | Where-Object { $_ -match '\\article\\' }
$cssFiles = $modifiedFiles | Where-Object { $_ -match '\.css$' }
$packageFiles = $modifiedFiles | Where-Object { $_ -match 'package\.json$' }
$docs = $modifiedFiles | Where-Object { $_ -match '\.(md|toml)$' }

Write-Host "Main pages: $($mainPages.Count)"
Write-Host "Article pages: $($articlePages.Count)"
Write-Host "CSS: $($cssFiles.Count)"
Write-Host "Package: $($packageFiles.Count)"
Write-Host "Docs: $($docs.Count)"
Write-Host "Rebrand Titik Jabar selesai ✅"