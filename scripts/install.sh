#! /bin/bash

#if type -p java; then
#    echo Info: Encontrado executável do java no PATH
#    _java=java
#el

echo Info: Verificando instalação do java
if [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
    echo Info: Executavel java encontrado em "$JAVA_HOME"/bin/java
    _java="$JAVA_HOME/bin/java"
elif type -p java; then
    echo Info: Encontrado executável do java no PATH
    _java=java
else
    echo "Erro: Instalação cancelada. java não encontrado"
    exit 0    
fi

if [[ "$_java" ]]; then
    version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo Info: Versão "$version"
else
    echo Erro: Instalação cancelada. Necessário instalação do java
    exit 0
fi

if [[ "$JAVA_HOME" ]]; then
    echo Info: JAVA_HOME="$JAVA_HOME"
else
    echo Info: JAVA_HOME não definido
fi

echo Info: Verificando usuário pentaho

user_info=$(getent passwd pentaho)
#echo $user_info
if [[ "$user_info" ]]; then
    user_dir=$(getent passwd pentaho | awk -F ':' '{print $6}')
    echo Info: Usuário pentaho encontrado no diretório "$user_dir"
    read -p "Confirma diretório de instalação: [$user_dir] (y/n)?" yn
    if [ $yn = "y" ] || [ $yn = "Y" ]; then 
        echo ok
    fi
fi

