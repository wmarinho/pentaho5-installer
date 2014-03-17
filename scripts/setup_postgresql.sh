!#/bin/bash
PWD=`pwd`
datetime=`date +"%Y%m%d-%H%M"`
install_dir="/opt/pentaho/biserver-ce"
postgres_user="postgres"
postgres_host="localhost"

if [ "$1" ]; then
	install_dir="$1"
fi

sql_script_dir="$install_dir/biserver-ce/data/postgresq"
postgres_bkp_dir="/tmp/pentaho/bkp/postgres"


function db_backup {

	echo "Fazendo backup do banco PostgreSQL ..."
	if [ ! -d "$postgres_bkp_dir" ]; then
		su - postgres -c mkidr -p "$postgres_bkp_dir"
	fi
	
	su - postgres -c "pg_dumpall -U $postgres_user -h $postgres_host > /tmp/pentaho/pq_dump_pentaho_${datetime}.sql"
}

#cp -r $PWD/config/postgresql/biserver-ce $PWD/config/postgresql/biserver-ce-tmp

#cp -r $PWD/config/postgresql/biserver-ce-tmp/* $install_dir/biserver-ce/*



if [ -f "$sql_script_dir/create_quartz_postgresql.sql" ]; then
#su - postgres -c "psql -U $postgres_user -h $postgres_host < $sql_script_dir/create_quartz_postgresql.sql"
fi

if [ -f "$sql_script_dir/create_repository_postgresql.sql" ]; then
#       su - postgres -c "psql -U $postgres_user -h $postgres_host < $sql_script_dir/create_repository_postgresql.sql"
fi

if [ -f "$sql_script_dir/create_jcr_postgresql.sql" ]; then
#       su - postgres -c "psql -U $postgres_user -h $postgres_host < $sql_script_dir/create_jcr_postgresql.sql"
fi
