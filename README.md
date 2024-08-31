# 🍿 POPCORN
  The Powershell Movie Companion Script.<br/>Popcorn can be used to add trailers to your movie collection, fix naming errors and it can also be triggered by Radarr to keep your trailers up to date with your recent additions.<br/>Popcorn was forked from <a href="https://github.com/James-Ashwin/trailers">trailers.ps1 by James Ashwin</a>.
<br/><br/>

### ✔️ Requirements
- Powershell 5+
- A movie library with the naming convention {Movie Title} ({Release Year}), example: Fall Guy (2024).
<br/>

### ⚙️ Installation
- Download the script in a directory of your choice. <br/>
  If you want to connect it to Radarr make sure it is in a directory that is visible to your Radarr installation.
- Open Powershell and navigate to the directory you saved Popcorn in.
- Run the following command ``./popcorn install``
- Now you will need to edit the settings.<br/>
  Run the following command ``./popcorn edit``
- You must change the following settings for Popcorn to work:<br/>
  - ``$libraryRoot = "C:\Your\Movie\Collection"``<br/>
  Change C:\Your\Movie\Collection to the parent directory of your movie collection.
  - ``$ytdlpCookies = "edge"``<br/>
  Change this to whatever browser would have your YouTube/Google Cookies.<br/>YT-DLP currently supports cookies from the following browsers:<br/>brave, chrome, chromium, edge, firefox, 
opera, safari, vivaldi, whale.
  - ``$tmdbApiKey = "TMDB-API-KEY"``<br/>
  Replace your 'TMDB-API-KEY' with your API Key from TMDB.<br/>This is required for the script to function.<br/>If you do not have one, please visit this website to create one:  https://www.themoviedb.org/settings/api/request
  - ``$googleApiKey = "GOOGLE-API-KEY"``<br/>
  Replace your 'GOOGLE-API-KEY' with your API Key from Google.<br/>Make sure it has access to the 'YouTube V3 API' at minimum.<br/>It is required for the script to function.<br/>If you do not have one, please visit this website to create one:  https://developers.google.com/workspace/guides/create-credentials#api-key
- Press ``CTRL+O`` to save then press ``CTRL-X`` to exit.
- Popcorn is now ready to use. ⭐
<br/>

### 🛠️ How to Use
- Open a PowerShell window.
- Navigate to the installation folder.
- Run the following command ``./popcorn trailers``
- Wait for the script to finish.
- If you receive any Invalid Name Format errors run the following command ``./popcorn fix`` then run  ``./popcorn trailers`` again.
- The first run will take a little bit of time depending on the size of your collection.
- You can monitor download progress in the Powershell window or in the most recent log file.
<br/>

### 🔗 Connect with Radarr
- Open Radarr
- Create a new Connection
  - Go to 'Settings', 'Connect', '+' and select 'Custom Script'.
  - Set the Notification Triggers to 'On Import' and 'On Rename'.
  - Set the path to your copy of popcorn.ps1.
  - Test the Connection.
  - Save the Connection.
<br/>

### 👑 Commands
- ``./popcorn fix`` Scan the library and attempt to fix any invalid naming formats found.
- ``./popcorn edit`` Launch Nano so you can edit the script.
- ``./popcorn help`` Displays the Help dialog.
- ``./popcorn about`` Displays the About dialog.
- ``./popcorn install`` Install the dependencies via Chocolatey Package Manager.  If you don't have Chocolatey it will be installed along with FFMPEG, YT-DLP and Nano.
- ``./popcorn trailers`` Scan the library and download trailers for the movies found.
    
