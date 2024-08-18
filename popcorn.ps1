#########################################################################################################
#                                                                                                       #
#            8888888b.   .d88888b.  8888888b.   .d8888b.   .d88888b.  8888888b.  888b    888            #
#            888   Y88b d88P   Y88b 888   Y88b d88P  Y88b d88P   Y88b 888   Y88b 8888b   888            #
#            888    888 888     888 888    888 888    888 888     888 888    888 88888b  888            #
#            888   d88P 888     888 888   d88P 888        888     888 888   d88P 888Y88b 888            #
#            8888888P   888     888 8888888P   888        888     888 8888888P   888 Y88b888            #
#            888        888     888 888        888    888 888     888 888 T88b   888  Y88888            #
#            888        Y88b. .d88P 888        Y88b  d88P Y88b. .d88P 888  T88b  888   Y8888            #
#            888          Y88888P   888          Y8888P     Y88888P   888   T88b 888    Y888            #
#                                                                                                       #
#                                 The Powershell Movie Companion Script                                 #  
#                                  https://github.com/esjaysee/popcorn                                  #
#                                                                                                       #
#########################################################################################################


#########################################################################################################
#  MANDATORY SETTINGS                                                                                   #
#########################################################################################################
$libraryRoot = "C:\Your\Movie\Collection"
# Change this to the parent directory of your movie collection.

$ytdlpCookies = "edge"
# Change this to whatever browser would have your YouTube/Google Cookies.
# YT-DLP Currently supports cookies from the following browsers:
# brave, chrome, chromium, edge, firefox, opera, safari, vivaldi, whale.

$tmdbApiKey = "TMDB-API-KEY"
# Replace your 'TMDB-API-KEY' with your API Key from TMDB.  This is required for
# the script to function.  If you do not have one, please visit the website below
# to create one.
# https://www.themoviedb.org/settings/api/request

$googleApiKey = "GOOGLE-API-KEY"
# Replace your 'GOOGLE-API-KEY' with your API Key from Google. Make sure it has
# access to the 'YouTube V3 API' at minimum. It is required for the script to
# function.  If you do not have one, please visit the website below to create one.
# https://developers.google.com/workspace/guides/create-credentials#api-key


#########################################################################################################
#  OPTIONAL SETTINGS                                                                                    #
#########################################################################################################
$logActivity = $true
# Change this to '$false' to turn off Logs.

$logFolderName = "Logs"
# Change this to whatever you want to name your log folder.
# Ignore this setting if you turned off Logs.

$radarrTestMode = $false
# DO NOT change this if you can connect to Radarr.
# Change this to '$true' if you have problems connecting to Radarr.

$ytLanguage = "en"
$ytKeyword1 = "Official Trailer"
$ytKeyword2 = "Trailer"
# DO NOT change anything in this settings group if you prefer English.
# You can use this to change what language it downloads the content in.
# For example if you want French change 'en' to 'fr', 'Official Trailer'
# to 'bande annonce officielle du film' and 'trailer' to 'bande annonce'.

$ytdlpQuality = "vcodec:h264,fps,res,acodec:m4a"
# If you like you can enter your custom YT-DLP sorting format above.
# Otherwise Popcorn will sort and download your trailers in H264 format.


#########################################################################################################
#  SCRIPT                                                                                               #
#########################################################################################################
$Version = "1.08.18"
Add-Type -AssemblyName System.Web
$Host.UI.RawUI.WindowTitle = "popcorn $Version"
$MyInvocation.MyCommand.Path | Split-Path | Push-Location
$ytParams = @{
    $ytLanguage=[pscustomobject]@{UseOriginalMovieName=$true; SearchKeywords=$ytKeyword1};
    default=[pscustomobject]@{UseOriginalMovieName=$false; SearchKeywords=$ytKeyword2}
}


#########################################################################################################
#  FUNCTIONS                                                                                            #
#########################################################################################################
function woRed
{
    process { Write-Host $_ -ForegroundColor Red  }
}
function woGreen
{
    process { Write-Host $_ -ForegroundColor DarkGreen  }
}
function woBlue
{
    process { Write-Host $_ -ForegroundColor Blue }
}

function woButter
{
    process { Write-Host $_ -ForegroundColor DarkYellow}
}

function woGray
{
    process { Write-Host $_ -ForegroundColor DarkGray }
}
function woWhite
{
    process { Write-Host $_ -ForegroundColor White }
}

