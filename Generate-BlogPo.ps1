# Generate-BlogPost.ps1
# Multi-category article generator with Pexels images

$ollamaUrl = "http://localhost:11434/api/generate"
$postsPath = "C:/Sites/backuppowerguide-jekyll/_posts"
$repoPath = "C:\Sites\backuppowerguide-jekyll"
$logFile = "C:\Clawdbot\generate.log"
$usedTopicsFile = "C:\Clawdbot\used-topics.txt"
$model = "qwen2.5:7b"
$pexelsKey = "l3yQI4UKtk0Jsaquljvdmmit9bqgzMVgzqD6ftaqmemf96x5xv9zkFo2"

function Write-Log {
    param($msg)
    $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg"
    Add-Content -Path $logFile -Value $entry
    Write-Host $entry
}

function Get-PexelsImage {
    param($keyword)
    try {
        $encoded = [System.Uri]::EscapeDataString($keyword)
        $url = "https://api.pexels.com/v1/search?query=$encoded&per_page=5&orientation=landscape"
        $headers = @{ Authorization = $pexelsKey }
        $response = Invoke-RestMethod -Uri $url -Headers $headers -TimeoutSec 15
        if ($response.photos -and $response.photos.Count -gt 0) {
            $photo = $response.photos | Get-Random
            return @{
                large = $photo.src.large2x
                medium = $photo.src.large
                photographer = $photo.photographer
            }
        }
    } catch {
        Write-Log "Pexels error: $_"
    }
    return $null
}

