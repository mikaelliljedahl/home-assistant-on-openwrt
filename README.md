# Script to install Home Assistant on OpenWRT 19.07.6
Home Assistant is an open source home automation platform. It is able to track and control thousands of smart devices and offer a platform for automating control. Details on https://github.com/home-assistant/home-assistant.  
Home Assistant supports only Windows, Linux, Mac and Raspberry offically. While this project is to install the Home Assistant on OpenWRT OS. So that you can run a Home Assistant on a router without having to run a 24-hours PC or Raspberry.   

**Note that OpenWRT is not an officially supported platform by Home Assistant and so not all integrations (e.g. Zigbee binaries) will work in this system.** 

## Hardware Requirements

A complete installation of Home Assistant will take nearly 350 MB Flash and 130 MB RAM. More components require more storage.  
A device needs 8 GB of storage, 512 MB RAM (or swap) and a powerful CPU. 
This fork contains script for installation on Netgear Nighthawk R8000 and similar devices. Before installation you need to mount a usb disk as /overlay and a swap file.
Follow instructions on https://openwrt.org/docs/guide-user/additional-software/extroot_configuration 
This is because that device only has 256 Mb. Compiling Python modules requres some disk and memory.

## Software Requirements

OpenWRT 19.07.6 

## Install Manually

You have to clone this project and excute install.sh manually.

### Clone this project

Open the OpenWRT interface through SSH. Using putty or xshell or some other tools.  
And then get into the root path and clone this project.

```bash
cd /root/
git clonehttps://github.com/mikaelliljedahl/home-assistant-on-openwrt.git
```

Note that maybe you'd install the git, use command like this:

```bash
opkg install git git-http
```

### Start installation

Get into the project folder and start the installation. Make sure your device has connected to the Internet.

```bash
cd home-assistant-on-openwrt
./install.sh 
```

It will take 20~30 minutes. After finished, it will print "HomeAssistant installation finished. Use command "hass -c /data/.homeassistant" to start the HA."

## Start Home Assistant for The First Time

After installation finished, use command `hass -c /data/.homeassistant` to start.  

Note that firstly start will download and install some Python modules. Make sure the network is connected while first starting. It will take about 20 minutes. If it stuck or print some error messages, don't worry, interupt it and retry `hass -c /data/.homeassistant` usually works.  

It has fully started when print messages like:

```bash
Starting Home Assistant
Timer:starting
```

## Enjoy Home Assistant on The Router

Connect to the Router through LAN ports or Wifi using your PC or phone. Visit the address `192.168.1.1:8123` , that's the web page for Home Assistant.  

Now you can link your smart devices together with Home Assistant.  

Questions and discussion about HA on https://community.home-assistant.io/
