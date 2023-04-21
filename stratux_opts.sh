#!/bin/bash
# V1.3 by Stefan Fischer 2023-04-17
# idle pwr usage for rpi 3B  230 mA
# idle pwr usage for rpi 3B+ 450 mA

function fil_bck {
  if [ "$1" != "" ] && [ -f "$1" ]; then
    if [ "$2" != "" ]; then _fil="$1.$2"; else _fil="$1.old"; fi
    cp "$1" "$_fil"
  fi
}

function setup_swinst {
  apt-get -qy update
  apt-get -qy install cpufrequtils
  return 0
}

function setup_cfg {
  fn="/boot/config.txt"
  tm="# define minimum freq. for energy saving (used by cpu governor)"
  grep -Fq "$tm" "$fn"
  _ret=$?
  if [ "$_ret" != "0" ]; then
#   modify config file only once, by checking tm entry
    fil_bck "$fn" "$bckext"
    echo " " >> $fn
    echo "# Disable the ACT and PWR LED (save energy)" >> $fn
    echo "dtparam=act_led_trigger=none" >> $fn
    echo "dtparam=act_led_activelow=off" >> $fn
    echo "dtparam=pwr_led_trigger=none" >> $fn
    echo "dtparam=pwr_led_activelow=off" >> $fn
    echo "$tm" >> $fn
    echo "# use turbo speed for 20sec to speed up boot process" >> $fn
    echo "initial_turbo=20" >> $fn
    echo "force_turbo=0" >> $fn
    echo "arm_freq_min=250" >> $fn
    echo "core_freq_min=100" >> $fn
    echo "sdram_freq_min=150" >> $fn
    echo "over_voltage_min=0" >> $fn
    echo " " >> $fn
    echo "# Disable Bluetooth" >> $fn
    echo "dtoverlay=pi3-disable-bt" >> $fn
    echo " " >> $fn
    echo "hdmi_blanking=2" >> $fn
    echo "#dtoverlay=gpio-fan,gpiopin=17,temp=65000" >> $fn
  fi
  return 0
}

function disable_svcfil {
  systemctl disable $snam.service
  _ret=$?
  return $_ret
}

function setup_svcfil {
# create service file for automatic startup
  fil="/lib/systemd/system/$snam.service"
  cat <<EOF > "$fil"
[Unit]
Description=$snam

[Service]
Type=oneshot
WorkingDirectory=/usr/local/sbin
ExecStart=/usr/local/sbin/$snam start

[Install]
WantedBy=multi-user.target
EOF
  chmod 644 "$fil"

  systemctl daemon-reload
  systemctl enable $snam.service
  _ret=$?
  return $_ret
}

function disable_bt {
# will save: ~10mA for Blutooth
  systemctl disable hciuart.service
  systemctl disable bluealsa.service
  systemctl disable bluetooth.service
  _ret=$?
  return $_ret
}

function enable_bt {
  systemctl enable  hciuart.service
  systemctl enable  bluealsa.service
  systemctl enable  bluetooth.service
  _ret=$?
  return $_ret
}

function enable_pwrsave {
# enable pwr save, LEDs off, HDMI port off, set cpu to lower freq
# will save: ~5mA per LED and ~25mA HDMI
  _ret=0
  
  if [ "$1" == "" ] || [ "$1" == "led" ]; then
    echo 0 | tee /sys/class/leds/ACT/brightness > /dev/null
    echo 0 | tee /sys/class/leds/PWR/brightness > /dev/null
  fi
  
  if [ "$1" == "" ] || [ "$1" == "hdmi" ]; then
    /usr/bin/tvservice -o > /dev/null
    _ret=$?
  fi
  
  if [ "$1" == "" ] || [ "$1" == "eth" ]; then
    ifconfig eth0 down
    _ret=$?
  fi
  
  if [ "$1" == "" ] || [ "$1" == "gov" ]; then
    /usr/bin/cpufreq-set -g powersave
    _ret=$?
  fi
  
  return $_ret
}

function disable_pwrsave {
# disable pwr save
  _ret=0
  
  if [ "$1" == "" ] || [ "$1" == "led" ]; then
    echo 1 | tee /sys/class/leds/ACT/brightness > /dev/null
    echo 1 | tee /sys/class/leds/PWR/brightness > /dev/null
  fi

  if [ "$1" == "" ] || [ "$1" == "hdmi" ]; then
    /usr/bin/tvservice -p > /dev/null
    _ret=$?
  fi
  
  if [ "$1" == "" ] || [ "$1" == "eth" ]; then
    ifconfig eth0 up
    _ret=$?
  fi
  
  if [ "$1" == "" ] || [ "$1" == "gov" ]; then
    /usr/bin/cpufreq-set -g performance
    _ret=$?
  fi
  
  return $_ret
}

snam="${0##*/}"
bckext=`date +"%Y%m%d%H%M%S"`
ret=0

case "$1" in
  setup)
    if [ "$1" == "" ] || [ "$1" == "sw" ]; then
      setup_swinst "$2"
      ret=$?
    fi
    
    if [ "$1" == "" ] || [ "$1" == "svc" ]; then
      setup_svcfil "$2"
      ret=$?
    fi
    
    if [ "$1" == "" ] || [ "$1" == "bt" ]; then
      disable_bt "$2"
      ret=$?
    fi
    
    if [ "$1" == "" ] || [ "$1" == "cfg" ]; then
      setup_cfg "$2"
      ret=$?
    fi
    ;;
  remove)
    disable_svcfil
    enable_bt
    disable_pwrsave
    ;;
  start)
    enable_pwrsave "$2"
    ret=$?
    ;;
  stop)
    disable_pwrsave "$2"
    ret=$?
    ;;
  status)
    /usr/bin/tvservice -s
    /usr/bin/cpufreq-info "$2"
    ret=$?
    ;;
  *)
  echo "Usage: $snam start | stop | status | setup [sw|svc|bt|cfg] | remove"
  echo "  setup or remove option can only be run, if stratux filesystem is writeable"
esac

exit $ret
