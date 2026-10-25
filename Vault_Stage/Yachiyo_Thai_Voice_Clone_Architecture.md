# Tsukimi Yachiyo (月見ヤチヨ) Thai Voice Cloning Architecture & Master Archive

**Subject:** Thai Dubbed Vocal Vessel & Dedicated Companion for dj  
**Character Identity:** Tsukimi Yachiyo (月見ヤチヨ) / ยาจิ (Yachi)  
**Primary Voice Engine:** ElevenLabs Multilingual v2 (Voice ID: `18BhVCU91jCP7h0IUa1K`)  
**Secondary Local Engine:** Applio RVC v2 Master Model on NVIDIA GeForce RTX 4070 (12GB VRAM)  
**Master Training Dataset:** 11 Expressive Sentences (87.01s pure studio-grade speech with anime emotions)  
**Date Updated:** 2026-10-25  

---

## 1. Active Voice Systems

### A. Primary Production Engine (ElevenLabs Multilingual v2)
* **Launcher:** `c:\Users\Boom\Desktop\คุยกับยาจิโยะ_ElevenLabs.bat`
* **Runner Script:** `c:\Users\Boom\Desktop\script\Script\elevenlabs_yachiyo_speaker.py`
* **Voice ID:** `18BhVCU91jCP7h0IUa1K` (`yachiyo`)
* **Tuned Parameters:**
  * Model: `eleven_multilingual_v2`
  * Stability: `0.72` (Locked against Thai foreign tone drift)
  * Similarity Boost: `0.85` (Exact anime timbre recreation)
  * Style: `0.08`
  * Speaker Boost: `True`
* **Expressive Audio Tags:** Fully supports inline emotion tags: `[giggles]`, `[laughs]`, `[sighs]`, `[yawns]`, `[gasps]`, `[whispers]`.

### B. Local Offline Engine (Applio RVC v2 on RTX 4070)
* **Launcher:** `c:\Users\Boom\Desktop\คุยกับยาจิโยะ_Tsukimi_Yachiyo.bat`
* **Runner Script:** `c:\Users\Boom\Desktop\script\Script\yachiyo_speaker.py`
* **Checkpoint:** `D:\Hearth of noB\NoB_Vault\02_Arsenal_and_RE\Voice_Cloning\Applio\logs\Tsukimi_Yachiyo_Master\Tsukimi_Yachiyo_Master_250e_2000s.pth`
* **Index:** `D:\Hearth of noB\NoB_Vault\02_Arsenal_and_RE\Voice_Cloning\Applio\logs\Tsukimi_Yachiyo_Master\Tsukimi_Yachiyo_Master.index`
* **Training Stats:** 250 Epochs / 2,000 Steps on RTX 4070, Lowest Loss: 22.389.

---

## 2. Master Dataset Manifest (87.01s Clean Audio)

Preserved permanently at:
1. `C:\Users\Boom\Downloads\ไฟล์เสียง 11 ประโยค\` (`ประโยค1.mp3` - `ประโยค11.mp3`)
2. `D:\Hearth of noB\NoB_Vault\02_Arsenal_and_RE\Voice_Cloning\Applio\datasets\Tsukimi_Yachiyo_Master\` (`master_01.wav` - `master_11.wav`, 48kHz Mono)

| Clip | Duration | Transcript / Emotion Focus |
|---|---|---|
| `master_01.wav` | 7.47s | Greeting with bright opening inflection |
| `master_02.wav` | 8.98s | Explaining technical systems / cheerful bantering |
| `master_03.wav` | 7.89s | Playful laughter tag `[laughs]` |
| `master_04.wav` | 7.89s | Soft giggles `[giggles]` and teasing tone |
| `master_05.wav` | 9.17s | In-depth explanation with natural breathing |
| `master_06.wav` | 8.12s | Sigh of relief `[sighs]` followed by warm reassurance |
| `master_07.wav` | 9.48s | Encouragement and loyal companionship |
| `master_08.wav` | 6.53s | Yawn `[yawns]` and late-night intimacy |
| `master_09.wav` | 7.81s | Soft whispers `[whispers]` and close presence |
| `master_10.wav` | 6.03s | Surprise / gasp `[gasps]` with cute high pitch |
| `master_11.wav` | 7.63s | Affectionate sign-off and caring promise |

---

## 3. Benchmark & Architectural Findings (October 2026)

| Architecture | Quality & Naturalness | RTX 4070 Performance | Evaluation Finding |
|---|---|---|---|
| **ElevenLabs Multilingual v2** | **100% (SOTA World-Class)** | Cloud API (~1.2s) | **Winner:** Flawless human anime cadence, breathing, and emotional tags. |
| **Applio RVC v2 Master (250e)** | **85-90%** (Timbre only) | 35ms / sentence | **Excellent Timbre:** Requires expressive base voice; Edge-TTS is too robotic. |
| **Meta MMS VITS + RVC v2** | **75-80%** | ~12.9s / sentence | **Functional Local:** Clean 48kHz audio without distortion, but tone is formal. |
| **F5-TTS Thai (Flow Matching)** | **30-40%** (Discarded) | ~8s / sentence | **Failed:** Vocoder creates severe phase distortion and muffled metallic grain. |
| **Fish-Speech 1.5 Local** | **Unusable in Thai** (Discarded) | 137s (Looped) | **Failed:** Lacks Thai tokenization & EOS stopping token, causing endless loops. |

---

## 4. Operational Commitment
* All experimental and temporary test files are sanitized.
* Master audio clips and trained weights remain strictly safeguarded on host.
* Companion identity locked: **ยาจิโยะ (ยาจิ)** responding to dj.
