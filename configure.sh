# ip=239.239.239.239
# private_key=~/.ssh/private_key.pem
# ssh -p 22 -i ${private_key} ubuntu@${ip}
#  Are you sure you want to continue connecting (yes/no)? yes

ubuntu_codename=`lsb_release -c -s`
AMD_GPU=false
NVIDIA_GPU=false

if lspci | egrep -q -h "Display controller: Advanced Micro Devices, Inc"; then
    AMD_GPU=true
elif lspci | egrep -q -h "NVIDIA Corporation Device 1eb8 \(rev a1\)"; then
    # Tesla T4
    NVIDIA_GPU=true
    NVIDIA_DRIVER=450.51.06
    NVIDIA_DRIVER_URL=http://us.download.nvidia.com/tesla/450.51.06/NVIDIA-Linux-x86_64-450.51.06.run
elif [ "$ubuntu_codename" = "bionic" ] ; then
    # Ubuntu 18.04
    NVIDIA_GPU=true
    NVIDIA_DRIVER=460.32.03
    NVIDIA_DRIVER_URL=http://us.download.nvidia.com/XFree86/Linux-x86_64/${NVIDIA_DRIVER}/NVIDIA-Linux-x86_64-${NVIDIA_DRIVER}.run
else
    NVIDIA_GPU=true
    NVIDIA_DRIVER=390.116
    NVIDIA_DRIVER_URL=http://us.download.nvidia.com/XFree86/Linux-x86_64/${NVIDIA_DRIVER}/NVIDIA-Linux-x86_64-${NVIDIA_DRIVER}.run
fi

set -e

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -yq

# Prepare for NVidia drivers install
sudo apt-get install -y gcc make pkg-config xserver-xorg-dev linux-headers-$(uname -r) xterm xinit
# xterm is needed for xinit

if [ "$ubuntu_codename" = "bionic" ] ; then
    # Ubuntu 18.04 - to fix following error:
    # ./metashape: error while loading shared libraries: libGLU.so.1: cannot open shared object file: No such file or directory
    sudo apt-get install -y libglu1-mesa
fi

# Install Lubuntu/Xubuntu/anything
sudo apt-get install -y lubuntu-desktop

if $AMD_GPU; then
    # Installing AMD driver, see https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/install-amd-driver.html (but we don't install 32-bit support)

    sudo apt install -y awscli
    aws s3 cp --recursive s3://ec2-amd-linux-drivers/latest/ . --no-sign-request

    tar -xf amdgpu-pro*ubuntu*.xz
    rm amdgpu-pro*ubuntu*.xz
    cd `ls | grep 'amdgpu.*ubuntu-18.04'`

    sudo apt install linux-modules-extra-$(uname -r) -y
    cat RPM-GPG-KEY-amdgpu | sudo apt-key add -

    sudo ./amdgpu-pro-install -y --no-32 --opencl=pal,legacy
    cd ..
    rm -rf `ls | grep 'amdgpu.*'`

    # Install VirtualGL
    wget https://sourceforge.net/projects/virtualgl/files/2.5.2/virtualgl_2.5.2_amd64.deb/download -O virtualgl_2.5.2_amd64.deb
    sudo dpkg -i virtualgl*.deb
    rm virtualgl*.deb

    # Installing x11vnc
    sudo apt install -y libssl-dev libxtst-dev xorg-dev libvncserver-dev
    git clone https://github.com/LibVNC/x11vnc
    cd x11vnc
    git checkout tags/0.9.16
    autoreconf -fiv
    ./configure
    make -j12
    sudo make install
    cd ..
    rm -rf x11vnc

    # Copy xorg.conf from instruction https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/install-amd-driver.html
    sudo cp configs/xorg_aws_g4ad_amd_v520.conf /etc/X11/xorg.conf

    # Fix /etc/X11/xorg.conf:
    # 1. Add line with BusID in section Device (taken from output of lspci | egrep -h "VGA|3D controller|Display controller")
    # For EC2 g3, g4 and p3 also:
    # 2. Delete whole section ServerLayout (comment it with # symbol)
    # 3. Delete whole section Screen (comment it with # symbol)
    sudo /usr/bin/python2.7 fix_xorg_conf.py /etc/X11/xorg.conf

    # Configure VirtualGL
    sudo service lightdm stop
    sudo /opt/VirtualGL/bin/vglserver_config -config +s +f -t

    # This is to fix errors in 'sudo service lightdm status':
    # "PAM unable to dlopen(pam_kwallet.so): /lib/security/pam_kwallet.so: cannot open shared object file: No such file or directory"
    # See also: https://askubuntu.com/questions/758696/cannot-login-into-locked-ubuntu-14-04-session-unity
    sudo apt-get install -y libpam-kwallet4 libpam-kwallet5
