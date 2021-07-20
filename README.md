# Cloud scripts

These scripts can configure Ubuntu 18.04 on EC2 graphics instances to support running OpenGL applications in TurboVNC via VirtualGL.

Please note that these scripts are tested on Amazon EC2 g2, g3, g4, p2, p3 and g4ad (AMD V520) instances, but they can work without or with a little changes on instances of other hosting providers.

# EC2 instances

Recommended instance - **g4ad.8xlarge**.

| Name          | GPUs    | GPU speed | CPUs     | CPU speed | RAM    | On demand       | ~ Spot instance |
| ------------- | ------- | --------- | -------- | --------- | ------ | --------------- | --------------- |
| Baseline Linux| GTX1080 |   x1.0    | i7 5960X | x1.0      | 64 Gb  | N/A             | N/A             |
| Baseline Win7 | GTX1080 |   x0.85   | i7 5960X | x1.0      | 64 Gb  | N/A             | N/A             |
| p2.xlarge     | 1 x K80 |   x0.35   |  4 vCPUs | x0.31     | 61 GiB | $ 0.97 per hour | ~ $0.3 per hour |
| g3.4xlarge    | 1 x M60 |   x0.7    | 16 vCPUs | x1.16     | 122 GiB| $ 1.21 per hour | ~ $0.4 per hour |
| g3.8xlarge    | 2 x M60 |   x1.38   | 32 vCPUs | x2.09     | 244 GiB| $ 2.42 per hour | ~ $0.7 per hour |
| g3.16xlarge   | 4 x M60 |   x2.58   | 64 vCPUs | x2.74     | 488 GiB| $ 4.84 per hour | ~ $1.5 per hour |
|**g4ad.4xlarge**|1 x V520|   x0.85   | 16 vCPUs | x1.31     |  64 GiB| $ 0.96 per hour | ~ $0.3 per hour |
|**g4ad.8xlarge**|2 x V520|   x1.63   | 32 vCPUs | x2.3      | 128 GiB| $ 1.94 per hour | ~ $0.6 per hour |
| p3.2xlarge    | 1 x V100|   x2.05   |  8 vCPUs | x0.61     | 61  GiB| $ 3.3  per hour | ~ $1   per hour |
| p3.8xlarge    | 4 x V100|   x6.95   | 32 vCPUs | x2.1      | 244 GiB| $13.2  per hour | ~ $4   per hour |

Spot instance prices from EU region (Ireland) actual for 20.07.2021.

Another [table with Amazon EC2 GPU instances comparison](https://docs.google.com/spreadsheets/d/1KUIag-1SmjI80BYXLpiruX3NiWCgajR8nGxrSEI5HSM/edit?usp=sharing) including performance per $ (w.r.t. spot instance prices actual on 14.08.2020).

Please note that there can be other cloud providers with GPUs (even with GTX) that could offer better ratio of performance per hour cost.
If you need assistance with launching on them - create issue, or start topic [on forum](http://www.agisoft.com/forum/) (please provide ```cloud-scripts/configure.log```, ```cloud-scripts/start_vnc_server.log```, ```/etc/X11/xorg.conf```, ```/var/log/Xorg.0.log``` and output of ```nvidia-smi``` execution).

**GPU speed** and **CPU speed** represents a typical relative speedup from **Baseline Linux**.

**Hint:** use a spot instance and attach an external volume where you can save your work - this will result in major cost savings.

# How to use

Connect to instance with Ubuntu 18.04 via ssh:

```bash
ip=239.239.239.239
private_key=~/.ssh/private_key.pem

ssh -p 22 -i ${private_key} ubuntu@${ip}
```

Configure everything with script (log will be saved to cloud-scripts/configure.log):

```bash
git clone https://github.com/agisoft-llc/cloud-scripts
cd cloud-scripts
chmod +x configure.sh
./configure.sh 2>&1 | tee configure.log
```

Wait a while (~7 minutes) when instance will be rebooted, then reconnect:

```bash
ssh -p 22 -i ${private_key} ubuntu@${ip}
```

Start X server and VNC server:

```bash
cd cloud-scripts
chmod +x start_vnc_server.sh
./start_vnc_server.sh 2>&1 | tee start_vnc_server.log
# On NVIDIA instances:
#  You will be asked to enter VNC Password twice.
#  You will be also asked:
#   Would you like to enter a view-only password (y/n)? n
# On AMD instances (G4ad):
#  You will be asked to enter Password for the ubuntu user twice.
#  And you will be asked to enter VNC Password twice.
#  You will be also asked:
#   Write password to /home/ubuntu/.vnc/passwd?  [y]/n y <- so that you will not be ask again to enter the password (on VNC server start)

# Press Ctrl+D to disconnect
```

Connect with TurboVNC (don't forget to allow inbounds for 5901 port in security groups):
```bash
# You can install it with:
#   wget https://sourceforge.net/projects/turbovnc/files/2.1.1/turbovnc_2.1.1_amd64.deb/download -O turbovnc_2.1.1_amd64.deb
#   sudo dpkg -i turbovnc*.deb
/opt/TurboVNC/bin/vncviewer ${ip}:5901
# Enter password you configured above
```

In terminal on instance you can download and run Metashape or any other OpenGL app with GUI:
```bash
# Download Metashape from http://www.agisoft.com/downloads/installer/
wget https://s3-eu-west-1.amazonaws.com/download.agisoft.com/metashape-pro_1_7_3_amd64.tar.gz
# Extract it:
tar -zxf metashape-pro_1_7_3_amd64.tar.gz

# Now you can run any OpenGL application:

# On NVIDIA instances - via vglrun:
vglrun metashape-pro/metashape.sh
# On AMD instances (G4ad) - as is:
metashape-pro/metashape.sh
```

# References

https://github.com/yrahal/ec2-setup/

https://virtualgl.org/Documentation/HeadlessNV
