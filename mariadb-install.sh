#!/bin/bash

sudo yum install mariadb-server -y
sudo service mariadb restart
sudo chkconfig mariadb on

