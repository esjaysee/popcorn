
#  8888888b.   .d88888b.  8888888b.   .d8888b.   .d88888b.  8888888b.  888b    888
#  888   Y88b d88P   Y88b 888   Y88b d88P  Y88b d88P   Y88b 888   Y88b 8888b   888
#  888    888 888     888 888    888 888    888 888     888 888    888 88888b  888
#  888   d88P 888     888 888   d88P 888        888     888 888   d88P 888Y88b 888
#  8888888P   888     888 8888888P   888        888     888 8888888P   888 Y88b888
#  888        888     888 888        888    888 888     888 888 T88b   888  Y88888
#  888        Y88b. .d88P 888        Y88b  d88P Y88b. .d88P 888  T88b  888   Y8888
#  888          Y88888P   888          Y8888P     Y88888P   888   T88b 888    Y888
#                       The Powershell Movie Companion Script                     

####################################################################################
#                                    SETTINGS                                      #
####################################################################################

$libraryRoot = "Z:\popcorn\movies"
#$libraryRoot = "C:\Your\Movie\Collection"
# Change this to the parent directory of your movie collection.

$LogActivity = $true
# Change this to '$false' to turn off Logs.

$LogFolderName = "Logs"
# Change this to whatever you want to name your Log folder.
# Ignore this setting if you turned off Logs.

$TestModeRadarr = $false
# DO NOT change this if you can connect to Radarr.
# Change this to '$true' if you have problems connecting to Radarr.

$YoutubeLanguage = "en"
$YoutubeKeyword1 = "Official Trailer"
$YoutubeKeyword2 = "Trailer"
# DO NOT change anything in this settings group if you prefer English.
# You can use this to change what language it downloads the content in.
# For example if you want French change 'en' to 'fr', 'Official Trailer'
# to 'bande annonce officielle du film' and 'trailer' to 'bande annonce'.

$ytdlpQuality = "vcodec:h264,fps,res,acodec:m4a"
# If you like you can enter your custom YT-DLP sorting format above.
# Otherwise Popcorn will sort and download your trailers in H264 format.

$ytdlpCookies = "chrome"
# Change this to whatever browser would have your YouTube/Google Cookies.
# YT-DLP Currently supports cookies from the following browsers:
# brave, chrome, chromium, edge, firefox, opera, safari, vivaldi, whale.

$TmdbApiKEy = "c547771cec63e614e796c428285efe48"
#$TmdbApiKEy = "TMDB-API-KEY"
# Replace your 'TMDB-API-KEY' with your API Key from TMDB.  This is required for
# the script to function.  If you do not have one, please visit the website below
# to create one.
# https://www.themoviedb.org/settings/api/request

$YoutubeApiKey = "AIzaSyDhJdviuovc9IWf0rdbIvHZ5jo-Ef9Ex7I"
#$YoutubeApiKey = "AIzaSyD9qfSzw3Fo91KanTCEKLn1xKzoZalTphk"
#$YoutubeApiKey = "AIzaSyAVm2mu31T9rbB0KA94Rx08vEfty91kX48"
#$YoutubeApiKey = "AIzaSyAAWewuNGOVcucBXNwY6vtzKxvRB8Q9xnU"
#$YoutubeApiKey = "GOOGLE-API-KEY"
# Replace your 'GOOGLE-API-KEY' with your API Key from Google. Make sure it has
# access to the 'YouTube V3 API' at minimum. It is required for the script to
# function.  If you do not have one, please visit the website below to create one.
# https://developers.google.com/workspace/guides/create-credentials#api-key




####################################################################################
#                                     SCRIPT                                       #
####################################################################################

$Version = "240815"
Add-Type -AssemblyName System.Web
$Host.UI.RawUI.WindowTitle = "POPCORN $Version"
$MyInvocation.MyCommand.Path | Split-Path | Push-Location
$YoutubeParams = @{
    $YoutubeLanguage=[pscustomobject]@{UseOriginalMovieName=$true; SearchKeywords=$YoutubeKeyword1};
    default=[pscustomobject]@{UseOriginalMovieName=$false; SearchKeywords=$YoutubeKeyword2}
}

if($LogActivity -and -not(Test-Path $LogFolderName)) {
    New-Item $LogFolderName -ItemType Directory
}
$LogFileName = Get-Date -Format FileDateTime
$LogFileName = "$LogFolderName/$LogFileName.txt"

function woLogo
{
    process { Write-Host $_ -ForegroundColor Yellow }
}

function woError
{
    process { Write-Host $_ -ForegroundColor Red  }
}
function woHelp
{
    process { Write-Host $_ -ForegroundColor Green  }
}
function woDownloading
{
    process { Write-Host $_ -ForegroundColor Blue }
}

function woDone
{
    process { Write-Host $_ -ForegroundColor DarkYellow}
}

