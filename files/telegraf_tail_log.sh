#!/bin/bash
NOW=$(date '+%s')

BAT=''
if [ -x /usr/bin/acpi ] ; then
  BAT="{\"tag\":\"battery\",\"time\":${NOW},\"percent\":$(acpi | grep 'y 0' | sed -e 's/^.*, \([1-9][-0-9]*\)%.*$/\1/')}"
fi

SCTL=/usr/sbin/smartctl
NVME=''
for ii in /dev/nvme? ; do
  DEV=$(echo $ii | sed -e 's/.*\/\(.*\)$/\1/')
  TEM=$($SCTL -A $ii | grep Temperature: | awk '{ print $2; }')
  POH=$($SCTL -A $ii | grep 'Power On Hours:' | awk '{ print $4; }' | sed -e 's/,//')
  ERR=$($SCTL -A $ii | grep 'Media and Data Integrity Errors:' | awk '{ print $6; }' | sed -e 's/,//')
  [ "$NVME" != '' ] && NVME="${NVME},"
  NVME="${NVME}{\"tag\":\"${DEV}\",\"time\":${NOW},\"celcius\":${TEM},\"hours\":${POH},\"errors\":${ERR}}"
done

SATA=''
for ii in /dev/sd? ; do
  DEV=$(echo $ii | sed -e 's/.*\/\(.*\)$/\1/')
  TEM=$($SCTL -A $ii | grep Temperature_Celsius | sed -e 's/^.*- *\([1-9][0-9]*\).*$/\1/')
  POH=$($SCTL -A $ii | grep Power_On_Hours | sed -e 's/^.*- *\([1-9][0-9]*\).*$/\1/')
  ERR=$($SCTL -A $ii | grep End-to-End_Error | sed -e 's/^.*- *\([0-9][0-9]*\).*$/\1/')
  [ "$SATA" != '' ] && SATA="${SATA},"
  SATA="${SATA}{\"tag\":\"${DEV}\",\"time\":${NOW},\"celcius\":${TEM},\"hours\":${POH},\"errors\":${ERR}}"
done

OUTPUT="$BAT"
if [ "$OUTPUT" != '' ] ; then
  [ "$NVME" != '' ] && OUTPUT="${OUTPUT},$NVME"
elif [ "$NVME" != '' ] ; then
  OUTPUT="$NVME"
fi
if [ "$OUTPUT" != '' ] ; then
  [ "$SATA" != '' ] && OUTPUT="${OUTPUT},$SATA"
elif [ "$SATA" != '' ] ; then
  OUTPUT="$SATA"
fi
printf "[%s%s%s%s]\n" $BAT $NVME $SATA >>/var/log/telegraf/tail.log
