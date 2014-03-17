#!/bin/bash -x

PWD=`pwd`

database="postgres"
datetime=`date +"%Y%m%d-%H%M"`
install_dir="/opt/pentaho/biserver-ce"
db_user="postgres"
db_host="localhost"
#db_param="-U $db_user -h $db_host"
db_param=""


if [ "$1" ]; then
        install_dir="$1"
fi
if [ "$2" ]; then
        database="$2"
fi
if [ "$3" ]; then
        db_user="$3"
fi
if [ "$4" ]; then
        db_host="$4"
fi

sql_script_dir="$install_dir/biserver-ce/data/$database"
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

#cp -r $PWD/config/postgresql/biserver-ce $PWD/config/postgresql/biserver-ce-tmp




if [ -f "$sql_script_dir/create_quartz_postgresql.sql" ]; then
	su - $db_user -c "psql $db_param < $sql_script_dir/create_quartz_postgresql.sql"
fi

if [ -f "$sql_script_dir/create_repository_postgresql.sql" ]; then
       su - $db_user -c "psql $db_param < $sql_script_dir/create_repository_postgresql.sql"
fi

if [ -f "$sql_script_dir/create_jcr_postgresql.sql" ]; then
       su - $db_user -c "psql $db_param < $sql_script_dir/create_jcr_postgresql.sql"
fi

#cp -r $PWD/config/postgresql/biserver-ce-tmp/* $install_dir/biserver-ce/*


