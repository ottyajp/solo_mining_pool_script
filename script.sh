#!/bin/bash

#必要パッケージのインストール
sudo add-apt-repository ppa:chris-lea/redis-server
sudo apt-get update
sudo apt-get install git curl build-essential libssl-dev redis-server

#monacoindのダウンロード
cd ~
if [`uname -m` = "x86_64"]; then
	wget -o monacoin.tar.gz http://monacoin.org/files/client/0.10.2.2-hotfix/monacoin-0.10.2.2-hotfix-linux64.tar.gz
then
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
echo -n "rpcallowip:"
read rpcallowip
echo -n "rpcport:"
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
sed -i -e s/zone117x\/node-stratum-pool\.git/visvirial\/node-stratum-pool\.git/g ./package.json
npm update

#NOMPのコンフィグ
echo -n "stratumHost:"
read stratumhost
cp ./config_example.json config.json
sed -i -e s/\"port\":\s80/\"port\":\s8080/g ./config.json
sed -i -e s/\"stratumHost\":\s\"cryppit\.com\"/\"stratumHost\":\s\"$stratumhost\"/g ./config.json

sed -i -e s/scrypt/lyra2re2/ ./coins/monacoin.json

cp ./pool_configs/litecoin_example.json monacoin.json

#自動起動のセッティング
echo "~/start_nomp start" >> ~/.bashrc
