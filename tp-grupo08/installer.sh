#!/bin/bash
#
# installer.sh
# Script para la instalacion del paquete RETAILD
#

# Exit Codes
# 0 - Instalacion Completa
# 1 - Ningun componente instalado
# 2 - Instalacion Incompleta

GRUPO=`pwd`
CONFDIR="conf"
MAEDIR="mae"
BINDIR="bin"
NOVEDIR="arribos"
DATASIZE=100 #MB
LOGDIR="log"
LOGEXT=".log"
LOGSIZE=400 #KB
LOGFILE="$CONFDIR/installer.log"
CONFFILE="$CONFDIR/installer.conf"
ACEPDIR="aceptadas"
INFODIR="informes"
RECHDIR="rechazados"

function toLower() {
    echo $1 | tr "[:upper:]" "[:lower:]"
}

function loguear() {
    logDate=`date "+%y-%m-%d_%H-%M-%S"` 
    echo "$logDate-$USER-$1-$2" >> $LOGFILE
}

function echoAndLog() {
    echo -e "$2"
    loguear "$1" "$2"
}

function chequeoInicial() {
    if [ ! -w "$GRUPO" ]; then
        echo "No tiene permisos de escitura en el directorio de instalación"
        echo "Instalación cancelada"
        exit 2
    fi

    if [ ! -d "$CONFDIR" ]; then
        echo "No existe el directorio $CONFDIR"
        echo "Instalación cancelada"
        exit 2
    elif [ ! -w "$CONFDIR" ]; then
        echo "No tiene permisos de escritura sobre el directorio $CONFDIR"
        echo "Instalación cancelada"
        exit 2
    fi
}

#Funcion para crear directorios
#Parametros:
#1 - Permisos 
#2 - Path del directorio a crear
function crearDirectorio() {
    if [ ! -d $2 ]; then
        mkdir -p -m$1 $2 2>/dev/null 
    fi
}

function terminosCondiciones() {
    echo "***************************************************************************"
    echo "*     TP SO7508 Primer Cuatrimestre 2014. Tema D Copyright © Grupo 08     *"
    loguear "Info" "TP SO7508 Primer Cuatrimestre 2014. Tema D Copyright © Grupo 08"
    echo "***************************************************************************"
    loguear "Info" "Al instalar TP SO7508 Primer Cuatrimestre 2014 UD. expresa estar en un todo de acuerdo con los términos y condiciones del \"ACUERDO DE LICENCIA DE SOFTWARE\" incluido en este paquete."
    echo "* Al instalar TP SO7508 Primer Cuatrimestre 2014 UD. expresa estar en un  *"
    echo "* todo de acuerdo  con los términos y condiciones del \"ACUERDO DE         *"
    echo "* LICENCIA DE SOFTWARE\" incluido en este paquete.                         *"
    echo "***************************************************************************"
    echoAndLog "Info" "Acepta? (s/n): "

    read respuesta

    loguear "Info" "$respuesta"
        
    if [ "$respuesta" = "" ] || [ `toLower $respuesta` != "s" ]; then
        echoAndLog "Info" "Instalacion Cancelada"
        exit 1
    fi
}

#Funcion que verifica si la version de perl instalada es 5 o superior
#Return Codes:
#    0 - La version instalada es 5 o superior
#    1 - No esta instalado perl o la version es menor a 5
function verificarPerl() {
    perlVersion=`perl --version | grep -o "v[5-9]\.[0-9]\{1,\}\.[0-9]\{1,\}"`
    if [ $? -ne 0 ]; then
        echoAndLog "Err" "Para instalar RETAILD es necesario contar con  Perl 5 o superior instalado. Efectúe su instalación e inténtelo nuevamente. Proceso de Instalación Cancelado."
        exit 1
    else
        echoAndLog "Info" "Version de Perl instalada: $perlVersion"
    echo ""
    fi
}

function mensajesInformativos() {
    echoAndLog "Info" "Todos los directorios del sistema serán subdirectorios de $GRUPO"
    echoAndLog "Info" "Todos los componentes de la instalación se obtendrán del repositorio: $GRUPO/$CONFDIR"
    listado=`ls $GRUPO/$CONFDIR`
    echoAndLog "Info" "Contenido del repositorio: $listado"
    echoAndLog "Info" "El log de la instalación se almacenara en $GRUPO/$CONFDIR"
    echo ""
    echoAndLog "Info" "Al finalizar la instalación, si la misma fue exitosa se dejara un archivo de configuración en $GRUPO/$CONFDIR"
    echo ""
}

