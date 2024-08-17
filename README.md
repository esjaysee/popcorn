# trailers.ps1
  Powershell script that can be used to add trailers to your movie collection, fix naming errors and it can be triggered by Radarr.

  This came about because I wanted trailers that my Roku will recognize and play through my Jellyfin client and I found trailers.ps1 by James Ashwin. It worked, although with some quirks.  Overall To me it needed a little 'juice'.

### Requirements
- Powershell
- A movie library with the naming convention {Movie Title} ({Release Year}), example: Ghostbusters - (1984).

### Installation
- Download the script and extract in a directory of your choice.  If you want to connect it to Radarr make sure it is in a directory that is visible to your Radarr installation.

- Open Powershell and navigate to directory you save Popcorn in.

- Run the following command
  ``./popcorn.ps1 install``
### Use Stand Alone
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
