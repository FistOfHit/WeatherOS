#!/bin/bash

# Bash script for completely automating the forecast process for the current day (Starts at midnight last
# night and runs forecast up to midnight tonight)

cat <<"EOF"
                                __          __  _                            _
                                 \ \        / / | |                          | |
                                  \ \  /\  / /__| | ___ ___  _ __ ___   ___  | |_ ___
                                   \ \/  \/ / _ \ |/ __/ _ \| '_ ` _ \ / _ \ | __/ _ \
                                    \  /\  /  __/ | (_| (_) | | | | | |  __/ | || (_) | _ _
                                     \/  \/ \___|_|\___\___/|_|_|_| |_|\___|  \__\___(_|_|_)

                                      _   _                   _     __                             _   _
                                     | | (_)                 | |   / _|                           | | (_)
  ______    ___  _ __   ___ _ __ __ _| |_ _  ___  _ __   __ _| |  | |_ ___  _ __ ___  ___ __ _ ___| |_ _ _ __   __ _   ______
 |______|  / _ \| '_ \ / _ \ '__/ _` | __| |/ _ \| '_ \ / _` | |  |  _/ _ \| '__/ _ \/ __/ _` / __| __| | '_ \ / _` | |______|
          | (_) | |_) |  __/ | | (_| | |_| | (_) | | | | (_| | |  | || (_) | | |  __/ (_| (_| \__ \ |_| | | | | (_| |
           \___/| .__/ \___|_|  \__,_|\__|_|\___/|_| |_|\__,_|_|  |_| \___/|_|  \___|\___\__,_|___/\__|_|_| |_|\__, |
                | |                                                                                             __/ |
                |_|                                                                                            |___/


(427920486974657368)
EOF


# Domain selection
cd ./WPS
echo "Do you to run a forecast over a custom location? Select '1' for yes or '2' for no. (Default is UK mainland)"
select custom_flag in "Yes" "No";
do
	case $custom_flag in
		Yes ) read -p 'Domain Central latitude: ' centre_lat

		      centre_lat=$( bc <<< "$centre_lat + 0" )

	              while (( $(echo "$centre_lat >= 90" | bc -l) || $(echo "$centre_lat <= -90" | bc -l) ));
	 	      do

                          echo "Latitude cannot be outside +- 90deg. Please input Latitude correctly."
			  read -p 'Domain Central latitude: ' centre_lat
      			  centre_lat=$( bc <<< "$centre_lat + 0" )

                      done

                      if (( $(echo "$centre_lat <= 25" | bc -l) && $(echo "$centre_lat >= -25" | bc -l) ));
                      then

                          sed -i "s/map_proj = .*/map_proj = 'mercator',/" namelist.wps

                      elif (( $(echo "$centre_lat <= 70" | bc -l) && $(echo "$centre_lat >= -70" | bc -l) ));
                      then

                          sed -i "s/map_proj = .*/map_proj = 'lambert',/" namelist.wps

                      else

                          echo "Forecasts at latitudes outside +-70deg are not reccomended with this system. Do you wish to proceed anyway? Select '1' for yes or '2' for no."

			  select lat_flag in "Yes" "No";
                          do
                              case $lat_flag in
                                  Yes ) sed -i "s/map_proj = .*/map_proj = 'mercator',/" namelist.wps
                                        break;;
                                  No ) echo "Please enter domain details again. Exiting" && exit 1
                                       break;;
                                  * ) echo "Please select '1' for yes or '2' for no"
                              esac
                          done
                      fi

		      read -p 'Domain Central longitude: ' centre_lon
		      read -p 'Grid box size (km) ' box_size
		      read -p 'Num boxes in x (west-east): ' num_x
		      read -p 'Num boxes in y (north-south): ' num_y

		      sed -i "s/ref_lat = .*/ref_lat = $centre_lat,/" namelist.wps
		      sed -i "s/ref_lon = .*/ref_lon = $centre_lon,/" namelist.wps
	              sed -i "s/stand_lon = .*/stand_lon = $centre_lon,/" namelist.wps
		      sed -i "s/dx = .*/dx = $box_size,/" namelist.wps
		      sed -i "s/dy = .*/dy = $box_size,/" namelist.wps
		      sed -i "s/e_we = .*/e_we = $num_x,/" namelist.wps
		      sed -i "s/e_sn = .*/e_sn = $num_y,/" namelist.wps
		      break;;

		No ) cp namelist.wps.default namelist.wps
		     break;;

		* ) echo "Please select '1' for yes or '2' for no"
	esac
done
cd ../


# Auto-detect current date for start of forecast and calculate end date
start_year=$(date "+%Y")
start_month=$(date "+%m")
start_day=$(date "+%d")

end_year=$(date --date="$start_year-$start_month-$start_day 00:00:00 UTC +24 hours" +"%Y")
end_month=$(date --date="$start_year-$start_month-$start_day 00:00:00 UTC +24 hours" +"%m")
end_day=$(date --date="$start_year-$start_month-$start_day 00:00:00 UTC +24 hours" +"%d")


# Easy to find directory for GFS data
GFS_DIR="${start_year}_${start_month}_${start_day}"


cd ./DATA
# Set variables in data downloading script and run
sed -i "s/var_year=.*/var_year=$start_year/" get_data_gfs.sh
sed -i "s/var_month=.*/var_month=$start_month/" get_data_gfs.sh
sed -i "s/var_day=.*/var_day=$start_day/" get_data_gfs.sh

printf "\n Downloading GFS data for ${GFS_DIR} (24 hours of data) \n"
bash get_data_gfs.sh
printf "\n GFS data finished downloading \n"


cd ../WPS
# Decompress the downloaded data and prepare for interpolation
ln -sf ungrib/Variable_Tables/Vtable.GFS Vtable    # Linking relevant variable table
./link_grib.csh ../DATA/$GFS_DIR/gfs*    # Linking in all GFS data files


# Assigning date variables in namelist
sed -i "s/start_date.*/start_date = '${start_year}-${start_month}-${start_day}_00:00:00',/" namelist.wps
sed -i "s/end_date.*/end_date = '${end_year}-${end_month}-${end_day}_00:00:00',/" namelist.wps


printf "\n Decompressing GFS data (takes a while...) \n"
./ungrib.exe >& ungrib_outputs.txt


# Check for success
end_line=$(tail -1 ungrib.log)
        if [[ $end_line = *"Successful"* ]];
        then
		printf "\n GFS data decompressed successfully \n"
        else
                printf "\n ERROR!!! - ungrib.exe NOT successfuly terminated - check ungrib.log in WPS directory for info \n"
		exit 1
        fi


# Remove files not needed anymore
rm GRIBFILE*
rm -r ../DATA/$GFS_DIR


# Create domain over NordZeeWind farm
printf "\n Creating domain of interest \n"
mpirun -np 4 ./geogrid.exe >& geogrid_outputs.txt
end_line=$(tail -1 geogrid.log.0000)
if [[ $end_line = *"Success"* ]];
then
	printf "\n Domain created \n"
else
        printf "\n ERROR!!! - geogrid.exe NOT successfully terminated - Check geogrid_log and geogrid_error files in WPS directory for info \n"
	exit 1
fi


# Interpolate data horizontally
printf "\n Interpolating data horizontally onto domain \n"
mpirun -np 4 ./metgrid.exe >& metgrid_outputs.txt


# Check for success
end_line=$(tail -1 metgrid.log.0000)
if [[ $end_line = *"Success"* ]];
then
	printf "\n Data horizontally interpolated onto domain \n"
else
        printf "\n ERROR!!! - metgrid.exe NOT successfully terminated - Check metgrid.log and metgrid_error files in WPS directory for info \n"
	exit 1
fi


# Removing more uneeded files
rm PLEVS*


cd ../WRF/run
# Performin horizontal interpolation and setup for micrphys schemes
ln -sf ../../WPS/met_em* .    # Link in the horizontally interpolated files


# Assing all relevant variables in namelist for model
sed -i "s/start_year .*/start_year = $start_year,/" namelist.input
sed -i "s/start_month .*/start_month = $start_month,/" namelist.input
sed -i "s/start_day .*/start_day = $start_day,/" namelist.input
sed -i "s/start_hour .*/start_hour = 00,/" namelist.input
sed -i "s/end_year .*/end_year = $end_year,/" namelist.input
sed -i "s/end_month .*/end_month = $end_month,/" namelist.input
sed -i "s/end_day .*/end_day = $end_day,/" namelist.input
sed -i "s/end_hour .*/end_hour = 00,/" namelist.input


# Must be very careful with digital filter dates
dfi_backyear=$(date --date="$start_year-$start_month-$start_day 00:00:00 UTC -4 hours" +"%Y")
dfi_backmonth=$(date --date="$start_year-$start_month-$start_day 00:00:00 UTC -4 hours" +"%m")
dfi_backday=$(date --date="$start_year-$start_month-$start_day 00:00:00 UTC -4 hours" +"%d")

sed -i "s/dfi_bckstop_year = .*/dfi_bckstop_year = $dfi_backyear,/" namelist.input
sed -i "s/dfi_bckstop_month =.*/dfi_bckstop_month = $dfi_backmonth,/" namelist.input
sed -i "s/dfi_bckstop_day =.*/dfi_bckstop_day = $dfi_backday,/" namelist.input

dfi_fwdyear=$(date --date="$start_year-$start_month-$start_day 00:00:00 UTC +2 hours" +"%Y")
dfi_fwdmonth=$(date --date="$start_year-$start_month-$start_day 00:00:00 UTC +2 hours" +"%m")
dfi_fwdday=$(date --date="$start_year-$start_month-$start_day 00:00:00 UTC +2 hours" +"%d")

sed -i "s/dfi_fwdstop_year = .*/dfi_fwdstop_year = $dfi_fwdyear,/" namelist.input
sed -i "s/dfi_fwdstop_month =.*/dfi_fwdstop_month = $dfi_fwdmonth,/" namelist.input
sed -i "s/dfi_fwdstop_day =.*/dfi_fwdstop_day = $dfi_fwdday,/" namelist.input


# Perform interpolation and setup
printf "\n Interpolating data vertically onto domain and creating BC's \n"
mpirun -np 5 ./real.exe >& real_outputs.txt


# Check for success
end_line=$(tail -1 rsl.error.0000)
if [[ $end_line = *"SUCCESS"* ]];
then
        printf "\n Data vertically interpolated, BC's created \n"
else
        printf "\n ERROR!!! - real.exe NOT successfully terminated - Check rsl.error files in WRF/run directory for info \n"
	exit 1
fi


# Removing uneccessary files
rm met_em* ../../WPS/met_em*


# Running the model finally
printf "\n Running model now \n"
mpirun -np 5 ./wrf.exe >& wrf_outputs.txt


# Check for success
end_line=$(tail -1 rsl.error.0000)
if [[ $end_line = *"SUCCESS"* ]];
then
        printf "\n Model finished running \n"
else
        printf "\n Model NOT successfully terminated - Check rsl.error files in WRF/run for info \n"
	exit 1
fi


# Remove any excess from model
rm wrfout*


cd ../../


# If all successful so far...
cat <<"EOF"
  ___  _  _          _    _                     __                             _      __
 |__ \| || |        | |  | |                   / _|                           | |    / _|          _
    ) | || |_ ______| |__| | ___  _   _ _ __  | |_ ___  _ __ ___  ___ __ _ ___| |_  | |_ ___  _ __(_)
   / /|__   _|______|  __  |/ _ \| | | | '__| |  _/ _ \| '__/ _ \/ __/ _` / __| __| |  _/ _ \| '__|
  / /_   | |        | |  | | (_) | |_| | |    | || (_) | | |  __/ (_| (_| \__ \ |_  | || (_) | |   _
 |____|  |_|        |_|  |_|\___/ \__,_|_|    |_| \___/|_|  \___|\___\__,_|___/\__| |_| \___/|_|  (_)

EOF

printf "\n $GFS_DIR \n"

cat <<"EOF"
                            _      _       _ _ _
                           | |    | |     | | | |
   ___ ___  _ __ ___  _ __ | | ___| |_ ___| | | |
  / __/ _ \| '_ ` _ \| '_ \| |/ _ \ __/ _ \ | | |
 | (_| (_) | | | | | | |_) | |  __/ ||  __/_|_|_|
  \___\___/|_| |_| |_| .__/|_|\___|\__\___(_|_|_)
                     | |
                     |_|

EOF

cd ../
