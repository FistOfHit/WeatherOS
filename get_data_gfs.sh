#!/bin/bash

URL="ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/gfs/prod"

var_year=2019
var_month=01
var_day=22

YEAR=$var_year
MONTH=$var_month
DAY=$var_day

DATA_DIR="${YEAR}_${MONTH}_${DAY}"

echo -e "\n Downloading files into $DATA_DIR directory, forecast starting from $DAY \n"

mkdir $DATA_DIR
cd $DATA_DIR

for starthour in 00
do

	for hour in {0..24}
	do


		if (( hour < 10 ))
		then
			axel -a ${URL}/gfs.${YEAR}${MONTH}${DAY}${starthour}/gfs.t${starthour}z.pgrb2.0p25.f00${hour}
			echo -e "\n $hour hour file downloaded \n"
			continue
		fi


		if (( 10 <= hour )) && (( hour < 100 ))
		then
    	axel -a ${URL}/gfs.${YEAR}${MONTH}${DAY}${starthour}/gfs.t${starthour}z.pgrb2.0p25.f0${hour}
			echo -e "\n $hour hour file downloaded \n"
			continue
    fi


	done

	echo -e "\n PRESSURE LEVEL files for $DAY$starthour downloaded \n"
	cd ..

done