function definirDirBinarios() {
    isOk=0
    while [ "$isOk" -eq 0 ]; do
        echoAndLog "Info" "Ingrese el nombre del directorio de ejecutables ($BINDIR):"
        read dirBin
        if [ ! -z "$dirBin" ]; then
            value=`echo $dirBin | grep "^\(\w\|_\)\+\(/\(\w\|_\)\+\)*$"`
            if [ $? -eq 0 ]; then
                BINDIR=$dirBin
                isOk=1
            else
                echoAndLog "Err" "$dirBin no es un nombre de directorio valido."
        echo ""
            fi
        else
            isOk=1
        fi 
    done
    loguear "Info" "Directorio de ejecutables: $BINDIR"
}

function definirDirMae() {
    isOk=0
    while [ "$isOk" -eq 0 ]; do
        echoAndLog "Info" "Ingrese el nombre del directorio para maestros y tablas ($MAEDIR):"
        read dirMae
        if [ ! -z "$dirMae" ]; then
            value=`echo $dirMae | grep "^\(\w\|_\)\+\(/\(\w\|_\)\+\)*$"`
            if [ $? -eq 0 ]; then
                MAEDIR=$dirMae
                isOk=1
            else
                echoAndLog "Err" "$dirMae no es un nombre de directorio valido."
        echo ""
            fi
        else
            isOk=1
        fi 
    done
    loguear "Info" "Directorio para maestros y tablas: $MAEDIR"
}

function definirDirnovedades() {
    isOk=0
    while [ "$isOk" -eq 0 ]; do
        echoAndLog "Info" "Ingrese el nombre del directorio de arribo de novedades ($NOVEDIR):"
        read dirnovedades
        if [ ! -z "$dirnovedades" ]; then
            value=`echo $dirnovedades | grep "^\(\w\|_\)\+\(/\(\w\|_\)\+\)*$"`
            if [ $? -eq 0 ]; then
                NOVEDIR=$dirnovedades
                isOk=1
            else
                echoAndLog "Err" "$dirnovedades no es un nombre de directorio valido."
        echo ""
            fi
        else
            isOk=1
        fi 
    done
    loguear "Info" "Directorio de arribo de novedades: $NOVEDIR"

    #Espacio disponible para NOVEDIR
    freeSize=0
    while [ $freeSize -lt $DATASIZE ]; do
        isOk=0
        while [ "$isOk" -eq 0 ]; do    
            echoAndLog "Info" "Ingrese el espacio minimo requerido para el arribo de novedades en MB ($DATASIZE):"
            read dataSize
            if [ ! -z $dataSize ]; then
                value=`echo $dataSize | grep "^[0-9]\+$"`
                if [ $? -eq 0 ]; then
                    DATASIZE=$dataSize
                    isOk=1
                else
                    echoAndLog "Err" "$dataSize no es un valor válido. Ingrese un valor numérico"
            echo ""
                fi
            else
                isOk=1
            fi
        done

        #Chequeo espacio disponible en disco
        freeSize=`df $GRUPO | tail -n 1 | sed 's/\s\+/ /g' | cut -d ' ' -f 4`
        let freeSize=$freeSize/1024
        if [ $freeSize -lt $DATASIZE ]; then
            echoAndLog "Err" "Insuficiente espacio en disco. Espacio disponible: $freeSize MB. Espacio requerido $DATASIZE MB"
        echo ""
        fi
    done
    loguear "Info" "Espacio para el arribo de novedades en MB: $DATASIZE"
}

function definirDirAcep() {
    isOk=0
    while [ "$isOk" -eq 0 ]; do
        echoAndLog "Info" "Defina el directorio de grabación de las Novedades aceptadas ($ACEPDIR):"
        read dirAcep
        if [ ! -z "$dirAcep" ]; then
            value=`echo $dirAcep | grep "^\(\w\|_\)\+\(/\(\w\|_\)\+\)*$"`
            if [ $? -eq 0 ]; then
                ACEPDIR=$dirAcep
                isOk=1
            else
                echoAndLog "Err" "$dirAcep no es un nombre de directorio valido."
        echo ""
            fi
        else
            isOk=1
        fi 
    done
    loguear "Info" "Directorio de grabación de las Novedades aceptadas: $ACEPDIR"
}

