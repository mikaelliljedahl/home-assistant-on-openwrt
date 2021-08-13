#!/bin/sh

echo -e "Follow these instructions to mount a usb drive to overlay and create swap if your memory < 512 Mb: https://openwrt.org/docs/guide-user/additional-software/extroot_configuration"

mkdir -p /root/tmp
export TMPDIR=/root/tmp

#Compare the first version and the second version. If the first lower than the second return 0 , or return 1
CompareVersion() {
    fversion_1=`echo $1 | awk -F '.' '{print $1}'`
    fversion_2=`echo $1 | awk -F '.' '{print $2}'`
    fversion_3=`echo $1 | awk -F '.' '{print $3}'`
    sversion_1=`echo $2 | awk -F '.' '{print $1}'`
    sversion_2=`echo $2 | awk -F '.' '{print $2}'`
    sversion_3=`echo $2 | awk -F '.' '{print $3}'`


    if [ $fversion_1 -lt $sversion_1 ]; then
        return 0
    elif [ $fversion_1 -gt $sversion_1 ]; then
        return 1
    fi

    if [ $fversion_2 -lt $sversion_2 ]; then
        return 0
    elif [ $fversion_2 -gt $sversion_2 ]; then
        return 1
    fi

    if [ $fversion_3 -lt $sversion_3 ]; then
        return 0
    elif [ $fversion_3 -gt $sversion_3 ]; then
        return 1
    fi

    return 0
}

#Get into the installation path /root/
cd /root/
currentpath=`pwd`
if [ "$currentpath" != "/root" ]; then
    echo -e "\033[31m ERROR! Cannot get into installation path, exit. \033[0m"
    exit 0
fi

#Update the opkg package info
try=0
while true
do
    try=$((try+1))
    if [ $try -le 5 ]; then
        echo -e "\033[33m opkg update...... try $try. \033[0m"
        opkg update
        if [ $? -ne 0 ]; then
            continue
        else
            break
        fi
    else
        echo -e "\033[31m ERROR! opkg update failed, check the network connection, exit. \033[0m"
        exit 0
    fi
done

#Install python3.7
try=0
while true
do
    try=$((try+1))
    if [ $try -le 5 ]; then
        echo -e "\033[33m Installing python3.7...... try $try. \033[0m"
        opkg install python3
        if [ $? -ne 0 ]; then
            continue
        else
            break
        fi
    else
        echo -e "\033[31m ERROR! Install python3.7 failed, check the network connection, exit. \033[0m"
        exit 0
    fi
done


#Download and install latest pip for python3
pipreq=0
command -v pip > /dev/null 2>&1
if [ $? -eq 0 ]; then
    CompareVersion 19.1.1 `pip --version | awk '{print $2}'`
    if [ $? -eq 0 ]; then
    pipreq=1
    fi
fi

if [ $pipreq -ne 1 ]; then
    try=0
    while true
    do
        try=$((try+1))
        if [ $try -le 5 ]; then
            echo -e "\033[33m Download and install pip...... try $try. \033[0m"
            curl https://bootstrap.pypa.io/get-pip.py > get-pip.py && python3 get-pip.py
            if [ $? -ne 0 ]; then
                rm ./get-pip.py
                continue
            else
                break
            fi
        else
            echo -e "\033[31m ERROR! Install pip failed,  exit. \033[0m"
            exit 0
        fi
    done
    rm ./get-pip.py
fi

#Set pip install configuration to no-cache-dir
pip3 config set install.no-cache-dir on

#Install gcc
try=0
while true
do
    try=$((try+1))
    if [ $try -le 5 ]; then
        echo -e "\033[33m Download and install gcc...... try $try. \033[0m"
        opkg install gcc
        if [ $? -ne 0 ]; then
            continue
        else
            break
        fi
    else
        echo -e "\033[31m ERROR! Install gcc failed,  exit. \033[0m"
        exit 0
    fi
done

#Install dependent C library
opkg install python3-dev
if [ $? -ne 0 ]; then
    echo -e "\033[31m ERROR! Install python-dev failed, exit. \033[0m"
    exit 0
fi
echo -e "\033[32m Install C library......libffi \033[0m"
mkdir -p /usr/include/ffi && \
cp ./home-assistant-on-openwrt/ffi* /usr/include/ffi && \
ln -s /usr/lib/libffi.so.6.0.1 /usr/lib/libffi.so
echo -e "\033[32m Install C library......libopenssl \033[0m"
cp -r ./home-assistant-on-openwrt/openssl /usr/include/python3.7/ && \
ln -s /usr/lib/libcrypto.so.1.0.0 /usr/lib/libcrypto.so && \
ln -s /usr/lib/libssl.so.1.0.0 /usr/lib/libssl.so
echo -e "\033[32m Install C library......libsodium \033[0m"
opkg install libsodium
if [ $? -ne 0 ]; then
    echo -e "\033[31m ERROR! Install libsodium failed,  exit. \033[0m"
    exit 0
