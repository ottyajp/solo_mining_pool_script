#!/bin/bash
cd `dirname $0`
S_DIR=`pwd`

#必要パッケージのインストール
sudo add-apt-repository ppa:chris-lea/redis-server
sudo apt-get update
sudo apt-get install git curl build-essential libssl-dev redis-server

#monacoindのダウンロード
cd ~
if [ `uname -m` = "x86_64" ]; then
	wget -o monacoin.tar.gz http://monacoin.org/files/client/0.10.2.2-hotfix/monacoin-0.10.2.2-hotfix-linux64.tar.gz
else
	wget -o monacoin.tar.gz http://monacoin.org/files/client/0.10.2.2-hotfix/monacoin-0.10.2.2-hotfix-linux32.tar.gz
fi

tar -zxvf monacoin-0.10.2.2*.tar.gz
sudo cp ./monacoin-0.10.2.2/bin/* /usr/local/bin/

#monacoindのセットアップ
monacoind
echo -n "rpcuser:"
read rpcuser
echo -n "rpcpassword:"
read rpcpassword
echo -n "rpcallowip(usually 127.0.0.1):"
read rpcallowip
echo -n "rpcport(usually 19332):"
read rpcport
echo server=1 >> .monacoin/monacoin.conf
echo daemon=1 >> .monacoin/monacoin.conf
echo rpcuser=$rpcuser >> .monacoin/monacoin.conf
echo rpcpassword=$rpcpassword >> .monacoin/monacoin.conf
echo rpcallowip=$rpcallowip >> .monacoin/monacoin.conf
echo rpcport=$rpcport >> .monacoin/monacoin.conf

monacoind

#node.jsのインストール
git clone https://github.com/creationix/nvm.git .nvm
. ~/.nvm/nvm.sh
nvm install v0.10.40

echo ". ~/.nvm/nvm.sh" >> .bashrc
echo "nvm use v0.10.40" >> .bashrc

#Redisのインストール、というか起動
redis-server &

#NOMPのダウンロード、インストール
git clone https://github.com/zone117x/node-open-mining-portal nomp
cd nomp
sed -i -e s#zone117x/node-stratum-pool#visvirial/node-stratum-pool#g ./package.json
npm update

#NOMPのコンフィグ
cp ./config_example.json ./config.json
echo -n "web port(usually 8080):"
read web_port
echo -n "stratumHost:"
read stratumhost
sed -i -e s/8080/$web_port/g $S_DIR/patch/config.json.patch
sed -i -e s/test/$stratumhost/g $S_DIR/patch/config.json.patch
patch -u ./config.json < $S_DIR/patch/config.json.patch


sed -i -e s/scrypt/lyra2re2/ ./coins/monacoin.json


cp ./pool_configs/litecoin_example.json ./pool_configs/monacoin.json
wbrga=`monacoin-cli getaccountaddress ""`
echo -n "minimumPayment:"
read minimum_payment
echo -n "initial_Diff:"
read ini_diff
echo -n "minimum_Diff:"
read min_diff
echo -n "maximum_Diff:"
read max_diff

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
echo "~/nomp_start.sh start" >> ~/.bashrc
cp $S_DIR/nomp_start.sh ~/

exit 0
