#!/bin/bash
# Grupo 8 Tema D
#
# Comando "start"
# 
# Opciones y Parámetros
#   Parámetro 1 (obligatorio): comando a iniciar

# Verifico ambiente inicializado
#if [ -n "$RETAIL_ENV" ] || [ $RETAIL_ENV != "Loaded" ]
#then
#	echo "El ambiente no ha sido inicializado previamente, debe inicializarlo mediante el comando initializer."
#	exit 1
#fi 

COMANDO=$1

if [ $# -ne 1 ]
then
	echo "No se enviaron los parametros correctos."
        $GRUPO/$BINDIR/logging.sh start "No se enviaron los parametros correctos." ERR
	exit 1
fi

if [ $COMANDO != "listener.sh" ] # 
then
	echo "Se ha llamado a start con un comando no reconocido."
	"$GRUPO/$BINDIR"/logging.sh start "Se ha llamado a start con un comando no reconocido." ERR
	exit 1
fi

## Si ya esta corriendo el comando, entonces no tengo que seguir
PID=$(ps -u "$EUID" | grep "$COMANDO" | awk '{ print $1 }')
if [ ! -z "$PID" ]
then
	echo "$COMANDO ya se esta ejecutando, se ignora el pedido."
	"$GRUPO/$BINDIR"/logging.sh start "$COMANDO ya se esta ejecutando, se ignora el pedido." WAR
else
	"$GRUPO/$BINDIR"/$COMANDO &
	PID=$!
	echo "Ejecutando $COMANDO, PID=$PID."
	"$GRUPO/$BINDIR"/logging.sh start "Ejecutando $COMANDO, PID=$PID." INFO
fi
exit 0