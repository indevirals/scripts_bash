#!/bin/bash
source ./dzen2.conf
$(kill_popup)
export MPD_HOST=$1
export MPD_PORT=$2
host(){
if [[ $MPD_HOST == $mpd_host ]]; then
  host='MPD (remote)'
else
  host='MPD (local)'
fi
stat="$(mpc | awk NR==2)"
echo -ne "^p(15)$host $stat"
}
ctrl(){
ctrl+="$fg1^ca(1,mpc -q prev)< prev ^ca()"
if [[ -n $(mpc | grep playing) ]];then
  ctrl+="^ca(1,mpc -q toggle ) pause ^ca()"
else
  ctrl+="^ca(1,mpc -q toggle ) start ^ca()"
fi
ctrl+="^ca(1,mpc -q stop && pkill -f $prefix ) stop ^ca()"
if [[ -n $(mpc | grep "random: on") ]]; then
  ctrl+="$fg3^ca(1,mpc -q random off) rand ^ca()$fg1" 
else
  ctrl+="$fg2^ca(1,mpc -q random on) rand ^ca()$fg1" 
fi
ctrl+="^ca(1,mpc -q next) next >^ca()$fc0^p()"
ctrl+="$fg1^p(65)^ca(1,mpc -q volume -10) - ^ca()"
ctrl+="$fg2 vol:$(mpc volume | grep -o '[0-9]*') "
ctrl+="$fg1^ca(1,mpc -q volume +10 ) + ^ca()^p()"
echo -ne "^p(15)$ctrl"
}
seek(){
state=$(mpc | awk NR==2'{print $4}' | grep -o '[0-9]*')
for i in {1..100}; do
  if (( $i < $state )); then
    seek+="^ca(1,mpc -q seek $i%)$fg3^r(4x4)$fc0^ca()"
  elif (( $i == $state )); then
    seek+="$fg1^r(4x8)$fc0"
  else
    seek+="^ca(1,mpc -q seek $i%)$fg2^r(4x4)$fc0^ca()" 
  fi
done
echo -ne "^p(15)$seek"
}
playlist(){
IFS=$'\n' mpc_playlist=($(mpc playlist)) 
for i in ${!mpc_playlist[*]}; do
  if [[ $i == $(($cur - 1)) ]]; then
    playlist+="${fg3}${mpc_playlist[$i]::57}${fc0}\n"
    for num in $(seq $(( $i + 1 ))  $(( $i + 7 ))); do
      playlist+="^p(15)${mpc_playlist[$num]::57}\n"
    done 
  fi
done
echo -ne "^pa(15)$playlist"
}
cover(){
  img="/tmp/cover.png"
  rm -f $img.xpm

  mpc readpicture "$(mpc current -f %file%)" > $img
  if ! file "$img" |grep -qE 'image|bitmap'; then
    mpc albumart "$(mpc current -f %file%)" > $img   
  fi
#  if [ -e "$img" ];then
  convert "$img" -resize 174x174 XPM:$img.xpm
  if ! file "$img" |grep -qE 'image|bitmap'; then
  artist=$(mpc current -f "%artist%")
    album=$(mpc current -f "%album%")
    url="http://ws.audioscrobbler.com/2.0/?method=album.getinfo&api_key=${key_lastfm}&format=json"
    json="$(curl -s --get "${url}" --data-urlencode "artist=$artist" --data-urlencode "album=$album")"
    wget -q $(echo -n "${json}" | jq -j -r '.album.image[2]."#text"') -O $img
    convert "$img" -resize 174x174 XPM:$img.xpm
    #convert $img XPM:$img.xpm
  fi    
  if [ -s $img.xpm ]; then
    pkill -f "${title}-cover"
    echo "^i($img.xpm)" | dzen2 -title-name "${title}-cover" -p -y 24 -x -625 -w 200 -h 204 -ta c -fn "$font" -e "$exp2"
  else
    pkill -f "${title}-cover"
  fi
}
while :; do
declare cur=$(mpc current -f "%position%")
if [[ -n $(mpc | grep "playing\|pause") ]];then
  echo -e "$(host)\n$(ctrl)\n$(seek)\n$(playlist)\n" > $tmp
  cat $tmp
  if [[ $cur != $pos ]]; then  
    pos=$cur; $(cover) &
  fi
else
  $(kill_popup)
fi
sleep 0.5
done | dzen2 -title-name "$title" -u -p -y 24 -x -425 -l 11 -w 425 -ta l -fn "$font" -e "$exp2"
