#!/bin/bash

#title:         wp_tranfer.sh
#description:   sichert alle notwendigen Daten für das Wordpress deployment im Prod, rollt die Daten in die Produktivumgebung aus
#####           und konfiguriert eine neue Wordpress Installation
#author:        Stefan Diefenbacher
#date:          25.05.2021
#version:       1.0
#usage:         yes, maybe
#param:         not yet
#notes:         Skript verwendet CR für den Zeilenumbruch!
#bash_version:  getestet unter 5.1.2 auf OSX Catalina

#Credentials for remote Server, will be taken as arguemnts later..
dbname=kx84u_diefenbacher
dbuser=kx84u_5ia18c
dbpass=SbY0S_BelB7

#################################################   local packaging

#wp_content
tar -C ./wp_data/wp-content/ -czvf themes_archive.tar.gz ./themes
tar -C ./wp_data/wp-content/ -czvf plugins_archive.tar.gz ./plugins
tar -C ./wp_data/wp-content/ -czvf uploads_archive.tar.gz ./uploads

#database_dump, arguments for user, password and DB later..
docker exec -it wpdeploy_db_1 /usr/bin/mysqldump -u wordpress -pwordpress -dwordpress > dump.sql

#local WordPress version
wp_version=$(grep wp_version wp_data/wp-includes/version.php | awk -F "'" '{print $2}')

#TODO remote backup
################################################################

################################################################


########################################################   #Deployment
#install WordPress on remote location, change dir to wordpress, copy file to parent dir, back to parent dir, remove WordPress Folder, rename wp-config.php from template
ssh -t kx84u_bbw@5ia18c.root-systems.ch "cd sites/5ia18c.root-systems.ch/diefenbacher && git clone -b "$wp_version" https://github.com/WordPress/WordPress.git && cd WordPress && cp -rf . .. && cd .. && rm -Rf WordPress && cp wp-config-sample.php wp-config.php"

#update database details with find and replace
ssh -t kx84u_bbw@5ia18c.root-systems.ch "cd sites/5ia18c.root-systems.ch/diefenbacher && sed -i \"s/define( 'DB_USER',[^\n]*/define( 'DB_USER', '\"$dbuser\"' );/g\" wp-config.php"
ssh -t kx84u_bbw@5ia18c.root-systems.ch "cd sites/5ia18c.root-systems.ch/diefenbacher && sed -i \"s/define( 'DB_PASSWORD',[^\n]*/define( 'DB_PASSWORD', '\"$dbpass\"' );/g\" wp-config.php"
ssh -t kx84u_bbw@5ia18c.root-systems.ch "cd sites/5ia18c.root-systems.ch/diefenbacher && sed -i \"s/define( 'DB_NAME',[^\n]*/define( 'DB_NAME', '\"$dbname\"' );/g\" wp-config.php"


#copy archive files to remote location
scp themes_archive.tar.gz kx84u_bbw@5ia18c.root-systems.ch:"~/sites/5ia18c.root-systems.ch/diefenbacher/wp-content/themes.tar.gz"
scp plugins_archive.tar.gz kx84u_bbw@5ia18c.root-systems.ch:"~/sites/5ia18c.root-systems.ch/diefenbacher/wp-content/plugins.tar.gz"
scp uploads_archive.tar.gz kx84u_bbw@5ia18c.root-systems.ch:"~/sites/5ia18c.root-systems.ch/diefenbacher/wp-content/uploads.tar.gz"
scp dump.sql kx84u_bbw@5ia18c.root-systems.ch:"~/sites/5ia18c.root-systems.ch/diefenbacher/"

#unpack files, change access rights and cleanup
ssh -t kx84u_bbw@5ia18c.root-systems.ch "cd sites/5ia18c.root-systems.ch/diefenbacher/wp-content && tar -xvzf themes.tar.gz && tar -xvzf plugins.tar.gz && tar -xvzf uploads.tar.gz && chmod 777 uploads && rm *.tar.gz"


#import the sql dump
ssh -t kx84u_bbw@5ia18c.root-systems.ch "cd sites/5ia18c.root-systems.ch/diefenbacher && mysqldump -u kx84u_5ia18c -pSbY0S_BelB7 -d kx84u_diefenbacher < dump.sql"

#wp-cli did not work!
#Habe laut anleitungen die php Dateien editiert, hat auch nicht funktioniert.