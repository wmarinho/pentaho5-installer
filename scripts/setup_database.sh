#!/bin/bash -x

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
#db_param="-U $db_user -h $db_host"
db_param=""


if [ "$1" ]; then
        install_dir="$1"
fi


read -p "Tecle ENTER para confirmar ou selecione o banco desejado [$database]:  " db
if [ "$db" ]; then
	database=$db
fi

if [ "$database" == "postgresql" ]; then
	echo Iniciando configuração do $database
else
	echo "Opção inválida. Somente postgresql disponível"
	exit 0;
fi

sql_script_dir="$biserver_dir/data/$database"
db_bkp_dir="/tmp/pentaho/bkp/$database"


function db_backup {

	echo "Fazendo backup do banco: $database ..."
	if [ ! -d "$db_bkp_dir" ]; then
		su - $db_user -c "mkdir -p $db_bkp_dir"
	fi
	
	#su - $db_user -c "pg_dumpall $db_param > $db_bkp_dir/pq_dump_pentaho_${datetime}.sql"
	su - $db_user -c "pg_dumpall $db_param | gzip > $db_bkp_dir/pq_dump_pentaho_${datetime}.sql.gz"
}

function db_restore {
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

#function pentaho_backup {

#}

#function pentaho_restore {

#}

db_backup
#db_restore

biserver_dir_tmp="$PWD/config/postgresql/biserver-ce-tmp"
db_config_dir="$PWD/config/${database}/biserver-ce"

cp -r $db_config_dir $biserver_dir_tmp

##INICIO CONFIGURAÇÃO 
##FIM CONFIGURAÇÃO

cp -r $biserver_dir_tmp/* $biserver_dir/

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
	db_restore
fi

rm -rf $biserver_dir_tmp

