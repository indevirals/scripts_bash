#!/bin/bash
source dzen2.conf
$(kill_popup)
ctrl(){
arr_usb=($(lsusb 2>/dev/null | awk '{print $2":"$4}'))
for i in ${!arr_usb[*]}; do
  text1=$(lsusb -s ${arr_usb[$i]} -v 2>/dev/null)
  if [[ -n $(printf '%s\n' "$text1" | grep "iInterface" | grep "MTP") ]]; then
    ((num++))
    _mtp=$(echo $(printf '%s\n' "$text1" | grep -E "idProduct|idVendor" | awk '{print $3}'))
    mass+="^pa(20)$num: "${_mtp}" ^pa(220)^pa(290)mtp^pa(350)${fc0}^pa()\n"
  elif [[ -n $(printf '%s\n' "$text1" | grep "bInterfaceClass" | grep "Mass") ]]; then
    ((num++))
    _ums=$(echo $(printf '%s\n' "$text1" | grep -E "idProduct|idVendor" | awk '{print $3}'))
    _bcd=$(printf '%s\n' "$text1" | grep "bcdDevice" | awk '{print $2}' | sed -e "s/\.//g")
    _arr_dev=($(udisksctl status | grep " $_bcd "))
    _dev=${_arr_dev[${#_arr_dev[@]}-1]%%/*}
    _arr_label=($(ls /dev | grep $_dev)) 
    for n in ${!_arr_label[*]}; do
      _label="/dev/${_arr_label[$n]}"
      _fs=$(lsblk -dnro FSTYPE $_label)
      if [[ -n $_fs ]];then
        _fm=$(findmnt $_label)
        _size=$(lsblk -dnro SIZE $_label)
        if [[ -z $_fm ]];then
          mass+="^pa(20)$num: "${_ums}" ["${_arr_label[$n]}"]"" ^pa(220)$_size^pa(290)$_fs^pa(350)${fc0}^pa()"
          mass+="${fg1}^ca(1,udisksctl mount -b $_label)mount^ca()${fc0}^pa()\n"
        else
          mass+="^pa(20)$num: "${_ums}" ["${_arr_label[$n]}"]"" ^pa(220)$_size^pa(290)$_fs^pa(350)${fc0}^pa()"
          mass+="${fg1}^ca(1,udisksctl unmount -b $_label)umount^ca()${fc0}^pa()\n"
        fi
      fi
    done
  fi 
done
echo -en "$mass"
}

if [[ -n $(ctrl) ]]; then
line=$(( `ctrl | wc -l` + 1 ))
(echo "^pa(20)name ^pa(220)size ^pa(290)fs ^pa(350)state"
while :; do
  echo -e "$(ctrl)\n" > $tmp
  cat $tmp
  line2=$(( `ctrl | wc -l` + 1 ))
  if [[ $line != $line2 ]]; then
    $(kill_popup)
  fi
sleep 3
done) | dzen2 -title-name "$title" -p -y 24 -x -400 -w 400 -ta l -l $line -fn "$font" -e "$exp2"
fi
