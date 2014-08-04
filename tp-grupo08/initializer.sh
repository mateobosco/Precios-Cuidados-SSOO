#!/bin/bash
# Grupo 8 Tema D
# Comando "initializer"
#
# Opciones y Parámetros: No recibe parametros, se debe ejecutar con punto espacio ". initializer.sh"

lin=$(grep "GRUPO" "../conf/installer.conf")
valor=$(echo "$lin" | cut -f2 -d '=')

export GRUPO=$valor

export CONFDIR="conf"

# Funcion que verifica la existencia del directorio pasado por parametro
existe ()
{
	if [ ! -e "$1" ]
	then
		echo "No existe el $3 $2 ($1)."
		"$GRUPO/$CONFDIR"/logging.sh initializer "No existe el $3 $2 ($1)." ERR
		return 1
	fi # [ ! -e "$1" ]
}

permiso_rw ()
{
	if [ ! -r "$1" ] || [ ! -w "$1" ]
	then
		"$GRUPO/$CONFDIR"/logging.sh initializer "No tengo permiso de lectura / escritura en el $3 $2 ($1)." WAR
		"$GRUPO/$CONFDIR"/logging.sh initializer "Corrigiendo los permisos de lectura / escritura en el $3 $2 ($1)." INFO
		chmod +rw $1
		if [ $? -eq 1 ]
		then
			echo "No fue posible corregir los permisos de lectura / escritura en el $3 $2 ($1), debe volver a instalar."
			"$GRUPO/$CONFDIR"/logging.sh initializer "No fue posible corregir los permisos de lectura / escritura en el $3 $2 ($1)." ERR
			return 1
		fi # [ $? -eq 1 ]
	fi # [ ! -r "$1" ] || [ ! -w "$1" ]
}

permiso_exe ()
{
	if [ ! -x "$1" ]
	then
		"$GRUPO/$CONFDIR"/logging.sh initializer "No tengo permiso de ejecucion en el $3 $2 ($1)." WAR
		"$GRUPO/$CONFDIR"/logging.sh initializer "Corrigiendo los permisos de ejecucion en el $3 $2 ($1)." INFO
		chmod +x $1
		if [ $? -eq 1 ]
		then
			echo "No fue posible corregir los permisos de ejecucion en el $3 $2 ($1), debe volver a instalar."
			"$GRUPO/$CONFDIR"/logging.sh initializer "No fue posible corregir los permisos de ejecucion en el $3 $2 ($1)." ERR
			return 1
		fi # [ $? -eq 1 ]
	fi # [ ! -x "$1" ]
}
# Loggeo el inicio del comando 
"$GRUPO/$CONFDIR"/logging.sh initializer " Inicio comando ." INFO

