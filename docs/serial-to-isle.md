# Serial to Isle

Rough notes for connecting to Isle UART using screen. You could use PuTTY on Windows. By default, Isle UART uses 115200 baud 8N1.

## Identify Device

Identify the device name on **Linux**:

```shell
ls /dev/ttyUSB*
```

Identify the device name on **macOS**:

```shell
ls /dev/cu.usbserial-*
```

Depending on your board's UART IC and driver the device name may vary.

Some boards, such as the Nexys Video, have a dedicated USB port for UART, so ensure you connect that via USB before attempting to use the UART. On Linux, you'll see multiple ttyUSB with the Nexys Video connected for programming and UART, if you connect the UART cable after the programming cable the correct device should be `/dev/ttyUSB2`.

## Connect with Screen

Then use **screen** to connect, replacing "foo" with the correct device name.

```
screen /dev/foo 115200
```

To exit screen, press Ctrl-a then type ":quit" and press return.

_NB. You won't be able to program the ULX3S while screen is connected to the UART._

## Delete

Isle software supports backspace (0x08) and delete (0x7F), but not all terminals are configured for this. If backspace and delete don't work as expected, check your terminal docs.

On macOS using screen, I had to add the following to `~/.screenrc` to get backspace and delete:

```
# backspace mapping
bindkey "^?" stuff ^H

# delete mapping (0x7F is 0177 in octal)
bindkey "\033[3~" stuff \177
```
