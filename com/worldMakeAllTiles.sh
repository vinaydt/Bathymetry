#!/bin/bash -x
set -u
echo "`date`: starting com/$0 $@ "
purge
source ../demPaths.sh

if [ "$#" != "0" ] ; then
	echo "usage: `basename $0` "
	echo "  example: `basename $0` "
	exit
fi

# tile size ---INTEGER--- degrees

tileWidth=15
tileHeight=15


# Code bugs and lame shell scripts require tile size to be integer multiple of resolution
#	but resolution in arc seconds can be (somewhat) arbitrary. In other words...
#
# The number of pixels (and hence nodes) must be integer divisor of tile dimension
#	or GMT moans
#
# e.g
#
# 	tile width(deg)*60(min/deg)*60(sec/min) = number of --PIXELS--
#
# 		and check if it is an integer!!!
#
# these resolutions and tile sizes -do- work...
#
# assuming a 15 degree tile width, res = 15 sec = 3600 pixels
# assuming a 15 degree tile width, res = 843.75 sec = 64 pixels
# assuming a 15 degree tile width, res = 439.02439024390244 sec = 123 pixels
#
# However; a 15 degree tile width, res = 53 sec = 1018.867 pixels   !!!
#	does -NOT- work...
#
# res=300		# ETOPO 5 degrees
# res=120		# Smith & Sandwell 1995
# res=30		# SRTM30+

res=15		# SRTM15+

# land and topo directory locations, (temp files are handy to keep around for debugging)

landDir="/geosat2/srtm15_data/land/
topoDir="/geosat2/srtm15_data/topo/



# ---- do NOT change folowing code ---- #

# make log file path absolute, we are changing directories, but want just one log...
if cd "`dirname \"$0\"`"; then
	logFile="`pwd`/`basename -s .sh $0`".log
    cd "$OLDPWD" || exit 1
else
    exit 1
fi
rm -f  $logFile
date > $logFile

echo "building SRTM in	$landDir"				>> $logFile 2>&1
echo "building SRTM_PLUS in	$topoDir"			>> $logFile 2>&1

# build land
landOptions="$res"c" $tileWidth $tileHeight $landDir"
cd land											>> $logFile 2>&1
bash worldMakeAllTiles.sh $landOptions			>> $logFile 2>&1
cd -											>> $logFile 2>&1

# build artic bathymetry
cd bathymetry									>> $logFile 2>&1
bash -x makeIBCAO_V3.sh "$res"c					>> $logFile 2>&1
cd -									 		>> $logFile 2>&1

# add sonar data to predicted bathymetry
cd bathymetry									>> $logFile 2>&1
bash -x worldMakeAllTiles.sh $landDir $topoDir	>> $logFile 2>&1
cd -											>> $logFile 2>&1

echo "Check $logFile for errors"
echo "`date`: finished com/$0 $@ "
