# Cloud scripts

These scripts can configure Ubuntu 16.04 on EC2 graphics instances to support running OpenGL applications in TurboVNC via VirtualGL.

Please note that these scripts are tested on Amazon EC2 g2 and g3 instances, but they can work without or with a little changes on instances of other hosting providers.

# EC2 instances

Recommended instances - **g3.4xlarge**, **g3.8xlarge** and **g3.16xlarge**.

Also if you don't need GUI (i.e. don't need OpenGL) - you can look at **p3** instances too.

| EC2 instance  | GPUs          | vCPUs |   RAM  | On demand      | ~ Spot instance |
| ------------- | ------------- | ----- | ------ | -------------- | --------------- |
| g3.4xlarge    | 1 x Tesla M60 | 16    | 122 Gb | $1.21 per hour | ~ $0.4 per hour |
| g3.8xlarge    | 2 x Tesla M60 | 32    | 244 Gb | $2.42 per hour | N/A             |
| g3.16xlarge   | 4 x Tesla M60 | 64    | 488 Gb | $4.84 per hour | N/A             |

Two **Tesla M60** are roughly equal to **GTX 1080ti**.

16 vCPUs of g3.4xlarge are a little bit faster than i7 5960X.

**Hint:** use a spot instance and attach an external volume where you can save your work - this will result in major cost savings.

# How to use

Connect to g3 instance with Ubuntu 16.04:

```bash
ip=239.239.239.239
private_key=~/.ssh/private_key.pem

ssh -p 22 -i ${private_key} ubuntu@${ip}
```

Configure everything with script:

```bash
git clone https://github.com/agisoft-llc/cloud-scripts
cd cloud-scripts
chmod +x configure.sh
./configure.sh
```

Wait a while when instance will be rebooted, then reconnect:

```bash
ssh -p 22 -i ${private_key} ubuntu@${ip}
```

Start X server and VNC server:

```bash
cd cloud-scripts
chmod +x start_vnc_server.sh
./start_vnc_server.sh
# You will be asked to enter Password twice.
# You will be also asked:
#  Would you like to enter a view-only password (y/n)? n

# Press Ctrl+D to disconnect
```

Connect with TurboVNC:
```bash
# You can install it with:
#   wget https://sourceforge.net/projects/turbovnc/files/2.1.1/turbovnc_2.1.1_amd64.deb/download -O turbovnc_2.1.1_amd64.deb
#   sudo dpkg -i turbovnc*.deb
/opt/TurboVNC/bin/vncviewer ${ip}:5901
# Enter password you configured above
```

In terminal on instance you can download and run PhotoScan or any other OpenGL app with GUI:
```bash
# Download PhotoScan from http://www.agisoft.com/downloads/installer/
wget http://download.agisoft.com/photoscan-pro_1_3_4_amd64.tar.gz
# Extract it:
tar -zxf photoscan-pro_1_3_4_amd64.tar.gz

# Now you can run any OpenGL application with vglrun:
vglrun photoscan-pro/photoscan.sh
```

# References

https://github.com/yrahal/ec2-setup/

https://virtualgl.org/Documentation/HeadlessNV