function woSkip
{
    process { Write-Host $_ -ForegroundColor DarkGray }
}

function Log {
    param ($LogText)

    if($LogActivity) {
        $LogText >> $LogFileName
    }
}

function LogInFunction {
    param($LogText)

    Write-Information $LogText -InformationAction Continue
    if($LogActivity) {
        $LogText >> $LogFileName
    }
}

function fetchJSON {
    param($url)

    $req = [System.Net.WebRequest]::Create("$url")

    $req.ContentType = "application/json; charset=utf-8"
    $req.Accept = "application/json"

    $resp = $req.GetResponse()
    $reader = new-object System.IO.StreamReader($resp.GetResponseStream())
    $responseJSON = $reader.ReadToEnd()

    $response = $responseJSON | ConvertFrom-Json
    return $response
}

function Get-YoutubeTrailer {
    param (
        $movieTitle, 
        $movieYear, 
        $moviePath,
        $tmdbId
    )

    $trailerFilename = "$moviePath\$movieTitle ($movieYear)-Trailer"

    $keywords = $YoutubeParams.default.SearchKeywords;
    if($TmdbApiKEy -ne 'TMDB-API-KEY' -and $tmdbId -ne '') {
        $tmdbURL = "https://api.themoviedb.org/3/movie/$($tmdbId)?api_key=$TmdbApiKEy"
        $tmdbInfo = fetchJSON($tmdbURL)

        if($YoutubeParams.ContainsKey($tmdbInfo.original_language)) {
            $keywords = $YoutubeParams[$tmdbInfo.original_language].SearchKeywords
            if($YoutubeParams[$tmdbInfo.original_language].UseOriginalMovieName) {
                $movieTitle = $tmdbInfo.original_title
            }
        }
    }

    $ytQuery = "$movieTitle $movieYear $keywords"
    $ytQuery = [System.Web.HTTPUtility]::UrlEncode($ytQuery)

    $ytSearchUrl = "https://youtube.googleapis.com/youtube/v3/search?part=snippet&maxResults=1&q=$ytQuery&type=video&videoDuration=short&key=$YoutubeApiKey"
    $ytSearchResults =  fetchJSON($ytSearchUrl)
    $ytVideoId = $ytSearchResults.items[0].id.videoId

    yt-dlp -i --cookies-from-browser $ytdlpCookies -S $ytdlpQuality -o $trailerFilename https://www.youtube.com/watch?v=$ytVideoId | Out-File -FilePath $LogFileName -Append
}

if($TestModeRadarr) {
    Log "Setting TEST MODE environment"
    $Env:radarr_eventtype = "Download"
    $Env:radarr_isupgrade = "False"
    $Env:radarr_movie_path = "Z:\Movies\Ghostbusters (1984)"
    $Env:radarr_movie_title = "Ghostbusters"
    $Env:radarr_movie_year = "1984"
    $Env:radarr_movie_tmdbid = "620"
}

cls

if(Test-Path Env:radarr_eventtype) {
    Log "RADARR :: SCRIPT TRIGGERED."

    if($Env:radarr_eventtype -eq "Test") {
        if($YoutubeApiKey -eq "GOOGLE-API-KEY") {
            Log "ERROR :: TMDB API KEY MISSING!"
            exit 1
        }
        Log "RADARR :: CONNECTION TEST SUCCESSFUL."
    }
    
    if(($Env:radarr_eventtype -eq "Download" -and $Env:radarr_isupgrade -eq "False") -or $Env:radarr_eventtype -eq "Rename") {
        Get-YoutubeTrailer $Env:radarr_movie_title $Env:radarr_movie_year $Env:radarr_movie_path $Env:radarr_movie_tmdbid
    }
    
    exit 0
}
Write-Output ""
write-output "#######################################################################################" | woLogo
Write-Output "##                                                                                   ##" | woLogo
write-output "##  8888888b.   .d88888b.  8888888b.   .d8888b.   .d88888b.  8888888b.  888b    888  ##" | woLogo
write-output "##  888   Y88b d88P   Y88b 888   Y88b d88P  Y88b d88P   Y88b 888   Y88b 8888b   888  ##" | woLogo
write-output "##  888    888 888     888 888    888 888    888 888     888 888    888 88888b  888  ##" | woLogo
write-output "##  888   d88P 888     888 888   d88P 888        888     888 888   d88P 888Y88b 888  ##" | woLogo
write-output "##  8888888P   888     888 8888888P   888        888     888 8888888P   888 Y88b888  ##" | woLogo
write-output "##  888        888     888 888        888    888 888     888 888 T88b   888  Y88888  ##" | woLogo
write-output "##  888        Y88b. .d88P 888        Y88b  d88P Y88b. .d88P 888  T88b  888   Y8888  ##" | woLogo
write-output "##  888          Y88888P   888          Y8888P     Y88888P   888   T88b 888    Y888  ##" | woLogo 
Write-Output "##                                                                                   ##" | woLogo
Write-Output "##  The Powershell Movie Companion Script                           version: $Version  ##" | woLogo
Write-Output "##                                                                                   ##" | woLogo
write-output "#######################################################################################" | woLogo
write-output ""       


