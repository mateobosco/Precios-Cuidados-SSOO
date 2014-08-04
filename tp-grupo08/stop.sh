#!/bin/bash
# Grupo 8 Tema D
#
# Comando "stop"
# 

# Verifico ambiente inicializado
#if [ -n "$RETAIL_ENV" ] || [ $RETAIL_ENV != "Loaded" ]
#then
#	echo "El ambiente no ha sido inicializado previamente, debe inicializarlo mediante el comando initializer."
#	exit 1
#fi

PID="$(ps -u $EUID | grep 'listener.sh' | awk '{ print $1 }')"
if [ ! -z "$PID" ]
then
	echo "listener.sh ya se esta ejecutando, se envia la señal TERM."
	"$GRUPO/$BINDIR"/logging.sh stop "listener.sh se esta ejecutando, se envia la señal TERM." INFO
	kill $PID
else
	echo "listener.sh no se estaba ejecutando, se ignora el pedido."
	"$GRUPO/$BINDIR"/logging.sh stop "listener.sh no se estaba ejecutando." WAR
fi
exit 0