# Each topic has: topic text, category slug, image keyword, tags, Amazon search term
$topicData = @(
    # ENERGY & POWER
    @{topic="portable generators buying guide for homeowners"; category="energy-power"; subcategory="generators"; image="portable generator outdoor power"; tags="generators,backup-power,home-energy"; amazon="portable generator home"},
    @{topic="whole house generator installation guide"; category="energy-power"; subcategory="generators"; image="house generator installation"; tags="generators,backup-power,installation"; amazon="whole house generator"},
    @{topic="solar battery storage systems for home"; category="energy-power"; subcategory="solar"; image="solar battery storage home"; tags="solar,battery,backup-power"; amazon="solar battery storage"},
    @{topic="UPS systems for home office power backup"; category="energy-power"; subcategory="batteries"; image="UPS power supply office"; tags="UPS,backup-power,office"; amazon="UPS battery backup"},
    @{topic="propane vs natural gas generators compared"; category="energy-power"; subcategory="generators"; image="propane gas generator"; tags="generators,propane,natural-gas"; amazon="propane generator"},
    @{topic="how long can a generator run continuously"; category="energy-power"; subcategory="generators"; image="generator running fuel tank"; tags="generators,fuel,runtime"; amazon="generator fuel tank"},
    @{topic="generator maintenance tips and schedule"; category="energy-power"; subcategory="generators"; image="generator engine maintenance"; tags="generators,maintenance"; amazon="generator maintenance kit"},
    @{topic="best battery backup systems for power outages"; category="energy-power"; subcategory="batteries"; image="battery backup power home"; tags="battery,backup-power"; amazon="home battery backup"},
    @{topic="solar panel sizing guide for home backup"; category="energy-power"; subcategory="solar"; image="solar panels roof home"; tags="solar,sizing,home"; amazon="solar panels home"},
    @{topic="inverter generator vs conventional generator"; category="energy-power"; subcategory="generators"; image="inverter generator quiet"; tags="generators,inverter"; amazon="inverter generator"},
    @{topic="transfer switch installation guide for generators"; category="energy-power"; subcategory="generators"; image="electrical transfer switch panel"; tags="generators,transfer-switch,installation"; amazon="generator transfer switch"},
    @{topic="lithium vs lead acid batteries for backup power"; category="energy-power"; subcategory="batteries"; image="lithium battery storage home"; tags="battery,lithium,backup-power"; amazon="lithium battery backup"},
    @{topic="Tesla Powerwall alternatives for home energy storage"; category="energy-power"; subcategory="batteries"; image="home battery wall energy storage"; tags="battery,solar,energy-storage"; amazon="home battery storage"},
    @{topic="off grid solar system setup guide"; category="energy-power"; subcategory="solar"; image="off grid solar cabin"; tags="solar,off-grid,DIY"; amazon="off grid solar kit"},
    @{topic="best portable power stations for home use"; category="energy-power"; subcategory="batteries"; image="portable power station"; tags="power-station,battery,portable"; amazon="portable power station"},
    @{topic="how to sell excess solar power back to the grid"; category="energy-power"; subcategory="solar"; image="solar grid export meter"; tags="solar,net-metering,grid"; amazon="solar monitoring system"},
    @{topic="solar incentives and tax credits 2026 Australia"; category="energy-power"; subcategory="solar"; image="solar tax credit government rebate"; tags="solar,rebates,Australia"; amazon="solar panels Australia"},
    @{topic="wind turbine for residential home use"; category="energy-power"; subcategory="generators"; image="small wind turbine home"; tags="wind,renewable,home-energy"; amazon="residential wind turbine"},
    @{topic="backup power for medical equipment at home"; category="energy-power"; subcategory="batteries"; image="medical equipment power home"; tags="medical,backup-power,UPS"; amazon="medical grade UPS"},
    @{topic="generator safety tips for homeowners"; category="energy-power"; subcategory="generators"; image="generator safety outdoor carbon monoxide"; tags="generators,safety,carbon-monoxide"; amazon="carbon monoxide detector"},

    # HOME & GARDEN
    @{topic="budget kitchen renovation ideas under 5000"; category="home-garden"; subcategory="renovation"; image="kitchen renovation modern budget"; tags="kitchen,renovation,budget"; amazon="kitchen renovation supplies"},
    @{topic="DIY bathroom renovation step by step guide"; category="home-garden"; subcategory="renovation"; image="bathroom renovation DIY"; tags="bathroom,renovation,DIY"; amazon="bathroom renovation kit"},
    @{topic="best plants for Australian backyard gardens"; category="home-garden"; subcategory="garden"; image="Australian garden backyard plants"; tags="garden,plants,Australia"; amazon="garden plants Australia"},
    @{topic="how to build a raised garden bed"; category="home-garden"; subcategory="garden"; image="raised garden bed vegetable"; tags="garden,DIY,raised-bed"; amazon="raised garden bed kit"},
    @{topic="interior design trends 2026 for Australian homes"; category="home-garden"; subcategory="interior"; image="modern interior design home 2026"; tags="interior-design,home,trends"; amazon="home decor Australia"},
    @{topic="best cordless power tools for home DIY"; category="home-garden"; subcategory="tools"; image="cordless power tools workshop"; tags="tools,DIY,power-tools"; amazon="cordless power tool set"},
    @{topic="how to clean and maintain hardwood floors"; category="home-garden"; subcategory="cleaning"; image="hardwood floor cleaning polish"; tags="cleaning,floors,maintenance"; amazon="hardwood floor cleaner"},
    @{topic="home insulation guide for Australian climate"; category="home-garden"; subcategory="renovation"; image="home insulation installation"; tags="insulation,renovation,energy-efficiency"; amazon="home insulation"},
    @{topic="smart home automation on a budget"; category="home-garden"; subcategory="interior"; image="smart home automation devices"; tags="smart-home,automation,budget"; amazon="smart home starter kit"},
    @{topic="how to install a rainwater tank at home"; category="home-garden"; subcategory="garden"; image="rainwater tank installation garden"; tags="rainwater,sustainability,garden"; amazon="rainwater tank"},

    # OUTDOORS & CAMPING
    @{topic="best camping gear checklist for beginners"; category="outdoors-camping"; subcategory="gear"; image="camping gear checklist tent"; tags="camping,gear,beginners"; amazon="camping gear set"},
    @{topic="how to choose the right hiking boots"; category="outdoors-camping"; subcategory="hiking"; image="hiking boots trail outdoor"; tags="hiking,boots,footwear"; amazon="hiking boots Australia"},
    @{topic="4WD track driving tips for beginners Australia"; category="outdoors-camping"; subcategory="4wd"; image="4WD offroad driving Australia outback"; tags="4WD,offroad,Australia"; amazon="4WD recovery kit"},
    @{topic="best fishing spots in Australia for beginners"; category="outdoors-camping"; subcategory="fishing"; image="fishing Australia river beach"; tags="fishing,Australia,beginners"; amazon="fishing rod Australia"},
    @{topic="wilderness survival skills everyone should know"; category="outdoors-camping"; subcategory="survival"; image="wilderness survival skills fire"; tags="survival,wilderness,skills"; amazon="survival kit"},
    @{topic="best portable solar panels for camping"; category="outdoors-camping"; subcategory="gear"; image="portable solar panel camping"; tags="solar,camping,portable"; amazon="camping solar panel"},
    @{topic="how to camp safely in Australian bushland"; category="outdoors-camping"; subcategory="gear"; image="camping bushland Australia tent"; tags="camping,Australia,safety"; amazon="camping safety gear"},
    @{topic="best hiking trails in Australia for all levels"; category="outdoors-camping"; subcategory="hiking"; image="hiking trail Australia mountains"; tags="hiking,trails,Australia"; amazon="hiking gear Australia"},

    # FINANCE
    @{topic="how to create a household budget that works"; category="finance"; subcategory="budgeting"; image="household budget planning finance"; tags="budgeting,finance,savings"; amazon="budget planner book"},
    @{topic="best high interest savings accounts in Australia 2026"; category="finance"; subcategory="saving"; image="savings account bank Australia"; tags="savings,banking,Australia"; amazon="finance planner"},
    @{topic="how to start investing in ASX shares for beginners"; category="finance"; subcategory="investing"; image="stock market investing ASX shares"; tags="investing,ASX,shares,Australia"; amazon="investing books Australia"},
    @{topic="best credit cards in Australia with no annual fee"; category="finance"; subcategory="saving"; image="credit card Australia cashback"; tags="credit-cards,Australia,finance"; amazon="finance tracker"},
    @{topic="how to reduce your electricity bill in Australia"; category="finance"; subcategory="budgeting"; image="electricity bill reduction home"; tags="electricity,savings,budgeting"; amazon="energy monitor home"},
    @{topic="superannuation explained for young Australians"; category="finance"; subcategory="superannuation"; image="superannuation retirement savings Australia"; tags="superannuation,retirement,Australia"; amazon="financial planning book"},
    @{topic="how to buy your first home in Australia 2026"; category="finance"; subcategory="investing"; image="first home buyer Australia real estate"; tags="property,home-buying,Australia"; amazon="home buying guide"},
    @{topic="best insurance policies for Australian homeowners"; category="finance"; subcategory="saving"; image="home insurance policy Australia"; tags="insurance,home,Australia"; amazon="home security system"},

    # TECHNOLOGY
    @{topic="best budget laptops for students Australia 2026"; category="technology"; subcategory="computers"; image="budget laptop student Australia"; tags="laptops,technology,students"; amazon="budget laptop Australia"},
    @{topic="how to set up a smart home on a budget"; category="technology"; subcategory="smart-home"; image="smart home budget setup"; tags="smart-home,technology,budget"; amazon="smart home devices"},
    @{topic="best AI tools for everyday productivity 2026"; category="technology"; subcategory="ai"; image="AI artificial intelligence productivity tools"; tags="AI,productivity,technology"; amazon="AI productivity tools"},
    @{topic="how to speed up your slow computer"; category="technology"; subcategory="computers"; image="computer speed upgrade RAM"; tags="computers,performance,tips"; amazon="computer RAM upgrade"},
    @{topic="best wireless earbuds under 100 dollars Australia"; category="technology"; subcategory="gadgets"; image="wireless earbuds music technology"; tags="earbuds,gadgets,audio"; amazon="wireless earbuds Australia"},
    @{topic="home network setup guide for beginners"; category="technology"; subcategory="smart-home"; image="home network router setup WiFi"; tags="networking,WiFi,home"; amazon="WiFi router home"},
    @{topic="best smartphones under 500 dollars Australia 2026"; category="technology"; subcategory="gadgets"; image="smartphone budget Australia"; tags="smartphones,gadgets,Australia"; amazon="budget smartphone Australia"},
    @{topic="how to protect your home from cyber threats"; category="technology"; subcategory="reviews"; image="cybersecurity home network protection"; tags="cybersecurity,home,protection"; amazon="cybersecurity software"},

    # HEALTH
    @{topic="how to start exercising when you are out of shape"; category="health"; subcategory="fitness"; image="exercise beginner fitness workout"; tags="fitness,exercise,beginners"; amazon="home gym equipment"},
    @{topic="best meal prep ideas for busy Australians"; category="health"; subcategory="nutrition"; image="meal prep healthy food containers"; tags="meal-prep,nutrition,healthy"; amazon="meal prep containers"},
    @{topic="how to improve your sleep quality naturally"; category="health"; subcategory="sleep"; image="sleep quality bedroom night"; tags="sleep,health,wellness"; amazon="sleep aid pillow"},
    @{topic="mental health tips for working from home"; category="health"; subcategory="mental-health"; image="mental health work from home"; tags="mental-health,wellbeing,work"; amazon="mindfulness journal"},
    @{topic="best home gym equipment for small spaces"; category="health"; subcategory="fitness"; image="home gym small space equipment"; tags="gym,fitness,home"; amazon="home gym equipment small space"},
    @{topic="Australian nutrition guidelines explained simply"; category="health"; subcategory="nutrition"; image="healthy nutrition food Australia"; tags="nutrition,health,Australia"; amazon="nutrition books Australia"},
    @{topic="how to manage stress and anxiety naturally"; category="health"; subcategory="mental-health"; image="stress anxiety management meditation"; tags="stress,anxiety,mental-health"; amazon="meditation cushion"},
    @{topic="best vitamins and supplements for Australians"; category="health"; subcategory="nutrition"; image="vitamins supplements health"; tags="vitamins,supplements,health"; amazon="vitamins Australia"},

    # AUTOMOTIVE
    @{topic="how to buy a used car in Australia safely"; category="automotive"; subcategory="reviews"; image="used car buying Australia inspection"; tags="cars,buying-guide,Australia"; amazon="car inspection tool"},
    @{topic="best electric cars available in Australia 2026"; category="automotive"; subcategory="ev"; image="electric car Australia charging"; tags="electric-vehicles,EV,Australia"; amazon="EV charging cable Australia"},
    @{topic="car maintenance schedule every owner should follow"; category="automotive"; subcategory="maintenance"; image="car maintenance service mechanic"; tags="maintenance,cars,DIY"; amazon="car maintenance kit"},
    @{topic="best road trips from Sydney Australia"; category="automotive"; subcategory="road-trips"; image="road trip Sydney Australia scenic"; tags="road-trips,travel,Australia"; amazon="road trip accessories"},
    @{topic="how to change your own car tyres safely"; category="automotive"; subcategory="maintenance"; image="car tyre change maintenance safety"; tags="tyres,maintenance,DIY"; amazon="tyre pressure gauge"},
    @{topic="best dash cams for Australian drivers 2026"; category="automotive"; subcategory="reviews"; image="dash cam car Australia"; tags="dash-cam,technology,cars"; amazon="dash cam Australia"},
    @{topic="how to save money on petrol in Australia"; category="automotive"; subcategory="road-trips"; image="petrol fuel saving Australia"; tags="fuel,savings,Australia"; amazon="fuel efficiency monitor"},
    @{topic="what to do when your car breaks down Australia"; category="automotive"; subcategory="maintenance"; image="car breakdown roadside Australia"; tags="breakdown,safety,Australia"; amazon="roadside emergency kit"},

    # SEASONAL
    @{topic="best Christmas gift ideas for men Australia 2026"; category="seasonal"; subcategory="christmas"; image="Christmas gifts men Australia"; tags="Christmas,gifts,Australia"; amazon="Christmas gifts men"},
    @{topic="how to survive a hot Australian summer at home"; category="seasonal"; subcategory="summer"; image="hot summer Australia home cooling"; tags="summer,Australia,cooling"; amazon="portable air conditioner Australia"},
    @{topic="winter home maintenance checklist for Australians"; category="seasonal"; subcategory="winter"; image="winter home maintenance checklist"; tags="winter,maintenance,home"; amazon="winter home supplies"},
    @{topic="best Easter activities for families in Australia"; category="seasonal"; subcategory="easter"; image="Easter family activities Australia"; tags="Easter,family,Australia"; amazon="Easter gifts Australia"},
    @{topic="school holiday activities for kids on a budget"; category="seasonal"; subcategory="school-holidays"; image="school holiday kids activities budget"; tags="school-holidays,kids,budget"; amazon="kids activity sets"},
    @{topic="how to prepare your garden for spring in Australia"; category="seasonal"; subcategory="summer"; image="spring garden preparation Australia"; tags="spring,garden,Australia"; amazon="garden tools spring"},
    @{topic="best Christmas lunch recipes for Australian summer"; category="seasonal"; subcategory="christmas"; image="Christmas lunch Australian summer BBQ"; tags="Christmas,food,Australia"; amazon="BBQ accessories Australia"},
    @{topic="how to save money on your Christmas budget Australia"; category="seasonal"; subcategory="christmas"; image="Christmas budget savings Australia"; tags="Christmas,budget,savings"; amazon="Christmas budget planner"}
)

