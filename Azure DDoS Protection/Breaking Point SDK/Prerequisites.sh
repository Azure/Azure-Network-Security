# Download BPC API Client from: https://breakingpoint.cloud/ 
# Reference docs: https://breakingpoint.cloud/api-help/BpcDdosAPI.htm 
# Script tested on Ubuntu 18.04 LTS
# Windows users download bpcddos.zip from https://breakingpoint.cloud/  to root folder

sudo apt install python3-pip
sudo apt install requests[security]
pip3 install requests-aws4auth
pip3 install boto3
pip3 install bpcddos.zip
