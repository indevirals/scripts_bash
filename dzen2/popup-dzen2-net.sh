#!/bin/bash
source ./dzen2.conf
$(kill_popup)
net() {
_ip=$(ip addr show $1 | grep -oP 'inet \K\S[0-9.]+')
  if [[ $1 == wl* ]]; then
    essid="^pa(175)${fg2}essid: ${fg1}$(iw dev $1 info | awk '/ssid/{print $2}')"
  fi
  echo "^pa(10)$fg2${1}: ${fg1}${_ip}${essid}^p()"
}
pub() {
  _ip=$(curl -s ipinfo.io | jq -r -j '.ip')
  _flag=$(curl -s ipinfo.io | jq -r -j '.country')
  if [[ -n $_ip ]]; then 
    echo "^pa(10)${fg2}public: ${fg1}${_ip}^pa(175)${fg2}country: ${fg1}${_flag}^p()"
  else
    echo "^pa(10)${fg2}public: ${fg1}not connected^p()"
  fi
}
ctrl() {
  _ip=$(ip addr show tun0 | grep -oP 'inet \K\S[0-9.]+')
  if [[ -z $_ip ]]; then
    echo "^pa(10)${fg2}network: ${fg1}vpn not connected^p()"
  else
    echo "^pa(10)${fg2}network: ${fg4}vpn connected^p()"
  fi
}
(echo $(ctrl)
while :; do
  echo "$(net $1)
  $(pub)
  " > $tmp
  cat $tmp
sleep 5
done) | dzen2 -title-name "$title" -p -y 24 -x -300 -l 3 -w 300 -ta l -fn "$font" -e "$exp2"
