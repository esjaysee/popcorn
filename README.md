# 🍿 POPCORN
  The Powershell Movie Companion Script.  Popcorn can be used to add trailers to your movie collection, fix naming errors and it can also be triggered by Radarr to keep your trailers up to date with your recent additions.

### Requirements
Powershell

A movie library with the naming convention {Movie Title} ({Release Year}), example: Fall Guy - (2024).

### Installation
Download the script in a directory of your choice.  If you want to connect it to Radarr make sure it is in a directory that is visible to your Radarr installation.

Open Powershell and navigate to the directory you saved Popcorn in.

Run the following command ``./popcorn.ps1 install``

Once that is done, you will need to edit the settings for Popcorn to work.

Run the following command ``./popcorn.ps1 edit``

You will need to change the following settings in order to make Popcorn work:<br/><br/>
``$libraryRoot = "C:\Your\Movie\Collection"``<br/>
Change C:\Your\Movie\Collection to the parent directory of your movie collection.

``$ytdlpCookies = "edge"``<br/>
Change this to whatever browser would have your YouTube/Google Cookies.  YT-DLP Currently supports cookies from the following browsers:  brave, chrome, chromium, edge, firefox, opera, safari, vivaldi, whale.

``$tmdbApiKey = "TMDB-API-KEY"``<br/>
Replace your 'TMDB-API-KEY' with your API Key from TMDB.<br/>This is required for the script to function.  If you do not have one, please visit this website to create one:  https://www.themoviedb.org/settings/api/request

``$googleApiKey = "GOOGLE-API-KEY"``<br/>
Replace your 'GOOGLE-API-KEY' with your API Key from Google. Make sure it has access to the 'YouTube V3 API' at minimum.<br/>It is required for the script to function.  If you do not have one, please visit this website to create one:  https://developers.google.com/workspace/guides/create-credentials#api-key

Press ``CTRL+O`` to save then press ``CTRL-X`` to exit.

Popcorn is now ready to use.

### How to Use
This is good to do for the first use.
- Open a PowerShell window.
- Navigate to the installation folder.
- Launch .\trailers.ps1 PATH_TO_MY_LIBRARY_ROOT_FOLDER (ex: .\trailers.ps1 z:\movies).
- Wait for the script to finish.

The first run will take a little bit of time depending on the size of your collection.
You can monitor download progress in the Powershell window or in the most recent log file stored under \logs.

### Connect with Radarr
This is the recommended usage.
- Open Radarr
- Create a new Connection
  - Go to 'Settings', 'Connect', '+' and select 'Custom Script'.
- Set the Notification Triggers to 'On Import' and 'On Rename'.
- Set the path to your copy of trailers.ps1.
- Test the Connection.
- Save the Connection.

### Turn off Logs
On Line 1 change "$LogActivity = $true"
to "$LogActivity = $false".
