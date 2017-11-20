# ssh -p 22 -i ${private_key} ubuntu@${ip}

set -e

# Start the X server
sudo service lightdm stop
sudo xinit &

echo ""
echo "************************************************************************************************"
echo "*                                                                                              *"
echo "* On g2 instance you can see this above:                                                       *"
echo "* XIO:  fatal IO error 11 (Resource temporarily unavailable) on X server ":0"                  *"
echo "*       after 7 requests (7 known processed) with 0 events remaining.                          *"
echo "* This is OK.                                                                                  *"
echo "*                                                                                              *"
echo "************************************************************************************************"
echo ""

# Start the server on port 5901
/opt/TurboVNC/bin/vncserver
# You will be asked to enter Password twice.
# You will be also asked:
#  Would you like to enter a view-only password (y/n)? n

# Press Ctrl+D to disconnect

# Connect with TurboVNC:
# /opt/TurboVNC/bin/vncviewer ${ip}:5901
# Enter password you configured above

# Download PhotoScan from http://www.agisoft.com/downloads/installer/
# wget http://download.agisoft.com/photoscan-pro_1_3_4_amd64.tar.gz
# Extract it:
# tar -zxf photoscan-pro_1_3_4_amd64.tar.gz
# Now you can run any OpenGL application with vglrun:
# vglrun photoscan-pro/photoscan.sh

# Benchmarking:
# mkdir benchmark
# cd benchmark
# wget https://gist.githubusercontent.com/PolarNick239/fd2931434c4796f53f26d03622649179/raw/9549316e6d46d79bb1879b2a0e97382f61252562/benchmark.py
#
# wget https://www.dropbox.com/s/hh5yg0fmpr4bpn3/benchmarking_1.3.zip
# unzip benchmarking_1.3.zip
#
# ../photoscan-pro/photoscan.sh -r benchmark.py >>benchmarking.log 2>&1