function definirDirInformes() {
    isOk=0
    while [ "$isOk" -eq 0 ]; do
        echoAndLog "Info" "Defina el directorio de grabación de los informes de salida ($INFODIR):"
        read dirInfo
        if [ ! -z "$dirInfo" ]; then
            value=`echo $dirInfo | grep "^\(\w\|_\)\+\(/\(\w\|_\)\+\)*$"`
            if [ $? -eq 0 ]; then
                INFODIR=$dirInfo
                isOk=1
            else
                echoAndLog "Err" "$dirInfo no es un nombre de directorio valido."
        echo ""
            fi
        else
            isOk=1
        fi 
    done
    loguear "Info" "Directorio de grabación de los informes de salida: $INFODIR"
}

function definirDirLog() {
    isOk=0
    while [ "$isOk" -eq 0 ]; do
        echoAndLog "Info" "Ingrese el nombre del directorio de log ($LOGDIR):"
        read dirLog
        if [ ! -z "$dirLog" ]; then
            value=`echo $dirLog | grep "^\(\w\|_\)\+\(/\(\w\|_\)\+\)*$"`
            if [ $? -eq 0 ]; then
                LOGDIR=$dirLog
                isOk=1
            else
                echoAndLog "Err" "$dirLog no es un nombre de directorio valido."
        echo ""
            fi
        else
            isOk=1
        fi 
    done
    loguear "Info" "Directorio de log: $LOGDIR"


    #Extension para los archivos de log
    isOk=0
    while [ "$isOk" -eq 0 ]; do
    echoAndLog "Info" "Ingrese la extension para los archivos de log ($LOGEXT):"
    read logExt
    if [ ! -z "$logExt" ]; then
        value=`echo $logExt | grep "^\.\w\{1,\}$"`
        if [ $? -eq 0 ]; then
            LOGEXT=$logExt
            isOk=1
        else
            echoAndLog "Err" "$logExt no es un nombre de extensión valido."
        echo ""
        fi
    else
        isOk=1
    fi 
    done
    loguear "Info" "Extension archivos de log: $LOGEXT"


    #Tamaño maximo para archivos de log
    isOk=0
    while [ "$isOk" -eq 0 ]; do    
    echoAndLog "Info" "Ingrese el tamaño máximo para los archivos <$LOGEXT> en KB ($LOGSIZE):"
    read logSize
    if [ ! -z $logSize ]; then
        value=`echo $logSize | grep "^[0-9]\+$"`
        if [ $? -eq 0 ]; then
            LOGSIZE=$logSize
            isOk=1
        else
            echoAndLog "Err" "$logSize no es un valor válido. Ingrese un valor numérico"
        echo ""
        fi
    else
        isOk=1
    fi
    done
    loguear "Info" "Tamaño máximo para archivos de log: $LOGSIZE"
}

function definirDirRechazados() {
    isOk=0
    while [ "$isOk" -eq 0 ]; do
        echoAndLog "Info" "Defina el directorio de grabación de Archivos Rechazados ($RECHDIR):"
        read dirRech
        if [ ! -z "$dirRech" ]; then
            value=`echo $dirRech | grep "^\(\w\|_\)\+\(/\(\w\|_\)\+\)*$"`
            if [ $? -eq 0 ]; then
                RECHDIR=$dirRech
                isOk=1
            else
                echoAndLog "Err" "$dirRech no es un nombre de directorio valido."
        echo ""
            fi
        else
            isOk=1
        fi 
    done
    loguear "Info" "Directorio de grabación de Archivos Rechazados: $RECHDIR"
}

