#!/bin/bash
# Grupo 8 Tema D
#
# Comando "mover"
# 
# Opciones y Parámetros
#   Parámetro 1 (obligatorio): archivo origen
#   Parámetro 2 (obligatorio): ruta destino
#   Parámetro 3 (opcional): comando que lo invoca

CONFIGURACION=../conf/installer.conf
BINDIR=`grep '^BINDIR' $CONFIGURACION | sed 's-\(.*\)=\(.*\)=\(.*\)=\(.*\)-\2-g'`

# Valido que el ambiente haya sido correctamente inicializado
#if [ -z "$RETAIL_ENV" ] # Si el ambiente fue inicializado, RETAIL_ENV tiene el valor "Loaded"
#then
#	echo "El ambiente no ha sido correctamente inicializado."
#	echo "No será posible utilizar el comando mover."
#	exit 1
#fi # [ -z "$RETAIL_ENV" ]

# Valido cantidad de parametros permitidos (2-3)
if [ $# -gt 3 -o $# -lt 2 ]; then
	$GRUPO/$BINDIR/logging.sh mover " Cantidad de parámetros inválida." ERR
	exit 1
fi # [ $# -gt 3 -o $# -lt 2 ]

origen=$1
destino=$2
comando=$3

# Valido que el origen recivido sea un archivo 
if [ ! -f $origen ];then 
	if [ $# -eq 3 ]; then
	        $GRUPO/$BINDIR/logging.sh mover " Mover Invocado por el comando $comando: Archivo para mover invalido." ERR
	        exit 1
	fi
	$GRUPO/$BINDIR/logging.sh mover " Archivo para mover invalido." ERR
	exit 1
fi # [ ! -f $origen ]

# Valido el directorio del destino exista
if [ ! -d $destino ]; then 
	if [ $# -eq 3 ]; then
	        $GRUPO/$BINDIR/logging.sh mover " Mover Invocado por el comando $comando: El directorio destino no existe." ERR
	        exit 1
	fi
	$GRUPO/$BINDIR/logging.sh mover " El directorio destino no existe." ERR
	exit 1
fi # [ ! -d $destino ]

nombreArchivo=`echo "$origen" | sed 's/^.*\/\(.*\)$/\1/'`
destinoCompleto="$destino/$nombreArchivo"

# Valido que la ruta origen y ruta destino sean diferentes
if [ "$origen" == "$destinoCompleto" ]; then
	if [ $# -eq 3 ]; then
	        $GRUPO/$BINDIR/logging.sh mover " Mover Invocado por el comando $comando: No se hizo nada porque el directorio origen es igual al directorio destino." ERR
	        exit 1
	fi
        $GRUPO/$BINDIR/logging.sh mover " No se hizo nada porque el directorio origen es igual al directorio destino." ERR
	exit 1
fi # [ "$origen" == "$destinoCompleto" ]

if [ -f "$destinoCompleto" ]; then #Archivo duplicado
	if [ ! -d "$destino/dup" ]; then
		mkdir "$destino/dup"
	fi # [ ! -d "$destino/dup" ]
	# Veo si no existe ya un archivo en dup con el mismo nombre y segun la extension aumentar el nnn
	nnn=$(ls "$destino/dup" | grep "^$nombreArchivo.[0-9]\{1,3\}$" | sort -r | sed s/$nombreArchivo.// | head -n 1)
	if [ "$nnn" == "" ]; then # por si todavia no habia ninguna copia del archivo en dup
		nnn=0
	fi # [ "$nnn" == "" ]
	if [ "$nnn" == "999" ]; then #el numero nnn tiene un rango de 1 a 999
           if [ $# -eq 3 ]; then
	        $GRUPO/$BINDIR/logging.sh mover " Mover Invocado por el comando $comando: No se pudo copiar, demasiados archivos duplicados." ERR
	        exit 1
           fi # [ $# -eq 3 ]
	fi # [ "$nnn" == "999" ]
	nnn=$(echo $nnn + 1 | bc -l) #sumo 1 al numero de secuencia
	mv "$1" "$destino/dup/$nombreArchivo.$nnn"
	if [ $# -eq 3 ]; then
	        $GRUPO/$BINDIR/logging.sh mover " Mover Invocado por el comando $comando: Archivo $destinoCompleto duplicado, movido a $destino/dup." INFO
                $GRUPO/$BINDIR/logging.sh $comando " Archivo $destinoCompleto duplicado, movido a $destino/dup." INFO 
	else
             $GRUPO/$BINDIR/logging.sh mover " Archivo $destinoCompleto duplicado, movido a $destino/dup." INFO
        fi # [ $# -eq 3 ]
else
	mv "$1" "$2"
	if [ $# -eq 3 ]; then
	       $GRUPO/$BINDIR/logging.sh mover " Mover Invocado por el comando $comando: Archivo $origen movido correctamente." INFO
               $GRUPO/$BINDIR/logging.sh $comando " Archivo $origen movido correctamente." INFO 
	else
               $GRUPO/$BINDIR/logging.sh mover " Archivo $origen movido correctamente." INFO
        fi # [ $# -eq 3 ]
fi # [ -f "$destinoCompleto" ]

exit 0