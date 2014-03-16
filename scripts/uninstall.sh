#!/bin/bash
read -p "Tem certeza que deseja desistalar o Pentaho? (y/n) " yn
if [ "$yn" == "y" ] || [ "$yn" == "Y" ]; then
	read -p "****** ATENÇÃO: TODOS OS ARQUIVOS SERÃO EXCLUÍDOS. CONFIRMA? (y/n): " y
        if [ "$y" == "y" ] || [ "$y" == "Y" ]; then
		userdel -f -r pentaho
	fi
fi
