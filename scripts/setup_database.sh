#!/bin/bash

echo "##########################################################"
echo "##########  CONFIGURAÇÃO DE BANCO DE DADOS ###############"
echo "##########################################################"

PWD=`pwd`

database="postgresql"
datetime=`date +"%Y%m%d-%H%M"`
install_dir="/opt/pentaho"
biserver_dir="$install_dir/biserver-ce"
db_user="postgres"
db_host="localhost"
db_port="5432"
#db_param="-U $db_user -h $db_host"
db_param=""


if [ "$1" ]; then
        install_dir="$1"
fi


read -p "Tecle ENTER para confirmar ou selecione o banco desejado [$database]:  " db
if [ "$db" ]; then
	database=$db
fi


echo "Verificando conexão com $database. Executando: nc -zv $db_host $db_port"

nc -zv $db_host $db_port
if [ "$?" -ne "0" ]; then
	echo "Erro: Instalação cancelada. Falha na conexão com $database $db_host:$db_port ..."
	echo "Para instalação local utilizar: "
	echo "RedHat/Centos: sudo yum install postgresql postgresql-server"		
	echo "Ubuntu:  sudo apt-get install postgresql postgresql-contrib"		
	
	exit 0
fi	

if [ "$database" == "postgresql" ]; then
	echo "Iniciando configuração do $database"
	
else
	echo "Opção inválida. Somente postgresql disponível"
	exit 0;
fi

db_bkp_dir="/tmp/$database"
pentaho_bkp_dir="/tmp/bkp/pentaho-biserver"

function backup_db {

	echo "Fazendo backup do banco: $database ..."
	if [ ! -d "$db_bkp_dir" ]; then
		su - $db_user -c "mkdir -p $db_bkp_dir"
	fi
        if [ ! -d "$pentaho_bkp_dir" ]; then
                mkdir -p $pentaho_bkp_dir
        fi
	
	#su - $db_user -c "pg_dumpall $db_param > $db_bkp_dir/pq_dump_pentaho_${datetime}.sql"
	su - $db_user -c "pg_dumpall $db_param | gzip > $db_bkp_dir/pq_dump_pentaho_${datetime}.sql.gz"
}

function restore_db {
	echo "Restaurando banco: $database ..."
	ls "$db_bkp_dir" | grep "pq_dump_pentaho_"
	last_file=`ls -lrt "$db_bkp_dir" | awk '/pq_dump_pentaho_/ { f=$NF };END{ print f }'`

	read -p "Tecle ENTER para confirmar ou selecione o arquivo desejado [$last_file]: " backup_file
	if [ ! "$backup_file" ]; then
		backup_file=$last_file
	fi
	if [ -f "$db_bkp_dir/$backup_file" ];then
		echo "Restaurando $db_bkp_dir/$backup_file ..."
		su - $db_user -c "gzip -cd $db_bkp_dir/$backup_file | psql -q $db_param"
	fi
}

function backup_pentaho {
	echo Salvando estado atual do Pentaho ...
	echo "Pode levar alguns minutos ..."
	tar -czf "$pentaho_bkp_dir/pentaho-biserver-ce-bkp-${datetime}.tgz" -C $install_dir "biserver-ce/"
}

function restore_pentaho {
        echo "Restaurando pentaho em $install_dir ..."
        ls "$pentaho_bkp_dir" | grep "pentaho-biserver-ce-bkp"
        last_file=`ls -lrt "$pentaho_bkp_dir" | awk '/pentaho-biserver-ce-bkp/ { f=$NF };END{ print f }'`

        read -p "Tecle ENTER para confirmar ou selecione o arquivo desejado [$last_file]: " backup_file
        if [ ! "$backup_file" ]; then
                backup_file=$last_file
        fi
        if [ -f "$pentaho_bkp_dir/$backup_file" ];then
                echo "Restaurando $pentaho_bkp_dir/$backup_file em $install_dir ..."
		echo "Pode levar alguns minutos ..."
		tar -xzf "$pentaho_bkp_dir/$backup_file" -C $install_dir
        fi
}

backup_db
backup_pentaho

biserver_dir_tmp="/tmp/biserver-ce-tmp"
db_config_dir="$PWD/config/${database}/biserver-ce"

cp -r $db_config_dir $biserver_dir_tmp

##INICIO CONFIGURAÇÃO 
##FIM CONFIGURAÇÃO

cp -r $biserver_dir_tmp/* $biserver_dir/

sql_script_dir="$biserver_dir_tmp/data/$database"

if [ -f "$sql_script_dir/create_quartz_postgresql.sql" ]; then
	su - $db_user -c "psql $db_param < $sql_script_dir/create_quartz_postgresql.sql"
fi

if [ -f "$sql_script_dir/create_repository_postgresql.sql" ]; then
       su - $db_user -c "psql $db_param < $sql_script_dir/create_repository_postgresql.sql"
fi

if [ -f "$sql_script_dir/create_jcr_postgresql.sql" ]; then
       su - $db_user -c "psql $db_param < $sql_script_dir/create_jcr_postgresql.sql"
fi

read -p "Deseja restaurar backup do ${database}? (y/n): " yn
if [ "$yn" == "y" ] || [ "$yn" == "Y" ]; then
	restore_db
fi
read -p "Deseja restaurar pentaho? (y/n): " yn
if [ "$yn" == "y" ] || [ "$yn" == "Y" ]; then
        restore_pentaho
fi

rm -rf $biserver_dir_tmp