function mostrarParametros() {
    echo "**********************************************************"
    echoAndLog "Info" "Parámetros de Instalación del paquete  RETAILD"
    echo "**********************************************************"
    echoAndLog "Info" "Directorio de trabajo: $GRUPO"
    echoAndLog "Info" "Directorio de configuración: $CONFDIR"
    echoAndLog "Info" "Directorio de datos maestros: $MAEDIR"
    echoAndLog "Info" "Directorio de ejecutables: $BINDIR"
    echoAndLog "Info" "Directorio de novedades: $NOVEDIR"
    echoAndLog "Info" "Espacio mínimo reservado en $NOVEDIR: $DATASIZE MB"
    echoAndLog "Info" "Directorio para los archivos de Log: $LOGDIR"
    echoAndLog "Info" "Extensión para los archivos de Log: $LOGEXT"
    echoAndLog "Info" "Tamaño máximo para cada archivo de Log: $LOGSIZE Kb"
    echoAndLog "Info" "Log de la instalación: $CONFDIR"
    echoAndLog "Info" "Directorio de informes: $INFODIR"
    echoAndLog "Info" "Directorio de aceptados: $ACEPDIR"
    echoAndLog "Info" "Directorio de rechazados: $RECHDIR"
    echo ""
}

function confirmarParametros() {
    echoAndLog "Info" "Si los datos ingresados son correctos de ENTER para continuar, si desea modificar algún parámetro oprima cualquier tecla para reiniciar"
    echo ""
    read -s -n1 respuesta

    if [ "$respuesta" = "" ]; then
        return 0
    else
        return 1
    fi
}

function confirmarInstalacion() {
    echoAndLog "Info" "Iniciando Instalación… Está UD. seguro? (Si/No):"
    read respuesta
    if [ "$respuesta" = "" ] || [ `toLower $respuesta` != "si" ]; then
        echoAndLog "Info" "Instalacion Cancelada"
        exit 1
    fi
}

function crearDirectorios() {
    echo "Creando estructuras de directorio..." 
    echo ""
    crearDirectorio 755 "$GRUPO/$CONFDIR"
    crearDirectorio 755 "$GRUPO/$MAEDIR"
    crearDirectorio 755 "$GRUPO/$MAEDIR/listas"
    crearDirectorio 755 "$GRUPO/$MAEDIR/listas/procesadas"
    crearDirectorio 755 "$GRUPO/$BINDIR"
    crearDirectorio 755 "$GRUPO/$NOVEDIR"
    crearDirectorio 755 "$GRUPO/$LOGDIR"
    crearDirectorio 755 "$GRUPO/$ACEPDIR"
    crearDirectorio 755 "$GRUPO/$ACEPDIR/procesadas"
    crearDirectorio 755 "$GRUPO/$INFODIR"
    crearDirectorio 755 "$GRUPO/$INFODIR/listas"
    crearDirectorio 755 "$GRUPO/$RECHDIR"
}

#Funcion para mover archivos
#Parametros:
#    1 - Archivo a mover
#    2 - Path destino del archivo
#    3 - Permisos del archivo
function moverArchivo() {
    if [ -f "$2/${1##*/}" ]; then
    return 2
    fi

    if [ ! -f $1 ]; then 
        loguear "Err" "200:Archivo inexistente: ${1##*/}" 
        return 1
    elif [ ! -d $2 ]; then
        loguear "Err" "200:Directorio inexistente: $2"
        return 1
    else
        mv $1 $2 2>/dev/null
        if [ $? -ne 0 ]; then
            loguear "Err" "210:No se pudo mover el archivo: ${1##*/}"
            return 1
        else
            chmod "$3" "$2/${1##*/}" 2>/dev/null
        fi
    fi
}

function copiarArchivo() {
    if [ -f "$2/${1##*/}" ]; then
    return 2
    fi

    if [ ! -f $1 ]; then 
        loguear "Err" "200:Archivo inexistente: ${1##*/}" 
        return 1
    elif [ ! -d $2 ]; then
        loguear "Err" "200:Directorio inexistente: $2"
        return 1
    else
        cp $1 $2 2>/dev/null
        if [ $? -ne 0 ]; then
            loguear "Err" "210:No se pudo copiar el archivo: ${1##*/}"
            return 1
        else
            chmod "$3" "$2/${1##*/}" 2>/dev/null
        fi
    fi
}