# Load used topics
if (Test-Path $usedTopicsFile) {
    $usedTopics = Get-Content $usedTopicsFile
} else {
    $usedTopics = @()
}

$availableTopics = $topicData | Where-Object { $usedTopics -notcontains $_.topic }

if ($availableTopics.Count -eq 0) {
    $availableTopics = $topicData
    Clear-Content $usedTopicsFile
    Write-Log "All topics used - resetting list"
}

$selected = $availableTopics | Get-Random
$topic = $selected.topic
$category = $selected.category
$subcategory = $selected.subcategory
$imageKeyword = $selected.image
$tags = $selected.tags
$amazonSearch = $selected.amazon

Add-Content -Path $usedTopicsFile -Value $topic

$date = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")
$slug = $topic.ToLower() -replace '[^a-z0-9\s-]', '' -replace '\s+', '-'
$filename = "$date-$slug.md"
$filepath = "$postsPath/$filename"

Write-Log "Generating article: [$category] $topic"

# Fetch Pexels image
Write-Log "Fetching image: $imageKeyword"
$imageData = Get-PexelsImage -keyword $imageKeyword
$imageUrl = ""
$imageThumb = ""
$imageCredit = ""

if ($imageData) {
    $imageUrl = $imageData.large
    $imageThumb = $imageData.medium
    $imageCredit = $imageData.photographer
    Write-Log "Image: $imageUrl"
} else {
    $seed = [Math]::Abs($topic.GetHashCode()) % 1000
    $imageUrl = "https://picsum.photos/seed/$seed/1200/600"
    $imageThumb = "https://picsum.photos/seed/$seed/400/250"
    Write-Log "Using fallback image"
}