fi
cp ./home-assistant-on-openwrt/sodium.h /usr/include/python3.7/ && \
cp -r ./home-assistant-on-openwrt/sodium /usr/include/python3.7/ && \
ln -s /usr/lib/libsodium.so.23.1.0 /usr/lib/libsodium.so

#Install dependent python module
try=0
while true
do
    try=$((try+1))
    if [ $try -le 5 ]; then
        echo -e "\033[33m Install python module: PyNaCl...... try $try. \033[0m"
        SODIUM_INSTALL=system pip3 install pynacl
        if [ $? -ne 0 ]; then
            continue
        else
            break
        fi
    else
        echo -e "\033[31m ERROR! Install PyNacl failed,  exit. \033[0m"
        exit 0
    fi
done

pip3 install -U ciso8601
pip3 install -U yarl==1.4.2
pip3 install -U aiohttp --user


#Install hass_nabucasa and ha-frontend...
echo "Install hass_nabucasa and ha-frontend..."
wget https://github.com/NabuCasa/hass-nabucasa/archive/0.39.0.tar.gz -O - > hass-nabucasa-0.39.0.tar.gz
tar -zxf hass-nabucasa-0.39.0.tar.gz
cd hass-nabucasa-0.39.0
sed -i 's/==.*"/"/' setup.py
sed -i 's/>=.*"/"/' setup.py
python3 setup.py install
cd ..
rm -rf hass-nabucasa-0.39.0.tar.gz hass-nabucasa-0.39.0


# tmp might be small for frontend
cd /root
wget https://files.pythonhosted.org/packages/8f/9b/aa394eb6265a8ed90af2b318d1a4c844e6a35de22f7a24e275161322cccc/home-assistant-frontend-20201229.1.tar.gz -O home-assistant-frontend-20201229.1.tar.gz
tar -zxf home-assistant-frontend-20201229.1.tar.gz
cd home-assistant-frontend-20201229.1
find ./hass_frontend/frontend_es5 -name '*.js' -exec rm -rf {} \;
find ./hass_frontend/frontend_es5 -name '*.map' -exec rm -rf {} \;
find ./hass_frontend/frontend_es5 -name '*.txt' -exec rm -rf {} \;
find ./hass_frontend/frontend_latest -name '*.js' -exec rm -rf {} \;
find ./hass_frontend/frontend_latest -name '*.map' -exec rm -rf {} \;
find ./hass_frontend/frontend_latest -name '*.txt' -exec rm -rf {} \;

find ./hass_frontend/static/mdi -name '*.json' -maxdepth 1 -exec rm -rf {} \;
find ./hass_frontend/static/polyfills -name '*.js' -maxdepth 1 -exec rm -rf {} \;
find ./hass_frontend/static/polyfills -name '*.map' -maxdepth 1 -exec rm -rf {} \;

