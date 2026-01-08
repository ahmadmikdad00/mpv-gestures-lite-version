# mpv-gestures-lite-version
Touchscreen and mouse gestures for mpv.

Supports seeking via horizontal swiping and volume via vertical swiping and speed control via click-n-drag mid mouse button and move to left for slower and right for faster.

Move gestures.lua to mpv configuration folder `C:\users\USERNAME\AppData\Roaming\mpv.net\scripts` create scripts folder if it doesn't exist.
Then you need to set `no-window-dragging` in your `mpv.conf` for this script to work.

set this for support seeking via horizontal touchpad gestures in your `input.conf`
```
Wheel_Right  no-osd seek  -1              # Seek Forward
Wheel_Left  no-osd seek  1                # Seek Backward
```
