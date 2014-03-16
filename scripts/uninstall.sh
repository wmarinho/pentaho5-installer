#!/bin/bash
pwd=`pwd`
read -p "Tem certeza que deseja desistalar o Pentaho? (y/n) " yn
if [ "$yn" == "y" ] || [ "$yn" == "Y" ]; then
	read -p "****** ATENÇÃO: TODOS OS ARQUIVOS SERÃO EXCLUÍDOS. CONFIRMA? (y/n): " y
        if [ "$y" == "y" ] || [ "$y" == "Y" ]; then
		echo "Desinstalando Pentaho"
	
		$pwd/scripts/_uninstall.sh
		if [ $? -ne 0 ]; then
			echo "Pentaho não foi removido corretamente."
		else
			echo "Pentaho foi removido com sucesso."
		fi
	fi
fi