function moverArchivos() {
    echo "Moviendo archivos..."
    echo ""

    moverArchivo "$GRUPO/asociados.mae" "$GRUPO/$MAEDIR" "444"
    moverArchivo "$GRUPO/super.mae" "$GRUPO/$MAEDIR" "444"
    moverArchivo "$GRUPO/um.tab" "$GRUPO/$MAEDIR" "444"

    moverArchivo "$GRUPO/initializer.sh" "$GRUPO/$BINDIR" "775"

    copiarArchivo "$GRUPO/logging.sh" "$GRUPO/$CONFDIR" "775"

    moverArchivo "$GRUPO/logging.sh" "$GRUPO/$BINDIR" "775"

    moverArchivo "$GRUPO/mover.sh" "$GRUPO/$BINDIR" "775"

    moverArchivo "$GRUPO/start.sh" "$GRUPO/$BINDIR" "775"
    moverArchivo "$GRUPO/stop.sh" "$GRUPO/$BINDIR" "775"
    moverArchivo "$GRUPO/rating.sh" "$GRUPO/$BINDIR" "775"

    moverArchivo "$GRUPO/listener.sh" "$GRUPO/$BINDIR" "775"

    moverArchivo "$GRUPO/reporting.pl" "$GRUPO/$BINDIR" "775"
    moverArchivo "$GRUPO/menuayuda" "$GRUPO/$BINDIR" "775"    

    moverArchivo "$GRUPO/masterlist.sh" "$GRUPO/$BINDIR" "775"

}

function leerConfiguracion() {
    if [ -f $CONFFILE ]; then
        GRUPO=`grep "GRUPO" $CONFFILE | cut -s -f2 -d'='`    
        CONFDIR=`grep "CONFDIR" $CONFFILE | cut -s -f2 -d'='`    
        MAEDIR=`grep "MAEDIR" $CONFFILE | cut -s -f2 -d'='`  
        BINDIR=`grep "BINDIR" $CONFFILE | cut -s -f2 -d'='`    
        NOVEDIR=`grep "NOVEDIR" $CONFFILE | cut -s -f2 -d'='`    
        DATASIZE=`grep "DATASIZE" $CONFFILE | cut -s -f2 -d'='`    
        LOGSIZE=`grep "MAXLOGSIZE" $CONFFILE | cut -s -f2 -d'='`    
        LOGDIR=`grep "LOGDIR" $CONFFILE | cut -s -f2 -d'='`    
        LOGEXT=`grep "LOGEXT" $CONFFILE | cut -s -f2 -d'='`    
        ACEPDIR=`grep "ACEPDIR" $CONFFILE | cut -s -f2 -d'='`
        INFODIR=`grep "INFODIR" $CONFFILE | cut -s -f2 -d'='`
        RECHDIR=`grep "RECHDIR" $CONFFILE | cut -s -f2 -d'='`
    fi
}

function guardarConfiguracion() {
    echo "GRUPO=$GRUPO=$USER=`date +"%F %T"`" > $CONFFILE    
    echo "CONFDIR=$CONFDIR=$USER=`date +"%F %T"`" >> $CONFFILE
    echo "MAEDIR=$MAEDIR=$USER=`date +"%F %T"`" >> $CONFFILE
    echo "BINDIR=$BINDIR=$USER=`date +"%F %T"`" >> $CONFFILE
    echo "NOVEDIR=$NOVEDIR=$USER=`date +"%F %T"`" >> $CONFFILE
    echo "DATASIZE=$DATASIZE=$USER=`date +"%F %T"`" >> $CONFFILE
    echo "LOGDIR=$LOGDIR=$USER=`date +"%F %T"`" >> $CONFFILE
    echo "LOGEXT=$LOGEXT=$USER=`date +"%F %T"`" >> $CONFFILE
    echo "MAXLOGSIZE=$LOGSIZE=$USER=`date +"%F %T"`" >> $CONFFILE
    echo "ACEPDIR=$ACEPDIR=$USER=`date +"%F %T"`" >> $CONFFILE
    echo "INFODIR=$INFODIR=$USER=`date +"%F %T"`" >> $CONFFILE
    echo "RECHDIR=$RECHDIR=$USER=`date +"%F %T"`" >> $CONFFILE
}


#Funcion que detecta si estan todos los componentes instalados
#Return Codes:
#     0: Instalacion completa
#     1: Ningun componente instalado
#     2: Instalacion incompleta

