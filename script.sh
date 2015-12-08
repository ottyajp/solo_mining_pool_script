#!/bin/bash
cd `dirname $0`
S_DIR=`pwd`

#必要情報の収集
echo "info for monacoind"
echo -n "rpcuser:"
read rpcuser
echo -n "rpcpassword:"
read rpcpassword
echo -n "rpcallowip(usually 127.0.0.1):"
read rpcallowip
echo -n "rpcport(usually 19332):"
read rpcport

echo "info for NOMP web"
echo -n "web port(usually 8080):"
read web_port
echo -n "stratumHost:"
read stratumhost

echo "info for pool config"
echo -n "minimumPayment:"
read minimum_payment
echo -n "initial_Diff:"
read ini_diff
echo -n "minimum_Diff:"
read min_diff
echo -n "maximum_Diff:"
read max_diff

#必要パッケージのインストール
if [ -e /etc/apt/sources.list.d/chris-lea-redis-server-trusty.list ]; then
  echo "already ppa:chris-lea/redis-server is added."
else
  sudo add-apt-repository ppa:chris-lea/redis-server
fi
sudo apt-get update
sudo apt-get install git curl build-essential libssl-dev redis-server

#monacoindのダウンロード
cd ~
rm -f monacoin.tar.gz
rm -rf monacoin-0.10.2.2

if [ `uname -m` = "x86_64" ]; then
	wget -O monacoin.tar.gz http://monacoin.org/files/client/0.10.2.2-hotfix/monacoin-0.10.2.2-hotfix-linux64.tar.gz
else
	wget -O monacoin.tar.gz http://monacoin.org/files/client/0.10.2.2-hotfix/monacoin-0.10.2.2-hotfix-linux32.tar.gz
fi

tar -zxvf monacoin-0.10.2.2.tar.gz
sudo cp ./monacoin-0.10.2.2/bin/* /usr/local/bin/

#monacoindのセットアップ
rm -f .monacoin/monacoin.conf
monacoind
echo server=1 >> .monacoin/monacoin.conf
echo daemon=1 >> .monacoin/monacoin.conf
echo rpcuser=$rpcuser >> .monacoin/monacoin.conf
echo rpcpassword=$rpcpassword >> .monacoin/monacoin.conf
echo rpcallowip=$rpcallowip >> .monacoin/monacoin.conf
echo rpcport=$rpcport >> .monacoin/monacoin.conf

monacoind

#node.jsのインストール
if [ -e ~/.nvm ]; then
else
  git clone https://github.com/creationix/nvm.git .nvm
fi
. ~/.nvm/nvm.sh
nvm install v0.10.40

cat .bashrc | grep nvm
if [ $? -eq 0 ]; then
else
  echo ". ~/.nvm/nvm.sh" >> .bashrc
  echo "nvm use v0.10.40" >> .bashrc
fi

#Redisのインストール、というか起動
redis-server &

#NOMPのダウンロード、インストール
rm -rf ./nomp
git clone https://github.com/zone117x/node-open-mining-portal nomp
cd nomp
sed -i -e s#zone117x/node-stratum-pool#visvirial/node-stratum-pool#g ./package.json
npm update

#NOMPのコンフィグ
cp ./config_example.json ./config.json
sed -i -e s/8080/$web_port/g $S_DIR/patch/config.json.patch
sed -i -e s/test/$stratumhost/g $S_DIR/patch/config.json.patch
patch -u ./config.json < $S_DIR/patch/config.json.patch


sed -i -e s/scrypt/lyra2re2/ ./coins/monacoin.json


cp ./pool_configs/litecoin_example.json ./pool_configs/monacoin.json
wbrga=`monacoin-cli getaccountaddress ""`

sed -i -e s/where_block_rewards_given/$wbrga/g $S_DIR/patch/monacoin.json.patch
sed -i -e s/minimum_payment/$minimum_payment/g $S_DIR/patch/monacoin.json.patch
sed -i -e s/daemon_port/$rpcport/g $S_DIR/patch/monacoin.json.patch
sed -i -e s/daemon_user/$rpcuser/g $S_DIR/patch/monacoin.json.patch
sed -i -e s/daemon_pass/$rpcpassword/g $S_DIR/patch/monacoin.json.patch
sed -i -e s/ini_diff/$ini_diff/g $S_DIR/patch/monacoin.json.patch
sed -i -e s/min_diff/$min_diff/g $S_DIR/patch/monacoin.json.patch
sed -i -e s/max_diff/$max_diff/g $S_DIR/patch/monacoin.json.patch
patch -u ./pool_configs/monacoin.json < $S_DIR/patch/monacoin.json.patch


#自動起動のセッティング
cat .bashrc | grep nomp_start.sh
if [ $? -eq 0 ]; then
else
  echo "~/nomp_start.sh start" >> ~/.bashrc
fi
rm -f ~/nomp_start.sh
cp $S_DIR/nomp_start.sh ~/

exit 0
