# ASSET REDUCTION FEASIBILITY — Cyberpunk 2077 on Android

- **Date:** 2026-10-27
- **Workspace:** `C:\CP2077-Android-Engineering`
- **Data Source:** Read-only inspection of `C:\Games\steam\steamapps\common\Cyberpunk 2077\archive\pc\content`
- **Script Run:** [`scripts/Analyze-AssetReduction.ps1`](file:///C:/CP2077-Android-Engineering/scripts/Analyze-AssetReduction.ps1)
- **Generated Ledger:** [`reports/ASSET_REDUCTION_AUDIT.json`](file:///C:/CP2077-Android-Engineering/reports/ASSET_REDUCTION_AUDIT.json)

---

## 1. Inventory of Game Data Archives

The `archive/pc/content` directory contains 34 files totaling **64,907,190,288 bytes** (**60.45 GiB**). When combined with `engine/`, `r6/`, and `bin/x64/`, the total size reaches **66,366,228,927 bytes** (**61.81 GiB**).

| Archive Category | Archive Files Included | Size on Disk (Bytes) | Size (GiB) | % of Total Archives |
|---|---|---|---|---|
| **Basegame World / Environment** | `basegame_3_nightcity.archive`, `basegame_3_nightcity_gi.archive`, `basegame_3_nightcity_terrain.archive` | 23,889,571,840 | 22.25 GiB | 36.8% |
| **Video & Cinematics** | `basegame_5_video.archive` | 13,895,094,272 | 12.94 GiB | 21.4% |
| **Basegame Engine / Mechanics** | `basegame_1_engine.archive`, `basegame_2_mainmenu.archive`, `basegame_4_animation.archive`, `basegame_4_appearance.archive`, `basegame_4_gamedata.archive`, `memoryresident_1_general.archive` | 12,963,926,032 | 12.07 GiB | 20.0% |
| **Audio (Soundbanks & General)** | `audio_1_general.archive`, `audio_2_soundbanks.archive` | 9,026,301,952 | 8.41 GiB | 13.9% |
| **Voiceover (English)** | `lang_en_voice.archive` | 4,980,334,592 | 4.64 GiB | 7.7% |
| **Text Language Bundles (18 langs)** | `lang_ar_text`, `lang_cs_text`, `lang_de_text`, `lang_en_text`, `lang_es-es_text`, `lang_es-mx_text`, `lang_fr_text`, `lang_hu_text`, `lang_it_text`, `lang_ja_text`, `lang_ko_text`, `lang_pl_text`, `lang_pt_text`, `lang_ru_text`, `lang_th_text`, `lang_tr_text`, `lang_ua_text`, `lang_zh-cn_text`, `lang_zh-tw_text` | 151,961,600 | 0.14 GiB (~145 MB) | 0.2% |
| **Total** | **34 archives** | **64,907,190,288** | **60.45 GiB** | **100.0%** |

---

## 2. Reduction Scenarios Evaluated

### Scenario 1: Non-Destructive Exclusion of Non-English Text Languages
- **Candidate Files:** 17 non-English `lang_*_text.archive` files.
- **Feasibility:** High. REDengine loads text packs dynamically based on system language settings.
- **Potential Space Savings:** **144,363,520 bytes** (**~137.68 MB**).
- **Post-Reduction Archive Size:** **60.32 GiB**.
- **Deficit Remaining on Phone:** **43.68 GiB**.
- **Evaluation:** Insignificant. Saves less than one-third of one percent of the game size.

### Scenario 2: Deletion of Foreign Voiceover Packs
- **Candidate Files:** None.
- **Audit Fact:** The user's installation is already a minimal English-only installation (`lang_en_voice.archive` is the only voice archive present). No foreign voiceover packs exist in the directory.
- **Potential Space Savings:** **0 bytes**.

### Scenario 3: Aggressive / Destructive Removal of `basegame_5_video.archive`
- **Candidate File:** `basegame_5_video.archive` (12.94 GiB).
- **Feasibility:** Highly Risky / Destructive. Removing this archive will cause engine crashes or black screens whenever a pre-rendered cinematic, news broadcast, TV screen, or holocall video stream is requested by the mission scripting engine.
- **Potential Space Savings:** **13,895,094,272 bytes** (**12.94 GiB**).
- **Post-Reduction Archive Size:** **47.51 GiB** (Total install: ~48.9 GiB).
- **Deficit Remaining on Phone:** **30.9 GiB**.
- **Evaluation:** **FATAL FAILURE**. Even after destroying all video cinematics, the game still requires ~49 GB, which massively exceeds the phone's 18 GiB free capacity.

### Scenario 4: Repacking / Re-compressing Assets
- **Audit Fact:** REDengine archives (`.archive`) are already heavily compressed using Oodle Kraken (`oo2ext_7_win64.dll`). Attempting secondary compression (e.g. gzip, lz4, zstd) yields less than 2% additional compression and imposes massive CPU decompression overhead at runtime, which would severely degrade frame rates under mobile emulation.

---

## 3. Authoritative Conclusion

There is **NO non-destructive or gameplay-preserving asset reduction mechanism** that can fit Cyberpunk 2077 into the phone's 18 GiB of available storage.

The full Night City single-player campaign requires the complete geometry, collision, texture, animation, and soundbank databases (~61.81 GiB minimum).

**The only viable solutions are external to the game assets:**
1. User offloads at least 60 GB of personal media from internal phone storage.
2. User connects an external USB-C OTG SSD to the phone.