function detectarInstalacion {
    cantInst=0
    cantNoInst=0
    unset instalados
    unset noinstalados   
    
    archivosAVerificar=(    "$GRUPO/$BINDIR/initializer.sh"
                "$GRUPO/$CONFDIR/logging.sh"
                "$GRUPO/$BINDIR/logging.sh"
                "$GRUPO/$BINDIR/mover.sh"
                "$GRUPO/$BINDIR/start.sh"
                "$GRUPO/$BINDIR/stop.sh"
                "$GRUPO/$BINDIR/rating.sh"
                "$GRUPO/$BINDIR/masterlist.sh"
                "$GRUPO/$BINDIR/listener.sh"
                "$GRUPO/$BINDIR/reporting.pl"
                "$GRUPO/$BINDIR/menuayuda"
                "$GRUPO/$MAEDIR/asociados.mae"
                "$GRUPO/$MAEDIR/super.mae"
                "$GRUPO/$MAEDIR/um.tab"
               )

    for archivo in ${archivosAVerificar[*]}
    do
        if [ -f "$archivo" ]; then
            owner=`ls -l $archivo | awk '{print $3 " " $6 " " $7}'`
            instalados[$cantInst]="${archivo##*/} $owner"
            let cantInst=$cantInst+1
        else
            noinstalados[$cantNoInst]="${archivo##*/}"
            let cantNoInst=$cantNoInst+1
        fi
    done
    
    if [  $cantInst -gt 0 ] && [ -f "$CONFFILE" ]; then
        if [ $cantNoInst -gt 0 ]; then 
            status=2 #Instalacion incompleta
        else
            status=0 #Instalacion completa
        fi                
    else
        status=1 #No se instalo ningun componente
    fi

    return $status
}

function mostrarComponentesInstalados() {
    detectarInstalacion

    echo "*********************************************************************" 
    echo "*  TP SO7508 Primer Cuatrimestre 2014. Tema D Copyright © Grupo 08  *"
    loguear "Info" "TP SO7508 Primer Cuatrimestre 2014. Tema D Copyright © Grupo 08"
    echo "*********************************************************************"
    
    if [ $cantInst -gt 0 ]; then
    echo -n "* "
        echoAndLog "Info" "Se encuentran instalados los siguientes componentes:"
    echo ""
        arr=("${instalados[@]}")
        for index in ${!arr[*]}
        do
        echo -n "  "
            echoAndLog "Info" "${arr[$index]}"
        done
    fi

    if [ $cantNoInst -gt 0 ]; then 
    echo -e -n "\n* " 
        echoAndLog "Info" "Falta instalar los siguientes componentes:"    
    echo ""
        for item in ${noinstalados[*]}
        do
        echo -n "  "
            echoAndLog "Err" "$item"
        done
        echo ""
    fi
}

#-----------------------------------------------------------------------------------------------#
#----------------------------------------------MAIN---------------------------------------------#
#-----------------------------------------------------------------------------------------------#

loguear "Info" "Inicio de Ejecucion"
clear
chequeoInicial
leerConfiguracion
detectarInstalacion
case "$?" in 
    0 )     #Instalacion completa
        mostrarComponentesInstalados
    echo -n "* "
        echoAndLog "Info" "Proceso de Instalacion Cancelado"
        exit 0;;

    1 )     #No hay instalacion previa
        terminosCondiciones
        verificarPerl
        mensajesInformativos
        modifica=1
        while [ $modifica -ne 0 ]; do
            definirDirBinarios
            definirDirMae
            definirDirnovedades
            definirDirAcep
            definirDirInformes
            definirDirLog
            definirDirRechazados
            clear
            mostrarParametros
            confirmarParametros
            modifica=$?
        done;;

    2 ) #Instalacion previa incompleta
        mostrarComponentesInstalados
        mostrarParametros;;
esac

confirmarInstalacion
crearDirectorios
moverArchivos
guardarConfiguracion
mostrarComponentesInstalados
echo "********************************************************************************************************"
echoAndLog "Info" "Fin del proceso de instalacion TP SO7508 Primer Cuatrimestre 2014. Tema D Copyright © Grupo 08"
echo "********************************************************************************************************" 
exit $?
