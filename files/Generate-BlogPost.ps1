# Generate-BlogPost.ps1
# Calls Ollama API to generate a Jekyll blog post and saves it to _posts

$ollamaUrl = "http://localhost:11434/api/generate"
$postsPath = "C:/Sites/backuppowerguide-jekyll/_posts"
$repoPath = "C:\Sites\backuppowerguide-jekyll"
$logFile = "C:\Clawdbot\generate.log"
$usedTopicsFile = "C:\Clawdbot\used-topics.txt"
$model = "qwen2.5:7b"

function Write-Log {
    param($msg)
    $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg"
    Add-Content -Path $logFile -Value $entry
    Write-Host $entry
}

# Topic list with image keywords
$topicData = @(
    @{topic="portable generators buying guide"; image="portable generator outdoor"},
    @{topic="whole house generator installation"; image="house generator installation"},
    @{topic="solar battery storage systems"; image="solar battery storage"},
    @{topic="UPS systems for home office"; image="UPS power supply office"},
    @{topic="propane vs natural gas generators"; image="propane gas generator"},
    @{topic="how long can a generator run"; image="generator running fuel"},
    @{topic="generator maintenance tips"; image="generator maintenance engine"},
    @{topic="best battery backup for power outages"; image="battery backup power"},
    @{topic="solar panel sizing for home backup"; image="solar panels roof home"},
    @{topic="inverter generator vs conventional generator"; image="inverter generator quiet"},
    @{topic="how to calculate backup power needs"; image="electricity power meter home"},
    @{topic="transfer switch installation guide"; image="electrical transfer switch panel"},
    @{topic="lithium vs lead acid batteries for backup power"; image="lithium battery storage"},
    @{topic="wind power for home backup"; image="wind turbine residential"},
    @{topic="EcoFlow vs Jackery power stations"; image="portable power station camping"},
    @{topic="whole home battery backup systems"; image="home battery wall unit"},
    @{topic="generator safety tips"; image="generator safety outdoor"},
    @{topic="off grid solar system setup"; image="off grid solar cabin"},
    @{topic="backup power for medical equipment"; image="medical equipment power hospital"},
    @{topic="power outage preparation checklist"; image="emergency preparedness supplies"},
    @{topic="how to wire a generator to your house"; image="electrical wiring generator"},
    @{topic="best solar generators for home use"; image="solar generator home"},
    @{topic="automatic standby generator reviews"; image="standby generator home automatic"},
    @{topic="how much does a whole house generator cost"; image="whole house generator cost"},
    @{topic="generator fuel consumption calculator"; image="fuel gauge calculator"},
    @{topic="best portable power stations 2026"; image="portable power station technology"},
    @{topic="how to store gasoline for generator"; image="fuel storage container gasoline"},
    @{topic="carbon monoxide safety with generators"; image="carbon monoxide detector safety"},
    @{topic="battery backup vs generator comparison"; image="battery generator comparison"},
    @{topic="how to size a generator for your home"; image="generator sizing home power"},
    @{topic="solar power bank for emergency backup"; image="solar power bank charging"},
    @{topic="best inverters for solar systems"; image="solar inverter installation"},
    @{topic="grid tie vs off grid solar systems"; image="solar grid system rooftop"},
    @{topic="how to install solar panels on roof"; image="solar panel installation roof"},
    @{topic="DIY solar battery bank build"; image="DIY solar battery bank"},
    @{topic="best deep cycle batteries for solar"; image="deep cycle battery solar"},
    @{topic="solar charge controller guide"; image="solar charge controller"},
    @{topic="how much does solar battery storage cost"; image="solar battery cost home"},
    @{topic="Tesla Powerwall alternatives"; image="home battery wall energy storage"},
    @{topic="Enphase IQ battery review"; image="home energy battery storage"},
    @{topic="how to maintain a backup generator"; image="generator engine maintenance oil"},
    @{topic="generator load calculation guide"; image="electrical load calculation"},
    @{topic="best dual fuel generators"; image="dual fuel generator"},
    @{topic="propane generator advantages"; image="propane tank generator"},
    @{topic="natural gas whole house generator installation"; image="natural gas generator home"},
    @{topic="how to connect solar panels in series vs parallel"; image="solar panel wiring diagram"},
    @{topic="MPPT vs PWM solar charge controllers"; image="solar charge controller panel"},
    @{topic="off grid cabin power system design"; image="off grid cabin solar power"},
    @{topic="backup power for sump pump"; image="sump pump basement flood"},
    @{topic="backup power for refrigerator during outage"; image="refrigerator food power outage"},
    @{topic="how to keep food cold during power outage"; image="food storage ice cooler"},
    @{topic="emergency power for well pump"; image="well pump water rural"},
    @{topic="backup power for electric heating"; image="electric heating home winter"},
    @{topic="backup power for air conditioning"; image="air conditioning unit home"},
    @{topic="power outage survival guide"; image="emergency survival kit candles"},
    @{topic="how to prepare for hurricane power outages"; image="hurricane storm preparation"},
    @{topic="wildfire power outage preparation"; image="wildfire emergency evacuation"},
    @{topic="winter storm power outage tips"; image="winter storm snow house"},
    @{topic="how long do power outages typically last"; image="power lines storm outage"},
    @{topic="smart home backup power integration"; image="smart home technology integration"},
    @{topic="backup power for home security system"; image="home security system camera"},
    @{topic="UPS for network router and modem"; image="router modem network office"},
    @{topic="best UPS for desktop computer"; image="computer UPS battery backup"},
    @{topic="how to choose a UPS for home office"; image="home office computer setup"},
    @{topic="APC vs CyberPower UPS comparison"; image="UPS battery backup unit"},
    @{topic="how does a UPS work"; image="UPS uninterruptible power supply"},
    @{topic="online vs offline UPS systems"; image="power supply unit technology"},
    @{topic="power conditioning for sensitive electronics"; image="electronics power conditioning"},
    @{topic="surge protector vs UPS difference"; image="surge protector power strip"},
    @{topic="backup power for home theater system"; image="home theater entertainment system"},
    @{topic="generator interlock kit installation"; image="electrical panel interlock"},
    @{topic="manual vs automatic transfer switch"; image="electrical transfer switch"},
    @{topic="Generac vs Kohler generator comparison"; image="standby generator comparison"},
    @{topic="Briggs and Stratton generator review"; image="generator engine outdoor"},
    @{topic="Honda generator vs Chinese generators"; image="generator comparison quality"},
    @{topic="Champion generator review"; image="champion generator portable"},
    @{topic="Westinghouse generator review"; image="portable generator outdoor power"},
    @{topic="quietest generators for residential use"; image="quiet generator residential"},
    @{topic="how to reduce generator noise"; image="generator soundproofing enclosure"},
    @{topic="generator enclosure DIY build"; image="generator shed enclosure wood"},
    @{topic="solar panel efficiency explained"; image="solar panel efficiency technology"},
    @{topic="monocrystalline vs polycrystalline solar panels"; image="solar panel types comparison"},
    @{topic="bifacial solar panels explained"; image="bifacial solar panel dual"},
    @{topic="how long do solar panels last"; image="solar panels roof longevity"},
    @{topic="solar panel cleaning and maintenance"; image="solar panel cleaning maintenance"},
    @{topic="best solar panels for cloudy climates"; image="solar panels cloudy sky"},
    @{topic="how to monitor solar power production"; image="solar monitoring system app"},
    @{topic="net metering explained"; image="electricity meter solar net"},
    @{topic="solar power ROI calculation"; image="solar investment return calculator"},
    @{topic="solar incentives and tax credits 2026"; image="solar tax credit government"},
    @{topic="community solar programs explained"; image="community solar farm field"},
    @{topic="portable solar panels for camping"; image="portable solar panel camping"},
    @{topic="solar powered water pump systems"; image="solar water pump irrigation"},
    @{topic="wind turbine for residential use"; image="small wind turbine home"},
    @{topic="micro hydro power for off grid homes"; image="micro hydro water power"},
    @{topic="combined solar and wind hybrid systems"; image="solar wind hybrid energy"},
    @{topic="backup power cost benefit analysis"; image="cost benefit analysis finance"},
    @{topic="how to sell excess solar power back to grid"; image="solar grid export meter"}
)

