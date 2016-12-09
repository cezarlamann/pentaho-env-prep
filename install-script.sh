#!/bin/sh
set -e

echo "Adicionando variaveis de ambiente";
PENTAHO_HOME=/opt/pentaho;

##PENTAHO_VERSION=7.0;
##PENTAHO_TAG=7.0.0.0-25;
##PENTAHO_FOLDER=pentaho-server;
##PENTAHO_COMPL='-ce';

########### DESCOMENTAR AS LINHAS ABAIXO E COMENTAR AS LINHAS ACIMA PARA PENTAHO 5.X E 6.X
PENTAHO_VERSION=6.1;
PENTAHO_TAG=6.1.0.1-196;
PENTAHO_FOLDER=biserver-ce;
PENTAHO_COMPL='';

DB_TYPE=postgresql;
DB_PORT=5432;
DB_HOST=localhost;
PLUGIN_SET=cdf,cda,cde,cgg,saiku;

####################### INSTALAÇÃO AUTOMÁTICA DO JAVA PARA O PENTAHO
echo "Adicionando repositorios e instalando Java";

apt-get purge openjdk*;

add-apt-repository ppa:openjdk-r/ppa -y && apt-get update && sleep 5 && apt-get install openjdk-8-jdk zip netcat wget git pwgen -y;

if [ $? != 0 ] 
then 
	echo "Falhou instalando Java!"; 
	exit 1; 
fi
sleep 3;

if ! grep -i "JAVA_HOME" /etc/environment > /dev/null;
then
	echo "Configurando variaveis de ambiente Java";
	echo "JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> /etc/environment;
	echo "PENTAHO_JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> /etc/environment;
	echo "PENTAHO_HOME=/opt/pentaho" >> /etc/environment;
	echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> /etc/environment;
	echo "export PENTAHO_JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> /etc/environment;
	echo "export PENTAHO_HOME=/opt/pentaho" >> /etc/environment;
	echo "export PATH=$JAVA_HOME/bin:$PATH" >> /etc/environment;
fi
PW=`pwgen -s 12 1`;

####################### INSTALAÇÃO AUTOMÁTICA DO DOCKER
##chmod a+x install-docker.sh && sh install-docker.sh;
##if [ $? != 0 ] 
##then 
##	echo "Falhou instalando Docker!"; 
##	exit 1; 
##fi
##
##sleep 5;
##echo "Tudo certo! Vamos definir o usuário ubuntu como parte do grupo do docker o//";
##usermod -aG docker ubuntu;
##
##sleep 3;

####################### INSTALAÇÃO AUTOMÁTICA DO POSTGRES PARA O PENTAHO
## DANDO UM TOQUE NO ARQUIVO DE REPOSITÓRIO(SE TIVER, OK, SENÃO CRIA O ARQUIVO)
touch /etc/apt/sources.list.d/pgdg.list;

if ! grep -i "postgresql" /etc/apt/sources.list > /dev/null;
then
	if ! grep -i "postgresql" /etc/apt/sources.list.d/pgdg.list > /dev/null;
	then
		su -c "echo \"deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release --codename | cut -f2`-pgdg main\" >> /etc/apt/sources.list.d/pgdg.list";
	fi
fi

sleep 3;
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8
apt-get update && apt-get install postgresql-9.4 -y

if [ $? != 0 ] 
then 
	echo "Falhou instalando PostgreSQL!"; 
	exit 1; 
fi

echo "Esperando o PostgreSQL iniciar";
sleep 5;

echo "LEMBRETE 1 !!!";
echo "-------------";
echo "Editar o arquivo /etc/postgresql/9.4/main/pg_hba.conf, mudando a parte de IPV4";
echo "de 127.0.0.1/32 para \"all\" caso seja destinado à uma máquina para desenvolvimento";
echo "ou para a subnet adequada, quando em produção.";
echo "-------------";
echo "LEMBRETE 2 !!!";
echo "-------------";
echo "Editar o arquivo /etc/postgresql/9.4/main/postgresql.conf, descomentando a linha ";
echo "\"listen_addresses = 'localhost'\" e colocar * para desenvolvimento ou os hosts de aplicação";
echo "quando em produção.";
echo "-------------";
echo "Reiniciar o serviço postgresql após realizar estas alterações (\"sudo service postgresql restart\")";
echo "-------------";

echo "Liberando o acesso à todos os hosts/subnets";
echo "-------------";

SRC="#listen_addresses = 'localhost'";
DST="listen_addresses = '*'";
sed -i "s/$SRC/$DST/g" /etc/postgresql/9.4/main/postgresql.conf
SRC="127.0.0.1\/32";
DST="all";
sed -i "s/$SRC/$DST/g" /etc/postgresql/9.4/main/pg_hba.conf
sed -i 's/local   all             all                                     peer/local   all             all                                     trust/' /etc/postgresql/9.4/main/pg_hba.conf
echo "-------------";

