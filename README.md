# Cloud scripts

These scripts can configure Ubuntu 16.04 on EC2 graphics instances to support running OpenGL applications in TurboVNC via VirtualGL.

Please note that these scripts are tested on Amazon EC2 p2, g2 and g3 instances, but they can work without or with a little changes on instances of other hosting providers.

# EC2 instances

Recommended instances - **g3.4xlarge**, **g3.8xlarge** and **g3.16xlarge**.

Also if you don't need GUI (i.e. don't need OpenGL) - you can look at **p3** instances too.

| Name          | GPUs    | GPU speed | CPUs     | CPU speed | RAM    | On demand       | ~ Spot instance |
| ------------- | ------- | --------- | -------- | --------- | ------ | --------------- | --------------- |
|**Baseline Linux**| GTX1080 |   x1.0    | i7 5960X | x1.0      | 64 Gb  | N/A             | N/A             |
| Baseline Win7 | GTX1080 |   x0.85   | i7 5960X | x1.0      | 64 Gb  | N/A             | N/A             |
| p2.xlarge     | 1 x K80 |   x0.35   |  4 vCPUs | x0.31     | 61 GiB | $ 0.9  per hour | ~ $0.2 per hour |
|**g3.4xlarge**| 1 x M60 |   x0.7    | 16 vCPUs | x1.16     | 122 GiB| $ 1.21 per hour | ~ $0.4 per hour |
|**g3.8xlarge**| 2 x M60 |   x1.38   | 32 vCPUs | x2.09     | 244 GiB| $ 2.42 per hour | N/A             |
|**g3.16xlarge**| 4 x M60 |   x2.58   | 64 vCPUs | x2.74     | 488 GiB| $ 4.84 per hour | N/A             |
| p3.2xlarge    | 1 x V100|   x2.05   |  8 vCPUs | x0.61     | 61  GiB| $ 3    per hour | N/A             |
| p3.8xlarge    | 4 x V100|   x6.95   | 32 vCPUs | x2.1      | 244 GiB| $12    per hour | ~ $3   per hour |

**g3 spot** instances offer best ratio of performance per $ on EC2.
But please note that there can be other cloud providers with GPUs (even with GTX) that could offer better ratio of performance per hour cost.
If you need assistance with launching on them - create issue, or start topic [on forum](http://www.agisoft.com/forum/).

**GPU speed** and **CPU speed** represents a typical relative speedup from **Baseline Linux**.

**Hint:** use a spot instance and attach an external volume where you can save your work - this will result in major cost savings.

# How to use

Connect to g3 instance with Ubuntu 16.04 via ssh:

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

Wait a while (~7 minutes) when instance will be rebooted, then reconnect:

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
