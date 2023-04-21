# stratux_opts

shell script for setup and power usage optimizazion for stratux on rpi platform (rpi 3B)

- script will automatically start at boot time
- switch hdmi port off, to reduce power consumption (will save ~25mA)
- switch activity and power LED off (will save ~5mA per LED)
- disable Blutooth services (will save ~10mA)
- power governor (cpufrequtils) will throttle rpi cores during normal operation
- during bootphase rpi will run at maximum speed for 20secs, to speed up the boot process 

Benefit:
My stratux system has doubled the operation time from 1:15h to 2:30h\

My config:
- stratux Europe Edition 1.6r1-eu028
- battery 6000mAh
- 2x SDR nano three
- usb gps
- AHRS GY-91
- rpi 3B
- 1x fan connected to 5V 

script functions:
- setup  (install required additional sw packages, modify config file and automatic startup at boot process)
- start  (power optimization)
- stop   (power optimization)
- status (shows hdmi, pwr governor statistics)

~~~bash
state 0x120000 [TV is off]

analyzing CPU 0-3:
  ...
  hardware limits: 600 MHz - 900 MHz
  available frequency steps: 600 MHz, 700 MHz, 800 MHz, 900 MHz
  available cpufreq governor: conservative, ondemand, userspace, powersave, performance, schedutil
  current policy: frequency should be within 600 MHz and 900 MHz.
                  The governor "powersave" may decide which speed to use
                  within this range.
  current CPU frequency is 600 MHz (asserted by call to hardware).
  cpufreq stats: 600 MHz:99.97%, 700 MHz:0.00%, 800 MHz:0.00%, 900 MHz:0.03%  (2)
~~~

Above statistics will show, that rpi 3B cores has run nearly 100% at 600MHz, to save energy. 

## login and set root password

ssh to your stratux system and set root password.

~~~bash
fromyourpc:# ssh pi@stratux.local

pi:# sudo passwd
pi:# su
root:#
~~~

## installation

required:
- configured and running stratux system
- set filesystem to writable (pls. see below)
- stratux system can access internet (for downloading extra packages)

rpi login as root required (needed only once):

~~~bash
root:# cd /usr/local/sbin
root:# wget -qN https://raw.githubusercontent.com/rudiratlos/stratux/master/stratux_opts
root:# chmod +x stratux_opts
root:# apt-get update
root:# apt-get upgrade
root:# ./stratux_opts setup
~~~

setup will do the following:
- install all required packages
- setting parameters in /boot/config.txt
- backup old config file with date extension (YYYYMMDDhhmmss)
- create service file for automatic startup
- enable automatic startup

After the setup phase tasks:
- set filesystem to readonly (pls. see below)
- reboot stratux
- finished

## set filesystem to read only / writable

go to stratux web gui setup page and locate Diagnostics section\
Persistent logging: Write logs to micro SD instead of RAM:\
- writeable: toggle switch ON  (blue)
- read only: toggle switch OFF (white)

## GPIO controlled fan

Using a circuit like this, will control the fan by temperature hysteresis.\
Just use the gpio-fan overlay in /boot/config.txt e.g.
~~~bash
dtoverlay=gpio-fan,gpiopin=17,temp=65000
~~~
This will switch the fan on, if temperature is above 65 degrees.\
GPIO17 (Pin11) will be used for control.
The fan will on run, if needed. This will save battery power.

![schematic](./img/stratux_fan.png)