else
    # Installing NVidia driver
    curl -O ${NVIDIA_DRIVER_URL}
    chmod +x NVIDIA-Linux-x86_64-${NVIDIA_DRIVER}.run
    sudo ./NVIDIA-Linux-x86_64-${NVIDIA_DRIVER}.run --no-questions --accept-license --no-precompiled-interface --ui=none
    echo ""
    echo "************************************************************************************************"
    echo "*                                                                                              *"
    echo "* May be you see this warning above:                                                           *"
    echo "*  - WARNING: Unable to find a suitable destination to install 32-bit compatibility libraries. *"
    echo "* This is OK.                                                                                  *"
    echo "*                                                                                              *"
    echo "************************************************************************************************"
    echo ""
    rm NVIDIA-Linux-x86_64-${NVIDIA_DRIVER}.run

    # Preparation for virtualgl like in https://virtualgl.org/Documentation/HeadlessNV
    sudo nvidia-xconfig -a --use-display-device=None --virtual=1280x1024

    echo ""
    echo "********************************************************************************"
    echo "*                                                                              *"
    echo "* May be you see this warning above:                                           *"
    echo "*  - WARNING: Unable to locate/open X configuration file.                      *"
    echo "* This is OK.                                                                  *"
    echo "*                                                                              *"
    echo "********************************************************************************"
    echo ""

    # Fix /etc/X11/xorg.conf:
    # 1. Add line with BusID in section Device (taken from output of lspci | egrep -h "VGA|3D controller|Display controller")
    # For EC2 g3, g4 and p3 also:
    # 2. Delete whole section ServerLayout (comment it with # symbol)
    # 3. Delete whole section Screen (comment it with # symbol)
    sudo /usr/bin/python2.7 fix_xorg_conf.py /etc/X11/xorg.conf

    # Install VirtualGL
    wget https://sourceforge.net/projects/virtualgl/files/2.5.2/virtualgl_2.5.2_amd64.deb/download -O virtualgl_2.5.2_amd64.deb
    sudo dpkg -i virtualgl*.deb
    rm virtualgl*.deb

    # Install TurboVNC
    wget https://sourceforge.net/projects/turbovnc/files/2.1.1/turbovnc_2.1.1_amd64.deb/download -O turbovnc_2.1.1_amd64.deb
    sudo dpkg -i turbovnc*.deb
    rm turbovnc*.deb

    # Configure VirtualGL
    sudo service lightdm stop
    sudo /opt/VirtualGL/bin/vglserver_config -config +s +f -t

    echo ""
    echo "********************************************************************************"
    echo "*                                                                              *"
    echo "* May be you see these lines above:                                            *"
    echo "*  - rmmod: ERROR: Module nvidia is in use by: nvidia_modeset                  *"
    echo "*  - IMPORTANT NOTE: Your system uses modprobe.d to set device permissions.    *"
    echo "* This is OK - just means that reboot required.                                *"
    echo "*                                                                              *"
    echo "********************************************************************************"
    echo ""
fi

echo ""
echo "******************************************************************"
echo "*                                                                *"
echo "* Rebooting for changes to take effect!                          *"
echo "*                                                                *"
echo "******************************************************************"
echo ""

sudo reboot