# Load used topics
if (Test-Path $usedTopicsFile) {
    $usedTopics = Get-Content $usedTopicsFile
} else {
    $usedTopics = @()
}

# Filter out used topics
$availableTopics = $topicData | Where-Object { $usedTopics -notcontains $_.topic }

# If all topics used, reset
if ($availableTopics.Count -eq 0) {
    $availableTopics = $topicData
    Clear-Content $usedTopicsFile
    Write-Log "All topics used - resetting list"
}

# Pick unused topic
$selected = $availableTopics | Get-Random
$topic = $selected.topic
$imageKeyword = $selected.image

# Record as used
Add-Content -Path $usedTopicsFile -Value $topic

$date = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")
$slug = $topic.ToLower() -replace '[^a-z0-9\s-]', '' -replace '\s+', '-'
$filename = "$date-$slug.md"
$filepath = "$postsPath/$filename"

Write-Log "Generating article: $topic"

$prompt = @"
Write an 800 word SEO blog article about: $topic

The article is for a home backup power website called "Backup Power Guide".

Within the article naturally include 2-3 product recommendations relevant to the topic. Format each recommendation as a markdown link using this Amazon affiliate URL format:
[Product Name](https://www.amazon.com.au/s?k=SEARCH+TERM&tag=owlno-22)

Replace SEARCH+TERM with relevant search keywords for that product type.

Output ONLY the Jekyll markdown file content, starting with --- on the very first line.

Use this exact format:
---
layout: single
title: "YOUR TITLE HERE"
date: $date
categories: [backup-power]
tags: [backup-power, generators, solar, home-energy]
image_keyword: "$imageKeyword"
excerpt: "A one sentence description of the article."
---

Then write the full article in markdown format with proper headings, paragraphs, and the Amazon affiliate links naturally placed within the content.

Do not include any explanation, preamble, or text outside the markdown file.
"@

$body = @{
    model = $model
    prompt = $prompt
    stream = $false
    options = @{
        temperature = 0.7
        num_predict = 1000
    }
} | ConvertTo-Json -Depth 3

Write-Log "Calling Ollama API..."

try {
    $response = Invoke-RestMethod -Uri $ollamaUrl -Method Post -Body $body -ContentType "application/json" -TimeoutSec 600
    $content = $response.response

    if ($content -and $content.Length -gt 100) {
        if (-not $content.TrimStart().StartsWith("---")) {
            $content = "---`n" + $content
        }

        [System.IO.File]::WriteAllText($filepath, $content)
        Write-Log "Saved: $filename ($($content.Length) bytes)"

        Set-Location $repoPath
        & git pull origin main --rebase 2>&1 | Out-Null
        & git add . 2>&1 | Out-Null
        & git commit -m "New post: $topic" 2>&1 | Out-Null
        & git push origin main 2>&1 | Out-Null
        Write-Log "Pushed to GitHub: $filename"

    } else {
        Write-Log "ERROR: Response too short or empty"
    }
} catch {
    Write-Log "ERROR: $_"
}
