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

# Returns $true if today's date (MM-dd) falls within the given MM-dd window.
# Topics with no $start/$end (non-seasonal) always return $true.
# Handles windows that wrap the new year (e.g. "12-01" to "02-28").
function Test-InSeason {
    param($start, $end, $today = (Get-Date))
    if (-not $start -or -not $end) { return $true }
    $todayMD = $today.ToString("MM-dd")
    if ($start -le $end) {
        return ($todayMD -ge $start -and $todayMD -le $end)
    } else {
        return ($todayMD -ge $start -or $todayMD -le $end)
    }
}

# Each topic has: topic text, category slug, image keyword, tags, Amazon search term
# Seasonal topics additionally set seasonStart / seasonEnd as "MM-dd" strings, OR
# easterOffsetStart / easterOffsetEnd (days relative to Easter Sunday) for movable-feast
# topics - these get resolved into real seasonStart/seasonEnd dates for the current year
# further down, right after this array is defined.
# A topic with none of these fields is available year-round.
$topicData = @(
    # ENERGY & POWER
    @{topic="how to choose a generator for construction sites"; category="energy-power"; subcategory="generators"; image="generator first home buyers"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="battery bank buying guide for medical equipment at home"; category="energy-power"; subcategory="batteries"; image="battery bank storage"; tags="battery,backup-power,energy-storage"; amazon="home battery backup"},
    @{topic="generator extension cord safety guide"; category="energy-power"; subcategory="generators"; image="generator renters"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="how long do generators last and when to replace them"; category="energy-power"; subcategory="generators"; image="generator homeowners"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="how solar battery systems pay for themselves over time"; category="energy-power"; subcategory="solar"; image="solar battery home"; tags="solar,renewable-energy,home-energy"; amazon="solar panel kit"},
    @{topic="best battery bank options for apartment dwellers"; category="energy-power"; subcategory="batteries"; image="battery bank storage"; tags="battery,backup-power,energy-storage"; amazon="home battery backup"},
    @{topic="how to reduce carbon monoxide risk when using a generator"; category="energy-power"; subcategory="generators"; image="generator first home buyers"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="generator fuel efficiency tips for small businesses"; category="energy-power"; subcategory="generators"; image="generator small businesses"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="off grid solar maintenance checklist"; category="energy-power"; subcategory="solar"; image="off grid solar home"; tags="solar,renewable-energy,home-energy"; amazon="solar panel kit"},
    @{topic="how to run a fridge on a generator during an outage"; category="energy-power"; subcategory="generators"; image="generator apartment dwellers"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="how to choose a generator for a home office"; category="energy-power"; subcategory="generators"; image="generator retirees"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="solar generators explained: pros and cons"; category="energy-power"; subcategory="generators"; image="generator families"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="best portable generators for apartment dwellers"; category="energy-power"; subcategory="generators"; image="generator apartment dwellers"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="how off grid solar systems pay for themselves over time"; category="energy-power"; subcategory="solar"; image="off grid solar home"; tags="solar,renewable-energy,home-energy"; amazon="solar panel kit"},
    @{topic="common generator problems and how to fix them"; category="energy-power"; subcategory="generators"; image="generator families"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="common mistakes when installing solar panel"; category="energy-power"; subcategory="solar"; image="solar panel home"; tags="solar,renewable-energy,home-energy"; amazon="solar panel kit"},
    @{topic="best generator brands rated by homeowners"; category="energy-power"; subcategory="generators"; image="generator homeowners"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="how long does a home battery last"; category="energy-power"; subcategory="batteries"; image="home battery storage"; tags="battery,backup-power,energy-storage"; amazon="home battery backup"},
    @{topic="best quiet generators for homeowners"; category="energy-power"; subcategory="generators"; image="generator homeowners"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="how to winterise a generator before storage"; category="energy-power"; subcategory="generators"; image="generator retirees"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="best generator brands rated by families"; category="energy-power"; subcategory="generators"; image="generator families"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="propane generators explained: pros and cons"; category="energy-power"; subcategory="generators"; image="generator rural properties"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="diesel generators explained: pros and cons"; category="energy-power"; subcategory="generators"; image="generator families"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="generator noise levels: what to expect and how to reduce them"; category="energy-power"; subcategory="generators"; image="generator first home buyers"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="how to size solar monitoring for your household"; category="energy-power"; subcategory="solar"; image="solar monitoring home"; tags="solar,renewable-energy,home-energy"; amazon="solar panel kit"},
    @{topic="generator fuel efficiency tips for homeowners"; category="energy-power"; subcategory="generators"; image="generator homeowners"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="dual fuel generators explained: pros and cons"; category="energy-power"; subcategory="generators"; image="generator first home buyers"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="best entry level generators for homeowners"; category="energy-power"; subcategory="generators"; image="generator homeowners"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="generator vs battery backup for caravans and RVs"; category="energy-power"; subcategory="generators"; image="generator rural properties"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="best portable power station options for apartment dwellers"; category="energy-power"; subcategory="batteries"; image="portable power station storage"; tags="battery,backup-power,energy-storage"; amazon="home battery backup"},
    @{topic="how to store a generator safely when not in use"; category="energy-power"; subcategory="generators"; image="generator renters"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="how to choose a generator for camping trips"; category="energy-power"; subcategory="generators"; image="generator retirees"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="how to choose a generator for tiny homes"; category="energy-power"; subcategory="generators"; image="generator rural properties"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="how much does it cost to run a generator for food trucks"; category="energy-power"; subcategory="generators"; image="generator homeowners"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="portable power station buying guide for caravans and RVs"; category="energy-power"; subcategory="batteries"; image="portable power station storage"; tags="battery,backup-power,energy-storage"; amazon="home battery backup"},
    @{topic="how to size solar inverter for your household"; category="energy-power"; subcategory="solar"; image="solar inverter home"; tags="solar,renewable-energy,home-energy"; amazon="solar panel kit"},
    @{topic="generator vs battery backup for a home workshop"; category="energy-power"; subcategory="generators"; image="generator families"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="how much does it cost to run a generator for power outages"; category="energy-power"; subcategory="generators"; image="generator first home buyers"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="UPS battery vs generator for backup power"; category="energy-power"; subcategory="batteries"; image="UPS battery storage"; tags="battery,backup-power,energy-storage"; amazon="home battery backup"},
    @{topic="how much does it cost to run a generator for a home office"; category="energy-power"; subcategory="generators"; image="generator retirees"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="best eco-friendly generators for renters"; category="energy-power"; subcategory="generators"; image="generator renters"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="best generator brands rated by first home buyers"; category="energy-power"; subcategory="generators"; image="generator first home buyers"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="how to choose a generator for boats"; category="energy-power"; subcategory="generators"; image="generator rural properties"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="generator vs battery backup for camping trips"; category="energy-power"; subcategory="generators"; image="generator apartment dwellers"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="generator vs battery backup for construction sites"; category="energy-power"; subcategory="generators"; image="generator renters"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="generator vs battery backup for boats"; category="energy-power"; subcategory="generators"; image="generator rural properties"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="generator vs battery backup for a home office"; category="energy-power"; subcategory="generators"; image="generator small businesses"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="generator fuel efficiency tips for apartment dwellers"; category="energy-power"; subcategory="generators"; image="generator apartment dwellers"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="solar panel maintenance checklist"; category="energy-power"; subcategory="solar"; image="solar panel home"; tags="solar,renewable-energy,home-energy"; amazon="solar panel kit"},
    @{topic="how much does it cost to run a generator for construction sites"; category="energy-power"; subcategory="generators"; image="generator retirees"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="how much does it cost to run a generator for caravans and RVs"; category="energy-power"; subcategory="generators"; image="generator first home buyers"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="lead acid battery buying guide for caravans and RVs"; category="energy-power"; subcategory="batteries"; image="lead acid battery storage"; tags="battery,backup-power,energy-storage"; amazon="home battery backup"},
    @{topic="generator fuel efficiency tips for retirees"; category="energy-power"; subcategory="generators"; image="generator retirees"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="best generator brands rated by rural properties"; category="energy-power"; subcategory="generators"; image="generator rural properties"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="is solar panel worth it for first home buyers in 2026"; category="energy-power"; subcategory="solar"; image="solar panel home"; tags="solar,renewable-energy,home-energy"; amazon="solar panel kit"},
    @{topic="generator fuel efficiency tips for tradies"; category="energy-power"; subcategory="generators"; image="generator tradies"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="common mistakes when installing off grid solar"; category="energy-power"; subcategory="solar"; image="off grid solar home"; tags="solar,renewable-energy,home-energy"; amazon="solar panel kit"},
    @{topic="home battery vs generator for backup power"; category="energy-power"; subcategory="batteries"; image="home battery storage"; tags="battery,backup-power,energy-storage"; amazon="home battery backup"},
    @{topic="UPS battery safety tips every owner should know"; category="energy-power"; subcategory="batteries"; image="UPS battery storage"; tags="battery,backup-power,energy-storage"; amazon="home battery backup"},
    @{topic="best generator brands rated by renters"; category="energy-power"; subcategory="generators"; image="generator renters"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="best generator brands rated by retirees"; category="energy-power"; subcategory="generators"; image="generator retirees"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="portable power station safety tips every owner should know"; category="energy-power"; subcategory="batteries"; image="portable power station storage"; tags="battery,backup-power,energy-storage"; amazon="home battery backup"},
    @{topic="EV battery buying guide for construction sites"; category="energy-power"; subcategory="batteries"; image="EV battery storage"; tags="battery,backup-power,energy-storage"; amazon="home battery backup"},
    @{topic="hybrid solar maintenance checklist"; category="energy-power"; subcategory="solar"; image="hybrid solar home"; tags="solar,renewable-energy,home-energy"; amazon="solar panel kit"},
    @{topic="generator vs battery backup for medical equipment at home"; category="energy-power"; subcategory="generators"; image="generator renters"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="generator fuel efficiency tips for first home buyers"; category="energy-power"; subcategory="generators"; image="generator first home buyers"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="generator fuel efficiency tips for renters"; category="energy-power"; subcategory="generators"; image="generator renters"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="best high capacity generators for farmers"; category="energy-power"; subcategory="generators"; image="generator farmers"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="best generator brands rated by farmers"; category="energy-power"; subcategory="generators"; image="generator farmers"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="common mistakes when installing solar monitoring"; category="energy-power"; subcategory="solar"; image="solar monitoring home"; tags="solar,renewable-energy,home-energy"; amazon="solar panel kit"},
    @{topic="generator vs battery backup for tiny homes"; category="energy-power"; subcategory="generators"; image="generator farmers"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="solar monitoring buying guide for retirees"; category="energy-power"; subcategory="solar"; image="solar monitoring home"; tags="solar,renewable-energy,home-energy"; amazon="solar panel kit"},
    @{topic="how much does it cost to run a generator for boats"; category="energy-power"; subcategory="generators"; image="generator families"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="solar battery maintenance checklist"; category="energy-power"; subcategory="solar"; image="solar battery home"; tags="solar,renewable-energy,home-energy"; amazon="solar panel kit"},
    @{topic="how long does a lithium battery last"; category="energy-power"; subcategory="batteries"; image="lithium battery storage"; tags="battery,backup-power,energy-storage"; amazon="home battery backup"},
    @{topic="is solar inverter worth it for first home buyers in 2026"; category="energy-power"; subcategory="solar"; image="solar inverter home"; tags="solar,renewable-energy,home-energy"; amazon="solar panel kit"},
    @{topic="best lithium battery options for farmers"; category="energy-power"; subcategory="batteries"; image="lithium battery storage"; tags="battery,backup-power,energy-storage"; amazon="home battery backup"},
    @{topic="how to choose a generator for food trucks"; category="energy-power"; subcategory="generators"; image="generator first home buyers"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="best top rated generators for apartment dwellers"; category="energy-power"; subcategory="generators"; image="generator apartment dwellers"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="generator fuel efficiency tips for families"; category="energy-power"; subcategory="generators"; image="generator families"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="is hybrid solar worth it for farmers in 2026"; category="energy-power"; subcategory="solar"; image="hybrid solar home"; tags="solar,renewable-energy,home-energy"; amazon="solar panel kit"},
    @{topic="common mistakes when installing hybrid solar"; category="energy-power"; subcategory="solar"; image="hybrid solar home"; tags="solar,renewable-energy,home-energy"; amazon="solar panel kit"},
    @{topic="how much does it cost to run a generator for a home workshop"; category="energy-power"; subcategory="generators"; image="generator rural properties"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="how much does it cost to run a generator for camping trips"; category="energy-power"; subcategory="generators"; image="generator apartment dwellers"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="how to charge a battery bank correctly"; category="energy-power"; subcategory="batteries"; image="battery bank storage"; tags="battery,backup-power,energy-storage"; amazon="home battery backup"},
    @{topic="how to choose a generator for power outages"; category="energy-power"; subcategory="generators"; image="generator farmers"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="hybrid solar buying guide for small businesses"; category="energy-power"; subcategory="solar"; image="hybrid solar home"; tags="solar,renewable-energy,home-energy"; amazon="solar panel kit"},
    @{topic="solar inverter maintenance checklist"; category="energy-power"; subcategory="solar"; image="solar inverter home"; tags="solar,renewable-energy,home-energy"; amazon="solar panel kit"},
    @{topic="how to choose a generator for a home workshop"; category="energy-power"; subcategory="generators"; image="generator small businesses"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="UPS battery buying guide for a home workshop"; category="energy-power"; subcategory="batteries"; image="UPS battery storage"; tags="battery,backup-power,energy-storage"; amazon="home battery backup"},
    @{topic="best heavy duty generators for renters"; category="energy-power"; subcategory="generators"; image="generator renters"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="how rooftop solar systems pay for themselves over time"; category="energy-power"; subcategory="solar"; image="rooftop solar home"; tags="solar,renewable-energy,home-energy"; amazon="solar panel kit"},
    @{topic="how long does a UPS battery last"; category="energy-power"; subcategory="batteries"; image="UPS battery storage"; tags="battery,backup-power,energy-storage"; amazon="home battery backup"},
    @{topic="how much does it cost to run a generator for medical equipment at home"; category="energy-power"; subcategory="generators"; image="generator families"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="lithium battery vs generator for backup power"; category="energy-power"; subcategory="batteries"; image="lithium battery storage"; tags="battery,backup-power,energy-storage"; amazon="home battery backup"},
    @{topic="best quiet generators for tradies"; category="energy-power"; subcategory="generators"; image="generator tradies"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="best generator brands rated by small businesses"; category="energy-power"; subcategory="generators"; image="generator small businesses"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="best compact generators for small businesses"; category="energy-power"; subcategory="generators"; image="generator small businesses"; tags="generators,backup-power,home-energy"; amazon="portable generator"},
    @{topic="best UPS battery options for tradies"; category="energy-power"; subcategory="batteries"; image="UPS battery storage"; tags="battery,backup-power,energy-storage"; amazon="home battery backup"},
    @{topic="how much does it cost to run a generator for tiny homes"; category="energy-power"; subcategory="generators"; image="generator rural properties"; tags="generators,backup-power,home-energy"; amazon="portable generator"},

    # HOME & GARDEN
    @{topic="how to design a patio for entertaining"; category="home-garden"; subcategory="garden"; image="bedroom garden"; tags="garden,home,DIY"; amazon="garden supplies"},
    @{topic="best succulents for Australian backyards"; category="home-garden"; subcategory="garden"; image="kitchen garden"; tags="garden,home,DIY"; amazon="garden supplies"},
    @{topic="how to choose the right leaf blower for your needs"; category="home-garden"; subcategory="tools"; image="bedroom tools"; tags="tools,home,DIY"; amazon="tools supplies"},
    @{topic="how to choose the right cordless drill for your needs"; category="home-garden"; subcategory="tools"; image="hallway tools"; tags="tools,home,DIY"; amazon="tools supplies"},
    @{topic="smart home upgrades for the driveway"; category="home-garden"; subcategory="interior"; image="driveway interior"; tags="interior,home,DIY"; amazon="interior supplies"},
    @{topic="low cost ways to upgrade your balcony"; category="home-garden"; subcategory="garden"; image="patio garden"; tags="garden,home,DIY"; amazon="garden supplies"},
    @{topic="how to childproof your home office"; category="home-garden"; subcategory="interior"; image="home office interior"; tags="interior,home,DIY"; amazon="interior supplies"},
    @{topic="before and after: balcony renovation inspiration"; category="home-garden"; subcategory="interior"; image="balcony interior"; tags="interior,home,DIY"; amazon="interior supplies"},
    @{topic="how to grow drought tolerant plants in an Australian garden"; category="home-garden"; subcategory="garden"; image="laundry garden"; tags="garden,home,DIY"; amazon="garden supplies"},
    @{topic="how to clean and maintain your living room"; category="home-garden"; subcategory="cleaning"; image="living room cleaning"; tags="cleaning,home,DIY"; amazon="cleaning supplies"},
    @{topic="best cleaning products for the bedroom"; category="home-garden"; subcategory="cleaning"; image="bedroom cleaning"; tags="cleaning,home,DIY"; amazon="cleaning supplies"},
    @{topic="how to choose the right pressure washer for your needs"; category="home-garden"; subcategory="tools"; image="laundry tools"; tags="tools,home,DIY"; amazon="tools supplies"},
    @{topic="how to childproof your bedroom"; category="home-garden"; subcategory="interior"; image="bedroom interior"; tags="interior,home,DIY"; amazon="interior supplies"},
    @{topic="before and after: driveway decluttering inspiration"; category="home-garden"; subcategory="interior"; image="driveway interior"; tags="interior,home,DIY"; amazon="interior supplies"},
    @{topic="how to grow climbing plants in an Australian garden"; category="home-garden"; subcategory="garden"; image="garage garden"; tags="garden,home,DIY"; amazon="garden supplies"},
    @{topic="how to grow herbs in an Australian garden"; category="home-garden"; subcategory="garden"; image="patio garden"; tags="garden,home,DIY"; amazon="garden supplies"},
    @{topic="smart home upgrades for the balcony"; category="home-garden"; subcategory="interior"; image="balcony interior"; tags="interior,home,DIY"; amazon="interior supplies"},
    @{topic="how to design a balcony for entertaining"; category="home-garden"; subcategory="garden"; image="attic garden"; tags="garden,home,DIY"; amazon="garden supplies"},
    @{topic="how to plan a garden bed cleaning on a budget"; category="home-garden"; subcategory="renovation"; image="garden bed renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="best leaf blower for home DIY projects"; category="home-garden"; subcategory="tools"; image="basement tools"; tags="tools,home,DIY"; amazon="tools supplies"},
    @{topic="how to soundproof a kitchen"; category="home-garden"; subcategory="renovation"; image="kitchen renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="before and after: garden bed styling inspiration"; category="home-garden"; subcategory="interior"; image="garden bed interior"; tags="interior,home,DIY"; amazon="interior supplies"},
    @{topic="how to grow indoor plants in an Australian garden"; category="home-garden"; subcategory="garden"; image="bathroom garden"; tags="garden,home,DIY"; amazon="garden supplies"},
    @{topic="how to soundproof a deck"; category="home-garden"; subcategory="renovation"; image="deck renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="how to soundproof a driveway"; category="home-garden"; subcategory="renovation"; image="driveway renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="balcony styling mistakes to avoid"; category="home-garden"; subcategory="renovation"; image="balcony renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="backyard storage solution mistakes to avoid"; category="home-garden"; subcategory="renovation"; image="backyard renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="garden hose reel maintenance and care guide"; category="home-garden"; subcategory="tools"; image="living room tools"; tags="tools,home,DIY"; amazon="tools supplies"},
    @{topic="how to plan a kitchen decluttering on a budget"; category="home-garden"; subcategory="renovation"; image="kitchen renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="how to soundproof a living room"; category="home-garden"; subcategory="renovation"; image="living room renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="low cost ways to upgrade your garden bed"; category="home-garden"; subcategory="garden"; image="deck garden"; tags="garden,home,DIY"; amazon="garden supplies"},
    @{topic="low maintenance bedroom decluttering ideas"; category="home-garden"; subcategory="renovation"; image="bedroom renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="how to design a courtyard for entertaining"; category="home-garden"; subcategory="garden"; image="garden bed garden"; tags="garden,home,DIY"; amazon="garden supplies"},
    @{topic="best cleaning products for the patio"; category="home-garden"; subcategory="cleaning"; image="patio cleaning"; tags="cleaning,home,DIY"; amazon="cleaning supplies"},
    @{topic="how to choose the right garden hose reel for your needs"; category="home-garden"; subcategory="tools"; image="attic tools"; tags="tools,home,DIY"; amazon="tools supplies"},
    @{topic="low cost ways to upgrade your driveway"; category="home-garden"; subcategory="garden"; image="hallway garden"; tags="garden,home,DIY"; amazon="garden supplies"},
    @{topic="best cleaning products for the backyard"; category="home-garden"; subcategory="cleaning"; image="backyard cleaning"; tags="cleaning,home,DIY"; amazon="cleaning supplies"},
    @{topic="best flowering shrubs for Australian backyards"; category="home-garden"; subcategory="garden"; image="front yard garden"; tags="garden,home,DIY"; amazon="garden supplies"},
    @{topic="best cleaning products for the kitchen"; category="home-garden"; subcategory="cleaning"; image="kitchen cleaning"; tags="cleaning,home,DIY"; amazon="cleaning supplies"},
    @{topic="best climbing plants for Australian backyards"; category="home-garden"; subcategory="garden"; image="bedroom garden"; tags="garden,home,DIY"; amazon="garden supplies"},
    @{topic="smart home upgrades for the laundry"; category="home-garden"; subcategory="interior"; image="laundry interior"; tags="interior,home,DIY"; amazon="interior supplies"},
    @{topic="paint colour ideas for a small courtyard"; category="home-garden"; subcategory="interior"; image="courtyard interior"; tags="interior,home,DIY"; amazon="interior supplies"},
    @{topic="patio storage solution mistakes to avoid"; category="home-garden"; subcategory="renovation"; image="patio renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="best cleaning products for the bathroom"; category="home-garden"; subcategory="cleaning"; image="bathroom cleaning"; tags="cleaning,home,DIY"; amazon="cleaning supplies"},
    @{topic="paint colour ideas for a small driveway"; category="home-garden"; subcategory="interior"; image="driveway interior"; tags="interior,home,DIY"; amazon="interior supplies"},
    @{topic="best pressure washer for home DIY projects"; category="home-garden"; subcategory="tools"; image="balcony tools"; tags="tools,home,DIY"; amazon="tools supplies"},
    @{topic="professional front yard makeover ideas"; category="home-garden"; subcategory="renovation"; image="front yard renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="cordless drill maintenance and care guide"; category="home-garden"; subcategory="tools"; image="garden bed tools"; tags="tools,home,DIY"; amazon="tools supplies"},
    @{topic="modern home office decluttering ideas"; category="home-garden"; subcategory="renovation"; image="home office renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="best lawn mower for home DIY projects"; category="home-garden"; subcategory="tools"; image="home office tools"; tags="tools,home,DIY"; amazon="tools supplies"},
    @{topic="paint colour ideas for a small bedroom"; category="home-garden"; subcategory="interior"; image="bedroom interior"; tags="interior,home,DIY"; amazon="interior supplies"},
    @{topic="how to plan a garden bed styling on a budget"; category="home-garden"; subcategory="renovation"; image="garden bed renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="lawn mower maintenance and care guide"; category="home-garden"; subcategory="tools"; image="laundry tools"; tags="tools,home,DIY"; amazon="tools supplies"},
    @{topic="paint colour ideas for a small backyard"; category="home-garden"; subcategory="interior"; image="backyard interior"; tags="interior,home,DIY"; amazon="interior supplies"},
    @{topic="quick weekend backyard styling ideas"; category="home-garden"; subcategory="renovation"; image="backyard renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="best cleaning products for the living room"; category="home-garden"; subcategory="cleaning"; image="living room cleaning"; tags="cleaning,home,DIY"; amazon="cleaning supplies"},
    @{topic="how to clean and maintain your attic"; category="home-garden"; subcategory="cleaning"; image="attic cleaning"; tags="cleaning,home,DIY"; amazon="cleaning supplies"},
    @{topic="professional courtyard decluttering ideas"; category="home-garden"; subcategory="renovation"; image="courtyard renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="how to fix common garage problems yourself"; category="home-garden"; subcategory="renovation"; image="garage renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="how to soundproof a bathroom"; category="home-garden"; subcategory="renovation"; image="bathroom renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="paint colour ideas for a small home office"; category="home-garden"; subcategory="interior"; image="home office interior"; tags="interior,home,DIY"; amazon="interior supplies"},
    @{topic="leaf blower maintenance and care guide"; category="home-garden"; subcategory="tools"; image="bedroom tools"; tags="tools,home,DIY"; amazon="tools supplies"},
    @{topic="before and after: garage cleaning inspiration"; category="home-garden"; subcategory="interior"; image="garage interior"; tags="interior,home,DIY"; amazon="interior supplies"},
    @{topic="courtyard organisation mistakes to avoid"; category="home-garden"; subcategory="renovation"; image="courtyard renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="how to soundproof a basement"; category="home-garden"; subcategory="renovation"; image="basement renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="how to plan a garage lighting upgrade on a budget"; category="home-garden"; subcategory="renovation"; image="garage renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="best cordless drill for home DIY projects"; category="home-garden"; subcategory="tools"; image="kitchen tools"; tags="tools,home,DIY"; amazon="tools supplies"},
    @{topic="front yard storage solution mistakes to avoid"; category="home-garden"; subcategory="renovation"; image="front yard renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="backyard makeover mistakes to avoid"; category="home-garden"; subcategory="renovation"; image="backyard renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="how to childproof your garden bed"; category="home-garden"; subcategory="interior"; image="garden bed interior"; tags="interior,home,DIY"; amazon="interior supplies"},
    @{topic="before and after: balcony organisation inspiration"; category="home-garden"; subcategory="interior"; image="balcony interior"; tags="interior,home,DIY"; amazon="interior supplies"},
    @{topic="how to design a deck for entertaining"; category="home-garden"; subcategory="garden"; image="living room garden"; tags="garden,home,DIY"; amazon="garden supplies"},
    @{topic="best native Australian plants for Australian backyards"; category="home-garden"; subcategory="garden"; image="deck garden"; tags="garden,home,DIY"; amazon="garden supplies"},
    @{topic="how to choose the right lawn mower for your needs"; category="home-garden"; subcategory="tools"; image="courtyard tools"; tags="tools,home,DIY"; amazon="tools supplies"},
    @{topic="how to grow vegetables in an Australian garden"; category="home-garden"; subcategory="garden"; image="courtyard garden"; tags="garden,home,DIY"; amazon="garden supplies"},
    @{topic="best herbs for Australian backyards"; category="home-garden"; subcategory="garden"; image="garage garden"; tags="garden,home,DIY"; amazon="garden supplies"},
    @{topic="how to childproof your backyard"; category="home-garden"; subcategory="interior"; image="backyard interior"; tags="interior,home,DIY"; amazon="interior supplies"},
    @{topic="paint colour ideas for a small basement"; category="home-garden"; subcategory="interior"; image="basement interior"; tags="interior,home,DIY"; amazon="interior supplies"},
    @{topic="hedge trimmer maintenance and care guide"; category="home-garden"; subcategory="tools"; image="deck tools"; tags="tools,home,DIY"; amazon="tools supplies"},
    @{topic="quick weekend laundry decluttering ideas"; category="home-garden"; subcategory="renovation"; image="laundry renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="best vegetables for Australian backyards"; category="home-garden"; subcategory="garden"; image="deck garden"; tags="garden,home,DIY"; amazon="garden supplies"},
    @{topic="best hedge trimmer for home DIY projects"; category="home-garden"; subcategory="tools"; image="attic tools"; tags="tools,home,DIY"; amazon="tools supplies"},
    @{topic="how to soundproof a courtyard"; category="home-garden"; subcategory="renovation"; image="courtyard renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="balcony renovation mistakes to avoid"; category="home-garden"; subcategory="renovation"; image="balcony renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="how to soundproof a patio"; category="home-garden"; subcategory="renovation"; image="patio renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="how to choose the right chainsaw for your needs"; category="home-garden"; subcategory="tools"; image="laundry tools"; tags="tools,home,DIY"; amazon="tools supplies"},
    @{topic="before and after: bathroom lighting upgrade inspiration"; category="home-garden"; subcategory="interior"; image="bathroom interior"; tags="interior,home,DIY"; amazon="interior supplies"},
    @{topic="deck decluttering mistakes to avoid"; category="home-garden"; subcategory="renovation"; image="deck renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="before and after: front yard lighting upgrade inspiration"; category="home-garden"; subcategory="interior"; image="front yard interior"; tags="interior,home,DIY"; amazon="interior supplies"},
    @{topic="before and after: bathroom renovation inspiration"; category="home-garden"; subcategory="interior"; image="bathroom interior"; tags="interior,home,DIY"; amazon="interior supplies"},
    @{topic="smart home upgrades for the living room"; category="home-garden"; subcategory="interior"; image="living room interior"; tags="interior,home,DIY"; amazon="interior supplies"},
    @{topic="living room organisation mistakes to avoid"; category="home-garden"; subcategory="renovation"; image="living room renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="how to choose the right hedge trimmer for your needs"; category="home-garden"; subcategory="tools"; image="hallway tools"; tags="tools,home,DIY"; amazon="tools supplies"},
    @{topic="best cleaning products for the laundry"; category="home-garden"; subcategory="cleaning"; image="laundry cleaning"; tags="cleaning,home,DIY"; amazon="cleaning supplies"},
    @{topic="paint colour ideas for a small garden bed"; category="home-garden"; subcategory="interior"; image="garden bed interior"; tags="interior,home,DIY"; amazon="interior supplies"},
    @{topic="how to design a backyard for entertaining"; category="home-garden"; subcategory="garden"; image="kitchen garden"; tags="garden,home,DIY"; amazon="garden supplies"},
    @{topic="garden bed organisation mistakes to avoid"; category="home-garden"; subcategory="renovation"; image="garden bed renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},
    @{topic="paint colour ideas for a small patio"; category="home-garden"; subcategory="interior"; image="patio interior"; tags="interior,home,DIY"; amazon="interior supplies"},
    @{topic="best drought tolerant plants for Australian backyards"; category="home-garden"; subcategory="garden"; image="basement garden"; tags="garden,home,DIY"; amazon="garden supplies"},
    @{topic="how to fix common living room problems yourself"; category="home-garden"; subcategory="renovation"; image="living room renovation"; tags="renovation,home,DIY"; amazon="renovation supplies"},

    # OUTDOORS & CAMPING
    @{topic="common canoeing mistakes budget travellers make"; category="outdoors-camping"; subcategory="gear"; image="canoeing national parks"; tags="canoeing,outdoors,Australia"; amazon="sleeping bags"},
    @{topic="best tents for bushwalking in Australia"; category="outdoors-camping"; subcategory="gear"; image="bushwalking the outback"; tags="bushwalking,outdoors,Australia"; amazon="tents"},
    @{topic="best rooftop tents for glamping in Australia"; category="outdoors-camping"; subcategory="gear"; image="glamping tropical North Queensland"; tags="glamping,outdoors,Australia"; amazon="rooftop tents"},
    @{topic="beginners guide to canoeing in the high country"; category="outdoors-camping"; subcategory="hiking"; image="canoeing the high country"; tags="canoeing,outdoors,Australia"; amazon="sleeping bags"},
    @{topic="how to stay safe from wildlife while hiking"; category="outdoors-camping"; subcategory="survival"; image="hiking the outback"; tags="hiking,outdoors,Australia"; amazon="sleeping bags"},
    @{topic="safety tips for camping in tropical North Queensland"; category="outdoors-camping"; subcategory="survival"; image="camping tropical North Queensland"; tags="camping,outdoors,Australia"; amazon="camping chairs"},
    @{topic="best bushwalking spots in remote Western Australia"; category="outdoors-camping"; subcategory="hiking"; image="bushwalking remote Western Australia"; tags="bushwalking,outdoors,Australia"; amazon="water filters"},
    @{topic="best camping chairs for 4WD touring in Australia"; category="outdoors-camping"; subcategory="gear"; image="4WD touring national parks"; tags="4WD touring,outdoors,Australia"; amazon="camping chairs"},
    @{topic="beginners guide to 4WD touring in tropical North Queensland"; category="outdoors-camping"; subcategory="hiking"; image="4WD touring tropical North Queensland"; tags="4WD touring,outdoors,Australia"; amazon="camping stoves"},
    @{topic="what to pack for caravanning in the Snowy Mountains"; category="outdoors-camping"; subcategory="gear"; image="caravanning the Snowy Mountains"; tags="caravanning,outdoors,Australia"; amazon="rooftop tents"},
    @{topic="best time of year to go fishing in the Red Centre"; category="outdoors-camping"; subcategory="hiking"; image="fishing the Red Centre"; tags="fishing,outdoors,Australia"; amazon="first aid kits"},
    @{topic="safety tips for overlanding in Tasmania"; category="outdoors-camping"; subcategory="survival"; image="overlanding Tasmania"; tags="overlanding,outdoors,Australia"; amazon="rooftop tents"},
    @{topic="common glamping mistakes experienced campers make"; category="outdoors-camping"; subcategory="gear"; image="glamping the Great Ocean Road"; tags="glamping,outdoors,Australia"; amazon="camping chairs"},
    @{topic="how to choose hiking backpacks for couples"; category="outdoors-camping"; subcategory="gear"; image="caravanning the Snowy Mountains"; tags="caravanning,outdoors,Australia"; amazon="hiking backpacks"},
    @{topic="common glamping mistakes couples make"; category="outdoors-camping"; subcategory="gear"; image="glamping the outback"; tags="glamping,outdoors,Australia"; amazon="water filters"},
    @{topic="how to stay safe from wildlife while overlanding"; category="outdoors-camping"; subcategory="survival"; image="overlanding Tasmania"; tags="overlanding,outdoors,Australia"; amazon="hiking backpacks"},
    @{topic="beginners guide to 4WD touring in the Snowy Mountains"; category="outdoors-camping"; subcategory="hiking"; image="4WD touring the Snowy Mountains"; tags="4WD touring,outdoors,Australia"; amazon="portable fridges"},
    @{topic="what to pack for bushwalking in the outback"; category="outdoors-camping"; subcategory="gear"; image="bushwalking the outback"; tags="bushwalking,outdoors,Australia"; amazon="tents"},
    @{topic="best caravanning spots in the Snowy Mountains"; category="outdoors-camping"; subcategory="hiking"; image="caravanning the Snowy Mountains"; tags="caravanning,outdoors,Australia"; amazon="solar chargers"},
    @{topic="budget camping tips for budget travellers"; category="outdoors-camping"; subcategory="gear"; image="camping the outback"; tags="camping,outdoors,Australia"; amazon="portable fridges"},
    @{topic="best time of year to go kayaking in the Red Centre"; category="outdoors-camping"; subcategory="hiking"; image="kayaking the Red Centre"; tags="kayaking,outdoors,Australia"; amazon="hiking backpacks"},
    @{topic="budget kayaking tips for solo travellers"; category="outdoors-camping"; subcategory="gear"; image="kayaking the Snowy Mountains"; tags="kayaking,outdoors,Australia"; amazon="camping chairs"},
    @{topic="what to pack for fishing in the outback"; category="outdoors-camping"; subcategory="gear"; image="fishing the outback"; tags="fishing,outdoors,Australia"; amazon="tents"},
    @{topic="how to stay safe from wildlife while 4WD touring"; category="outdoors-camping"; subcategory="survival"; image="4WD touring remote Western Australia"; tags="4WD touring,outdoors,Australia"; amazon="water filters"},
    @{topic="safety tips for fishing in Tasmania"; category="outdoors-camping"; subcategory="survival"; image="fishing Tasmania"; tags="fishing,outdoors,Australia"; amazon="water filters"},
    @{topic="budget bushwalking tips for experienced campers"; category="outdoors-camping"; subcategory="gear"; image="bushwalking the high country"; tags="bushwalking,outdoors,Australia"; amazon="solar chargers"},
    @{topic="best time of year to go glamping in the high country"; category="outdoors-camping"; subcategory="hiking"; image="glamping the high country"; tags="glamping,outdoors,Australia"; amazon="first aid kits"},
    @{topic="best bushwalking spots in coastal Australia"; category="outdoors-camping"; subcategory="hiking"; image="bushwalking coastal Australia"; tags="bushwalking,outdoors,Australia"; amazon="solar chargers"},
    @{topic="how to plan a bushwalking trip to coastal Australia"; category="outdoors-camping"; subcategory="4wd"; image="bushwalking coastal Australia"; tags="bushwalking,outdoors,Australia"; amazon="tents"},
    @{topic="what to pack for hiking in national parks"; category="outdoors-camping"; subcategory="gear"; image="hiking national parks"; tags="hiking,outdoors,Australia"; amazon="tents"},
    @{topic="best camping stoves for glamping in Australia"; category="outdoors-camping"; subcategory="gear"; image="glamping the outback"; tags="glamping,outdoors,Australia"; amazon="camping stoves"},
    @{topic="best water filters for kayaking in Australia"; category="outdoors-camping"; subcategory="gear"; image="kayaking the Red Centre"; tags="kayaking,outdoors,Australia"; amazon="water filters"},
    @{topic="common glamping mistakes families make"; category="outdoors-camping"; subcategory="gear"; image="glamping national parks"; tags="glamping,outdoors,Australia"; amazon="portable fridges"},
    @{topic="common canoeing mistakes couples make"; category="outdoors-camping"; subcategory="gear"; image="canoeing national parks"; tags="canoeing,outdoors,Australia"; amazon="hiking backpacks"},
    @{topic="best kayaking spots in Tasmania"; category="outdoors-camping"; subcategory="hiking"; image="kayaking Tasmania"; tags="kayaking,outdoors,Australia"; amazon="water filters"},
    @{topic="how to choose water filters for couples"; category="outdoors-camping"; subcategory="gear"; image="camping tropical North Queensland"; tags="camping,outdoors,Australia"; amazon="water filters"},
    @{topic="best sleeping bags for canoeing in Australia"; category="outdoors-camping"; subcategory="gear"; image="canoeing the high country"; tags="canoeing,outdoors,Australia"; amazon="sleeping bags"},
    @{topic="what to pack for overlanding in remote Western Australia"; category="outdoors-camping"; subcategory="gear"; image="overlanding remote Western Australia"; tags="overlanding,outdoors,Australia"; amazon="first aid kits"},
    @{topic="how to stay safe from wildlife while caravanning"; category="outdoors-camping"; subcategory="survival"; image="caravanning the high country"; tags="caravanning,outdoors,Australia"; amazon="rooftop tents"},
    @{topic="how to plan a kayaking trip to the Snowy Mountains"; category="outdoors-camping"; subcategory="4wd"; image="kayaking the Snowy Mountains"; tags="kayaking,outdoors,Australia"; amazon="water filters"},
    @{topic="beginners guide to canoeing in the Snowy Mountains"; category="outdoors-camping"; subcategory="hiking"; image="canoeing the Snowy Mountains"; tags="canoeing,outdoors,Australia"; amazon="tents"},
    @{topic="how to plan a hiking trip to tropical North Queensland"; category="outdoors-camping"; subcategory="4wd"; image="hiking tropical North Queensland"; tags="hiking,outdoors,Australia"; amazon="first aid kits"},
    @{topic="essential hiking checklist for budget travellers"; category="outdoors-camping"; subcategory="gear"; image="hiking the Great Ocean Road"; tags="hiking,outdoors,Australia"; amazon="tents"},
    @{topic="how to choose rooftop tents for beginners"; category="outdoors-camping"; subcategory="gear"; image="bushwalking remote Western Australia"; tags="bushwalking,outdoors,Australia"; amazon="rooftop tents"},
    @{topic="beginners guide to kayaking in the outback"; category="outdoors-camping"; subcategory="hiking"; image="kayaking the outback"; tags="kayaking,outdoors,Australia"; amazon="camping stoves"},
    @{topic="essential kayaking checklist for families"; category="outdoors-camping"; subcategory="gear"; image="kayaking the high country"; tags="kayaking,outdoors,Australia"; amazon="portable fridges"},
    @{topic="best glamping spots in the Snowy Mountains"; category="outdoors-camping"; subcategory="hiking"; image="glamping the Snowy Mountains"; tags="glamping,outdoors,Australia"; amazon="water filters"},
    @{topic="how to choose camping stoves for budget travellers"; category="outdoors-camping"; subcategory="gear"; image="canoeing Tasmania"; tags="canoeing,outdoors,Australia"; amazon="camping stoves"},
    @{topic="how to choose sleeping bags for experienced campers"; category="outdoors-camping"; subcategory="gear"; image="kayaking the Great Ocean Road"; tags="kayaking,outdoors,Australia"; amazon="sleeping bags"},
    @{topic="best rooftop tents for fishing in Australia"; category="outdoors-camping"; subcategory="gear"; image="fishing coastal Australia"; tags="fishing,outdoors,Australia"; amazon="rooftop tents"},
    @{topic="beginners guide to overlanding in national parks"; category="outdoors-camping"; subcategory="hiking"; image="overlanding national parks"; tags="overlanding,outdoors,Australia"; amazon="camping chairs"},
    @{topic="how to choose water filters for solo travellers"; category="outdoors-camping"; subcategory="gear"; image="canoeing Tasmania"; tags="canoeing,outdoors,Australia"; amazon="water filters"},
    @{topic="budget glamping tips for solo travellers"; category="outdoors-camping"; subcategory="gear"; image="glamping the Snowy Mountains"; tags="glamping,outdoors,Australia"; amazon="rooftop tents"},
    @{topic="essential caravanning checklist for couples"; category="outdoors-camping"; subcategory="gear"; image="caravanning the outback"; tags="caravanning,outdoors,Australia"; amazon="camping chairs"},
    @{topic="best sleeping bags for kayaking in Australia"; category="outdoors-camping"; subcategory="gear"; image="kayaking tropical North Queensland"; tags="kayaking,outdoors,Australia"; amazon="sleeping bags"},
    @{topic="best first aid kits for kayaking in Australia"; category="outdoors-camping"; subcategory="gear"; image="kayaking the outback"; tags="kayaking,outdoors,Australia"; amazon="first aid kits"},
    @{topic="budget hiking tips for beginners"; category="outdoors-camping"; subcategory="gear"; image="hiking the high country"; tags="hiking,outdoors,Australia"; amazon="camping chairs"},
    @{topic="essential 4WD touring checklist for families"; category="outdoors-camping"; subcategory="gear"; image="4WD touring the Red Centre"; tags="4WD touring,outdoors,Australia"; amazon="hiking backpacks"},
    @{topic="beginners guide to fishing in the outback"; category="outdoors-camping"; subcategory="hiking"; image="fishing the outback"; tags="fishing,outdoors,Australia"; amazon="water filters"},
    @{topic="budget canoeing tips for solo travellers"; category="outdoors-camping"; subcategory="gear"; image="canoeing the Great Ocean Road"; tags="canoeing,outdoors,Australia"; amazon="first aid kits"},
    @{topic="safety tips for fishing in the Red Centre"; category="outdoors-camping"; subcategory="survival"; image="fishing the Red Centre"; tags="fishing,outdoors,Australia"; amazon="camping chairs"},
    @{topic="budget 4WD touring tips for beginners"; category="outdoors-camping"; subcategory="gear"; image="4WD touring the Red Centre"; tags="4WD touring,outdoors,Australia"; amazon="rooftop tents"},
    @{topic="best time of year to go caravanning in national parks"; category="outdoors-camping"; subcategory="hiking"; image="caravanning national parks"; tags="caravanning,outdoors,Australia"; amazon="tents"},
    @{topic="beginners guide to caravanning in Tasmania"; category="outdoors-camping"; subcategory="hiking"; image="caravanning Tasmania"; tags="caravanning,outdoors,Australia"; amazon="rooftop tents"},
    @{topic="best caravanning spots in national parks"; category="outdoors-camping"; subcategory="hiking"; image="caravanning national parks"; tags="caravanning,outdoors,Australia"; amazon="first aid kits"},
    @{topic="safety tips for caravanning in the high country"; category="outdoors-camping"; subcategory="survival"; image="caravanning the high country"; tags="caravanning,outdoors,Australia"; amazon="camping stoves"},
    @{topic="common bushwalking mistakes solo travellers make"; category="outdoors-camping"; subcategory="gear"; image="bushwalking remote Western Australia"; tags="bushwalking,outdoors,Australia"; amazon="water filters"},
    @{topic="beginners guide to overlanding in the Great Ocean Road"; category="outdoors-camping"; subcategory="hiking"; image="overlanding the Great Ocean Road"; tags="overlanding,outdoors,Australia"; amazon="solar chargers"},
    @{topic="best hiking backpacks for hiking in Australia"; category="outdoors-camping"; subcategory="gear"; image="hiking the Great Ocean Road"; tags="hiking,outdoors,Australia"; amazon="hiking backpacks"},
    @{topic="how to plan a overlanding trip to national parks"; category="outdoors-camping"; subcategory="4wd"; image="overlanding national parks"; tags="overlanding,outdoors,Australia"; amazon="water filters"},
    @{topic="best first aid kits for fishing in Australia"; category="outdoors-camping"; subcategory="gear"; image="fishing tropical North Queensland"; tags="fishing,outdoors,Australia"; amazon="first aid kits"},
    @{topic="best camping stoves for canoeing in Australia"; category="outdoors-camping"; subcategory="gear"; image="canoeing the outback"; tags="canoeing,outdoors,Australia"; amazon="camping stoves"},
    @{topic="beginners guide to camping in remote Western Australia"; category="outdoors-camping"; subcategory="hiking"; image="camping remote Western Australia"; tags="camping,outdoors,Australia"; amazon="sleeping bags"},
    @{topic="budget overlanding tips for budget travellers"; category="outdoors-camping"; subcategory="gear"; image="overlanding the outback"; tags="overlanding,outdoors,Australia"; amazon="camping chairs"},
    @{topic="what to pack for kayaking in the Great Ocean Road"; category="outdoors-camping"; subcategory="gear"; image="kayaking the Great Ocean Road"; tags="kayaking,outdoors,Australia"; amazon="camping stoves"},
    @{topic="beginners guide to bushwalking in the outback"; category="outdoors-camping"; subcategory="hiking"; image="bushwalking the outback"; tags="bushwalking,outdoors,Australia"; amazon="solar chargers"},
    @{topic="safety tips for fishing in the outback"; category="outdoors-camping"; subcategory="survival"; image="fishing the outback"; tags="fishing,outdoors,Australia"; amazon="camping stoves"},
    @{topic="what to pack for bushwalking in the Snowy Mountains"; category="outdoors-camping"; subcategory="gear"; image="bushwalking the Snowy Mountains"; tags="bushwalking,outdoors,Australia"; amazon="first aid kits"},
    @{topic="budget 4WD touring tips for solo travellers"; category="outdoors-camping"; subcategory="gear"; image="4WD touring the Snowy Mountains"; tags="4WD touring,outdoors,Australia"; amazon="sleeping bags"},
    @{topic="essential glamping checklist for solo travellers"; category="outdoors-camping"; subcategory="gear"; image="glamping Tasmania"; tags="glamping,outdoors,Australia"; amazon="hiking backpacks"},
    @{topic="how to plan a glamping trip to the Snowy Mountains"; category="outdoors-camping"; subcategory="4wd"; image="glamping the Snowy Mountains"; tags="glamping,outdoors,Australia"; amazon="camping chairs"},
    @{topic="best time of year to go kayaking in the outback"; category="outdoors-camping"; subcategory="hiking"; image="kayaking the outback"; tags="kayaking,outdoors,Australia"; amazon="solar chargers"},
    @{topic="beginners guide to glamping in national parks"; category="outdoors-camping"; subcategory="hiking"; image="glamping national parks"; tags="glamping,outdoors,Australia"; amazon="hiking backpacks"},
    @{topic="how to stay safe from wildlife while canoeing"; category="outdoors-camping"; subcategory="survival"; image="canoeing the Snowy Mountains"; tags="canoeing,outdoors,Australia"; amazon="portable fridges"},
    @{topic="best 4WD touring spots in Tasmania"; category="outdoors-camping"; subcategory="hiking"; image="4WD touring Tasmania"; tags="4WD touring,outdoors,Australia"; amazon="camping chairs"},
    @{topic="safety tips for overlanding in the Great Ocean Road"; category="outdoors-camping"; subcategory="survival"; image="overlanding the Great Ocean Road"; tags="overlanding,outdoors,Australia"; amazon="rooftop tents"},
    @{topic="how to choose rooftop tents for experienced campers"; category="outdoors-camping"; subcategory="gear"; image="glamping the high country"; tags="glamping,outdoors,Australia"; amazon="rooftop tents"},
    @{topic="essential hiking checklist for beginners"; category="outdoors-camping"; subcategory="gear"; image="hiking coastal Australia"; tags="hiking,outdoors,Australia"; amazon="hiking backpacks"},
    @{topic="how to stay safe from wildlife while camping"; category="outdoors-camping"; subcategory="survival"; image="camping national parks"; tags="camping,outdoors,Australia"; amazon="first aid kits"},
    @{topic="budget kayaking tips for beginners"; category="outdoors-camping"; subcategory="gear"; image="kayaking the Snowy Mountains"; tags="kayaking,outdoors,Australia"; amazon="water filters"},
    @{topic="safety tips for hiking in Tasmania"; category="outdoors-camping"; subcategory="survival"; image="hiking Tasmania"; tags="hiking,outdoors,Australia"; amazon="rooftop tents"},
    @{topic="best fishing spots in the Great Ocean Road"; category="outdoors-camping"; subcategory="hiking"; image="fishing the Great Ocean Road"; tags="fishing,outdoors,Australia"; amazon="rooftop tents"},
    @{topic="safety tips for hiking in national parks"; category="outdoors-camping"; subcategory="survival"; image="hiking national parks"; tags="hiking,outdoors,Australia"; amazon="camping chairs"},
    @{topic="what to pack for hiking in remote Western Australia"; category="outdoors-camping"; subcategory="gear"; image="hiking remote Western Australia"; tags="hiking,outdoors,Australia"; amazon="solar chargers"},
    @{topic="essential hiking checklist for experienced campers"; category="outdoors-camping"; subcategory="gear"; image="hiking the Snowy Mountains"; tags="hiking,outdoors,Australia"; amazon="sleeping bags"},
    @{topic="safety tips for fishing in coastal Australia"; category="outdoors-camping"; subcategory="survival"; image="fishing coastal Australia"; tags="fishing,outdoors,Australia"; amazon="solar chargers"},
    @{topic="what to pack for hiking in the Red Centre"; category="outdoors-camping"; subcategory="gear"; image="hiking the Red Centre"; tags="hiking,outdoors,Australia"; amazon="camping chairs"},
    @{topic="best time of year to go overlanding in the Snowy Mountains"; category="outdoors-camping"; subcategory="hiking"; image="overlanding the Snowy Mountains"; tags="overlanding,outdoors,Australia"; amazon="camping stoves"},
    @{topic="common hiking mistakes solo travellers make"; category="outdoors-camping"; subcategory="gear"; image="hiking tropical North Queensland"; tags="hiking,outdoors,Australia"; amazon="camping chairs"},
    @{topic="budget overlanding tips for families"; category="outdoors-camping"; subcategory="gear"; image="overlanding the Great Ocean Road"; tags="overlanding,outdoors,Australia"; amazon="tents"},

    # FINANCE
    @{topic="common sense guide to home loans for retirees"; category="finance"; subcategory="investing"; image="home loans Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="common tax returns mistakes first home buyers make"; category="finance"; subcategory="budgeting"; image="tax returns Australia"; tags="budgeting,finance,Australia"; amazon="finance planner"},
    @{topic="emergency funds explained simply for retirees"; category="finance"; subcategory="saving"; image="emergency funds Australia"; tags="saving,finance,Australia"; amazon="finance planner"},
    @{topic="how to start financial independence with little money"; category="finance"; subcategory="investing"; image="financial independence Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="is now a good time for first home buyers to focus on home loans"; category="finance"; subcategory="investing"; image="home loans Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="credit cards explained simply for single income households"; category="finance"; subcategory="saving"; image="credit cards Australia"; tags="saving,finance,Australia"; amazon="finance planner"},
    @{topic="step by step guide to energy bill savings for freelancers"; category="finance"; subcategory="budgeting"; image="energy bill savings Australia"; tags="budgeting,finance,Australia"; amazon="finance planner"},
    @{topic="how to start side hustles with little money"; category="finance"; subcategory="investing"; image="side hustles Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="common tax returns mistakes single income households make"; category="finance"; subcategory="budgeting"; image="tax returns Australia"; tags="budgeting,finance,Australia"; amazon="finance planner"},
    @{topic="side hustles explained simply for students"; category="finance"; subcategory="investing"; image="side hustles Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="common sense guide to property investing for students"; category="finance"; subcategory="investing"; image="property investing Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="how freelancers can get better at energy bill savings"; category="finance"; subcategory="budgeting"; image="energy bill savings Australia"; tags="budgeting,finance,Australia"; amazon="finance planner"},
    @{topic="2026 guide to property investing for first home buyers"; category="finance"; subcategory="investing"; image="property investing Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="best energy bill savings strategies for retirees in Australia"; category="finance"; subcategory="budgeting"; image="energy bill savings Australia"; tags="budgeting,finance,Australia"; amazon="finance planner"},
    @{topic="investing in shares explained simply for single income households"; category="finance"; subcategory="investing"; image="investing in shares Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="common sense guide to emergency funds for freelancers"; category="finance"; subcategory="saving"; image="emergency funds Australia"; tags="saving,finance,Australia"; amazon="finance planner"},
    @{topic="how to start tax returns with little money"; category="finance"; subcategory="budgeting"; image="tax returns Australia"; tags="budgeting,finance,Australia"; amazon="finance planner"},
    @{topic="how to start superannuation with little money"; category="finance"; subcategory="superannuation"; image="superannuation Australia"; tags="superannuation,finance,Australia"; amazon="finance planner"},
    @{topic="2026 guide to home loans for retirees"; category="finance"; subcategory="investing"; image="home loans Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="how to compare budgeting options in Australia"; category="finance"; subcategory="budgeting"; image="budgeting Australia"; tags="budgeting,finance,Australia"; amazon="finance planner"},
    @{topic="best investing in shares strategies for young Australians in Australia"; category="finance"; subcategory="investing"; image="investing in shares Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="best tax returns strategies for families in Australia"; category="finance"; subcategory="budgeting"; image="tax returns Australia"; tags="budgeting,finance,Australia"; amazon="finance planner"},
    @{topic="how retirees can get better at side hustles"; category="finance"; subcategory="investing"; image="side hustles Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="is now a good time for small business owners to focus on side hustles"; category="finance"; subcategory="investing"; image="side hustles Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="tax returns explained simply for students"; category="finance"; subcategory="budgeting"; image="tax returns Australia"; tags="budgeting,finance,Australia"; amazon="finance planner"},
    @{topic="how single income households can get better at budgeting"; category="finance"; subcategory="budgeting"; image="budgeting Australia"; tags="budgeting,finance,Australia"; amazon="finance planner"},
    @{topic="how to compare property investing options in Australia"; category="finance"; subcategory="investing"; image="property investing Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="how first home buyers can get better at home loans"; category="finance"; subcategory="investing"; image="home loans Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="how to start retirement planning with little money"; category="finance"; subcategory="superannuation"; image="retirement planning Australia"; tags="superannuation,finance,Australia"; amazon="finance planner"},
    @{topic="common side hustles mistakes families make"; category="finance"; subcategory="investing"; image="side hustles Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="how to start saving with little money"; category="finance"; subcategory="saving"; image="saving Australia"; tags="saving,finance,Australia"; amazon="finance planner"},
    @{topic="financial independence explained simply for students"; category="finance"; subcategory="investing"; image="financial independence Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="how retirees can get better at investing in shares"; category="finance"; subcategory="investing"; image="investing in shares Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="how to start credit cards with little money"; category="finance"; subcategory="saving"; image="credit cards Australia"; tags="saving,finance,Australia"; amazon="finance planner"},
    @{topic="how to start investing in shares with little money"; category="finance"; subcategory="investing"; image="investing in shares Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="how to compare emergency funds options in Australia"; category="finance"; subcategory="saving"; image="emergency funds Australia"; tags="saving,finance,Australia"; amazon="finance planner"},
    @{topic="best energy bill savings strategies for families in Australia"; category="finance"; subcategory="budgeting"; image="energy bill savings Australia"; tags="budgeting,finance,Australia"; amazon="finance planner"},
    @{topic="low risk guide to financial independence for families"; category="finance"; subcategory="investing"; image="financial independence Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="how families can get better at budgeting"; category="finance"; subcategory="budgeting"; image="budgeting Australia"; tags="budgeting,finance,Australia"; amazon="finance planner"},
    @{topic="is now a good time for young Australians to focus on side hustles"; category="finance"; subcategory="investing"; image="side hustles Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="best emergency funds strategies for first home buyers in Australia"; category="finance"; subcategory="saving"; image="emergency funds Australia"; tags="saving,finance,Australia"; amazon="finance planner"},
    @{topic="best financial independence strategies for small business owners in Australia"; category="finance"; subcategory="investing"; image="financial independence Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="how first home buyers can get better at retirement planning"; category="finance"; subcategory="superannuation"; image="retirement planning Australia"; tags="superannuation,finance,Australia"; amazon="finance planner"},
    @{topic="how families can get better at property investing"; category="finance"; subcategory="investing"; image="property investing Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="insurance explained simply for first home buyers"; category="finance"; subcategory="saving"; image="insurance Australia"; tags="saving,finance,Australia"; amazon="finance planner"},
    @{topic="how to compare insurance options in Australia"; category="finance"; subcategory="saving"; image="insurance Australia"; tags="saving,finance,Australia"; amazon="finance planner"},
    @{topic="common tax returns mistakes freelancers make"; category="finance"; subcategory="budgeting"; image="tax returns Australia"; tags="budgeting,finance,Australia"; amazon="finance planner"},
    @{topic="how to compare saving options in Australia"; category="finance"; subcategory="saving"; image="saving Australia"; tags="saving,finance,Australia"; amazon="finance planner"},
    @{topic="common paying off debt mistakes families make"; category="finance"; subcategory="budgeting"; image="paying off debt Australia"; tags="budgeting,finance,Australia"; amazon="finance planner"},
    @{topic="best insurance strategies for young Australians in Australia"; category="finance"; subcategory="saving"; image="insurance Australia"; tags="saving,finance,Australia"; amazon="finance planner"},
    @{topic="best saving strategies for young Australians in Australia"; category="finance"; subcategory="saving"; image="saving Australia"; tags="saving,finance,Australia"; amazon="finance planner"},
    @{topic="best credit cards strategies for first home buyers in Australia"; category="finance"; subcategory="saving"; image="credit cards Australia"; tags="saving,finance,Australia"; amazon="finance planner"},
    @{topic="property investing explained simply for small business owners"; category="finance"; subcategory="investing"; image="property investing Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="how retirees can get better at superannuation"; category="finance"; subcategory="superannuation"; image="superannuation Australia"; tags="superannuation,finance,Australia"; amazon="finance planner"},
    @{topic="how to start property investing with little money"; category="finance"; subcategory="investing"; image="property investing Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="best side hustles strategies for small business owners in Australia"; category="finance"; subcategory="investing"; image="side hustles Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="how small business owners can get better at insurance"; category="finance"; subcategory="saving"; image="insurance Australia"; tags="saving,finance,Australia"; amazon="finance planner"},
    @{topic="common emergency funds mistakes small business owners make"; category="finance"; subcategory="saving"; image="emergency funds Australia"; tags="saving,finance,Australia"; amazon="finance planner"},
    @{topic="2026 guide to energy bill savings for retirees"; category="finance"; subcategory="budgeting"; image="energy bill savings Australia"; tags="budgeting,finance,Australia"; amazon="finance planner"},
    @{topic="step by step guide to energy bill savings for young Australians"; category="finance"; subcategory="budgeting"; image="energy bill savings Australia"; tags="budgeting,finance,Australia"; amazon="finance planner"},
    @{topic="paying off debt explained simply for first home buyers"; category="finance"; subcategory="budgeting"; image="paying off debt Australia"; tags="budgeting,finance,Australia"; amazon="finance planner"},
    @{topic="how to compare investing in shares options in Australia"; category="finance"; subcategory="investing"; image="investing in shares Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="is now a good time for freelancers to focus on property investing"; category="finance"; subcategory="investing"; image="property investing Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="home loans explained simply for retirees"; category="finance"; subcategory="investing"; image="home loans Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="is now a good time for first home buyers to focus on paying off debt"; category="finance"; subcategory="budgeting"; image="paying off debt Australia"; tags="budgeting,finance,Australia"; amazon="finance planner"},
    @{topic="best side hustles strategies for young Australians in Australia"; category="finance"; subcategory="investing"; image="side hustles Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="how freelancers can get better at financial independence"; category="finance"; subcategory="investing"; image="financial independence Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="common budgeting mistakes freelancers make"; category="finance"; subcategory="budgeting"; image="budgeting Australia"; tags="budgeting,finance,Australia"; amazon="finance planner"},
    @{topic="common budgeting mistakes single income households make"; category="finance"; subcategory="budgeting"; image="budgeting Australia"; tags="budgeting,finance,Australia"; amazon="finance planner"},
    @{topic="common investing in shares mistakes small business owners make"; category="finance"; subcategory="investing"; image="investing in shares Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="best side hustles strategies for first home buyers in Australia"; category="finance"; subcategory="investing"; image="side hustles Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="best retirement planning strategies for families in Australia"; category="finance"; subcategory="superannuation"; image="retirement planning Australia"; tags="superannuation,finance,Australia"; amazon="finance planner"},
    @{topic="is now a good time for students to focus on retirement planning"; category="finance"; subcategory="superannuation"; image="retirement planning Australia"; tags="superannuation,finance,Australia"; amazon="finance planner"},
    @{topic="property investing explained simply for families"; category="finance"; subcategory="investing"; image="property investing Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="paying off debt explained simply for families"; category="finance"; subcategory="budgeting"; image="paying off debt Australia"; tags="budgeting,finance,Australia"; amazon="finance planner"},
    @{topic="best property investing strategies for families in Australia"; category="finance"; subcategory="investing"; image="property investing Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="is now a good time for families to focus on energy bill savings"; category="finance"; subcategory="budgeting"; image="energy bill savings Australia"; tags="budgeting,finance,Australia"; amazon="finance planner"},
    @{topic="tax returns explained simply for young Australians"; category="finance"; subcategory="budgeting"; image="tax returns Australia"; tags="budgeting,finance,Australia"; amazon="finance planner"},
    @{topic="best retirement planning strategies for young Australians in Australia"; category="finance"; subcategory="superannuation"; image="retirement planning Australia"; tags="superannuation,finance,Australia"; amazon="finance planner"},
    @{topic="how to compare side hustles options in Australia"; category="finance"; subcategory="investing"; image="side hustles Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="emergency funds explained simply for students"; category="finance"; subcategory="saving"; image="emergency funds Australia"; tags="saving,finance,Australia"; amazon="finance planner"},
    @{topic="how to compare energy bill savings options in Australia"; category="finance"; subcategory="budgeting"; image="energy bill savings Australia"; tags="budgeting,finance,Australia"; amazon="finance planner"},
    @{topic="how to start home loans with little money"; category="finance"; subcategory="investing"; image="home loans Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="low risk guide to energy bill savings for freelancers"; category="finance"; subcategory="budgeting"; image="energy bill savings Australia"; tags="budgeting,finance,Australia"; amazon="finance planner"},
    @{topic="credit cards explained simply for young Australians"; category="finance"; subcategory="saving"; image="credit cards Australia"; tags="saving,finance,Australia"; amazon="finance planner"},
    @{topic="best energy bill savings strategies for single income households in Australia"; category="finance"; subcategory="budgeting"; image="energy bill savings Australia"; tags="budgeting,finance,Australia"; amazon="finance planner"},
    @{topic="is now a good time for retirees to focus on emergency funds"; category="finance"; subcategory="saving"; image="emergency funds Australia"; tags="saving,finance,Australia"; amazon="finance planner"},
    @{topic="common superannuation mistakes freelancers make"; category="finance"; subcategory="superannuation"; image="superannuation Australia"; tags="superannuation,finance,Australia"; amazon="finance planner"},
    @{topic="how to compare home loans options in Australia"; category="finance"; subcategory="investing"; image="home loans Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="how families can get better at insurance"; category="finance"; subcategory="saving"; image="insurance Australia"; tags="saving,finance,Australia"; amazon="finance planner"},
    @{topic="best superannuation strategies for young Australians in Australia"; category="finance"; subcategory="superannuation"; image="superannuation Australia"; tags="superannuation,finance,Australia"; amazon="finance planner"},
    @{topic="how to compare financial independence options in Australia"; category="finance"; subcategory="investing"; image="financial independence Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="how families can get better at side hustles"; category="finance"; subcategory="investing"; image="side hustles Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="insurance explained simply for single income households"; category="finance"; subcategory="saving"; image="insurance Australia"; tags="saving,finance,Australia"; amazon="finance planner"},
    @{topic="is now a good time for first home buyers to focus on retirement planning"; category="finance"; subcategory="superannuation"; image="retirement planning Australia"; tags="superannuation,finance,Australia"; amazon="finance planner"},
    @{topic="is now a good time for young Australians to focus on emergency funds"; category="finance"; subcategory="saving"; image="emergency funds Australia"; tags="saving,finance,Australia"; amazon="finance planner"},
    @{topic="how small business owners can get better at side hustles"; category="finance"; subcategory="investing"; image="side hustles Australia"; tags="investing,finance,Australia"; amazon="finance planner"},
    @{topic="how to start emergency funds with little money"; category="finance"; subcategory="saving"; image="emergency funds Australia"; tags="saving,finance,Australia"; amazon="finance planner"},
    @{topic="is now a good time for first home buyers to focus on insurance"; category="finance"; subcategory="saving"; image="insurance Australia"; tags="saving,finance,Australia"; amazon="finance planner"},
    @{topic="common emergency funds mistakes first home buyers make"; category="finance"; subcategory="saving"; image="emergency funds Australia"; tags="saving,finance,Australia"; amazon="finance planner"},

    # TECHNOLOGY
    @{topic="beginners guide to VPNs"; category="technology"; subcategory="smart-home"; image="e-readers technology"; tags="smart-home,technology,gadgets"; amazon="e-readers"},
    @{topic="how to keep your smart watches secure"; category="technology"; subcategory="reviews"; image="smart watches technology"; tags="reviews,technology,gadgets"; amazon="smart watches"},
    @{topic="how to keep your gaming monitors secure"; category="technology"; subcategory="reviews"; image="gaming monitors technology"; tags="reviews,technology,gadgets"; amazon="gaming monitors"},
    @{topic="best laptops for small businesses in 2026"; category="technology"; subcategory="gadgets"; image="laptops technology"; tags="gadgets,technology,gadgets"; amazon="laptops"},
    @{topic="how to choose VPNs in 2026"; category="technology"; subcategory="reviews"; image="smart watches technology"; tags="reviews,technology,gadgets"; amazon="smart watches"},
    @{topic="how seniors can protect their data online"; category="technology"; subcategory="reviews"; image="laptops technology"; tags="reviews,technology,gadgets"; amazon="laptops"},
    @{topic="how to troubleshoot tablets in 2026"; category="technology"; subcategory="computers"; image="tablets technology"; tags="computers,technology,gadgets"; amazon="tablets"},
    @{topic="how to choose smart watches in 2026"; category="technology"; subcategory="computers"; image="smart watches technology"; tags="computers,technology,gadgets"; amazon="smart watches"},
    @{topic="smart home devices worth buying for remote workers"; category="technology"; subcategory="smart-home"; image="smart speakers technology"; tags="smart-home,technology,gadgets"; amazon="smart speakers"},
    @{topic="best cloud storage for families"; category="technology"; subcategory="reviews"; image="portable chargers technology"; tags="reviews,technology,gadgets"; amazon="portable chargers"},
    @{topic="common tablets problems and how to fix them"; category="technology"; subcategory="computers"; image="tablets technology"; tags="computers,technology,gadgets"; amazon="tablets"},
    @{topic="how remote workers can protect their data online"; category="technology"; subcategory="reviews"; image="gaming monitors technology"; tags="reviews,technology,gadgets"; amazon="gaming monitors"},
    @{topic="common smart speakers problems and how to fix them"; category="technology"; subcategory="computers"; image="smart speakers technology"; tags="computers,technology,gadgets"; amazon="smart speakers"},
    @{topic="how to keep your e-readers secure"; category="technology"; subcategory="reviews"; image="e-readers technology"; tags="reviews,technology,gadgets"; amazon="e-readers"},
    @{topic="how to choose password managers in 2026"; category="technology"; subcategory="reviews"; image="security cameras technology"; tags="reviews,technology,gadgets"; amazon="security cameras"},
    @{topic="beginners guide to antivirus software"; category="technology"; subcategory="smart-home"; image="smart watches technology"; tags="smart-home,technology,gadgets"; amazon="smart watches"},
    @{topic="best smart speakers for families in 2026"; category="technology"; subcategory="gadgets"; image="smart speakers technology"; tags="gadgets,technology,gadgets"; amazon="smart speakers"},
    @{topic="best smart speakers for remote workers in 2026"; category="technology"; subcategory="gadgets"; image="smart speakers technology"; tags="gadgets,technology,gadgets"; amazon="smart speakers"},
    @{topic="smart home devices worth buying for families"; category="technology"; subcategory="smart-home"; image="wireless earbuds technology"; tags="smart-home,technology,gadgets"; amazon="wireless earbuds"},
    @{topic="how to keep your tablets secure"; category="technology"; subcategory="reviews"; image="tablets technology"; tags="reviews,technology,gadgets"; amazon="tablets"},
    @{topic="how to compare tablets in 2026"; category="technology"; subcategory="computers"; image="tablets technology"; tags="computers,technology,gadgets"; amazon="tablets"},
    @{topic="how to choose antivirus software in 2026"; category="technology"; subcategory="reviews"; image="laptops technology"; tags="reviews,technology,gadgets"; amazon="laptops"},
    @{topic="smart home devices worth buying for seniors"; category="technology"; subcategory="smart-home"; image="wireless earbuds technology"; tags="smart-home,technology,gadgets"; amazon="wireless earbuds"},
    @{topic="smart home devices worth buying for gamers"; category="technology"; subcategory="smart-home"; image="tablets technology"; tags="smart-home,technology,gadgets"; amazon="tablets"},
    @{topic="how to get the most out of smart speakers in 2026"; category="technology"; subcategory="computers"; image="smart speakers technology"; tags="computers,technology,gadgets"; amazon="smart speakers"},
    @{topic="beginners guide to password managers"; category="technology"; subcategory="smart-home"; image="robot vacuums technology"; tags="smart-home,technology,gadgets"; amazon="robot vacuums"},
    @{topic="how to keep your wireless earbuds secure"; category="technology"; subcategory="reviews"; image="wireless earbuds technology"; tags="reviews,technology,gadgets"; amazon="wireless earbuds"},
    @{topic="how students can protect their data online"; category="technology"; subcategory="reviews"; image="gaming monitors technology"; tags="reviews,technology,gadgets"; amazon="gaming monitors"},
    @{topic="common e-readers problems and how to fix them"; category="technology"; subcategory="computers"; image="e-readers technology"; tags="computers,technology,gadgets"; amazon="e-readers"},
    @{topic="how to keep your robot vacuums secure"; category="technology"; subcategory="reviews"; image="robot vacuums technology"; tags="reviews,technology,gadgets"; amazon="robot vacuums"},
    @{topic="smart home devices worth buying for budget shoppers"; category="technology"; subcategory="smart-home"; image="laptops technology"; tags="smart-home,technology,gadgets"; amazon="laptops"},
    @{topic="best gaming monitors for gamers in 2026"; category="technology"; subcategory="gadgets"; image="gaming monitors technology"; tags="gadgets,technology,gadgets"; amazon="gaming monitors"},
    @{topic="smart speakers buying guide for remote workers"; category="technology"; subcategory="gadgets"; image="smart speakers technology"; tags="gadgets,technology,gadgets"; amazon="smart speakers"},
    @{topic="best wireless earbuds for seniors in 2026"; category="technology"; subcategory="gadgets"; image="wireless earbuds technology"; tags="gadgets,technology,gadgets"; amazon="wireless earbuds"},
    @{topic="how to upgrade smart speakers in 2026"; category="technology"; subcategory="computers"; image="smart speakers technology"; tags="computers,technology,gadgets"; amazon="smart speakers"},
    @{topic="smart home devices worth buying for small businesses"; category="technology"; subcategory="smart-home"; image="smartphones technology"; tags="smart-home,technology,gadgets"; amazon="smartphones"},
    @{topic="how budget shoppers can protect their data online"; category="technology"; subcategory="reviews"; image="robot vacuums technology"; tags="reviews,technology,gadgets"; amazon="robot vacuums"},
    @{topic="how to maintain routers in 2026"; category="technology"; subcategory="computers"; image="routers technology"; tags="computers,technology,gadgets"; amazon="routers"},
    @{topic="robot vacuums buying guide for small businesses"; category="technology"; subcategory="gadgets"; image="robot vacuums technology"; tags="gadgets,technology,gadgets"; amazon="robot vacuums"},
    @{topic="best smart speakers for students in 2026"; category="technology"; subcategory="gadgets"; image="smart speakers technology"; tags="gadgets,technology,gadgets"; amazon="smart speakers"},
    @{topic="best tablets for families in 2026"; category="technology"; subcategory="gadgets"; image="tablets technology"; tags="gadgets,technology,gadgets"; amazon="tablets"},
    @{topic="best VPNs for gamers"; category="technology"; subcategory="reviews"; image="smartphones technology"; tags="reviews,technology,gadgets"; amazon="smartphones"},
    @{topic="best robot vacuums for families in 2026"; category="technology"; subcategory="gadgets"; image="robot vacuums technology"; tags="gadgets,technology,gadgets"; amazon="robot vacuums"},
    @{topic="gaming monitors buying guide for students"; category="technology"; subcategory="gadgets"; image="gaming monitors technology"; tags="gadgets,technology,gadgets"; amazon="gaming monitors"},
    @{topic="common routers problems and how to fix them"; category="technology"; subcategory="computers"; image="routers technology"; tags="computers,technology,gadgets"; amazon="routers"},
    @{topic="gaming monitors buying guide for small businesses"; category="technology"; subcategory="gadgets"; image="gaming monitors technology"; tags="gadgets,technology,gadgets"; amazon="gaming monitors"},
    @{topic="smart home devices worth buying for students"; category="technology"; subcategory="smart-home"; image="security cameras technology"; tags="smart-home,technology,gadgets"; amazon="security cameras"},
    @{topic="common security cameras problems and how to fix them"; category="technology"; subcategory="computers"; image="security cameras technology"; tags="computers,technology,gadgets"; amazon="security cameras"},
    @{topic="common robot vacuums problems and how to fix them"; category="technology"; subcategory="computers"; image="robot vacuums technology"; tags="computers,technology,gadgets"; amazon="robot vacuums"},
    @{topic="common gaming monitors problems and how to fix them"; category="technology"; subcategory="computers"; image="gaming monitors technology"; tags="computers,technology,gadgets"; amazon="gaming monitors"},
    @{topic="common wireless earbuds problems and how to fix them"; category="technology"; subcategory="computers"; image="wireless earbuds technology"; tags="computers,technology,gadgets"; amazon="wireless earbuds"},
    @{topic="best cloud storage for gamers"; category="technology"; subcategory="reviews"; image="smartphones technology"; tags="reviews,technology,gadgets"; amazon="smartphones"},
    @{topic="how to upgrade routers in 2026"; category="technology"; subcategory="computers"; image="routers technology"; tags="computers,technology,gadgets"; amazon="routers"},
    @{topic="best VPNs for budget shoppers"; category="technology"; subcategory="reviews"; image="smartphones technology"; tags="reviews,technology,gadgets"; amazon="smartphones"},
    @{topic="how to set up wireless earbuds in 2026"; category="technology"; subcategory="computers"; image="wireless earbuds technology"; tags="computers,technology,gadgets"; amazon="wireless earbuds"},
    @{topic="smartphones buying guide for families"; category="technology"; subcategory="gadgets"; image="smartphones technology"; tags="gadgets,technology,gadgets"; amazon="smartphones"},
    @{topic="how small businesses can protect their data online"; category="technology"; subcategory="reviews"; image="robot vacuums technology"; tags="reviews,technology,gadgets"; amazon="robot vacuums"},
    @{topic="how families can protect their data online"; category="technology"; subcategory="reviews"; image="portable chargers technology"; tags="reviews,technology,gadgets"; amazon="portable chargers"},
    @{topic="how to compare laptops in 2026"; category="technology"; subcategory="computers"; image="laptops technology"; tags="computers,technology,gadgets"; amazon="laptops"},
    @{topic="how to compare smartphones in 2026"; category="technology"; subcategory="computers"; image="smartphones technology"; tags="computers,technology,gadgets"; amazon="smartphones"},
    @{topic="best antivirus software for families"; category="technology"; subcategory="reviews"; image="robot vacuums technology"; tags="reviews,technology,gadgets"; amazon="robot vacuums"},
    @{topic="best smart watches for gamers in 2026"; category="technology"; subcategory="gadgets"; image="smart watches technology"; tags="gadgets,technology,gadgets"; amazon="smart watches"},
    @{topic="best robot vacuums for small businesses in 2026"; category="technology"; subcategory="gadgets"; image="robot vacuums technology"; tags="gadgets,technology,gadgets"; amazon="robot vacuums"},
    @{topic="best routers for small businesses in 2026"; category="technology"; subcategory="gadgets"; image="routers technology"; tags="gadgets,technology,gadgets"; amazon="routers"},
    @{topic="portable chargers buying guide for seniors"; category="technology"; subcategory="gadgets"; image="portable chargers technology"; tags="gadgets,technology,gadgets"; amazon="portable chargers"},
    @{topic="smart watches buying guide for remote workers"; category="technology"; subcategory="gadgets"; image="smart watches technology"; tags="gadgets,technology,gadgets"; amazon="smart watches"},
    @{topic="best routers for remote workers in 2026"; category="technology"; subcategory="gadgets"; image="routers technology"; tags="gadgets,technology,gadgets"; amazon="routers"},
    @{topic="best security cameras for students in 2026"; category="technology"; subcategory="gadgets"; image="security cameras technology"; tags="gadgets,technology,gadgets"; amazon="security cameras"},
    @{topic="how to troubleshoot smart watches in 2026"; category="technology"; subcategory="computers"; image="smart watches technology"; tags="computers,technology,gadgets"; amazon="smart watches"},
    @{topic="how to get the most out of tablets in 2026"; category="technology"; subcategory="computers"; image="tablets technology"; tags="computers,technology,gadgets"; amazon="tablets"},
    @{topic="best password managers for seniors"; category="technology"; subcategory="reviews"; image="tablets technology"; tags="reviews,technology,gadgets"; amazon="tablets"},
    @{topic="how to choose smartphones in 2026"; category="technology"; subcategory="computers"; image="smartphones technology"; tags="computers,technology,gadgets"; amazon="smartphones"},
    @{topic="best cloud storage for remote workers"; category="technology"; subcategory="reviews"; image="tablets technology"; tags="reviews,technology,gadgets"; amazon="tablets"},
    @{topic="best cloud storage for small businesses"; category="technology"; subcategory="reviews"; image="smartphones technology"; tags="reviews,technology,gadgets"; amazon="smartphones"},
    @{topic="common smart watches problems and how to fix them"; category="technology"; subcategory="computers"; image="smart watches technology"; tags="computers,technology,gadgets"; amazon="smart watches"},
    @{topic="how to keep your smartphones secure"; category="technology"; subcategory="reviews"; image="smartphones technology"; tags="reviews,technology,gadgets"; amazon="smartphones"},
    @{topic="beginners guide to cloud storage"; category="technology"; subcategory="smart-home"; image="wireless earbuds technology"; tags="smart-home,technology,gadgets"; amazon="wireless earbuds"},
    @{topic="best antivirus software for small businesses"; category="technology"; subcategory="reviews"; image="security cameras technology"; tags="reviews,technology,gadgets"; amazon="security cameras"},
    @{topic="how to choose routers in 2026"; category="technology"; subcategory="computers"; image="routers technology"; tags="computers,technology,gadgets"; amazon="routers"},
    @{topic="how to get the most out of laptops in 2026"; category="technology"; subcategory="computers"; image="laptops technology"; tags="computers,technology,gadgets"; amazon="laptops"},
    @{topic="best antivirus software for remote workers"; category="technology"; subcategory="reviews"; image="e-readers technology"; tags="reviews,technology,gadgets"; amazon="e-readers"},
    @{topic="how to upgrade smartphones in 2026"; category="technology"; subcategory="computers"; image="smartphones technology"; tags="computers,technology,gadgets"; amazon="smartphones"},
    @{topic="best routers for gamers in 2026"; category="technology"; subcategory="gadgets"; image="routers technology"; tags="gadgets,technology,gadgets"; amazon="routers"},
    @{topic="best smart watches for small businesses in 2026"; category="technology"; subcategory="gadgets"; image="smart watches technology"; tags="gadgets,technology,gadgets"; amazon="smart watches"},
    @{topic="laptops buying guide for students"; category="technology"; subcategory="gadgets"; image="laptops technology"; tags="gadgets,technology,gadgets"; amazon="laptops"},
    @{topic="how to keep your laptops secure"; category="technology"; subcategory="reviews"; image="laptops technology"; tags="reviews,technology,gadgets"; amazon="laptops"},
    @{topic="how to upgrade tablets in 2026"; category="technology"; subcategory="computers"; image="tablets technology"; tags="computers,technology,gadgets"; amazon="tablets"},
    @{topic="best VPNs for remote workers"; category="technology"; subcategory="reviews"; image="portable chargers technology"; tags="reviews,technology,gadgets"; amazon="portable chargers"},
    @{topic="laptops buying guide for seniors"; category="technology"; subcategory="gadgets"; image="laptops technology"; tags="gadgets,technology,gadgets"; amazon="laptops"},
    @{topic="how gamers can protect their data online"; category="technology"; subcategory="reviews"; image="gaming monitors technology"; tags="reviews,technology,gadgets"; amazon="gaming monitors"},
    @{topic="best password managers for families"; category="technology"; subcategory="reviews"; image="smartphones technology"; tags="reviews,technology,gadgets"; amazon="smartphones"},
    @{topic="common portable chargers problems and how to fix them"; category="technology"; subcategory="computers"; image="portable chargers technology"; tags="computers,technology,gadgets"; amazon="portable chargers"},
    @{topic="tablets buying guide for seniors"; category="technology"; subcategory="gadgets"; image="tablets technology"; tags="gadgets,technology,gadgets"; amazon="tablets"},
    @{topic="best VPNs for seniors"; category="technology"; subcategory="reviews"; image="tablets technology"; tags="reviews,technology,gadgets"; amazon="tablets"},
    @{topic="how to maintain gaming monitors in 2026"; category="technology"; subcategory="computers"; image="gaming monitors technology"; tags="computers,technology,gadgets"; amazon="gaming monitors"},
    @{topic="how to choose e-readers in 2026"; category="technology"; subcategory="computers"; image="e-readers technology"; tags="computers,technology,gadgets"; amazon="e-readers"},
    @{topic="how to keep your portable chargers secure"; category="technology"; subcategory="reviews"; image="portable chargers technology"; tags="reviews,technology,gadgets"; amazon="portable chargers"},
    @{topic="best portable chargers for remote workers in 2026"; category="technology"; subcategory="gadgets"; image="portable chargers technology"; tags="gadgets,technology,gadgets"; amazon="portable chargers"},
    @{topic="best password managers for gamers"; category="technology"; subcategory="reviews"; image="gaming monitors technology"; tags="reviews,technology,gadgets"; amazon="gaming monitors"},
    @{topic="best cloud storage for students"; category="technology"; subcategory="reviews"; image="gaming monitors technology"; tags="reviews,technology,gadgets"; amazon="gaming monitors"},

    # HEALTH
    @{topic="how to build a weight management routine that sticks"; category="health"; subcategory="fitness"; image="weight management health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="best sleep habits for seniors"; category="health"; subcategory="fitness"; image="sleep health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="best sleep habits for remote workers"; category="health"; subcategory="fitness"; image="sleep health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="how to fit better nutrition into a busy schedule"; category="health"; subcategory="fitness"; image="nutrition health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="signs your stress management needs attention"; category="health"; subcategory="mental-health"; image="stress management health"; tags="mental-health,health,wellbeing"; amazon="wellness products"},
    @{topic="best posture habits for seniors"; category="health"; subcategory="fitness"; image="posture health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="best stress management habits for seniors"; category="health"; subcategory="fitness"; image="stress management health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="how to fit better screen time into a busy schedule"; category="health"; subcategory="fitness"; image="screen time health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="common meal prep mistakes shift workers make"; category="health"; subcategory="nutrition"; image="meal prep health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="practical tips to improve your stress management"; category="health"; subcategory="fitness"; image="stress management health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="natural tips to improve your sleep"; category="health"; subcategory="fitness"; image="sleep health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="how to fit better hydration into a busy schedule"; category="health"; subcategory="fitness"; image="hydration health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="how seniors can improve their exercise"; category="health"; subcategory="mental-health"; image="exercise health"; tags="mental-health,health,wellbeing"; amazon="wellness products"},
    @{topic="natural tips to improve your stress management"; category="health"; subcategory="fitness"; image="stress management health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="how beginners can improve their stress management"; category="health"; subcategory="mental-health"; image="stress management health"; tags="mental-health,health,wellbeing"; amazon="wellness products"},
    @{topic="how to build a healthy habits routine that sticks"; category="health"; subcategory="fitness"; image="healthy habits health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="beginner friendly tips to improve your healthy habits"; category="health"; subcategory="fitness"; image="healthy habits health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="how shift workers can improve their healthy habits"; category="health"; subcategory="mental-health"; image="healthy habits health"; tags="mental-health,health,wellbeing"; amazon="wellness products"},
    @{topic="how beginners can improve their home workouts"; category="health"; subcategory="mental-health"; image="home workouts health"; tags="mental-health,health,wellbeing"; amazon="wellness products"},
    @{topic="best mental health habits for seniors"; category="health"; subcategory="fitness"; image="mental health health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="common screen time mistakes busy professionals make"; category="health"; subcategory="nutrition"; image="screen time health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="beginner friendly tips to improve your screen time"; category="health"; subcategory="fitness"; image="screen time health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="common nutrition mistakes beginners make"; category="health"; subcategory="nutrition"; image="nutrition health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="common posture mistakes shift workers make"; category="health"; subcategory="nutrition"; image="posture health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="how to build a stress management routine that sticks"; category="health"; subcategory="fitness"; image="stress management health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="how to fit better healthy habits into a busy schedule"; category="health"; subcategory="fitness"; image="healthy habits health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="screen time guide for seniors in Australia"; category="health"; subcategory="nutrition"; image="screen time health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="how shift workers can improve their stress management"; category="health"; subcategory="mental-health"; image="stress management health"; tags="mental-health,health,wellbeing"; amazon="wellness products"},
    @{topic="signs your nutrition needs attention"; category="health"; subcategory="mental-health"; image="nutrition health"; tags="mental-health,health,wellbeing"; amazon="wellness products"},
    @{topic="how to build a meal prep routine that sticks"; category="health"; subcategory="fitness"; image="meal prep health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="common exercise mistakes Australians make"; category="health"; subcategory="nutrition"; image="exercise health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="how busy professionals can improve their mental health"; category="health"; subcategory="mental-health"; image="mental health health"; tags="mental-health,health,wellbeing"; amazon="wellness products"},
    @{topic="how to build a sleep routine that sticks"; category="health"; subcategory="fitness"; image="sleep health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="how to build a home workouts routine that sticks"; category="health"; subcategory="fitness"; image="home workouts health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="signs your posture needs attention"; category="health"; subcategory="mental-health"; image="posture health"; tags="mental-health,health,wellbeing"; amazon="wellness products"},
    @{topic="how seniors can improve their screen time"; category="health"; subcategory="mental-health"; image="screen time health"; tags="mental-health,health,wellbeing"; amazon="wellness products"},
    @{topic="weight management guide for remote workers in Australia"; category="health"; subcategory="nutrition"; image="weight management health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="signs your mental health needs attention"; category="health"; subcategory="mental-health"; image="mental health health"; tags="mental-health,health,wellbeing"; amazon="wellness products"},
    @{topic="how Australians can improve their mental health"; category="health"; subcategory="mental-health"; image="mental health health"; tags="mental-health,health,wellbeing"; amazon="wellness products"},
    @{topic="best mental health habits for students"; category="health"; subcategory="fitness"; image="mental health health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="how to build a mental health routine that sticks"; category="health"; subcategory="fitness"; image="mental health health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="common hydration mistakes beginners make"; category="health"; subcategory="nutrition"; image="hydration health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="how remote workers can improve their exercise"; category="health"; subcategory="mental-health"; image="exercise health"; tags="mental-health,health,wellbeing"; amazon="wellness products"},
    @{topic="signs your sleep needs attention"; category="health"; subcategory="mental-health"; image="sleep health"; tags="mental-health,health,wellbeing"; amazon="wellness products"},
    @{topic="how to fit better home workouts into a busy schedule"; category="health"; subcategory="fitness"; image="home workouts health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="common mental health mistakes parents make"; category="health"; subcategory="nutrition"; image="mental health health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="simple tips to improve your stress management"; category="health"; subcategory="fitness"; image="stress management health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="best screen time habits for seniors"; category="health"; subcategory="fitness"; image="screen time health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="best home workouts habits for seniors"; category="health"; subcategory="fitness"; image="home workouts health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="how students can improve their hydration"; category="health"; subcategory="mental-health"; image="hydration health"; tags="mental-health,health,wellbeing"; amazon="wellness products"},
    @{topic="evidence based tips to improve your mental health"; category="health"; subcategory="fitness"; image="mental health health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="simple tips to improve your healthy habits"; category="health"; subcategory="fitness"; image="healthy habits health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="evidence based tips to improve your hydration"; category="health"; subcategory="fitness"; image="hydration health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="natural tips to improve your exercise"; category="health"; subcategory="fitness"; image="exercise health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="best screen time habits for beginners"; category="health"; subcategory="fitness"; image="screen time health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="best mental health habits for shift workers"; category="health"; subcategory="fitness"; image="mental health health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="common screen time mistakes seniors make"; category="health"; subcategory="nutrition"; image="screen time health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="hydration guide for seniors in Australia"; category="health"; subcategory="nutrition"; image="hydration health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="signs your exercise needs attention"; category="health"; subcategory="mental-health"; image="exercise health"; tags="mental-health,health,wellbeing"; amazon="wellness products"},
    @{topic="how to fit better exercise into a busy schedule"; category="health"; subcategory="fitness"; image="exercise health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="how to build a nutrition routine that sticks"; category="health"; subcategory="fitness"; image="nutrition health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="mental health guide for students in Australia"; category="health"; subcategory="nutrition"; image="mental health health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="best posture habits for students"; category="health"; subcategory="fitness"; image="posture health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="how to fit better weight management into a busy schedule"; category="health"; subcategory="fitness"; image="weight management health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="signs your hydration needs attention"; category="health"; subcategory="mental-health"; image="hydration health"; tags="mental-health,health,wellbeing"; amazon="wellness products"},
    @{topic="common hydration mistakes students make"; category="health"; subcategory="nutrition"; image="hydration health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="common hydration mistakes Australians make"; category="health"; subcategory="nutrition"; image="hydration health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="natural tips to improve your posture"; category="health"; subcategory="fitness"; image="posture health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="best home workouts habits for busy professionals"; category="health"; subcategory="fitness"; image="home workouts health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="nutrition guide for busy professionals in Australia"; category="health"; subcategory="nutrition"; image="nutrition health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="common stress management mistakes beginners make"; category="health"; subcategory="nutrition"; image="stress management health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="best meal prep habits for parents"; category="health"; subcategory="fitness"; image="meal prep health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="natural tips to improve your nutrition"; category="health"; subcategory="fitness"; image="nutrition health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="how beginners can improve their screen time"; category="health"; subcategory="mental-health"; image="screen time health"; tags="mental-health,health,wellbeing"; amazon="wellness products"},
    @{topic="how shift workers can improve their posture"; category="health"; subcategory="mental-health"; image="posture health"; tags="mental-health,health,wellbeing"; amazon="wellness products"},
    @{topic="mental health guide for remote workers in Australia"; category="health"; subcategory="nutrition"; image="mental health health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="home workouts guide for Australians in Australia"; category="health"; subcategory="nutrition"; image="home workouts health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="best nutrition habits for remote workers"; category="health"; subcategory="fitness"; image="nutrition health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="how to fit better stress management into a busy schedule"; category="health"; subcategory="fitness"; image="stress management health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="how seniors can improve their sleep"; category="health"; subcategory="mental-health"; image="sleep health"; tags="mental-health,health,wellbeing"; amazon="wellness products"},
    @{topic="common home workouts mistakes beginners make"; category="health"; subcategory="nutrition"; image="home workouts health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="how students can improve their screen time"; category="health"; subcategory="mental-health"; image="screen time health"; tags="mental-health,health,wellbeing"; amazon="wellness products"},
    @{topic="healthy habits guide for seniors in Australia"; category="health"; subcategory="nutrition"; image="healthy habits health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="how shift workers can improve their mental health"; category="health"; subcategory="mental-health"; image="mental health health"; tags="mental-health,health,wellbeing"; amazon="wellness products"},
    @{topic="common mental health mistakes remote workers make"; category="health"; subcategory="nutrition"; image="mental health health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="common nutrition mistakes remote workers make"; category="health"; subcategory="nutrition"; image="nutrition health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="exercise guide for Australians in Australia"; category="health"; subcategory="nutrition"; image="exercise health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="evidence based tips to improve your home workouts"; category="health"; subcategory="fitness"; image="home workouts health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="best screen time habits for remote workers"; category="health"; subcategory="fitness"; image="screen time health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="how remote workers can improve their hydration"; category="health"; subcategory="mental-health"; image="hydration health"; tags="mental-health,health,wellbeing"; amazon="wellness products"},
    @{topic="natural tips to improve your weight management"; category="health"; subcategory="fitness"; image="weight management health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="evidence based tips to improve your stress management"; category="health"; subcategory="fitness"; image="stress management health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="how students can improve their exercise"; category="health"; subcategory="mental-health"; image="exercise health"; tags="mental-health,health,wellbeing"; amazon="wellness products"},
    @{topic="stress management guide for beginners in Australia"; category="health"; subcategory="nutrition"; image="stress management health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="stress management guide for remote workers in Australia"; category="health"; subcategory="nutrition"; image="stress management health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="best weight management habits for parents"; category="health"; subcategory="fitness"; image="weight management health"; tags="fitness,health,wellbeing"; amazon="wellness products"},
    @{topic="common home workouts mistakes shift workers make"; category="health"; subcategory="nutrition"; image="home workouts health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="common healthy habits mistakes students make"; category="health"; subcategory="nutrition"; image="healthy habits health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="common home workouts mistakes parents make"; category="health"; subcategory="nutrition"; image="home workouts health"; tags="nutrition,health,wellbeing"; amazon="wellness products"},
    @{topic="best posture habits for shift workers"; category="health"; subcategory="fitness"; image="posture health"; tags="fitness,health,wellbeing"; amazon="wellness products"},

    # AUTOMOTIVE
    @{topic="best hybrid cars for road trippers in 2026"; category="automotive"; subcategory="reviews"; image="hybrid cars Australia"; tags="reviews,cars,Australia"; amazon="hybrid cars"},
    @{topic="how to save money maintaining used cars"; category="automotive"; subcategory="maintenance"; image="used cars Australia"; tags="maintenance,cars,Australia"; amazon="used cars"},
    @{topic="best road trips for road trippers in Australia"; category="automotive"; subcategory="road-trips"; image="family SUVs Australia"; tags="road-trips,cars,Australia"; amazon="family SUVs"},
    @{topic="how to choose the right roadside safety for your car"; category="automotive"; subcategory="maintenance"; image="used cars Australia"; tags="maintenance,cars,Australia"; amazon="used cars"},
    @{topic="common family SUVs mistakes families make"; category="automotive"; subcategory="reviews"; image="family SUVs Australia"; tags="reviews,cars,Australia"; amazon="family SUVs"},
    @{topic="how to prepare your car for tyres"; category="automotive"; subcategory="maintenance"; image="4WDs Australia"; tags="maintenance,cars,Australia"; amazon="4WDs"},
    @{topic="how to prepare your car for brakes"; category="automotive"; subcategory="maintenance"; image="motorbikes Australia"; tags="maintenance,cars,Australia"; amazon="motorbikes"},
    @{topic="how to choose the right tyres for your car"; category="automotive"; subcategory="maintenance"; image="electric cars Australia"; tags="maintenance,cars,Australia"; amazon="electric cars"},
    @{topic="best 4WDs for road trippers in 2026"; category="automotive"; subcategory="reviews"; image="4WDs Australia"; tags="reviews,cars,Australia"; amazon="4WDs"},
    @{topic="guide to selling family SUVs in Australia"; category="automotive"; subcategory="reviews"; image="family SUVs Australia"; tags="reviews,cars,Australia"; amazon="family SUVs"},
    @{topic="dash cams guide for Australian drivers"; category="automotive"; subcategory="maintenance"; image="caravans Australia"; tags="maintenance,cars,Australia"; amazon="caravans"},
    @{topic="common used cars mistakes families make"; category="automotive"; subcategory="reviews"; image="used cars Australia"; tags="reviews,cars,Australia"; amazon="used cars"},
    @{topic="common caravans mistakes road trippers make"; category="automotive"; subcategory="reviews"; image="caravans Australia"; tags="reviews,cars,Australia"; amazon="caravans"},
    @{topic="guide to servicing 4WDs in Australia"; category="automotive"; subcategory="reviews"; image="4WDs Australia"; tags="reviews,cars,Australia"; amazon="4WDs"},
    @{topic="roadside safety guide for Australian drivers"; category="automotive"; subcategory="maintenance"; image="4WDs Australia"; tags="maintenance,cars,Australia"; amazon="4WDs"},
    @{topic="how to save money buying motorbikes"; category="automotive"; subcategory="maintenance"; image="motorbikes Australia"; tags="maintenance,cars,Australia"; amazon="motorbikes"},
    @{topic="how to choose the right brakes for your car"; category="automotive"; subcategory="maintenance"; image="family SUVs Australia"; tags="maintenance,cars,Australia"; amazon="family SUVs"},
    @{topic="best road trips for families in Australia"; category="automotive"; subcategory="road-trips"; image="motorbikes Australia"; tags="road-trips,cars,Australia"; amazon="motorbikes"},
    @{topic="guide to detailing caravans in Australia"; category="automotive"; subcategory="reviews"; image="caravans Australia"; tags="reviews,cars,Australia"; amazon="caravans"},
    @{topic="common 4WDs mistakes first time buyers make"; category="automotive"; subcategory="reviews"; image="4WDs Australia"; tags="reviews,cars,Australia"; amazon="4WDs"},
    @{topic="guide to financing used cars in Australia"; category="automotive"; subcategory="reviews"; image="used cars Australia"; tags="reviews,cars,Australia"; amazon="used cars"},
    @{topic="common family SUVs mistakes road trippers make"; category="automotive"; subcategory="reviews"; image="family SUVs Australia"; tags="reviews,cars,Australia"; amazon="family SUVs"},
    @{topic="guide to insuring used cars in Australia"; category="automotive"; subcategory="reviews"; image="used cars Australia"; tags="reviews,cars,Australia"; amazon="used cars"},
    @{topic="brakes guide for Australian drivers"; category="automotive"; subcategory="maintenance"; image="hybrid cars Australia"; tags="maintenance,cars,Australia"; amazon="hybrid cars"},
    @{topic="how to choose the right dash cams for your car"; category="automotive"; subcategory="maintenance"; image="utes Australia"; tags="maintenance,cars,Australia"; amazon="utes"},
    @{topic="best road trips for P plate drivers in Australia"; category="automotive"; subcategory="road-trips"; image="electric cars Australia"; tags="road-trips,cars,Australia"; amazon="electric cars"},
    @{topic="guide to servicing family SUVs in Australia"; category="automotive"; subcategory="reviews"; image="family SUVs Australia"; tags="reviews,cars,Australia"; amazon="family SUVs"},
    @{topic="how to prepare your car for car batteries"; category="automotive"; subcategory="maintenance"; image="family SUVs Australia"; tags="maintenance,cars,Australia"; amazon="family SUVs"},
    @{topic="best hybrid cars for tradies in 2026"; category="automotive"; subcategory="reviews"; image="hybrid cars Australia"; tags="reviews,cars,Australia"; amazon="hybrid cars"},
    @{topic="how to save money insuring electric cars"; category="automotive"; subcategory="maintenance"; image="electric cars Australia"; tags="maintenance,cars,Australia"; amazon="electric cars"},
    @{topic="guide to servicing electric cars in Australia"; category="automotive"; subcategory="reviews"; image="electric cars Australia"; tags="reviews,cars,Australia"; amazon="electric cars"},
    @{topic="how to save money selling hybrid cars"; category="automotive"; subcategory="maintenance"; image="hybrid cars Australia"; tags="maintenance,cars,Australia"; amazon="hybrid cars"},
    @{topic="car batteries guide for Australian drivers"; category="automotive"; subcategory="maintenance"; image="hybrid cars Australia"; tags="maintenance,cars,Australia"; amazon="hybrid cars"},
    @{topic="how to save money servicing utes"; category="automotive"; subcategory="maintenance"; image="utes Australia"; tags="maintenance,cars,Australia"; amazon="utes"},
    @{topic="common 4WDs mistakes budget buyers make"; category="automotive"; subcategory="reviews"; image="4WDs Australia"; tags="reviews,cars,Australia"; amazon="4WDs"},
    @{topic="how to choose the right car batteries for your car"; category="automotive"; subcategory="maintenance"; image="family SUVs Australia"; tags="maintenance,cars,Australia"; amazon="family SUVs"},
    @{topic="how to save money insuring caravans"; category="automotive"; subcategory="maintenance"; image="caravans Australia"; tags="maintenance,cars,Australia"; amazon="caravans"},
    @{topic="how to save money financing caravans"; category="automotive"; subcategory="maintenance"; image="caravans Australia"; tags="maintenance,cars,Australia"; amazon="caravans"},
    @{topic="best road trips for tradies in Australia"; category="automotive"; subcategory="road-trips"; image="motorbikes Australia"; tags="road-trips,cars,Australia"; amazon="motorbikes"},
    @{topic="best motorbikes for first time buyers in 2026"; category="automotive"; subcategory="reviews"; image="motorbikes Australia"; tags="reviews,cars,Australia"; amazon="motorbikes"},
    @{topic="guide to selling utes in Australia"; category="automotive"; subcategory="reviews"; image="utes Australia"; tags="reviews,cars,Australia"; amazon="utes"},
    @{topic="common hybrid cars mistakes families make"; category="automotive"; subcategory="reviews"; image="hybrid cars Australia"; tags="reviews,cars,Australia"; amazon="hybrid cars"},
    @{topic="how to save money financing electric cars"; category="automotive"; subcategory="maintenance"; image="electric cars Australia"; tags="maintenance,cars,Australia"; amazon="electric cars"},
    @{topic="best road trips for first time buyers in Australia"; category="automotive"; subcategory="road-trips"; image="family SUVs Australia"; tags="road-trips,cars,Australia"; amazon="family SUVs"},
    @{topic="best utes for first time buyers in 2026"; category="automotive"; subcategory="reviews"; image="utes Australia"; tags="reviews,cars,Australia"; amazon="utes"},
    @{topic="common electric cars mistakes families make"; category="automotive"; subcategory="reviews"; image="electric cars Australia"; tags="reviews,cars,Australia"; amazon="electric cars"},
    @{topic="guide to financing family SUVs in Australia"; category="automotive"; subcategory="reviews"; image="family SUVs Australia"; tags="reviews,cars,Australia"; amazon="family SUVs"},
    @{topic="how to save money selling motorbikes"; category="automotive"; subcategory="maintenance"; image="motorbikes Australia"; tags="maintenance,cars,Australia"; amazon="motorbikes"},
    @{topic="how to save money financing 4WDs"; category="automotive"; subcategory="maintenance"; image="4WDs Australia"; tags="maintenance,cars,Australia"; amazon="4WDs"},
    @{topic="how to save money servicing caravans"; category="automotive"; subcategory="maintenance"; image="caravans Australia"; tags="maintenance,cars,Australia"; amazon="caravans"},
    @{topic="common used cars mistakes P plate drivers make"; category="automotive"; subcategory="reviews"; image="used cars Australia"; tags="reviews,cars,Australia"; amazon="used cars"},
    @{topic="common motorbikes mistakes budget buyers make"; category="automotive"; subcategory="reviews"; image="motorbikes Australia"; tags="reviews,cars,Australia"; amazon="motorbikes"},
    @{topic="guide to financing caravans in Australia"; category="automotive"; subcategory="reviews"; image="caravans Australia"; tags="reviews,cars,Australia"; amazon="caravans"},
    @{topic="best utes for P plate drivers in 2026"; category="automotive"; subcategory="reviews"; image="utes Australia"; tags="reviews,cars,Australia"; amazon="utes"},
    @{topic="how to save money insuring family SUVs"; category="automotive"; subcategory="maintenance"; image="family SUVs Australia"; tags="maintenance,cars,Australia"; amazon="family SUVs"},
    @{topic="best electric cars for tradies in 2026"; category="automotive"; subcategory="reviews"; image="electric cars Australia"; tags="reviews,cars,Australia"; amazon="electric cars"},
    @{topic="best 4WDs for budget buyers in 2026"; category="automotive"; subcategory="reviews"; image="4WDs Australia"; tags="reviews,cars,Australia"; amazon="4WDs"},
    @{topic="best hybrid cars for first time buyers in 2026"; category="automotive"; subcategory="reviews"; image="hybrid cars Australia"; tags="reviews,cars,Australia"; amazon="hybrid cars"},
    @{topic="guide to selling electric cars in Australia"; category="automotive"; subcategory="reviews"; image="electric cars Australia"; tags="reviews,cars,Australia"; amazon="electric cars"},
    @{topic="guide to servicing caravans in Australia"; category="automotive"; subcategory="reviews"; image="caravans Australia"; tags="reviews,cars,Australia"; amazon="caravans"},
    @{topic="common utes mistakes budget buyers make"; category="automotive"; subcategory="reviews"; image="utes Australia"; tags="reviews,cars,Australia"; amazon="utes"},
    @{topic="common motorbikes mistakes road trippers make"; category="automotive"; subcategory="reviews"; image="motorbikes Australia"; tags="reviews,cars,Australia"; amazon="motorbikes"},
    @{topic="how to save money detailing used cars"; category="automotive"; subcategory="maintenance"; image="used cars Australia"; tags="maintenance,cars,Australia"; amazon="used cars"},
    @{topic="tyres guide for Australian drivers"; category="automotive"; subcategory="maintenance"; image="used cars Australia"; tags="maintenance,cars,Australia"; amazon="used cars"},
    @{topic="common utes mistakes tradies make"; category="automotive"; subcategory="reviews"; image="utes Australia"; tags="reviews,cars,Australia"; amazon="utes"},
    @{topic="common used cars mistakes budget buyers make"; category="automotive"; subcategory="reviews"; image="used cars Australia"; tags="reviews,cars,Australia"; amazon="used cars"},
    @{topic="best family SUVs for P plate drivers in 2026"; category="automotive"; subcategory="reviews"; image="family SUVs Australia"; tags="reviews,cars,Australia"; amazon="family SUVs"},
    @{topic="guide to financing electric cars in Australia"; category="automotive"; subcategory="reviews"; image="electric cars Australia"; tags="reviews,cars,Australia"; amazon="electric cars"},
    @{topic="best road trips for budget buyers in Australia"; category="automotive"; subcategory="road-trips"; image="4WDs Australia"; tags="road-trips,cars,Australia"; amazon="4WDs"},
    @{topic="best 4WDs for P plate drivers in 2026"; category="automotive"; subcategory="reviews"; image="4WDs Australia"; tags="reviews,cars,Australia"; amazon="4WDs"},
    @{topic="best caravans for first time buyers in 2026"; category="automotive"; subcategory="reviews"; image="caravans Australia"; tags="reviews,cars,Australia"; amazon="caravans"},
    @{topic="guide to insuring electric cars in Australia"; category="automotive"; subcategory="reviews"; image="electric cars Australia"; tags="reviews,cars,Australia"; amazon="electric cars"},
    @{topic="guide to selling 4WDs in Australia"; category="automotive"; subcategory="reviews"; image="4WDs Australia"; tags="reviews,cars,Australia"; amazon="4WDs"},
    @{topic="best 4WDs for families in 2026"; category="automotive"; subcategory="reviews"; image="4WDs Australia"; tags="reviews,cars,Australia"; amazon="4WDs"},
    @{topic="common utes mistakes families make"; category="automotive"; subcategory="reviews"; image="utes Australia"; tags="reviews,cars,Australia"; amazon="utes"},
    @{topic="how to prepare your car for dash cams"; category="automotive"; subcategory="maintenance"; image="electric cars Australia"; tags="maintenance,cars,Australia"; amazon="electric cars"},
    @{topic="guide to servicing used cars in Australia"; category="automotive"; subcategory="reviews"; image="used cars Australia"; tags="reviews,cars,Australia"; amazon="used cars"},
    @{topic="guide to buying caravans in Australia"; category="automotive"; subcategory="reviews"; image="caravans Australia"; tags="reviews,cars,Australia"; amazon="caravans"},
    @{topic="common hybrid cars mistakes budget buyers make"; category="automotive"; subcategory="reviews"; image="hybrid cars Australia"; tags="reviews,cars,Australia"; amazon="hybrid cars"},
    @{topic="guide to selling hybrid cars in Australia"; category="automotive"; subcategory="reviews"; image="hybrid cars Australia"; tags="reviews,cars,Australia"; amazon="hybrid cars"},
    @{topic="guide to insuring family SUVs in Australia"; category="automotive"; subcategory="reviews"; image="family SUVs Australia"; tags="reviews,cars,Australia"; amazon="family SUVs"},
    @{topic="how to save money insuring utes"; category="automotive"; subcategory="maintenance"; image="utes Australia"; tags="maintenance,cars,Australia"; amazon="utes"},
    @{topic="how to save money detailing utes"; category="automotive"; subcategory="maintenance"; image="utes Australia"; tags="maintenance,cars,Australia"; amazon="utes"},
    @{topic="how to prepare your car for roadside safety"; category="automotive"; subcategory="maintenance"; image="motorbikes Australia"; tags="maintenance,cars,Australia"; amazon="motorbikes"},
    @{topic="common electric cars mistakes budget buyers make"; category="automotive"; subcategory="reviews"; image="electric cars Australia"; tags="reviews,cars,Australia"; amazon="electric cars"},
    @{topic="guide to detailing utes in Australia"; category="automotive"; subcategory="reviews"; image="utes Australia"; tags="reviews,cars,Australia"; amazon="utes"},
    @{topic="best used cars for families in 2026"; category="automotive"; subcategory="reviews"; image="used cars Australia"; tags="reviews,cars,Australia"; amazon="used cars"},
    @{topic="best caravans for families in 2026"; category="automotive"; subcategory="reviews"; image="caravans Australia"; tags="reviews,cars,Australia"; amazon="caravans"},
    @{topic="how to save money servicing electric cars"; category="automotive"; subcategory="maintenance"; image="electric cars Australia"; tags="maintenance,cars,Australia"; amazon="electric cars"},
    @{topic="common motorbikes mistakes tradies make"; category="automotive"; subcategory="reviews"; image="motorbikes Australia"; tags="reviews,cars,Australia"; amazon="motorbikes"},
    @{topic="guide to maintaining caravans in Australia"; category="automotive"; subcategory="reviews"; image="caravans Australia"; tags="reviews,cars,Australia"; amazon="caravans"},
    @{topic="how to save money servicing family SUVs"; category="automotive"; subcategory="maintenance"; image="family SUVs Australia"; tags="maintenance,cars,Australia"; amazon="family SUVs"},
    @{topic="best utes for road trippers in 2026"; category="automotive"; subcategory="reviews"; image="utes Australia"; tags="reviews,cars,Australia"; amazon="utes"},
    @{topic="how to save money maintaining electric cars"; category="automotive"; subcategory="maintenance"; image="electric cars Australia"; tags="maintenance,cars,Australia"; amazon="electric cars"},
    @{topic="common utes mistakes road trippers make"; category="automotive"; subcategory="reviews"; image="utes Australia"; tags="reviews,cars,Australia"; amazon="utes"},
    @{topic="best used cars for road trippers in 2026"; category="automotive"; subcategory="reviews"; image="used cars Australia"; tags="reviews,cars,Australia"; amazon="used cars"},
    @{topic="common hybrid cars mistakes road trippers make"; category="automotive"; subcategory="reviews"; image="hybrid cars Australia"; tags="reviews,cars,Australia"; amazon="hybrid cars"},
    @{topic="best utes for families in 2026"; category="automotive"; subcategory="reviews"; image="utes Australia"; tags="reviews,cars,Australia"; amazon="utes"},
    @{topic="how to save money detailing hybrid cars"; category="automotive"; subcategory="maintenance"; image="hybrid cars Australia"; tags="maintenance,cars,Australia"; amazon="hybrid cars"},
    @{topic="how to save money buying used cars"; category="automotive"; subcategory="maintenance"; image="used cars Australia"; tags="maintenance,cars,Australia"; amazon="used cars"},

    # SEASONAL - each entry only becomes eligible during its date window.
    # Fixed-date entries use seasonStart/seasonEnd ("MM-dd"). Easter-relative entries
    # use easterOffsetStart/easterOffsetEnd (days relative to Easter Sunday), resolved
    # to real dates for the current year further down in the script.
    # Christmas
    @{topic="best Christmas gift ideas for men Australia 2026"; category="seasonal"; subcategory="christmas"; image="Christmas gifts men Australia"; tags="Christmas,gifts,Australia"; amazon="Christmas gifts men"; seasonStart="11-01"; seasonEnd="12-25"},
    @{topic="best Christmas gift ideas for women Australia 2026"; category="seasonal"; subcategory="christmas"; image="Christmas gifts women Australia"; tags="Christmas,gifts,Australia"; amazon="Christmas gifts women"; seasonStart="11-01"; seasonEnd="12-25"},
    @{topic="best Christmas gift ideas for kids Australia 2026"; category="seasonal"; subcategory="christmas"; image="Christmas gifts kids Australia"; tags="Christmas,gifts,kids,Australia"; amazon="Christmas gifts kids"; seasonStart="11-01"; seasonEnd="12-25"},
    @{topic="best Christmas gift ideas for teenagers"; category="seasonal"; subcategory="christmas"; image="Christmas gifts teenagers"; tags="Christmas,gifts,teens"; amazon="Christmas gifts teenagers"; seasonStart="11-01"; seasonEnd="12-25"},
    @{topic="best secret santa gift ideas under 25 dollars"; category="seasonal"; subcategory="christmas"; image="secret santa gifts budget"; tags="Christmas,gifts,budget"; amazon="secret santa gifts"; seasonStart="11-15"; seasonEnd="12-25"},
    @{topic="best stocking stuffer ideas for the whole family"; category="seasonal"; subcategory="christmas"; image="stocking stuffers Christmas"; tags="Christmas,gifts,family"; amazon="stocking stuffers"; seasonStart="11-15"; seasonEnd="12-25"},
    @{topic="how to save money on your Christmas budget Australia"; category="seasonal"; subcategory="christmas"; image="Christmas budget savings Australia"; tags="Christmas,budget,savings"; amazon="Christmas budget planner"; seasonStart="11-01"; seasonEnd="12-25"},
    @{topic="best Christmas lunch recipes for Australian summer"; category="seasonal"; subcategory="christmas"; image="Christmas lunch Australian summer BBQ"; tags="Christmas,food,Australia"; amazon="BBQ accessories Australia"; seasonStart="11-15"; seasonEnd="12-25"},
    @{topic="how to host a backyard Christmas party in Australia"; category="seasonal"; subcategory="christmas"; image="backyard Christmas party Australia"; tags="Christmas,party,Australia"; amazon="outdoor party supplies"; seasonStart="11-15"; seasonEnd="12-25"},
    @{topic="eco-friendly ways to celebrate Christmas this year"; category="seasonal"; subcategory="christmas"; image="eco friendly Christmas sustainable"; tags="Christmas,sustainability,Australia"; amazon="reusable gift wrap"; seasonStart="11-15"; seasonEnd="12-25"},
    @{topic="outdoor Christmas lights and decorating ideas"; category="seasonal"; subcategory="christmas"; image="Christmas lights decorations outdoor"; tags="Christmas,decorating,home"; amazon="outdoor Christmas lights"; seasonStart="11-01"; seasonEnd="12-25"},
    @{topic="last minute Christmas gift ideas you can still get in time"; category="seasonal"; subcategory="christmas"; image="last minute Christmas gifts"; tags="Christmas,gifts,last-minute"; amazon="gift cards Australia"; seasonStart="12-10"; seasonEnd="12-24"},
    @{topic="best gifts for pets this Christmas"; category="seasonal"; subcategory="christmas"; image="Christmas gifts for pets"; tags="Christmas,gifts,pets"; amazon="pet Christmas gifts"; seasonStart="11-15"; seasonEnd="12-25"},
    @{topic="how to wrap presents like a pro"; category="seasonal"; subcategory="christmas"; image="gift wrapping Christmas presents"; tags="Christmas,gifts,DIY"; amazon="gift wrap supplies"; seasonStart="11-15"; seasonEnd="12-24"},

    # Boxing Day
    @{topic="best Boxing Day sales tips for Australian shoppers"; category="seasonal"; subcategory="boxing-day"; image="Boxing Day sales shopping Australia"; tags="Boxing-Day,sales,Australia"; amazon="Boxing Day deals"; seasonStart="12-15"; seasonEnd="12-26"},
    @{topic="what to buy in the Boxing Day sales this year"; category="seasonal"; subcategory="boxing-day"; image="Boxing Day shopping deals"; tags="Boxing-Day,sales,shopping"; amazon="Boxing Day deals"; seasonStart="12-15"; seasonEnd="12-26"},
    @{topic="how to return or exchange unwanted Christmas gifts"; category="seasonal"; subcategory="boxing-day"; image="gift returns exchange Christmas"; tags="Boxing-Day,shopping,returns"; amazon="gift receipt organiser"; seasonStart="12-20"; seasonEnd="12-31"},
    @{topic="Boxing Day cricket traditions in Australia"; category="seasonal"; subcategory="boxing-day"; image="Boxing Day cricket Australia"; tags="Boxing-Day,Australia,tradition"; amazon="cricket gear Australia"; seasonStart="12-20"; seasonEnd="12-26"},

    # New Year
    @{topic="realistic New Year resolutions that actually stick"; category="seasonal"; subcategory="new-year"; image="New Year resolutions goals planning"; tags="New-Year,goals,resolutions"; amazon="goal planner journal"; seasonStart="12-15"; seasonEnd="01-02"},
    @{topic="New Years Eve party ideas for a night in"; category="seasonal"; subcategory="new-year"; image="New Years Eve party at home"; tags="New-Year,party,celebration"; amazon="party supplies Australia"; seasonStart="12-15"; seasonEnd="12-31"},
    @{topic="best spots to watch fireworks on New Years Eve in Australia"; category="seasonal"; subcategory="new-year"; image="New Years Eve fireworks Australia"; tags="New-Year,fireworks,Australia"; amazon="picnic blanket"; seasonStart="12-15"; seasonEnd="12-31"},
    @{topic="how to declutter your home for the new year"; category="seasonal"; subcategory="new-year"; image="decluttering home new year"; tags="New-Year,decluttering,home"; amazon="storage containers"; seasonStart="12-20"; seasonEnd="01-05"},
    @{topic="simple money resolutions to start the year off right"; category="seasonal"; subcategory="new-year"; image="New Year finance resolutions"; tags="New-Year,finance,budgeting"; amazon="budget planner"; seasonStart="12-15"; seasonEnd="01-05"},

    # Australia Day
    @{topic="best backyard Australia Day BBQ ideas"; category="seasonal"; subcategory="australia-day"; image="Australia Day BBQ backyard"; tags="Australia-Day,BBQ,summer"; amazon="BBQ accessories Australia"; seasonStart="12-20"; seasonEnd="01-26"},
    @{topic="fun backyard cricket rules for Australia Day"; category="seasonal"; subcategory="australia-day"; image="backyard cricket Australia Day"; tags="Australia-Day,games,family"; amazon="backyard cricket set"; seasonStart="12-20"; seasonEnd="01-26"},
    @{topic="best day trip ideas for the Australia Day long weekend"; category="seasonal"; subcategory="australia-day"; image="Australia Day long weekend trip"; tags="Australia-Day,travel,Australia"; amazon="esky cooler"; seasonStart="12-20"; seasonEnd="01-26"},
    @{topic="how to host an Australia Day backyard party"; category="seasonal"; subcategory="australia-day"; image="Australia Day party backyard"; tags="Australia-Day,party,Australia"; amazon="outdoor party supplies"; seasonStart="12-20"; seasonEnd="01-26"},

    # Back to School
    @{topic="back to school shopping guide for Australian parents"; category="seasonal"; subcategory="back-to-school"; image="back to school shopping Australia"; tags="back-to-school,kids,Australia"; amazon="school supplies Australia"; seasonStart="12-15"; seasonEnd="02-05"},
    @{topic="budget friendly school lunchbox ideas kids will actually eat"; category="seasonal"; subcategory="back-to-school"; image="school lunchbox ideas kids"; tags="back-to-school,kids,food"; amazon="lunchbox set kids"; seasonStart="01-01"; seasonEnd="02-05"},
    @{topic="how to choose the right school backpack for your child"; category="seasonal"; subcategory="back-to-school"; image="school backpack kids"; tags="back-to-school,kids,gear"; amazon="kids school backpack"; seasonStart="01-01"; seasonEnd="02-05"},
    @{topic="tips for an easier back to school morning routine"; category="seasonal"; subcategory="back-to-school"; image="back to school morning routine"; tags="back-to-school,kids,family"; amazon="kids alarm clock"; seasonStart="01-10"; seasonEnd="02-05"},
    @{topic="how to budget for the back to school season in Australia"; category="seasonal"; subcategory="back-to-school"; image="back to school budget Australia"; tags="back-to-school,budget,Australia"; amazon="budget planner"; seasonStart="12-15"; seasonEnd="02-05"},

    # Valentine's Day
    @{topic="best Valentines Day gift ideas in Australia"; category="seasonal"; subcategory="valentines"; image="Valentines Day gifts Australia"; tags="Valentines,gifts,Australia"; amazon="Valentines Day gifts"; seasonStart="01-01"; seasonEnd="02-14"},
    @{topic="budget friendly Valentines Day date night ideas"; category="seasonal"; subcategory="valentines"; image="Valentines Day date night"; tags="Valentines,dating,budget"; amazon="date night gift box"; seasonStart="01-15"; seasonEnd="02-14"},
    @{topic="how to cook a romantic dinner at home for Valentines Day"; category="seasonal"; subcategory="valentines"; image="romantic dinner at home"; tags="Valentines,food,romance"; amazon="dinnerware set"; seasonStart="01-15"; seasonEnd="02-14"},
    @{topic="Valentines Day gift ideas for him"; category="seasonal"; subcategory="valentines"; image="Valentines Day gifts for him"; tags="Valentines,gifts,men"; amazon="Valentines gifts for him"; seasonStart="01-15"; seasonEnd="02-14"},
    @{topic="Valentines Day gift ideas for her"; category="seasonal"; subcategory="valentines"; image="Valentines Day gifts for her"; tags="Valentines,gifts,women"; amazon="Valentines gifts for her"; seasonStart="01-15"; seasonEnd="02-14"},
    @{topic="Galentines Day ideas for celebrating with friends"; category="seasonal"; subcategory="valentines"; image="Galentines Day friends celebration"; tags="Valentines,friends,celebration"; amazon="gift box friends"; seasonStart="01-15"; seasonEnd="02-14"},

    # Easter (movable - computed at runtime)
    @{topic="best Easter activities for families in Australia"; category="seasonal"; subcategory="easter"; image="Easter family activities Australia"; tags="Easter,family,Australia"; amazon="Easter gifts Australia"; easterOffsetStart=-49; easterOffsetEnd=0},
    @{topic="Easter egg hunt ideas for the backyard"; category="seasonal"; subcategory="easter"; image="Easter egg hunt backyard kids"; tags="Easter,kids,Australia"; amazon="Easter egg hunt kit"; easterOffsetStart=-21; easterOffsetEnd=0},
    @{topic="Easter craft ideas to keep kids entertained"; category="seasonal"; subcategory="easter"; image="Easter craft ideas kids"; tags="Easter,kids,crafts"; amazon="Easter craft supplies"; easterOffsetStart=-35; easterOffsetEnd=0},
    @{topic="best Easter long weekend road trips from Sydney"; category="seasonal"; subcategory="easter"; image="Easter long weekend road trip"; tags="Easter,travel,road-trip"; amazon="road trip accessories"; easterOffsetStart=-42; easterOffsetEnd=-1},
    @{topic="Easter camping trip ideas for the long weekend"; category="seasonal"; subcategory="easter"; image="Easter camping long weekend"; tags="Easter,camping,outdoors"; amazon="camping gear set"; easterOffsetStart=-42; easterOffsetEnd=-1},
    @{topic="chocolate free Easter gift ideas for kids"; category="seasonal"; subcategory="easter"; image="Easter gifts non chocolate kids"; tags="Easter,gifts,kids"; amazon="non chocolate Easter gifts"; easterOffsetStart=-28; easterOffsetEnd=0},
    @{topic="simple hot cross bun recipe ideas for Easter"; category="seasonal"; subcategory="easter"; image="hot cross buns Easter baking"; tags="Easter,food,baking"; amazon="baking supplies"; easterOffsetStart=-14; easterOffsetEnd=0},
    @{topic="what to do with your Easter Monday public holiday"; category="seasonal"; subcategory="easter"; image="Easter Monday activities"; tags="Easter,long-weekend,Australia"; amazon="picnic set"; easterOffsetStart=0; easterOffsetEnd=1},
    @{topic="budget friendly Easter basket ideas"; category="seasonal"; subcategory="easter"; image="Easter basket ideas budget"; tags="Easter,gifts,budget"; amazon="Easter basket"; easterOffsetStart=-21; easterOffsetEnd=0},

    # School Holidays
    @{topic="Easter school holiday activities for kids Australia"; category="seasonal"; subcategory="school-holidays"; image="Easter school holidays kids activities"; tags="school-holidays,Easter,kids"; amazon="kids activity sets"; easterOffsetStart=-14; easterOffsetEnd=1},
    @{topic="December school holiday activities for kids on a budget"; category="seasonal"; subcategory="school-holidays"; image="summer school holiday kids activities budget"; tags="school-holidays,kids,budget"; amazon="kids activity sets"; seasonStart="10-15"; seasonEnd="01-28"},
    @{topic="indoor school holiday activities for a hot summer day"; category="seasonal"; subcategory="school-holidays"; image="indoor school holiday activities summer"; tags="school-holidays,kids,summer"; amazon="indoor kids games"; seasonStart="11-01"; seasonEnd="01-28"},
    @{topic="July school holiday activities for kids Australia"; category="seasonal"; subcategory="school-holidays"; image="winter school holidays kids activities"; tags="school-holidays,winter,kids"; amazon="kids indoor activity kits"; seasonStart="05-15"; seasonEnd="07-15"},
    @{topic="indoor school holiday activities for a cold winter day"; category="seasonal"; subcategory="school-holidays"; image="indoor school holiday activities winter"; tags="school-holidays,kids,winter"; amazon="board games kids"; seasonStart="05-15"; seasonEnd="07-15"},
    @{topic="September school holiday activities for kids Australia"; category="seasonal"; subcategory="school-holidays"; image="spring school holidays kids activities"; tags="school-holidays,spring,kids"; amazon="kids outdoor activity kits"; seasonStart="07-15"; seasonEnd="10-05"},
    @{topic="free school holiday activities for families on a budget"; category="seasonal"; subcategory="school-holidays"; image="free school holiday activities budget"; tags="school-holidays,budget,family"; amazon="kids activity sets"; seasonStart="09-01"; seasonEnd="10-05"},

    # Anzac Day
    @{topic="Anzac Day traditions and how Australians commemorate it"; category="seasonal"; subcategory="anzac-day"; image="Anzac Day Australia commemoration"; tags="Anzac-Day,Australia,history"; amazon="Australian history books"; seasonStart="03-15"; seasonEnd="04-25"},
    @{topic="how to explain Anzac Day to young children"; category="seasonal"; subcategory="anzac-day"; image="Anzac Day explaining kids"; tags="Anzac-Day,kids,Australia"; amazon="kids history books"; seasonStart="03-25"; seasonEnd="04-25"},
    @{topic="simple Anzac biscuit baking ideas at home"; category="seasonal"; subcategory="anzac-day"; image="Anzac biscuits baking Australia"; tags="Anzac-Day,baking,Australia"; amazon="baking supplies"; seasonStart="04-01"; seasonEnd="04-25"},
    @{topic="what to expect at a dawn service on Anzac Day"; category="seasonal"; subcategory="anzac-day"; image="dawn service Anzac Day Australia"; tags="Anzac-Day,Australia,tradition"; amazon="thermos flask"; seasonStart="04-10"; seasonEnd="04-25"},

    # Mother's Day
    @{topic="best Mothers Day gift ideas in Australia"; category="seasonal"; subcategory="mothers-day"; image="Mothers Day gifts Australia"; tags="Mothers-Day,gifts,Australia"; amazon="Mothers Day gifts"; seasonStart="03-15"; seasonEnd="05-14"},
    @{topic="Mothers Day brunch ideas to make at home"; category="seasonal"; subcategory="mothers-day"; image="Mothers Day brunch at home"; tags="Mothers-Day,food,family"; amazon="brunch cookware set"; seasonStart="04-01"; seasonEnd="05-14"},
    @{topic="DIY Mothers Day gift ideas on a budget"; category="seasonal"; subcategory="mothers-day"; image="DIY Mothers Day gifts budget"; tags="Mothers-Day,gifts,DIY"; amazon="craft supplies"; seasonStart="04-01"; seasonEnd="05-14"},
    @{topic="best day out ideas for Mothers Day in Australia"; category="seasonal"; subcategory="mothers-day"; image="Mothers Day day out Australia"; tags="Mothers-Day,activities,Australia"; amazon="gift voucher"; seasonStart="04-01"; seasonEnd="05-14"},
    @{topic="self care gift ideas for Mothers Day"; category="seasonal"; subcategory="mothers-day"; image="self care gifts Mothers Day"; tags="Mothers-Day,gifts,wellbeing"; amazon="self care gift set"; seasonStart="04-01"; seasonEnd="05-14"},

    # Winter
    @{topic="winter home maintenance checklist for Australians"; category="seasonal"; subcategory="winter"; image="winter home maintenance checklist"; tags="winter,maintenance,home"; amazon="winter home supplies"; seasonStart="04-15"; seasonEnd="08-31"},
    @{topic="how to keep your home warm in winter without high bills"; category="seasonal"; subcategory="winter"; image="warm home winter heating Australia"; tags="winter,heating,savings"; amazon="portable heater Australia"; seasonStart="04-15"; seasonEnd="08-31"},
    @{topic="best warming recipes for cold Australian winters"; category="seasonal"; subcategory="winter"; image="winter comfort food recipes"; tags="winter,food,recipes"; amazon="slow cooker"; seasonStart="05-01"; seasonEnd="08-31"},
    @{topic="winter car care tips for Australian drivers"; category="seasonal"; subcategory="winter"; image="winter car care maintenance"; tags="winter,cars,maintenance"; amazon="car battery charger"; seasonStart="04-15"; seasonEnd="08-31"},
    @{topic="best indoor activities for a rainy winter weekend"; category="seasonal"; subcategory="winter"; image="indoor activities winter rainy day"; tags="winter,activities,family"; amazon="board games"; seasonStart="05-01"; seasonEnd="08-31"},
    @{topic="how to winter proof your wardrobe on a budget"; category="seasonal"; subcategory="winter"; image="winter wardrobe clothing budget"; tags="winter,fashion,budget"; amazon="winter jacket"; seasonStart="04-15"; seasonEnd="07-31"},

    # Father's Day
    @{topic="best Fathers Day gift ideas in Australia"; category="seasonal"; subcategory="fathers-day"; image="Fathers Day gifts Australia"; tags="Fathers-Day,gifts,Australia"; amazon="Fathers Day gifts"; seasonStart="07-01"; seasonEnd="09-07"},
    @{topic="Fathers Day BBQ gear worth buying"; category="seasonal"; subcategory="fathers-day"; image="Fathers Day BBQ gear gifts"; tags="Fathers-Day,gifts,BBQ"; amazon="BBQ tools set"; seasonStart="07-15"; seasonEnd="09-07"},
    @{topic="DIY Fathers Day gift ideas the kids can make"; category="seasonal"; subcategory="fathers-day"; image="DIY Fathers Day gifts kids"; tags="Fathers-Day,gifts,kids"; amazon="craft supplies"; seasonStart="07-15"; seasonEnd="09-07"},
    @{topic="breakfast in bed ideas for Fathers Day"; category="seasonal"; subcategory="fathers-day"; image="breakfast in bed Fathers Day"; tags="Fathers-Day,food,family"; amazon="breakfast tray"; seasonStart="07-15"; seasonEnd="09-07"},
    @{topic="outdoor activity ideas to do with dad this Fathers Day"; category="seasonal"; subcategory="fathers-day"; image="outdoor activities Fathers Day"; tags="Fathers-Day,activities,family"; amazon="outdoor gear"; seasonStart="07-15"; seasonEnd="09-07"},

    # Spring
    @{topic="how to prepare your garden for spring in Australia"; category="seasonal"; subcategory="spring"; image="spring garden preparation Australia"; tags="spring,garden,Australia"; amazon="garden tools spring"; seasonStart="08-15"; seasonEnd="11-15"},
    @{topic="spring cleaning checklist for the whole house"; category="seasonal"; subcategory="spring"; image="spring cleaning checklist home"; tags="spring,cleaning,home"; amazon="spring cleaning supplies"; seasonStart="08-15"; seasonEnd="10-15"},
    @{topic="hay fever season tips for Australian spring"; category="seasonal"; subcategory="spring"; image="hay fever spring allergy season"; tags="spring,wellbeing,seasonal"; amazon="air purifier home"; seasonStart="08-15"; seasonEnd="11-15"},
    @{topic="best spring outdoor entertaining ideas"; category="seasonal"; subcategory="spring"; image="spring outdoor entertaining backyard"; tags="spring,entertaining,home"; amazon="outdoor furniture"; seasonStart="09-01"; seasonEnd="11-15"},
    @{topic="spring wardrobe refresh ideas on a budget"; category="seasonal"; subcategory="spring"; image="spring wardrobe fashion budget"; tags="spring,fashion,budget"; amazon="spring clothing"; seasonStart="08-15"; seasonEnd="10-31"},
    @{topic="spring home maintenance jobs worth doing early"; category="seasonal"; subcategory="spring"; image="spring home maintenance jobs"; tags="spring,maintenance,home"; amazon="home maintenance kit"; seasonStart="08-15"; seasonEnd="11-15"},

    # Halloween
    @{topic="how Halloween is celebrated in Australia"; category="seasonal"; subcategory="halloween"; image="Halloween decorations Australia"; tags="Halloween,Australia,family"; amazon="Halloween decorations"; seasonStart="09-15"; seasonEnd="10-31"},
    @{topic="budget friendly Halloween costume ideas"; category="seasonal"; subcategory="halloween"; image="Halloween costume ideas budget"; tags="Halloween,costumes,budget"; amazon="Halloween costumes"; seasonStart="09-15"; seasonEnd="10-31"},
    @{topic="Halloween party ideas for Australian backyards"; category="seasonal"; subcategory="halloween"; image="Halloween backyard party Australia"; tags="Halloween,party,Australia"; amazon="Halloween party supplies"; seasonStart="09-15"; seasonEnd="10-31"},
    @{topic="trick or treat safety tips for parents"; category="seasonal"; subcategory="halloween"; image="trick or treat safety kids"; tags="Halloween,safety,kids"; amazon="reflective safety gear"; seasonStart="10-01"; seasonEnd="10-31"},
    @{topic="pumpkin carving ideas for Halloween"; category="seasonal"; subcategory="halloween"; image="pumpkin carving Halloween ideas"; tags="Halloween,DIY,decorating"; amazon="pumpkin carving kit"; seasonStart="10-01"; seasonEnd="10-31"},
    @{topic="Halloween safe trick or treat lolly ideas"; category="seasonal"; subcategory="halloween"; image="Halloween lollies treats"; tags="Halloween,food,kids"; amazon="Halloween lolly bags"; seasonStart="10-01"; seasonEnd="10-31"},
    @{topic="spooky but simple Halloween home decorating ideas"; category="seasonal"; subcategory="halloween"; image="Halloween home decor ideas"; tags="Halloween,decorating,home"; amazon="Halloween decorations"; seasonStart="09-15"; seasonEnd="10-31"},

    # Black Friday / Cyber Monday
    @{topic="how to find the best Black Friday deals in Australia"; category="seasonal"; subcategory="black-friday"; image="Black Friday sales shopping Australia"; tags="Black-Friday,sales,Australia"; amazon="Black Friday deals"; seasonStart="10-15"; seasonEnd="12-02"},
    @{topic="Black Friday shopping mistakes to avoid"; category="seasonal"; subcategory="black-friday"; image="Black Friday shopping tips"; tags="Black-Friday,shopping,tips"; amazon="shopping list planner"; seasonStart="10-15"; seasonEnd="12-02"},
    @{topic="best tech deals to watch for on Cyber Monday"; category="seasonal"; subcategory="black-friday"; image="Cyber Monday tech deals"; tags="Black-Friday,technology,deals"; amazon="tech accessories"; seasonStart="10-15"; seasonEnd="12-02"},
    @{topic="how to budget for Black Friday without overspending"; category="seasonal"; subcategory="black-friday"; image="Black Friday budgeting savings"; tags="Black-Friday,budgeting,savings"; amazon="budget planner"; seasonStart="10-15"; seasonEnd="12-02"},
    @{topic="how to spot fake Black Friday deals and scams"; category="seasonal"; subcategory="black-friday"; image="Black Friday scams online shopping"; tags="Black-Friday,scams,safety"; amazon="identity theft protection"; seasonStart="10-15"; seasonEnd="12-02"},

    # Summer
    @{topic="how to survive a hot Australian summer at home"; category="seasonal"; subcategory="summer"; image="hot summer Australia home cooling"; tags="summer,Australia,cooling"; amazon="portable air conditioner Australia"; seasonStart="10-15"; seasonEnd="02-28"},
    @{topic="best beach day essentials for an Australian summer"; category="seasonal"; subcategory="summer"; image="beach day essentials Australia summer"; tags="summer,beach,Australia"; amazon="beach essentials Australia"; seasonStart="11-01"; seasonEnd="02-28"},
    @{topic="sun safety tips for the Australian summer"; category="seasonal"; subcategory="summer"; image="sun safety summer Australia"; tags="summer,safety,Australia"; amazon="sun hat sunscreen"; seasonStart="11-01"; seasonEnd="02-28"},
    @{topic="best backyard pool safety tips for summer"; category="seasonal"; subcategory="summer"; image="pool safety backyard summer"; tags="summer,safety,family"; amazon="pool safety fence"; seasonStart="11-01"; seasonEnd="02-28"},
    @{topic="summer BBQ recipe ideas for the whole family"; category="seasonal"; subcategory="summer"; image="summer BBQ recipes Australia"; tags="summer,food,BBQ"; amazon="BBQ accessories Australia"; seasonStart="11-01"; seasonEnd="02-28"},
    @{topic="best road trip ideas for the Australian summer holidays"; category="seasonal"; subcategory="summer"; image="summer road trip Australia"; tags="summer,travel,road-trip"; amazon="road trip accessories"; seasonStart="11-01"; seasonEnd="02-15"},
    @{topic="how to keep pets cool during an Australian summer"; category="seasonal"; subcategory="summer"; image="pets summer heat cooling Australia"; tags="summer,pets,Australia"; amazon="pet cooling mat"; seasonStart="11-01"; seasonEnd="02-28"}
)

# Computes Easter Sunday for a given year (anonymous Gregorian / Meeus algorithm).
function Get-EasterSunday {
    param([int]$year)
    $a = $year % 19
    $b = [Math]::Floor($year / 100)
    $c = $year % 100
    $d = [Math]::Floor($b / 4)
    $e2 = $b % 4
    $f = [Math]::Floor(($b + 8) / 25)
    $g = [Math]::Floor(($b - $f + 1) / 3)
    $h = (19 * $a + $b - $d - $g + 15) % 30
    $i = [Math]::Floor($c / 4)
    $k = $c % 4
    $l = (32 + 2 * $e2 + 2 * $i - $h - $k) % 7
    $m = [Math]::Floor(($a + 11 * $h + 22 * $l) / 451)
    $month = [Math]::Floor(($h + $l - 7 * $m + 114) / 31)
    $day = (($h + $l - 7 * $m + 114) % 31) + 1
    return Get-Date -Year $year -Month $month -Day $day
}

# Resolve Easter-relative topics (easterOffsetStart/End) into concrete seasonStart/seasonEnd
# "MM-dd" strings for the current year, so Test-InSeason can treat them like any other topic.
$easterSunday = Get-EasterSunday -year (Get-Date).Year
foreach ($t in $topicData) {
    if ($null -ne $t.easterOffsetStart -and $null -ne $t.easterOffsetEnd) {
        $t.seasonStart = $easterSunday.AddDays($t.easterOffsetStart).ToString("MM-dd")
        $t.seasonEnd = $easterSunday.AddDays($t.easterOffsetEnd).ToString("MM-dd")
    }
}

# Restrict to topics that are in-season right now (non-seasonal topics always pass)
$now = Get-Date
$inSeasonTopics = $topicData | Where-Object { Test-InSeason -start $_.seasonStart -end $_.seasonEnd -today $now }
Write-Log "In-season topic pool: $($inSeasonTopics.Count) of $($topicData.Count) total topics"

# Load used topics
if (Test-Path $usedTopicsFile) {
    $usedTopics = Get-Content $usedTopicsFile
} else {
    $usedTopics = @()
}

$availableTopics = $inSeasonTopics | Where-Object { $usedTopics -notcontains $_.topic }

if ($availableTopics.Count -eq 0) {
    # Reset only the "used" markers for topics currently in season, so out-of-season
    # seasonal topics stay marked used and won't immediately repeat next time they're in season.
    $availableTopics = $inSeasonTopics
    $inSeasonTopicNames = $inSeasonTopics | ForEach-Object { $_.topic }
    $keepUsed = $usedTopics | Where-Object { $inSeasonTopicNames -notcontains $_ }
    Set-Content -Path $usedTopicsFile -Value $keepUsed
    Write-Log "All in-season topics used - resetting in-season portion of the used list"
}

# Contributors - each has a name, short bio, a distinct writing voice, and the
# categories they cover. Seasonal posts try to match on the specific occasion
# (seasonalSubcategories) first, since that gives a much more natural fit than
# just "seasonal" - e.g. the family-organiser persona writing Easter/back-to-school
# posts, the money-coach persona writing Black Friday/New Year posts.
$contributors = @(
    @{
        name = "Jack Nguyen"
        slug = "jack-nguyen"
        bio = "Licensed electrician and hands-on renovator who writes about the practical, get-it-done side of home and power."
        voice = "Blunt and practical. Short, punchy sentences. Speaks like an experienced tradie explaining something to a mate - no fluff, no hype, just what works and what to avoid. Uses plain Australian phrasing."
        categories = @("energy-power", "home-garden", "automotive")
        seasonalSubcategories = @("winter")
    },
    @{
        name = "Priya Anand"
        slug = "priya-anand"
        bio = "Former financial counsellor who now writes about everyday money decisions for Australian households."
        voice = "Warm and clear, never judgmental about money mistakes. Breaks numbers down simply with real-world comparisons. Encouraging tone, avoids jargon, always brings it back to a concrete next step the reader can take."
        categories = @("finance")
        seasonalSubcategories = @("new-year", "black-friday", "boxing-day")
    },
    @{
        name = "Sam Whitfield"
        slug = "sam-whitfield"
        bio = "Weekend adventurer who has camped, hiked and 4WDed across most of Australia, writing from experience."
        voice = "Enthusiastic and first-person, like telling a story around a campfire. Leads with real experience and small anecdotes, weaves in safety reminders naturally rather than as a checklist. Loves an exclamation mark but doesn't overdo it."
        categories = @("outdoors-camping")
        seasonalSubcategories = @("summer", "australia-day", "anzac-day")
    },
    @{
        name = "Leah Chen"
        slug = "leah-chen"
        bio = "Tech writer who specialises in explaining gadgets and software to everyday, non-technical readers."
        voice = "Friendly and patient, like a knowledgeable friend explaining tech over coffee. Avoids jargon, and defines any term it does use in plain language. Uses simple analogies to make abstract tech concepts concrete."
        categories = @("technology")
        seasonalSubcategories = @()
    },
    @{
        name = "Ben Foster"
        slug = "ben-foster"
        bio = "Health and habits writer focused on small, sustainable changes rather than extreme routines."
        voice = "Calm and encouraging. Focuses on realistic, small steps rather than dramatic transformations. Never preachy or clinical, and avoids absolute claims - frames things as 'what tends to help' rather than strict rules."
        categories = @("health")
        seasonalSubcategories = @("spring")
    },
    @{
        name = "Grace Holloway"
        slug = "grace-holloway"
        bio = "Interior stylist who writes about making homes feel warmer and more considered, season by season."
        voice = "Warm, descriptive and a little cosy. Paints a picture of how a space or moment feels, not just what to buy. Design-forward but always keeps practicality and budget in view."
        categories = @("home-garden")
        seasonalSubcategories = @("christmas", "mothers-day", "valentines")
    },
    @{
        name = "Dave Whitfield"
        slug = "dave-whitfield"
        bio = "Lifelong car enthusiast who writes for everyday drivers, not just petrolheads."
        voice = "Straight-talking with a dry sense of humour. Explains car topics without talking down to the reader, and is upfront about trade-offs rather than oversimplifying. Occasionally self-deprecating about his own car obsession."
        categories = @("automotive")
        seasonalSubcategories = @()
    },
    @{
        name = "Ava Sinclair"
        slug = "ava-sinclair"
        bio = "Parent of three who writes practical, budget-conscious guides for the chaos of family life."
        voice = "Empathetic and solutions-focused, like advice from a friend who has been through the same school-holiday scramble. Acknowledges the stress or hassle before offering the practical fix. Down to earth, never precious."
        categories = @()
        seasonalSubcategories = @("back-to-school", "easter", "school-holidays", "halloween", "fathers-day")
    }
)

$selected = $availableTopics | Get-Random
$topic = $selected.topic
$category = $selected.category
$subcategory = $selected.subcategory
$imageKeyword = $selected.image
$tags = $selected.tags
$amazonSearch = $selected.amazon

# Match a contributor to this post: for seasonal topics, prefer whoever specialises
# in that specific occasion; otherwise match on category; fall back to anyone.
$matchingContributors = @()
if ($category -eq "seasonal") {
    $matchingContributors = $contributors | Where-Object { $_.seasonalSubcategories -contains $subcategory }
}
if ($matchingContributors.Count -eq 0) {
    $matchingContributors = $contributors | Where-Object { $_.categories -contains $category }
}
if ($matchingContributors.Count -eq 0) {
    $matchingContributors = $contributors
}
$contributor = $matchingContributors | Get-Random

Add-Content -Path $usedTopicsFile -Value $topic

$date = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")
$slug = $topic.ToLower() -replace '[^a-z0-9\s-]', '' -replace '\s+', '-'
$filename = "$date-$slug.md"
$filepath = "$postsPath/$filename"

Write-Log "Generating article: [$category] $topic (by $($contributor.name))"

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

You are writing as $($contributor.name), a contributor with this background: $($contributor.bio)
Write in this voice throughout the article: $($contributor.voice)

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
author: "$($contributor.name)"
author_bio: "$($contributor.bio)"
image: "$imageUrl"
image_thumb: "$imageThumb"
image_credit: "$imageCredit"
excerpt: "One sentence description."
---

Write the full 800 word article in markdown with proper headings and paragraphs, staying in the voice described above.
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
        & git commit -m "New post [$category] by $($contributor.name): $topic" 2>&1 | Out-Null
        & git push origin main 2>&1 | Out-Null
        Write-Log "Pushed: $filename"
    } else {
        Write-Log "ERROR: Response too short"
    }
} catch {
    Write-Log "ERROR: $_"
}