$prompt = @"
Write an 800 word SEO blog article about: $topic

The article should be practical, informative and written for an Australian audience where relevant.

Naturally include 2-3 product recommendations. Format each as a markdown link:
[Product Name](https://www.amazon.com.au/s?k=$amazonSearch&tag=owlno-22)

Output ONLY the Jekyll markdown file content starting with --- on the first line.

---
layout: single
title: "YOUR TITLE HERE"
date: $date
categories: [$category]
tags: [$tags]
image: "$imageUrl"
image_thumb: "$imageThumb"
image_credit: "$imageCredit"
excerpt: "One sentence description."
---

Write the full 800 word article in markdown with proper headings and paragraphs.
Do not include anything outside the markdown file.
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

Write-Log "Calling Ollama..."

try {
    $response = Invoke-RestMethod -Uri $ollamaUrl -Method Post -Body $body -ContentType "application/json" -TimeoutSec 600
    $content = $response.response

    if ($content -and $content.Length -gt 100) {
        if (-not $content.TrimStart().StartsWith("---")) {
            $content = "---`n" + $content
        }
        [System.IO.File]::WriteAllText($filepath, $content)
        Write-Log "Saved: $filename"

        Set-Location $repoPath
        & git pull origin main --rebase 2>&1 | Out-Null
        & git add . 2>&1 | Out-Null
        & git commit -m "New post [$category]: $topic" 2>&1 | Out-Null
        & git push origin main 2>&1 | Out-Null
        Write-Log "Pushed: $filename"
    } else {
        Write-Log "ERROR: Response too short"
    }
} catch {
    Write-Log "ERROR: $_"
}