function log {
    param ($logText)

    if($logActivity) {
        $logText >> $logFileName
    }
}

function logWrite {
    param($logText)

    Write-Information $logText -InformationAction Continue
    if($logActivity) {
        $logText >> $logFileName
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

    $keywords = $ytParams.default.SearchKeywords;
    if($tmdbApiKey -ne 'TMDB-API-KEY' -and $tmdbId -ne '') {
        $tmdbURL = "https://api.themoviedb.org/3/movie/$($tmdbId)?api_key=$tmdbApiKey"
        $tmdbInfo = fetchJSON($tmdbURL)

        if($ytParams.ContainsKey($tmdbInfo.original_language)) {
            $keywords = $ytParams[$tmdbInfo.original_language].SearchKeywords
            if($ytParams[$tmdbInfo.original_language].UseOriginalMovieName) {
                $movieTitle = $tmdbInfo.original_title
            }
        }
    }

    $ytQuery = "$movieTitle $movieYear $keywords"
    $ytQuery = [System.Web.HTTPUtility]::UrlEncode($ytQuery)

    $ytSearchUrl = "https://youtube.googleapis.com/youtube/v3/search?part=snippet&maxResults=1&q=$ytQuery&type=video&videoDuration=short&key=$googleApiKey"
    $ytSearchResults =  fetchJSON($ytSearchUrl)
    $ytVideoId = $ytSearchResults.items[0].id.videoId

    yt-dlp -i --cookies-from-browser $ytdlpCookies -S $ytdlpQuality -o $trailerFilename https://www.youtube.com/watch?v=$ytVideoId | Out-File -FilePath $logFileName -Append
}


#########################################################################################################
#  MAKE LOGS                                                                                            #
#########################################################################################################
if($logActivity -and -not(Test-Path $logFolderName)) {
    New-Item $logFolderName -ItemType Directory
}
$logFileName = Get-Date -Format FileDateTime
$logFileName = "$logFolderName/$logFileName.txt"


#########################################################################################################
#  RADARR CALLED                                                                                        #
#########################################################################################################
if($radarrTestMode) {
    logWrite "Setting TEST MODE environment"
    $Env:radarr_eventtype = "Download"
    $Env:radarr_isupgrade = "False"
    $Env:radarr_movie_path = "Z:\Movies\Ghostbusters (1984)"
    $Env:radarr_movie_title = "Ghostbusters"
    $Env:radarr_movie_year = "1984"
    $Env:radarr_movie_tmdbid = "620"
}

cls

if(Test-Path Env:radarr_eventtype) {
    logWrite "RADARR :: SCRIPT TRIGGERED."

    if($Env:radarr_eventtype -eq "Test") {
        if($googleApiKey -eq "GOOGLE-API-KEY") {
            logWrite "ERROR :: TMDB API KEY MISSING!"
            exit 1
        }
        logWrite "RADARR :: CONNECTION TEST SUCCESSFUL."
    }
    
    if(($Env:radarr_eventtype -eq "Download" -and $Env:radarr_isupgrade -eq "False") -or $Env:radarr_eventtype -eq "Rename") {
        Get-YoutubeTrailer $Env:radarr_movie_title $Env:radarr_movie_year $Env:radarr_movie_path $Env:radarr_movie_tmdbid
    }
    
    exit 0
}


#####################################################################################################
#  SPLASH                                                                                           #
#####################################################################################################
Write-Output ""
write-output "#######################################################################################" | woButter
Write-Output "##                                                                                   ##" | woButter
write-output "##  8888888b.   .d88888b.  8888888b.   .d8888b.   .d88888b.  8888888b.  888b    888  ##" | woButter
write-output "##  888   Y88b d88P   Y88b 888   Y88b d88P  Y88b d88P   Y88b 888   Y88b 8888b   888  ##" | woButter
write-output "##  888    888 888     888 888    888 888    888 888     888 888    888 88888b  888  ##" | woButter
write-output "##  888   d88P 888     888 888   d88P 888        888     888 888   d88P 888Y88b 888  ##" | woButter
write-output "##  8888888P   888     888 8888888P   888        888     888 8888888P   888 Y88b888  ##" | woButter
write-output "##  888        888     888 888        888    888 888     888 888 T88b   888  Y88888  ##" | woButter
write-output "##  888        Y88b. .d88P 888        Y88b  d88P Y88b. .d88P 888  T88b  888   Y8888  ##" | woButter
write-output "##  888          Y88888P   888          Y8888P     Y88888P   888   T88b 888    Y888  ##" | woButter 
Write-Output "##                                                                                   ##" | woButter
Write-Output "##  The Powershell Movie Companion Script                          version: $Version  ##" | woButter
Write-Output "##                                                                                   ##" | woButter
write-output "#######################################################################################" | woButter
write-output ""       


#########################################################################################################
#  NO ARGUMENTS                                                                                         #
#########################################################################################################
if($args.Count -eq 0) {
    Write-Output "For a list of commands type './popcorn help'" | woWhite
    Write-Output ""
    exit 
}


#########################################################################################################
#  EDIT ARGUMENT                                                                                        #
#########################################################################################################
if ($args -eq "edit"){
    Write-Output "Launching..." | woWhite
    nano mypopcorn.ps1
    Write-Output "Done..." | woWhite
    exit
}


#########################################################################################################
#  HELP ARGUMENT                                                                                        #
#########################################################################################################
if ($args -eq "help"){
    Write-Output "Please run './popcorn install' and configure the settings before calling the script." | woWhite
    Write-Output "To configure the settings either open the script in an external text editor such as" | woWhite
    Write-Output "Notepad, VScode or run './popcorn edit' to edit in the terminal." | woWhite
    Write-Output ""
    Write-Output "You MUST fill in the 'libraryRoot', 'ytdlpCookies', 'tmdbApiKey' and 'googleApiKey'" | woButter
    write-output "information at MINIMUM for Popcorn to work.  The other settings are optional." | woButter
    Write-Output ""
    Write-Output "#######################################################################################" | woGreen
    Write-Output "# Popcorn Commands                                                                    #" | woGreen
    Write-Output "# to use enter the command when calling the script.                                   #" | woGreen
    Write-Output "# for example to grab trailers run ./popcorn trailers                             #" | woGreen
    Write-Output "#######################################################################################" | woGreen
    Write-Output " fix           Scan the library and attempt to fix invalid naming formats." | woWhite
    Write-Output ""
    Write-Output " help          Display this help dialog." | woWhite
    Write-Output "" 
    Write-Output " edit          Open Nano so you can edit the settings." | woWhite
    Write-Output ""
    Write-Output " about         Displays the about dialog." | woWhite
    Write-Output ""
    Write-Output " install       Install the dependencies for Popcorn." | woWhite
    Write-Output ""
    Write-Output " trailers      Scan the library, search for trailers and download them." | woWhite
    Write-Output ""
    exit
}


#########################################################################################################
#  ABOUT ARGUMENT                                                                                       #
#########################################################################################################
if ($args -eq "about"){
    Write-Output "Popcorn - The Powershell Movie Companion Script" | woWhite
    Write-Output "Version $version" | woWhite
    Write-Output "Made by Esjaysee" | woWhite
    Write-Output "https://www.github.com/esjaysee/popcorn" | woWhite
    Write-Output "GPL3 License, No warranty, No Liability, No Fucks Given." | woWhite
    Write-Output ""
    exit
}


#########################################################################################################
#  FIX ARGUMENT                                                                                         #
#########################################################################################################
if ($args -eq "fix"){
    Write-Output "Popcorn is attempting to fix Invalid naming formats..." | woButter
        
    $fixedCount = 0
    Get-ChildItem -Path $libraryRoot -Directory |
    ForEach-Object {
        $alreadyHasProperName = $false
        Get-ChildItem -LiteralPath "$($_.FullName)" -File -Exclude *part -Filter "*Trailer.*" |
        ForEach-Object {
            if($_.Extension -ne ".part") {
                $alreadyHasProperName = $true
            }
        }
    
        if($alreadyHasProperName) {}
        else {
        Get-ChildItem $libraryRoot -Directory | Foreach-Object { 
        $file = $_.Fullname} 
        Get-ChildItem $libraryRoot -Recurse -File | 
        Where-Object { $_.Extension -in ".mkv", ".Avi", ".mov", ".MPG", ".MPEG", ".MP4" } | 
        ForEach-Object { Rename-Item $_.FullName -NewName ($_.Directory.Name + $_.Extension) -ErrorAction SilentlyContinue}
        Write-Output "Fixed $($_.FullName)"
        $fixedCount++
        
        }
    }
    if ($fixedCount -ne 0){
        Write-Output "Popcorn fixed $fixedCount Invalid naming formats." | woButter
    }else{Write-Output "Popcorn found no Invalid naming formats." | woButter}
    
        exit}

#########################################################################################################
#  INSTALL ARGUMENT                                                                                     #
#########################################################################################################
if ($args -eq "install"){
    Write-Output "Popcorn will download and install the following depenecies:" | woWhite
    Write-Output "-----------------------------------------------------------" | woWhite
    Write-Output "Chocolatey Package Manager" | woWhite
    Write-Output " - used to download and install dependencies." | woGray
    Write-Output ""
    Write-Output "YT-DLP" | woWhite
    Write-Output " - used to download trailers from youtube." | woGray
    Write-Output ""
    Write-Output "FFMPEG" | woWhite
    Write-Output " - used to make the trailers watchable." | woGray
    Write-Output ""
    Write-Output "Nano" | woWhite
    Write-Output " - used to make edits to the script via Powershell." | woGray
    Write-Output ""
    Write-Output ""
    $title    = ''
    $question = 'Do you want to continue and install the dependencies?'
    $choices  = '&Yes', '&No'

    $decision = $Host.UI.PromptForChoice($title, $question, $choices, 0)
    if ($decision -eq 0) {
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Start-Process -FilePath powershell.exe -ArgumentList {choco install ffmpeg yt-dlp nano} -verb RunAs
        Write-Output "Dependecies successfully installed." | woButter
        exit
    }
    else {
        Write-Output "Cancelled by User." | woRed
        }
    }
 if ($args -eq "ch"){
 Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
 }
#########################################################################################################
#  TRAILERS ARGUMENT                                                                                    #
#########################################################################################################
else{
if ($args -eq "trailers"){
    Write-Output "Popcorn is looking for trailers..." | woButter
    $downloadedTrailersCount = 0
    $errorCount = 0
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
            logWrite "Skipping $($_.Name). It already has a trailer." | woGray
        }
        else {  
            $videoFile = Get-ChildItem -LiteralPath "$($_.FullName)" -File | Sort-Object Length -Descending | Select-Object BaseName -First 1
            if($videoFile.BaseName -match "(.*) \((\d{4})\)") {
                $title = $Matches.1
                $year = $Matches.2
                
                $tmdbId = '';
                if($tmdbApiKey -ne 'TMDB-API-KEY') {
                    $tmdbSearchURL = "https://api.themoviedb.org/3/search/movie?api_key=$tmdbApiKey&query=$([System.Web.HTTPUtility]::UrlEncode($title))&year=$year"
                    $tmdbSearchResultsJSON = curl $tmdbSearchURL
                    $tmdbSearchResults = $tmdbSearchResultsJSON | ConvertFrom-Json
                    if($tmdbSearchResults.total_results -ge 1) {
                        $tmdbId = $tmdbSearchResults.results[0].id;
                    }
                }
                Write-Output "Downloading a trailer for $($_.Name)..." | woBlue
                Get-YoutubeTrailer $title $year $_.FullName $tmdbId
                $downloadedTrailersCount++
                logWrite "Downloaded a trailer for ""$($_.Name)""." 
                Write-Output "Successfully downloaded a trailer for ""$($_.Name)""." | woBlue
            }
            else {
                Write-Output "$($_.Name) has an invalid file name format or is missing!" | woRed
                logWrite "$($_.Name) has an invalid file name format or is missing!" | woRed
                $errorCount++    
            }
        
    }}
    logWrite "Popcorn downloaded $downloadedTrailersCount new trailer(s)."
    Write-Output "Popcorn downloaded $downloadedTrailersCount new trailers to your collection." | woButter
    if ($errorCount -ne 0){
    Write-Output "Popcorn returned $errorCount error(s)." | woRed
    logWrite "Popcorn returned $errorCount error(s)." 
    write-output "Please run './popcorn fix', then run the trailer grabber again." | woRed
    }
}
else{
#########################################################################################################
#  ERROR MESSAGE                                                                                        #
#########################################################################################################
    write-output "You have reached a command that is no longer in service.  If you feel you have reached" | woRed
    Write-Output "this message in error please check your entry and try your command again.  If you meed" | woRed
    write-output "help, dial your operator.  Good Bye." | woRed
    Write-Output "" | woWhite
    exit
}

}


#########################################################################################################
#  THE END                                                                                              #
#########################################################################################################