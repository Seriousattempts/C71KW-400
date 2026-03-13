# C71KW-400
## DirecTv android 11 box model C71KW-400
`armv7`

`cortex-a53`

`VideoCore V HW (V3D-520)`

`OpenGL ES 3.1`

`Broadcom Brahma-B15 cpu`

## Turn on debugging mode on a fresh device:

- Press - on your remote
- Go to device preferences
- About
- Tap OS Build until you get developer mode
- Go back a screen before about
- Go to developer options
- Enable debugging
- Grab the IP from About, Status (usually a 192 ip within there)
- With windows command line opened in an extracted adb folder type `adb connect 192.###)

## To install apps via adb 

In windows command line after connecting:
- adb shell settings put global verifier_verify_adb_installs 0
- adb push app.apk /data/local/tmp/
- adb shell pm install -r -d -g /data/local/tmp/app.apk

## To run commands in termux through adb
Requires termux installed
- adb shell
- run-as com.termux
- /data/data/com.termux/files/usr/bin/bash -l
- export PATH=/data/data/com.termux/files/usr/bin:$PATH
- pkg update -y
- pkg upgrade -y

### x86 wine script shown in the video was ran in termux with the following:
Requires termux, termux:x11, termux:widget installed
- pkg install dos2unix -y #script was created on windows and needed to be modified
- termux-setup-storage
- cp ~/storage/downloads/open.sh ~/open.sh
- dos2unix ~/open.sh
- bash ~/open.sh
