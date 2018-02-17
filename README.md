# Chrono
Reliable server based time for Defold

Chrono enables you to get a server timestamp from Google's NTP severs via a socket connection, and from TimeStampNow.com for HTML5 builds. Use Chrono if you want to easily use a server based timestamp (not trust local device time) but don't want to run your own server for timestamps.

You should always resync time when your Defold app regains window focus.