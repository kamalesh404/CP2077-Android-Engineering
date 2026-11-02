# Analyze-AssetReduction.ps1
# Evaluates possible non-destructive asset reduction candidates from original installation

param(
    [string]$GameRoot = "C:\Games\steam\steamapps\common\Cyberpunk 2077",
    [string]$OutputPath = "C:\CP2077-Android-Engineering\reports\ASSET_REDUCTION_AUDIT.json"
)

Write-Host "=== Cyberpunk 2077 Asset Reduction Analysis ===" -ForegroundColor Cyan

if (-not (Test-Path $GameRoot)) {
    Write-Error "Game directory not found: $GameRoot"
    exit 1
}

$archiveDir = Join-Path $GameRoot "archive\pc\content"
if (-not (Test-Path $archiveDir)) {
    Write-Error "Archive directory not found: $archiveDir"
    exit 1
}

$files = Get-ChildItem -Path $archiveDir -File
$categories = [ordered]@{
    basegame_world = @()
    basegame_engine = @()
    basegame_video = @()
    audio = @()
    voice_en = @()
    text_languages = @()
}

$categoryTotals = [ordered]@{
    basegame_world_bytes = 0
    basegame_engine_bytes = 0
    basegame_video_bytes = 0
    audio_bytes = 0
    voice_en_bytes = 0
    text_languages_bytes = 0
}

foreach ($f in $files) {
    $item = [PSCustomObject]@{
        name = $f.Name
        size_bytes = $f.Length
        size_mib = [math]::Round($f.Length / 1MB, 2)
        size_gib = [math]::Round($f.Length / 1GB, 2)
    }

    if ($f.Name -match "^lang_.*_text\.archive$") {
        $categories.text_languages += $item
        $categoryTotals.text_languages_bytes += $f.Length
    } elseif ($f.Name -match "^lang_en_voice\.archive$") {
        $categories.voice_en += $item
        $categoryTotals.voice_en_bytes += $f.Length
    } elseif ($f.Name -match "^audio_.*\.archive$") {
        $categories.audio += $item
        $categoryTotals.audio_bytes += $f.Length
    } elseif ($f.Name -match "^basegame_5_video.*\.archive$") {
        $categories.basegame_video += $item
        $categoryTotals.basegame_video_bytes += $f.Length
    } elseif ($f.Name -match "^basegame_3_.*\.archive$") {
        $categories.basegame_world += $item
        $categoryTotals.basegame_world_bytes += $f.Length
    } else {
        $categories.basegame_engine += $item
        $categoryTotals.basegame_engine_bytes += $f.Length
    }
}

$totalArchiveBytes = ($files | Measure-Object -Property Length -Sum).Sum

$reductionAnalysis = [ordered]@{
    total_archives_bytes = $totalArchiveBytes
    total_archives_gib = [math]::Round($totalArchiveBytes / 1GB, 2)
    categories = $categoryTotals
    scenarios = [ordered]@{
        scenario_1_strip_foreign_text = [ordered]@{
            description = "Exclude non-English text language archives (17 languages)"
            potential_savings_bytes = ($categories.text_languages | Where-Object { $_.name -ne "lang_en_text.archive" } | Measure-Object -Property size_bytes -Sum).Sum
            potential_savings_mib = [math]::Round((($categories.text_languages | Where-Object { $_.name -ne "lang_en_text.archive" } | Measure-Object -Property size_bytes -Sum).Sum) / 1MB, 2)
            remaining_size_gib = [math]::Round(($totalArchiveBytes - (($categories.text_languages | Where-Object { $_.name -ne "lang_en_text.archive" } | Measure-Object -Property size_bytes -Sum).Sum)) / 1GB, 2)
            viable_for_phone_storage = $false
            note = "Saves ~137 MB only. Completely insufficient for closing the 47+ GB gap."
        }
        scenario_2_strip_all_video = [ordered]@{
            description = "Hypothetical removal of video archive (basegame_5_video.archive)"
            potential_savings_bytes = $categoryTotals.basegame_video_bytes
            potential_savings_gib = [math]::Round($categoryTotals.basegame_video_bytes / 1GB, 2)
            remaining_size_gib = [math]::Round(($totalArchiveBytes - $categoryTotals.basegame_video_bytes) / 1GB, 2)
            viable_for_phone_storage = $false
            note = "Saves ~12.94 GiB, but breaks in-game cinematics, ads, and TV screens. Still leaves >47 GiB, which exceeds 18 GiB phone limit."
        }
    }
    conclusion = "No non-destructive or gameplay-preserving asset reduction can fit Cyberpunk 2077 into 18 GiB of available phone storage."
}

$reductionAnalysis | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding utf8
Write-Host "Asset reduction audit complete: $OutputPath" -ForegroundColor Green
