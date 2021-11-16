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

Once Chrono has connected with a server it will allow you to get the current time with.

Note that the builtin dt can sometimes be unreliable currently do to possible vsync issues so you should use socket.gettime() to build your own dt. An example of this is included in the example script. A short example is also included below.

```
function init(self)
	self.last_time = socket.gettime()
end

function update(self, dt)
	local dt_actual = socket.gettime() - self.last_time
	self.last_time = socket.gettime()
	chrono.update(dt_actual)
end
```

You may want to keep the total time updated in your main.script and then allow other scripts to reference chrono to get the time.

Using ```chrono.update(dt)``` ever can still be a liability if the user is able to change their system time while using socket.gettime() / their system has vsync issues and goes too fast. So if you really want to ensure time is respected you will want to sync time and then get time after every important time based action (while displayed timers could still be based on the dt generated versions). This way you can display a somewhat relaible timer, but still have actions require direct updates to remote time differences.


```
chrono.get_time()
```

Chrono will not constantly connect to time servers, but use the dt passed to it to keep the current time up to date. Therefore you should always resync time when your Defold app regains window focus.

```
chrono.sync_time()
```

Do not constantly sync time with a remote server. Only sync when absolutely necessary such as before allowing time based actions (daily resets / energy regeneration).

Defold has built in ability to check if Window has gained focus. There is also DefWindow if you need multiple window callbacks.