# No puede recibir parametros
if [ $# -gt 0 ]
then
	echo " Initializer no recibe parametros, volver a ejecutar."
        "$GRUPO/$CONFDIR"/logging.sh initializer " Initializer no recibe parametros." ERR
	return 1
fi # [ $# -gt 0 ]

# Verifico ambiente inicializado
#if [ -n "$RETAIL_ENV" ] && [ $RETAIL_ENV == "Loaded" ]
if [ -n "$RETAIL_ENV" ] && [ $RETAIL_ENV == "Loaded" ]
then
	echo "El ambiente ya ha sido inicializado, para ejecutar el Listener utilize el comando ./start.sh listener.sh."
	"$GRUPO/$BINDIR"/logging.sh initializer "El ambiente ya ha sido inicializado." WAR
	return 1
fi # [ -n "$RETAIL_ENV" ] && [ $RETAIL_ENV == "Loaded" ]

# Verifico instalacion completa
if [ ! -d "$GRUPO/$CONFDIR" ]
then
	echo "No existe el directorio de configuracion $CONFDIR, volver a instalar."
	return 1
fi # [ ! -d "$GRUPO/$CONFDIR" ]

if [ ! -f "$GRUPO/$CONFDIR/installer.conf" ]
then
	echo " No se encuenta el archivo de configuracion, volver a instalar."
	"$GRUPO/$CONFDIR"/logging.sh initializer " No se encuenta el archivo de configuracion, volver a instalar." INFO		
	return 1	
fi # [ ! -f "$GRUPO/$CONFDIR/installer.conf" ]

# Busco variables de ambiente en archivo de conf y las exporto 
for i in BINDIR MAEDIR NOVEDIR DATASIZE ACEPDIR RECHDIR INFODIR LOGDIR LOGEXT MAXLOGSIZE
do
	linea=$(grep $i "$GRUPO/$CONFDIR/installer.conf")
	if [ -z "$linea" ] 
	then
		echo "Falta la variable $i en el archivo de configuracion, debe correr el instalador otra vez."
		return 1
	fi

	if [ -z "$(echo "$linea" | grep '=')" ]
	then
		echo "La entrada de $i es invalida en el archivo de configuracion, debe correr el instalador nuevamente."
		return 1
	fi
		
	valor=$(echo "$linea" | cut -f2 -d '=')
	if [ -z "$valor" ]
	then
		echo "La variable $i tiene un valor nulo, verifique la configuracion de xxxxx"
		return 1
	fi
	
	export $i=$valor
done

# Verifico existencia directorios de las variables de ambiente y los permisos
for i in CONFDIR BINDIR MAEDIR NOVEDIR ACEPDIR RECHDIR INFODIR 
do
	eval valor="\$$i"
	existe "$GRUPO/$valor" "$i" "directorio"
	permiso_rw "$GRUPO/$valor" "$i" "directorio"
done

# Verifico valores validos
for i in MAXLOGSIZE DATASIZE
do
	eval valor="\$$i"
	if [ ! -z $(echo "$valor" | grep '[^0-9]') ]
	then
		echo "El campo $i ($valor) deberia ser numerico, debe ingresar la cantidad de MegaBytes cuando pregunta el instalador."
		"$GRUPO/$CONFDIR"/logging.sh initializer "El campo $i ($valor) deberia ser numerico, debe ingresar la cantidad de MegaBytes." ERR
		return 1
	fi
done

# Verifico existencia de los comandos y permisos
for i in mover.sh logging.sh initializer.sh start.sh stop.sh listener.sh masterlist.sh rating.sh reporting.pl
do
	existe "$GRUPO/$BINDIR/$i" "$i" "archivo"
	permiso_exe "$GRUPO/$BINDIR/$i" "$i" "archivo"
done

# Verifico existencia archivos necesarios
for i in asociados.mae super.mae um.tab
do
	existe "$GRUPO/$MAEDIR/$i" "$i" "archivo"
	permiso_rw "$GRUPO/$MAEDIR/$i" "$i" "archivo"
done

# export RETAIL_ENV= "Loaded"

# Ver si se desea correr Listener

while [ "$eleccion" != "SI" ] && [ "$eleccion" != "NO" ]
do
	printf "Desea efectuar la activacion de listener? (Si - No) "
	read eleccion
	eleccion=$(echo "$eleccion" | tr 'a-z' 'A-Z')
	if [ "$eleccion" == "SI" ]
	then
		"$GRUPO/$BINDIR"/start.sh listener.sh
	else
		if [ "$eleccion" != "NO" ]
		then
			echo "Respuesta no reconocida, las opciones validas son: Si - No."
		else
			echo "Puede efectuar la activacion de listener mediante start.sh listener.sh"
		fi
	fi
done

# Muestro variables
echo "TP SO7508 Primer Cuatrimestre 2014. Tema D Copyright Grupo 8"
echo "Directorio de Configuracion: $GRUPO/$CONFDIR"
ls $GRUPO/$CONFDIR
echo "Directorio de Ejecutables: $GRUPO/$BINDIR"
ls $GRUPO/$BINDIR
echo "Directorio Maestros y Tablas: $GRUPO/$MAEDIR"
ls $GRUPO/$MAEDIR
echo "Directorio de Novedades: $GRUPO/$NOVEDIR"
echo "Directorio de Novedades Aceptadas: $GRUPO/$ACEPDIR"
echo "Directorio Informes de Salida: $GRUPO/$INFODIR"
echo "Directorio de Log de Comandos: $GRUPO/$LOGDIR/<comando>$LOGEXT"
echo "Directorio de Novedades Rechazados: $GRUPO/$RECHDIR"
echo "Estado del Sistema: LOADED"

# Notifico ambiente inicializado
export RETAIL_ENV=Loaded

# Loggeo el fin del comando 
$GRUPO/$BINDIR/logging.sh initializer " Se realizo correctamente la inicializacion del programa ." INFO

return 0