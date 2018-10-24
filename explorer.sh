#!/usr/bin/env bash

D=$PWD

sudo apt-get install \
      build-essential pkg-config libc6-dev m4 g++-multilib \
      autoconf libtool ncurses-dev unzip git python python-zmq \
      zlib1g-dev wget bsdmainutils automake curl

# build vidulumd patched with addressindexing support
#git clone https://github.com/vidulum/vidulum-indexing
cd vidulum-indexing
chmod +x zcutil/build.sh depends/config.guess depends/config.sub autogen.sh share/genbuild.sh src/leveldb/build_detect_platform
./zcutil/fetch-params.sh
./zcutil/build.sh --disable-rust

# install npm and use node v4
cd ..
sudo apt-get -y install npm
sudo npm install -g n
sudo n 4

# install ZeroMQ libraries
sudo apt-get -y install libzmq3-dev

# install vidulum version of bitcore
npm install git+https://git@github.com/vidulum/bitcore-lib-vidulum.git

# create bitcore node
./node_modules/bitcore-node-vidulum/bin/bitcore-node create vidulum-explorer
cd vidulum-explorer

# install insight api/ui
../node_modules/bitcore-node-vidulum/bin/bitcore-node install vidulum/insight-api-vidulum vidulum/insight-ui-vidulum

# create bitcore config file for bitcore
cat << EOF > bitcore-node.json
{
  "network": "mainnet",
  "port": 3001,
  "services": [
    "bitcoind",
    "insight-api-vidulum",
    "insight-ui-vidulum",
    "web"
  ],
  "servicesConfig": {
    "bitcoind": {
      "spawn": {
        "datadir": "./data",
        "exec": "../vidulum-indexing/src/vidulumd"
      }
    },
     "insight-ui-vidulum": {
      "apiPrefix": "api"
     },
    "insight-api-vidulum": {
      "routePrefix": "api"
    }
  }
}


EOF

# create vidulum.conf
cat << EOF > data/vidulum.conf
server=1
whitelist=127.0.0.1
txindex=1
addressindex=1
timestampindex=1
spentindex=1
zmqpubrawtx=tcp://127.0.0.1:7676
zmqpubhashblock=tcp://127.0.0.1:7676
rpcallowip=127.0.0.1
rpcuser=bitcoin
rpcpassword=local321
uacomment=bitcore
showmetrics=0
maxconnections=1000

EOF

cd vidulum-explorer

echo "Start the block explorer, open in your browser http://server_ip:3001"
echo "./node_modules/bitcore-node-vidulum/bin/bitcore-node start"