echo "Configurando a senha do usuário \"postgres\" como \"postgres\"";
runuser -l postgres -c "psql -c \"ALTER USER \"postgres\" with encrypted password 'postgres'\" ";

echo "-------------";
echo "Rodar o comando abaixo como root/sudo para alterar a senha do usuário \"postgres\"";
echo " runuser -l postgres -c \"psql -c \\\"ALTER USER \\\"postgres\\\" with encrypted password '<senha>'\\\" \" ";
echo "-------------";

service postgresql restart;

if [ $? != 0 ] 
then 
	echo "Falhou reiniciando o serviço PostgreSQL!"; 
	exit 1; 
fi

echo " ";
echo "Iniciando instalação do Pentaho!!!";
echo " ";

mkdir $PENTAHO_HOME; useradd -s /bin/bash -d $PENTAHO_HOME pentaho; chown -hR pentaho:pentaho $PENTAHO_HOME

wget --progress=dot:giga http://ufpr.dl.sourceforge.net/project/pentaho/Business%20Intelligence%20Server/$PENTAHO_VERSION/$PENTAHO_FOLDER$PENTAHO_COMPL-$PENTAHO_TAG.zip -O /tmp/$PENTAHO_FOLDER-$PENTAHO_TAG.zip;

unzip -q /tmp/$PENTAHO_FOLDER-$PENTAHO_TAG.zip -d  $PENTAHO_HOME;
rm -f /tmp/$PENTAHO_FOLDER-$PENTAHO_TAG.zip $PENTAHO_HOME/$PENTAHO_FOLDER/promptuser.sh;

sed -i -e 's/\(exec ".*"\) start/\1 run/' $PENTAHO_HOME/$PENTAHO_FOLDER/tomcat/bin/startup.sh;

chmod +x $PENTAHO_HOME/$PENTAHO_FOLDER/start-pentaho.sh;

chown -hR pentaho $PENTAHO_HOME/;
chgrp -R pentaho $PENTAHO_HOME/;

wget --no-check-certificate 'https://raw.githubusercontent.com/sramazzina/ctools-installer/master/ctools-installer.sh' -P / -o /dev/null && chmod +x ctools-installer.sh && ./ctools-installer.sh -s $PENTAHO_HOME/$PENTAHO_FOLDER/pentaho-solutions -y -c $PLUGIN_SET

git clone https://github.com/cezarlamann/docker-pentaho.git

for f in `grep -lr "@@DB_HOST@@" docker-pentaho` ; do sed -i 's/@@DB_HOST@@/'$DB_HOST'/g' $f; done
for f in `grep -lr "@@DB_PORT@@" docker-pentaho` ; do sed -i 's/@@DB_PORT@@/'$DB_PORT'/g' $f; done
for f in `grep -lr "@@DB_PWD@@" docker-pentaho` ; do sed -i 's/@@DB_PWD@@/'$PW'/g' $f; done

mv docker-pentaho/v5/db/$DB_TYPE/*.sql $PENTAHO_HOME/$PENTAHO_FOLDER/data/$DB_TYPE/
for f in `find $PENTAHO_HOME/$PENTAHO_FOLDER/data/$DB_TYPE -name '*.sql'` ; do runuser -l postgres -c "psql -f \"$f\" "; done
runuser -l postgres -c "psql quartz -f `pwd`/docker-pentaho/v5/db/dummy_quartz_table.sql";

mv docker-pentaho/v5/pentaho/system/$DB_TYPE/applicationContext-spring-security-hibernate.properties $PENTAHO_HOME/$PENTAHO_FOLDER/pentaho-solutions/system/applicationContext-spring-security-hibernate.properties
mv docker-pentaho/v5/pentaho/system/$DB_TYPE/hibernate-settings.xml $PENTAHO_HOME/$PENTAHO_FOLDER/pentaho-solutions/system/hibernate/hibernate-settings.xml
mv docker-pentaho/v5/pentaho/system/$DB_TYPE/quartz.properties $PENTAHO_HOME/$PENTAHO_FOLDER/pentaho-solutions/system/quartz/quartz.properties
mv docker-pentaho/v5/pentaho/system/$DB_TYPE/repository.xml $PENTAHO_HOME/$PENTAHO_FOLDER/pentaho-solutions/system/jackrabbit/repository.xml
mv docker-pentaho/v5/pentaho/system/$DB_TYPE/postgresql.hibernate.cfg.xml $PENTAHO_HOME/$PENTAHO_FOLDER/pentaho-solutions/system/hibernate/postgresql.hibernate.cfg.xml
mv docker-pentaho/v5/tomcat/$DB_TYPE/context.xml $PENTAHO_HOME/$PENTAHO_FOLDER/tomcat/webapps/pentaho/META-INF/context.xml
mv docker-pentaho/v5/tomcat/web.xml $PENTAHO_HOME/$PENTAHO_FOLDER/tomcat/webapps/pentaho/WEB-INF/web.xml

chown -hR pentaho $PENTAHO_HOME/;
chgrp -R pentaho $PENTAHO_HOME/;

echo "Feito!";