#!/bin/bash

sudo yum install httpd php php-mysql -y
sudo service httpd restart
sudo chkconfig httpd on

echo "<?php phpinfo(); ?>" > /var/www/html/index.php

