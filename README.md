# 🍿 POPCORN
  The Powershell Movie Companion Script.  Popcorn can be used to add trailers to your movie collection, fix naming errors and it can also be triggered by Radarr to keep your trailers up to date with your recent additions.  Popcorn was forked from <a href="https://github.com/James-Ashwin/trailers">trailers.ps1 by James Ashwin</a>.
<br/>

### ✔️ Requirements
- Powershell
- A movie library with the naming convention {Movie Title} ({Release Year}), example: Fall Guy (2024).
<br/>

### ⚙️ Installation
- Download the script in a directory of your choice.  If you want to connect it to Radarr make sure it is in a directory that is visible to your Radarr installation.
- Open Powershell and navigate to the directory you saved Popcorn in.
- Run the following command ``./popcorn.ps1 install``
- Once that is done, you will need to edit the settings for Popcorn to work.
- Run the following command ``./popcorn.ps1 edit``
- You will need to change the following settings in order to make Popcorn work:<br/>
  - ``$libraryRoot = "C:\Your\Movie\Collection"``<br/>
  Change C:\Your\Movie\Collection to the parent directory of your movie collection.
  - ``$ytdlpCookies = "edge"``<br/>
  Change this to whatever browser would have your YouTube/Google Cookies.  YT-DLP Currently supports cookies from the following browsers:  brave, chrome, chromium, edge, firefox, 
opera, safari, vivaldi, whale.
  - ``$tmdbApiKey = "TMDB-API-KEY"``<br/>
  Replace your 'TMDB-API-KEY' with your API Key from TMDB.<br/>This is required for the script to function.  If you do not have one, please visit this website to create one:  https://www.themoviedb.org/settings/api/request
  - ``$googleApiKey = "GOOGLE-API-KEY"``<br/>
  Replace your 'GOOGLE-API-KEY' with your API Key from Google. Make sure it has access to the 'YouTube V3 API' at minimum.<br/>It is required for the script to function.  If you do not have one, please visit this website to create one:  https://developers.google.com/workspace/guides/create-credentials#api-key
- Press ``CTRL+O`` to save then press ``CTRL-X`` to exit.
- Popcorn is now ready to use. ⭐
<br/>

### 🛠️ How to Use
- Open a PowerShell window.
- Navigate to the installation folder.
- Run the following command ``./popcorn.ps1 trailers``
- Wait for the script to finish.
- If you receive any Invalid Name Format errors run the following command ``./popcorn.ps1 fix`` then run  ``./popcorn.ps1 trailers`` again.
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
