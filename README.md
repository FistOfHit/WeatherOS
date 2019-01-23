<a href="https://imgur.com/8l69u7w"><img src="https://i.imgur.com/SzJJ5oF.png" title="source: imgur.com" /></a>

# WeatherOS

A Virtual machine (NOT a docker container) that comes with WRF-ARW code compiled and ready to use, along with the huge terrestrial data files and some scripts to help automate the not-immediately-clear process of using WRF-ARW software. Also, I've included some other software for visualisation and post-processing that should help! (like zsh+ohmyzsh)

## Requirements and installation ##
- 50GB storage space
- As much RAM as you can get access to 
- As many CPU's as you can get access to
- VirtualBoX 6.0 (or equivalent)

First of all, you'll need to download the VM itself <a href="https://drive.google.com/file/d/18z2hPCsAJHmfv7r1AOwa7DZt1t8BzjXt/view?usp=sharing">here:</a>

To setup, simply import the .ova file from within VirtualBox (File > import appliance) and the rest is self-explanatory. 

## Usage ##

### Running simulations ###
To make life easy for those who just want to play around and run a few small simulations for the current day over the UK, I've included scripts that automate the whole process. For this, you have to:
- Startup the VM
- Open a terminal
- cd Desktop/Build_WRF
- bash run_forecast.sh

It really is as simple as that!

To run custom simulations with different domains, dates, physics options etc. you'll have to learn how to use the WRF-ARW software. Lukcily for you, I've made to sure to include literally everything you should need (WRF-Chem, WRFDA, NCL, netcdf-tools etc.) but you'll need to compile some things yourself. To get familiar with how to use the software, there really is no easy way except to read through the comprehensive user guide they've made <a href="http://www2.mmm.ucar.edu/wrf/users/docs/user_guide_v4/v4.0/contents.html">here:</a>

### Visualisations ###
Panoply, a very easy to use software made by NASA has already been installed on this VM, and you can easily figure out how to use it <a href="https://www.giss.nasa.gov/tools/panoply/">here:</a>. The .nc file containing all the outputs of your simulation will be located in ```/Desktop/Build_WRF/WRF/run``` and will be called "wrf_out_d01_<date>" or something very similar. Simply open this with Panoply (icon in taskbar) and make some amazing animations!
  
Additionally, if you think you can do better manually, I've also included NCL and Grads for you to use, a lot harder to learn but can produce some amazing visuals too.


## Contributing ##
If you want to help improve the VM, update the software, or correct any mistakes I may have made, then feel free to contact me and let me know, I'm open to updating the VM over time (released as V1.0). 

## License ##

MIT license, feel free to use and develop for your own investigations!