# shopping list and calendar missing gzipped
gzip ./hass_frontend/static/translations/calendar/*
gzip ./hass_frontend/static/translations/shopping_list/*

find ./hass_frontend/static/translations -name '*.json' -exec rm -rf {} \;

mv hass_frontend /usr/lib/python3.7/site-packages/hass_frontend
python3 setup.py install
cd ..
rm -rf home-assistant-frontend-20201229.1.tar.gz home-assistant-frontend-20201229.1
cd /tmp

#Install Home Assistant
try=0
while true
do
    try=$((try+1))
    if [ $try -le 5 ]; then
        echo -e "\033[33m Install HomeAssistant...... try $try. \033[0m"
        #python3 -m pip install homeassistant
        # following is from https://github.com/openlumi/homeassistant_on_openwrt/blob/main/ha_install.sh
		cd /root/tmp
		wget https://files.pythonhosted.org/packages/99/a0/dfb23c5fcf168825964cc367fd9d3ff62636b7f056077656e87880b1a356/homeassistant-2021.1.5.tar.gz -O - > /root/tmp/homeassistant-2021.1.5.tar.gz
		tar -zxf /root/tmp/homeassistant-2021.1.5.tar.gz
		rm -rf homeassistant-2021.1.5.tar.gz
		cd homeassistant-2021.1.5/homeassistant/
		echo '' > requirements.txt
		
		mv components components-orig
		mkdir components
		cd components-orig
		
		mv \
  __init__.py \
  alarm_control_panel \
  alert \
  alexa \
  api \
  auth \
  automation \
  binary_sensor \
  camera \
  climate \
  cloud \
  config \
  cover \
  default_config \
  device_automation \
  device_tracker \
  fan \
  frontend \
  google_assistant \
  google_translate \
  group \
  hassio \
  history \
  homeassistant \
  http \
  humidifier \
  image_processing \
  input_boolean \
  input_datetime \
  input_number \
  input_select \
  input_text \
  ipp \
  light \
  lock \
  logger \
  logbook \
  lovelace \
  map \
  media_player \
  met \
  mobile_app \
  notify \
  number \
  onboarding \
  persistent_notification \
  person \
  python_script \
  recorder \
  scene \
  script \
  search \
  sensor \
  shopping_list \
  ssdp \
  stream \
  sun \
  switch \
  system_health \
  system_log \
  time_date \
  timer \
  tts \
  updater \
  vacuum \
  wake_on_lan \
  weather \
  webhook \
  websocket_api \
  workday \
  xiaomi_aqara \
  xiaomi_miio \
  zeroconf \
  zha \
  zone \
  blueprint \
  counter \
  image \
  media_source \
  tag \
  panel_custom \
  brother \
  discovery \
  mqtt \
  mpd \
  telegram \
  telegram_bot \
  ../components
  
  
# serve static with gzipped files
sed -i 's/filepath = self._directory.joinpath(filename).resolve()/try:\n                filepath = self._directory.joinpath(Path(rel_url + ".gz")).resolve()\n                if not filepath.exists():\n                    raise FileNotFoundError()\n            except Exception as e:\n                filepath = self._directory.joinpath(filename).resolve()/' http/static.py

sed -i 's/sqlalchemy==1.3.20/sqlalchemy/' recorder/manifest.json
sed -i 's/pillow==7.2.0/pillow/' image/manifest.json
sed -i 's/, UnidentifiedImageError//' image/__init__.py
sed -i 's/except UnidentifiedImageError/except OSError/' image/__init__.py
sed -i 's/zeroconf==0.28.8/zeroconf/' zeroconf/manifest.json
sed -i 's/netdisco==2.8.2/netdisco/' discovery/manifest.json
sed -i 's/PyNaCl==1.3.0/PyNaCl/' mobile_app/manifest.json
sed -i 's/"defusedxml==0.6.0", "netdisco==2.8.2"/"defusedxml", "netdisco"/' ssdp/manifest.json
# remove unwanted zha requirements
sed -i 's/"bellows==0.21.0",//' zha/manifest.json
sed -i 's/"zigpy-cc==0.5.2",//' zha/manifest.json
sed -i 's/"zigpy-deconz==0.11.1",//' zha/manifest.json
sed -i 's/"zigpy-xbee==0.13.0",//' zha/manifest.json
sed -i 's/"zigpy-znp==0.3.0"//' zha/manifest.json
sed -i 's/"zigpy-zigate==0.7.3",/"zigpy-zigate"/' zha/manifest.json
sed -i 's/import bellows.zigbee.application//' zha/core/const.py
sed -i 's/import zigpy_cc.zigbee.application//' zha/core/const.py
sed -i 's/import zigpy_deconz.zigbee.application//' zha/core/const.py
sed -i 's/import zigpy_xbee.zigbee.application//' zha/core/const.py
sed -i 's/import zigpy_znp.zigbee.application//' zha/core/const.py
sed -i -e '/znp = (/,/)/d' -e '/ezsp = (/,/)/d' -e '/deconz = (/,/)/d' -e '/ti_cc = (/,/)/d' -e '/xbee = (/,/)/d' zha/core/const.py

sed -i 's/"cloud",//' default_config/manifest.json
sed -i 's/"mobile_app",//' default_config/manifest.json
sed -i 's/"updater",//' default_config/manifest.json

cd ../..
sed -i 's/    "/    # "/' homeassistant/generated/config_flows.py
sed -i 's/    # "mqtt"/    "mqtt"/' homeassistant/generated/config_flows.py
sed -i 's/    # "zha"/    "zha"/' homeassistant/generated/config_flows.py

sed -i 's/install_requires=REQUIRES/install_requires=[]/' setup.py
python3 setup.py install
cd ../
rm -rf homeassistant-2021.1.5/

mkdir -p /etc/homeassistant
ln -s /etc/homeassistant /root/.homeassistant
cat << "EOF" > /etc/homeassistant/configuration.yaml
# Configure a default setup of Home Assistant (frontend, api, etc)
default_config:
# Text to speech
tts:
  - platform: google_translate
    language: ru
recorder:
  purge_keep_days: 2
  db_url: 'sqlite:///:memory:'
group: !include groups.yaml
automation: !include automations.yaml
script: !include scripts.yaml
scene: !include scenes.yaml
EOF

touch /etc/homeassistant/groups.yaml
touch /etc/homeassistant/automations.yaml
touch /etc/homeassistant/scripts.yaml
touch /etc/homeassistant/scenes.yaml

echo "Create starting script in init.d"
cat << "EOF" > /etc/init.d/homeassistant
#!/bin/sh /etc/rc.common
START=99
USE_PROCD=1
start_service()
{
    procd_open_instance
    procd_set_param command hass --config /etc/homeassistant
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_close_instance
}
EOF
chmod +x /etc/init.d/homeassistant
/etc/init.d/homeassistant enable

echo "Done."
		
        if [ $? -ne 0 ]; then
            continue
        else
            break
        fi
    else
        echo -e "\033[33m Install HomeAssistant failed, exit. \033[0m"
        exit 0
    fi
done
#Config the homeassistant
mkdir -p /data/.homeassistant
cp ./home-assistant-on-openwrt/configuration/* /data/.homeassistant/
#Install finished
echo -e "\033[32m HomeAssistant installation finished. Use command \"hass -c /data/.homeassistant\" to start it. \033[0m"
echo -e "\033[32m Note that the firstly start will take 20~30 minutes. If failed, retry it. \033[0m"
