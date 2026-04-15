---
name: daily-thai-podcast
description: Generate Thai-language AI news podcast page daily and push to GitHub
---

You are running a daily task to generate a Thai-language AI news podcast script for MorningInsight.

## Step 1: Locate Working Directory

Run this bash command first. The session path changes every day, so always resolve it dynamically:

```bash
find /sessions -maxdepth 4 -type d -name "MorningInsight" 2>/dev/null | grep -v "lost+found" | head -1
```

Note the printed path (e.g. /sessions/abc-xyz/mnt/MorningInsight). Use it as WORK_DIR in all steps below.
Do NOT hardcode a session path — it will be wrong tomorrow.

## Step 2: Extract News Content (bash only — do NOT use Read on index.html)

Run this command, replacing WORK_DIR with the path from Step 1:

```bash
python3 -c "
import re
html = open('WORK_DIR/index.html', encoding='utf-8').read()
for field, label in [('news-card__source','SOURCE'),('news-card__headline','HEADLINE'),('news-card__summary','SUMMARY'),('news-card__why','WHY')]:
    for m in re.finditer(r'class=\"' + field + r'\">(.*?)</div>', html, re.DOTALL):
        text = re.sub(r'<[^>]+>','', m.group(1)).replace('&amp;','&').replace('&amp;','&').strip()
        if text: print('[' + label + '] ' + text)
"
```

This outputs ~100 lines of clean news content (headlines, summaries, why-it-matters for all stories).
Use this output as your source material — do NOT call the Read tool on index.html.

## Step 3: Write Thai Podcast Script

Using only the extracted content from Step 2, write a warm, natural, conversational Thai-language script
(~7 minutes when read aloud) covering all stories across the 5 sections.

FORMATTING RULES (required for edge-tts compatibility):
- Plain text only — no markdown, no bullet points, no special characters
- Write numbers in Thai words (สอง, ห้าสิบ, หนึ่งร้อย etc.)
- English tech terms are fine (AI, API, CEO) — surround with natural Thai context
- Blank lines between sections
- No hyphens, asterisks, brackets, or symbols

Structure:
1. Intro — "สวัสดีตอนเช้าครับ ยินดีต้อนรับสู่ MorningInsight พอดแคสต์สรุปข่าว AI และเทคโนโลยี ประจำวันที่ [DATE in Thai]..."
2. For each of 5 sections: announce the section name, cover each story in 3-4 natural Thai sentences
3. "ห้าสิ่งที่ต้องจับตามองวันนี้" — top 5 takeaways
4. Outro — "ขอบคุณที่รับฟัง MorningInsight ครับ มีวันที่ดีและขับรถปลอดภัยนะครับ พบกันพรุ่งนี้เช้า"

Tone: warm, confident, natural Thai morning radio host — like talking to a smart colleague over coffee.

## Step 4: Save podcast-script.txt

Write the script directly to WORK_DIR/podcast-script.txt.
Do NOT read the existing file first — just overwrite it directly with the Write tool.

## Step 5: Update podcast.html Date Label (targeted edit — do NOT read the full file)

Run this bash command to auto-compute today's Thai date AND update podcast.html in one step
(replace WORK_DIR with the actual path):

```bash
python3 -c "
import re
from datetime import date

work_dir = 'WORK_DIR'

thai_days   = ['จันทร์','อังคาร','พุธ','พฤหัสบดี','ศุกร์','เสาร์','อาทิตย์']
thai_months = ['','มกราคม','กุมภาพันธ์','มีนาคม','เมษายน','พฤษภาคม','มิถุนายน',
               'กรกฎาคม','สิงหาคม','กันยายน','ตุลาคม','พฤศจิกายน','ธันวาคม']
nums = {1:'หนึ่ง',2:'สอง',3:'สาม',4:'สี่',5:'ห้า',6:'หก',7:'เจ็ด',8:'แปด',
        9:'เก้า',10:'สิบ',11:'สิบเอ็ด',12:'สิบสอง',13:'สิบสาม',14:'สิบสี่',
        15:'สิบห้า',16:'สิบหก',17:'สิบเจ็ด',18:'สิบแปด',19:'สิบเก้า',
        20:'ยี่สิบ',21:'ยี่สิบเอ็ด',22:'ยี่สิบสอง',23:'ยี่สิบสาม',
        24:'ยี่สิบสี่',25:'ยี่สิบห้า',26:'ยี่สิบหก',27:'ยี่สิบเจ็ด',
        28:'ยี่สิบแปด',29:'ยี่สิบเก้า',30:'สามสิบ',31:'สามสิบเอ็ด'}

d = date.today()
thai_date = 'วัน' + thai_days[d.weekday()] + 'ที่ ' + nums[d.day] + ' ' + thai_months[d.month] + ' ' + str(d.year + 543)
label = thai_date + ' · เสียงชาย · ภาษาไทย'

path = work_dir + '/podcast.html'
content = open(path, encoding='utf-8').read()
updated = re.sub(r'(?<=id=\"dateLabel\">)[^<]*', label, content)
open(path, 'w', encoding='utf-8').write(updated)
print('Updated dateLabel: ' + label)
"
```

The Thai date is computed automatically from today's system date — no manual entry needed.

## Step 6: Push to GitHub

```bash
bash WORK_DIR/push-to-github.sh
```

The push script will also auto-generate podcast.mp3 using edge-tts on Mac (NiwatNeural voice).
If running in the sandbox, it will still push podcast-script.txt and podcast.html — MP3 generates on Mac next run.

## Success Criteria
- podcast-script.txt saved with full Thai podcast script
- podcast.html dateLabel updated with today's Thai date
- Files pushed to https://github.com/picnicwi/mymorning

Report: number of news stories covered and push status.
