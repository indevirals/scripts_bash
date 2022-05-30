#!/bin/bash
cd $(cd $(dirname $0) && pwd)
source ./dzen2.conf
_usb(){
arr_usb=($(lsusb 2>/dev/null | awk '{print $2":"$4}'))
num=0
for i in ${!arr_usb[*]}; do
  text1=$(lsusb -s ${arr_usb[$i]} -v 2>/dev/null)
  if [[ -n $(printf '%s\n' "$text1" | grep "iInterface" | grep "MTP") ]]; then
    ((num++))
  elif [[ -n $(printf '%s\n' "$text1" | grep "bInterfaceClass" | grep "Mass") ]]; then
    ((num++))
  fi 
done
if [[ $num -ne 0 ]]; then 
  echo " ^ca(1,./${prefix}usb.sh) ${fg2}usb:${fg1}$num ^ca()"
fi
}
_mus(){
#if [[ -n `timeout 1 mpc | grep playing` || `mpc -p $mpd_port -h $mpd_host | grep playing` ]];then
if [[ -n $(pgrep ncmpcpp) ]]; then
  if [[ -n $(mpc | grep playing) ]];then  
#    export MPD_HOST="$mpd_host"
#    export MPD_PORT="$mpd_port"
  title=$(mpc current -f %title%)
  artist=$(mpc current -f %artist%)
  file=$(mpc current -f %file%)
  if [[ -n $artist ]]; then
    echo "^ca(1,./${prefix}mpd.sh $MPD_HOST $MPD_PORT)$fg3${artist::40} $fg2- $fg1${title::40} ^ca()"
  elif [[ -z $title && -z $artist ]]; then
    echo "^ca(1,./${prefix}mpd.sh $MPD_HOST $MPD_PORT)$fg1${file::40} ^ca()"
  else
    echo "^ca(1,./${prefix}mpd.sh $MPD_HOST $MPD_PORT)$fg1${title::40} ^ca()"
  fi
  else 
    echo " ^ca(1, pkill -f ncmpcpp) ${fg2}ncmpc:${fg1}stoped ^ca()"
  fi
fi
}
#_bri(){
#bri=$(xbacklight | cut -f1 -d.)
#if (( $bri <= "95" )); then
#  echo "^ca(1,./${prefix}bri.sh) ${fg2}bri:${fg1}$bri ^ca()"
#fi
#}
_vol(){
if [[ -z $(amixer get Master | awk '$0~/%/{print $6}' | grep off) ]]; then
  vol=$(amixer get Master | awk '$0~/%/{print $5}' | tr -d '[]%' | head -1 )
  echo "^ca(1,./${prefix}vol.sh) ${fg2}vol:${fg1}$vol ^ca()"
else
  echo "^ca(1,./${prefix}vol.sh) ${fg2}vol:${fg4}!mute ^ca()"
fi
}
#_bat(){
#bat=(`cat /sys/class/power_supply/BAT1/uevent | sed "s/POWER.*=//"`)
#if [ ${bat[2]} == "Discharging" ]; then
#  if (( ${bat[12]} >= 25 )); then
#    echo " ${fg2}bat:${fg1}${bat[12]}${fc0} "
#  elif (( ${bat[12]} < 25 )); then
#    echo " ${fg2}bat:${fg4}!${bat[12]}${fc0} "
#  fi
#else
#  if ((  ${bat[12]} <= 90 )); then
#    echo " ${fg2}charge:$fg1${bat[12]}${fc0} "
#  fi
#fi
#}
_net(){
lan_dev=(`ls /sys/class/net/`)
lan_st=(`cat /sys/class/net/*/operstate`)
for i in ${!lan_dev[*]}; do
  if [[ ${lan_st[$i]} == "up" ]]; then
  lan_ip=$(ip addr show ${lan_dev[$i]} | grep -oP 'inet \K\S[0-9.]+')
    if [[ -n $lan_ip ]]; then
      echo "^ca(1,./${prefix}net.sh ${lan_dev[$i]}) ${fg2}net:${fg1}${lan_dev[$i]} ^ca()"
    fi
  fi
done
}
_cpu(){
_cpu=$(echo `ps -A -o pcpu | tail -n+2 | paste -sd+ | bc` / 4 | bc )
echo " ${fg2}cpu:${fg1}$_cpu "
}
_mem(){
_mem=$(free | grep Mem | awk '{ printf(int($3/$2 * 100)) }')
echo " ${fg2}mem:${fg1}$_mem "
}
_date(){
  echo "^ca(1,./${prefix}cal.sh) ${fg1}$(date "+%H:%M")${fc0} ^ca()" 
}
_lang(){
if [[ $(skb -1) == Eng ]]; then 
  echo " ${bg1}${fg1} en "
else
  echo " ${bg1}${fg1} ru "
fi
}
while true; do
  echo "$(_mus)$(_usb)$(_net)$(_cpu)$(_mem)$(_vol)$(_date)$(_lang)"
  sleep 1
done | dzen2 -ta r -w 1000 -x -1000 -y 0 -h 25 -fn "$font" -e "$exp1"
