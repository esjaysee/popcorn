#########################################################################################################
#                                                                                                       #
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
#                                                                                                       #
#########################################################################################################
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


#########################################################################################################
#  SCRIPT                                                                                               #
#########################################################################################################
$Version = "1.08.17"
Add-Type -AssemblyName System.Web
$Host.UI.RawUI.WindowTitle = "POPCORN $Version"
$MyInvocation.MyCommand.Path | Split-Path | Push-Location
$YoutubeParams = @{
    $YoutubeLanguage=[pscustomobject]@{UseOriginalMovieName=$true; SearchKeywords=$YoutubeKeyword1};
    default=[pscustomobject]@{UseOriginalMovieName=$false; SearchKeywords=$YoutubeKeyword2}
}


#########################################################################################################
#  FUNCTIONS                                                                                            #
#########################################################################################################
function Pass-Parameters {
    Param ([hashtable]$NamedParameters)
    return ($NamedParameters.GetEnumerator()|%{"-$($_.Key) `"$($_.Value)`""}) -join " "
}
function woError
{
    process { Write-Host $_ -ForegroundColor Red  }
}
function woHeader
{
    process { Write-Host $_ -ForegroundColor DarkGreen  }
}
function woDownloading
{
    process { Write-Host $_ -ForegroundColor Blue }
}

function woAnnouncement
{
    process { Write-Host $_ -ForegroundColor DarkYellow}
}

function woSkip
{
    process { Write-Host $_ -ForegroundColor DarkGray }
}
function woText
{
    process { Write-Host $_ -ForegroundColor White }
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
    if($tmdbApiKey -ne 'TMDB-API-KEY' -and $tmdbId -ne '') {
        $tmdbURL = "https://api.themoviedb.org/3/movie/$($tmdbId)?api_key=$tmdbApiKey"
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

    $ytSearchUrl = "https://youtube.googleapis.com/youtube/v3/search?part=snippet&maxResults=1&q=$ytQuery&type=video&videoDuration=short&key=$googleApiKey"
    $ytSearchResults =  fetchJSON($ytSearchUrl)
    $ytVideoId = $ytSearchResults.items[0].id.videoId

    yt-dlp -i --cookies-from-browser $ytdlpCookies -S $ytdlpQuality -o $trailerFilename https://www.youtube.com/watch?v=$ytVideoId | Out-File -FilePath $LogFileName -Append
}


#########################################################################################################
#  MAKE LOGS                                                                                            #
#########################################################################################################
if($LogActivity -and -not(Test-Path $LogFolderName)) {
    New-Item $LogFolderName -ItemType Directory
}
$LogFileName = Get-Date -Format FileDateTime
$LogFileName = "$LogFolderName/$LogFileName.txt"


#########################################################################################################
#  RADARR CALLED                                                                                        #
#########################################################################################################
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
        if($googleApiKey -eq "GOOGLE-API-KEY") {
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


#####################################################################################################
#  SPLASH                                                                                           #
#####################################################################################################
Write-Output ""
write-output "#######################################################################################" | woAnnouncement
Write-Output "##                                                                                   ##" | woAnnouncement
write-output "##  8888888b.   .d88888b.  8888888b.   .d8888b.   .d88888b.  8888888b.  888b    888  ##" | woAnnouncement
write-output "##  888   Y88b d88P   Y88b 888   Y88b d88P  Y88b d88P   Y88b 888   Y88b 8888b   888  ##" | woAnnouncement
write-output "##  888    888 888     888 888    888 888    888 888     888 888    888 88888b  888  ##" | woAnnouncement
write-output "##  888   d88P 888     888 888   d88P 888        888     888 888   d88P 888Y88b 888  ##" | woAnnouncement
write-output "##  8888888P   888     888 8888888P   888        888     888 8888888P   888 Y88b888  ##" | woAnnouncement
write-output "##  888        888     888 888        888    888 888     888 888 T88b   888  Y88888  ##" | woAnnouncement
write-output "##  888        Y88b. .d88P 888        Y88b  d88P Y88b. .d88P 888  T88b  888   Y8888  ##" | woAnnouncement
write-output "##  888          Y88888P   888          Y8888P     Y88888P   888   T88b 888    Y888  ##" | woAnnouncement 
Write-Output "##                                                                                   ##" | woAnnouncement
Write-Output "##  The Powershell Movie Companion Script                          version: $Version  ##" | woAnnouncement
Write-Output "##                                                                                   ##" | woAnnouncement
write-output "#######################################################################################" | woAnnouncement
write-output ""       


#########################################################################################################
#  NO ARGUMENTS                                                                                         #
#########################################################################################################
if($args.Count -eq 0) {
    Write-Output "For a list of commands type './popcorn.ps1 help'" | woText
    Write-Output ""
    exit 
}


#########################################################################################################
#  EDIT ARGUMENT                                                                                        #
#########################################################################################################
if ($args -eq "edit"){
    Write-Output "Launching..." | woText
    nano mypopcorn.ps1
    Write-Output "Done..." | woText
    exit
}


#########################################################################################################
#  HELP ARGUMENT                                                                                        #
#########################################################################################################
if ($args -eq "help"){
    Write-Output "Please run './popcorn.ps1 install' and configure the settings before calling the script." | woText
    Write-Output "To configure the settings either open the script in an external text editor such as" | woText
    Write-Output "Notepad, VScode or run './popcorn.ps1 edit' to edit in the terminal." | woText
    Write-Output ""
    Write-Output "You MUST fill in the 'libraryRoot', 'ytdlpCookies', 'tmdbApiKey' and 'googleApiKey'" | woAnnouncement
    write-output "information at MINIMUM for Popcorn to work.  The other settings are optional." | woAnnouncement
    Write-Output ""
    Write-Output "#######################################################################################" | woHeader
    Write-Output "# Popcorn Commands                                                                    #" | woHeader
    Write-Output "# to use enter the command when calling the script.                                   #" | woHeader
    Write-Output "# for example to grab trailers run ./popcorn.ps1 trailers                             #" | woHeader
    Write-Output "#######################################################################################" | woHeader
    Write-Output " fix           Scan the library and attempt to fix invalid naming formats." | woText
    Write-Output ""
    Write-Output " help          Display this help dialog." | woText
    Write-Output "" 
    Write-Output " edit          Open Nano so you can edit the settings." | woText
    Write-Output ""
    Write-Output " about         Displays the about dialog." | woText
    Write-Output ""
    Write-Output " install       Install the dependencies for Popcorn." | woText
    Write-Output ""
    Write-Output " trailers      Scan the library, search for trailers and download them." | woText
    Write-Output ""
    exit
}


#########################################################################################################
#  ABOUT ARGUMENT                                                                                       #
#########################################################################################################
if ($args -eq "about"){⠀⠀
    Write-Output "Popcorn - The Powershell Movie Companion Script" | woText
    Write-Output "Version $version" | woText
    Write-Output "Made by Esjaysee" | woText
    Write-Output "https://www.github.com/esjaysee/popcorn" | woText
    Write-Output "GPL3 License, No warranty, No Liability, No Fucks Given." | woText
    Write-Output ""
    exit
}


#########################################################################################################
#  FIX ARGUMENT                                                                                         #
#########################################################################################################
if ($args -eq "fix"){
    Write-Output "Popcorn is attempting to fix Invalid naming formats..." | woAnnouncement
        
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
        Write-Output "Popcorn fixed $fixedCount Invalid naming formats." | woAnnouncement
    }else{Write-Output "Popcorn found no Invalid naming formats." | woAnnouncement}
    
        exit}

#########################################################################################################
#  INSTALL ARGUMENT                                                                                     #
#########################################################################################################
if ($args -eq "install"){
    Write-Output "Popcorn will download and install the following depenecies:" | woText
    Write-Output "-----------------------------------------------------------" | woText
    Write-Output "Chocolatey Package Manager" | woText
    Write-Output " - used to download and install dependencies." | woSkip
    Write-Output ""
    Write-Output "YT-DLP" | woText
    Write-Output " - used to download trailers from youtube." | woSkip
    Write-Output ""
    Write-Output "FFMPEG" | woText
    Write-Output " - used to make the trailers watchable." | woSkip
    Write-Output ""
    Write-Output "Nano" | woText
    Write-Output " - used to make edits to the script via Powershell." | woSkip
    Write-Output ""
    Write-Output ""
    $title    = ''
    $question = 'Do you want to continue and install the dependencies?'
    $choices  = '&Yes', '&No'

    $decision = $Host.UI.PromptForChoice($title, $question, $choices, 0)
    if ($decision -eq 0) {
        Start-Process -FilePath powershell.exe -ArgumentList {choco install ffmpeg yt-dlp nano} -verb RunAs
        Write-Output "Dependecies successfully installed." | woAnnouncement
        exit
    }
    else {
        Write-Output "Cancelled by User." | woError
        }
    }

#########################################################################################################
#  TRAILERS ARGUMENT                                                                                    #
#########################################################################################################
else{
if ($args -eq "trailers"){
    Write-Output "Popcorn is looking for trailers..." | woAnnouncement
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
            #write-output "Skipping $($_.Name). It already has a trailer." | woSkip
        }
        else {
          #  Write-Output "Searching for a trailer for $($_.Name)..." | woText
            
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
                Write-Output "Downloading a trailer for $($_.Name)..." | woDownloading
                Get-YoutubeTrailer $title $year $_.FullName $tmdbId
                $downloadedTrailersCount++
                Log "Downloaded $($_.Name)" 
                Write-Output "Successfully downloaded a trailer for ""$($_.Name)""." | woDownloading
            }
            else {
                Write-Output "$($_.Name) has an invalid file name format or is missing!" | woError
                 $errorCount++    
            }
        
    }}
    Log "Downloaded $downloadedTrailersCount new trailer(s)."
    Write-Output "Popcorn downloaded $downloadedTrailersCount new trailers to your collection." | woAnnouncement
    if ($errorCount -ne 0){
    Write-Output "Popcorn returned $errorCount error(s)." | woError
    write-output "Please run './popcorn.ps1 fix', then run the trailer grabber again." | woError
    }
}
else{
#########################################################################################################
#  ERROR MESSAGE                                                                                        #
#########################################################################################################
    write-output "You have reached a command that is no longer in service.  If you feel you have reached" | woError
    Write-Output "this message in error please check your entry and try your command again.  If you meed" | woError
    write-output "help, dial your operator.  Good Bye." | woError
    Write-Output "" | woText
    exit
}

}


#########################################################################################################
#  THE END                                                                                              #
#########################################################################################################