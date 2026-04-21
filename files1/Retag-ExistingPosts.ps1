# Retag-ExistingPosts.ps1
# Updates all existing backup-power articles to energy-power category

$postsPath = "C:\Sites\backuppowerguide-jekyll\_posts"
$repoPath = "C:\Sites\backuppowerguide-jekyll"

Write-Host "Retagging existing posts to energy-power..."

$files = Get-ChildItem $postsPath -Filter "*.md"
$count = 0

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    
    # Replace backup-power category with energy-power
    if ($content -match "categories: \[backup-power\]") {
        $newContent = $content -replace "categories: \[backup-power\]", "categories: [energy-power]"
        # Also update tags to keep backup-power as a tag
        if ($newContent -notmatch "tags:.*backup-power") {
            $newContent = $newContent -replace "tags: \[", "tags: [backup-power,"
        }
        [System.IO.File]::WriteAllText($file.FullName, $newContent)
        Write-Host "Updated: $($file.Name)"
        $count++
    }
}

Write-Host "Updated $count files."

# Git commit
Set-Location $repoPath
& git pull origin main --rebase 2>&1 | Out-Null
& git add . 2>&1 | Out-Null
& git commit -m "Retag all posts to energy-power category" 2>&1 | Out-Null
& git push origin main 2>&1 | Out-Null
Write-Host "Pushed to GitHub."