#########################
#  NO ARGUMENTS         #
#########################
if($args.Count -eq 0) {
    Write-Output "ENTER './POPCORN.PS1 -HELP' FOR HELP." 
    Write-Output ""
    exit 0
}

#########################
#  FIX ARGUMENT         #
#########################
if ($args -eq "-fix"){
    Write-Output "working on it" | woError
    exit 1
}   

#########################
#  HELP ARGUMENT        #
#########################
if ($args -eq "-help"){
    Write-Output "CONGRATULATIONS!!!  YOU FOUND THE SUPER SECRET HELP SECTION!" | woHelp
    Write-Output ""
    Write-Output "TO USE POPCORN YOU MUST TELL IT WHERE YOUR MOVIE COLLECTION IS." | woHelp
    Write-Output "TO DO SO, RUN THE SCRIPT LIKE THIS: .\POPCORN.PS1 YOUR\MOVIE\COLLECTION" | woHelp
    Write-Output ""
    write-output "CHANGE 'YOUR\MOVIE\COLLECTION' TO THE PARENT DIRECTORY OF YOUR COLLECTION." | woHelp
    write-output "EXAMPLE: .\POPCORN.PS1 C:\STORAGE\MEDIA\MOVIES" | woHelp
    Write-Output ""
    write-output "NOW YOU CAN SIT BACK AND WATCH IT WORK OR YOU CAN JUST CHECK THE LOGS LATER." | woHelp
    Write-Output ""
    exit 1
}

#########################
#  TRAILERS ARGUMENT    #
#########################
if ($args -eq "-trailers"){
    $downloadedTrailersCount = 0
    Get-ChildItem -Path $libraryRoot -Directory |
    ForEach-Object {
        $alreadyHasTrailer = $false
        Get-ChildItem -LiteralPath "$($_.FullName)" -File -Exclude *part -Filter "*Trailer.*" |
        ForEach-Object {
            if($_.Extension -ne ".part") {
                $alreadyHasTrailer = $true
            }
        }
    
        if($alreadyHasTrailer) {
            write-output "Skipping $($_.Name)." | woSkip
        }
        else {
            Write-Output "Searching $($_.Name)..."
            
            $videoFile = Get-ChildItem -LiteralPath "$($_.FullName)" -File | Sort-Object Length -Descending | Select-Object BaseName -First 1
            if($videoFile.BaseName -match "(.*) \((\d{4})\)") {
                $title = $Matches.1
                $year = $Matches.2
                
                $tmdbId = '';
                if($TmdbApiKEy -ne 'TMDB-API-KEY') {
                    $tmdbSearchURL = "https://api.themoviedb.org/3/search/movie?api_key=$TmdbApiKEy&query=$([System.Web.HTTPUtility]::UrlEncode($title))&year=$year"
                    $tmdbSearchResultsJSON = curl $tmdbSearchURL
                    $tmdbSearchResults = $tmdbSearchResultsJSON | ConvertFrom-Json
                    if($tmdbSearchResults.total_results -ge 1) {
                        $tmdbId = $tmdbSearchResults.results[0].id;
                    }
                }
                Write-Output "Downloading content for $($_.Name)..." | woDownloading
                Get-YoutubeTrailer $title $year $_.FullName $tmdbId
                $downloadedTrailersCount++
                Log "Downloaded $($_.Name)" 
                Write-Output "Successfully downloaded content for ""$($_.Name)""." | woDone
                Timeout /T 62
            }
            else {
                Write-Output "$($_.Name) HAS AN INVALID NAME FORMAT OR IS MISSING." | woError
                Write-Output "USE ./'POPCORN.PS1 -FIX' TO ATTEMPT TO CORRECT THE FILE NAME FORMAT." | woError
                }
        
    }}}
else{
    Log "ROOT FOLDER NOT FOUND!"
    write-output "THE DIRECTORY OR COMMAND YOU ENTERED IS NOT IN SERVICE.  PLEASE CHECK YOUR ENTRY AND TRY YOUR" | woError
    write-output "ATTEMPT AGAIN.  IF YOU NEED HELP CONSULT YOUR FILE BROWSER.  GOOD BYE." | woError
    Write-Output ""
    exit 1



Log "Downloaded $downloadedTrailersCount new trailers."
Write-Output "Popcorn downloaded $downloadedTrailersCount new trailers to your collection." | woDone
}

