#! /bin/bash

#yum update -y > /dev/null
yum update python -y 
yum install -y git
curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
python get-pip.py
git clone git://github.com/osrg/ryu.git
cd ryu/
pip install .
ryu-manager
