# Chrono
Reliable server based time for Defold

Chrono enables you to get a server timestamp from Google's NTP severs via a socket connection, and from TimeStampNow.com for HTML5 builds. Use Chrono if you want to easily use a server based timestamp (not trust local device time) but don't want to run your own server for timestamps.

## Installation
You can use Chrono in your own project by adding this project as a [Defold library dependency](http://www.defold.com/manuals/libraries/). Open your game.project file and in the dependencies field under project add:

	https://github.com/subsoap/chrono/archive/master.zip
  
Once added, you must require the main Lua module in scripts via

```
local chrono = require("chrono.chrono")
```

## Usage
Chrono will auto-init once the first update is ran. You must include

```
chrono.update(dt)
```

within the script including Chrono to keep its time up to date.

Once Chrono has connected with a server it will allow you to get the current time with

```
chrono.get_time()
```

Chrono will not constantly connect to time servers, but use the dt passed to it to keep the current time up to date. Therefore you should always resync time when your Defold app regains window focus.

```
chrono.sync_time()
```

Defold has built in ability to check if Window has gained focus. There is also DefWindow if you need multiple window callbacks.
