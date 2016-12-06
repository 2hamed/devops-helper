#!/bin/bash
echo "Enter your desired user name:"
read userName

useradd $userName
homePath=/home/$userName/www
mkdir $homePath -p
chown $userName:$userName /home/$userName -R
chmod 755 /home/$userName -R

phpPoolRoute=/etc/php/7.0/fpm/pool.d/

echo "Your home path is: $homePath"

echo "Default PHP Pool route is: $phpPoolRoute"
echo "Is this correct? (y/n)"
read poolRoutePrompt
if [ "$poolRoutePrompt" == "n" ];
then
    echo "Enter the correct route:"
    read phpPoolRoute
fi

echo "PHP Pool route: $phpPoolRoute"

nginxDefRoute="/etc/nginx/"

echo "Default NGINX route is: $nginxDefRoute"
echo "Is this correct? (y/n)"
read nginxRoutePrompt
if [ "$nginxRoutePrompt" == "n" ];
then
    echo "Enter the correct route:"
    read nginxDefRoute
fi

echo "NGINX route is set to: $nginxDefRoute"

echo "Laravel or Wordpress? (l/w):"
read sysType

echo "Enter your domains, all in one line:"
read domains

# Copyin php pool conf file
cp templates/php-pool.tpl.conf $phpPoolRoute/$userName.conf
sed -i "s/{username}/$userName/g" $phpPoolRoute/$userName.conf
sed -i "s/{poolname}/$userName/g" $phpPoolRoute/$userName.conf

if [ "$sysType"=="l" ];
then
    cp templates/nginx.laravel.tpl.conf $nginxDefRoute/sites-available/$userName.conf
    ln -s $nginxDefRoute/sites-available/$userName.conf $nginxDefRoute/sites-enabled/$userName.conf
    homePath="$homePath/public"
    homePath=$(sed 's/[\/&]/\\&/g' <<< "$homePath")
    sed -i "s/{homepath}/$homePath/g" $nginxDefRoute/sites-available/$userName.conf
    sed -i "s/{username}/$userName/g" $nginxDefRoute/sites-available/$userName.conf
    sed -i "s/{domains}/$domains/g" $nginxDefRoute/sites-available/$userName.conf
else
    cp templates/nginx.wordpress.tpl.conf $nginxDefRoute/sites-available/$userName.conf
    ln -s $nginxDefRoute/sites-available/$userName.conf $nginxDefRoute/sites-enabled/$userName.conf
    homePath=$(sed 's/[\/&]/\\&/g' <<< "$homePath")
    sed -i "s/{homepath}/$homePath/g" $nginxDefRoute/sites-available/$userName.conf
    sed -i "s/{username}/$userName/g" $nginxDefRoute/sites-available/$userName.conf
    sed -i "s/{domains}/$domains/g" $nginxDefRoute/sites-available/$userName.conf
fi

service php7.0-fpm restart
service nginx reload
