# mpv-gestures-lite-version
Touchscreen and mouse gestures for mpv.

Supports click/touch for play/pause and seeking via horizontal swiping and volume via vertical swiping and speed control via click-n-drag mid mouse button and move to left for slower and right for faster.

Move gestures.lua to mpv configuration folder `C:\users\USERNAME\AppData\Roaming\mpv.net\scripts` create scripts folder if it doesn't exist.
Then you need to set `no-window-dragging` in your `mpv.conf` for this script to work.

set this config in your `input.conf` for support seeking via horizontal touchpad gestures.
```
Wheel_Right  no-osd seek  -1              # Seek Forward
Wheel_Left  no-osd seek  1                # Seek Backward
```
