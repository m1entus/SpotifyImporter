# Spotify Playlist Importer to Apple Music

OS X which help you to import your playlist from Spotify to Apple Music. Inspired by [spotify2am](https://github.com/simonschellaert/spotify2am) am which didn't work for me :D

### [Downwload DMG](https://raw.github.com/m1entus/SpotifyImporter/master/SpotifyImporter.dmg)


[![](https://raw.github.com/m1entus/SpotifyImporter/master/Screens/screen1.png)](https://raw.github.com/m1entus/SpotifyImporter/master/Screens/screen1.png)

## Why ?
I created this project before [@maciej's Playlist Importer](https://lupin.rocks/entry/seamlessly-import-your-spotify-playlists-into-itunes) show up, i am iOS developer and i wanted to try OS X development. Disadvantage of @maciej's Playlist Importer is that you have to leave your Mac for a some time and it can't import your songs in background. This project disadvantage it that you have to sniff iTunes packet to get your account identifiers and cookie but it works in background!

# Usage

## 1. Export from Spotify and import to SpotiyImporter

1. Export the Spotify URIs

You can copy as many as you want, but remember - only single track URIs are supported. This is how it should look like:

[![](https://raw.github.com/m1entus/SpotifyImporter/master/Screens/screen2.png)](https://raw.github.com/m1entus/SpotifyImporter/master/Screens/screen2.png)

2. Export the Spotify songs to an CSV File

The first step is getting the songs you want to import into Apple Music into a CSV file. The simplest way to do this is using [Exportify](https://rawgit.com/watsonbox/exportify/master/exportify.html).
If you want to export you whole Spotify library, simply create a new playlist called All and drag your whole library into it using the Spotify desktop app. You can then export the playlist All using Exportify. Save the resulting file as spotify.csv in the same directory as the directory you cloned this repo into.

## 2. Use an intercepting proxy to retrieve the Apple Music request headers

We are going to retrieve cookie data from iTunes using Charles Proxy.

1. From the Menu Proxy go to SSL Proxy Settings

2. Check 'Enable SSL Proxying'

3. Click on add and insert '*itunes.apple.com'

4. In the same Menu check on 'Mac OS X Proxy'

5. Go to iTunes go to an Apple Music playlist but don't do nothing

6. Check you have enabled recording (please refer to image below)

7. When recording is enabled add the playlist to my Music

[![](https://raw.github.com/m1entus/SpotifyImporter/master/Screens/screen3_thumb.png)](https://raw.github.com/m1entus/SpotifyImporter/master/Screens/screen3.png)

Application simply compares the title and artist to find out if a Spotify and Apple Music song match, additionaly if some of this didn't match i am calculating matching score based on title of song. Some songs don't have the exact same title (extraneous spacing for example) in both services.
