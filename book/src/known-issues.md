# Known Issues

This section describes know issues and how to fix them.

## Kernel boot hangs after flashing

Sometimes, after flashing a fresh image onto the SD card, the boot hangs. If you have a screen connected, it might go blank about 14 s in to the kernel boot. If you have UART communication with the RPi, you'll see no more logs after

```
[   15.201106] vc4_hvs fe400000.hvs: Couldn't get core clock
[   15.212233] platform fef05700.hdmi: deferred probe pending: (reason unknown)
```

### Solution

Not yet sure why this happens but re-flashing the image onto the SD card fixes it.
