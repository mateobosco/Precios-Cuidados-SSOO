#!/bin/bash

##################################################################################################################################################
#                                       LISTENER
#
#	while true
#		grabar en el log que ciclo es
#		archivos = buscar archivos en $NOVEDIR
#	
#		for archivo in archivos:
#			if (tipo(archivo) no es de texto) se mueve a $RECHDIR
#			elif (nombre(archivo) == formato(LISTADECOMPRAS) se mueve a $ACEPDIR // formato LISTA DE COMPRAS = "usuario.xxx"
#			elif (nombre(archivo) == formato(LISTADEPRECIOS) se mueve a $MAEDIR/listas // formato LISTA DE PRECIOS = "super-fecha.usuario"
#			else se mueve archivo a $RECHDIR y loggear que el motivo de la invalidez
#	
#		archivos = buscar archivos en $MAEDIR/listas
#		for archivo in archivos:
#			if (no se esta corriendo MASTERLIST and no se esta corriendo RATING)
#				MASTERSLIST(archivo)
#				LOG( se esta corriendo masterlist bajo el id_process)
#			else LOG(se deja para el proximo ciclo)
#	
#		archivos = buscar archivos en $ACEPDIR
#		for archivo in archivos:
#			if (no se esta corriendo MASTERLIST and no se esta corriendo RATING)
#				MASTERSLIST(archivo)
#				LOG( se esta corriendo masterlist bajo el id_process)
#			else LOG(se deja para el proximo ciclo)
#	
#		DORMIR(MINUTOS)
####################################################################################################################################################	


#CONFIGURACION=../conf/installer.conf
#GRUPO=`grep '^GRUPO' $CONFIGURACION | sed 's-\(.*\)=\(.*\)=\(.*\)=\(.*\)-\2-g'`
#MAEDIR=`grep '^MAEDIR' $CONFIGURACION | sed 's-\(.*\)=\(.*\)=\(.*\)=\(.*\)-\2-g'`
#NOVEDIR=`grep '^NOVEDIR' $CONFIGURACION | sed 's-\(.*\)=\(.*\)=\(.*\)=\(.*\)-\2-g'`
#RECHDIR=`grep '^RECHDIR' $CONFIGURACION | sed 's-\(.*\)=\(.*\)=\(.*\)=\(.*\)-\2-g'`
#ACEPDIR=`grep '^ACEPDIR' $CONFIGURACION | sed 's-\(.*\)=\(.*\)=\(.*\)=\(.*\)-\2-g'`
#BINDIR=`grep '^BINDIR' $CONFIGURACION | sed 's-\(.*\)=\(.*\)=\(.*\)=\(.*\)-\2-g'`
#export $GRUPO
#export $MAEDIR
#export $BINDIR
#export $ACEPTDIR
#export $RECHDIR

#################################################################################FALTA EL WHILE TRUE
AUX=1

while true; do
	$GRUPO/$BINDIR/logging.sh listener  " Ciclo Nro $AUX." INFO
	for file in $(ls -1 $GRUPO/$NOVEDIR )
	do 
		if !(file $GRUPO/$NOVEDIR/$file | grep '.*text, with CRLF line terminators$') #FILTRA ARCHIVOS QUE SEAN SOLO DE TEXTO
			then $GRUPO/$BINDIR/logging.sh listener  " $file no es un archivo de texto." INFO
			$GRUPO/$BINDIR/mover.sh $GRUPO/$NOVEDIR/$file $GRUPO/$RECHDIR listener	
			
		#elif ( file $GRUPO/$NOVEDIR/$file | sed 's-\(.*\):\(.*\)-\1-g' | grep '^.*-.*\..*$' ) #LISTA DE PRECIOS super-fecha.usuario
		elif ( echo "$file" | grep '^.*-.*\..*$' )
			then usuario=`echo "$file" | sed 's/\(.*\)-\(.*\)\.\(.*\)/\3/g'`
				fecha=`echo "$file" | sed 's/\(.*\)-\(.*\)\.\(.*\)/\2/g'`
				fecha_actual=`date +%Y%m%d`
				fecha_actual+=1
				anio=`echo "$fecha" | sed 's-\([0-9]\{4\}\)\([0-1][0-9]\)\([0-3][0-9]\)-\1-g'`
				mes=`echo "$fecha" | sed 's-\([0-9]\{4\}\)\([0-1][0-9]\)\([0-3][0-9]\)-\2-g'`
				dia=`echo "$fecha" | sed 's-\([0-9]\{4\}\)\([0-1][0-9]\)\([0-3][0-9]\)-\3-g'`
				movido=0
				fecha2=`echo $anio$mes$dia`
				fecha3="$(date -d "$fecha2" +'%D' 2>&1)"
				error=$(echo $fecha3 | grep date | wc -l)
				if [ "$error" = 1 ]
					then $GRUPO/$BINDIR/logging.sh listener  " $file no tiene una fecha valida." INFO; # log fecha invalida
					$GRUPO/$BINDIR/mover.sh $GRUPO/$NOVEDIR/$file $GRUPO/$RECHDIR listener
				
				elif [ $fecha \> $fecha_actual ]
					then $GRUPO/$BINDIR/logging.sh listener  " $file tiene una fecha mayor a la actual." INFO; #log fecha mayor a la actual
					$GRUPO/$BINDIR/mover.sh $GRUPO/$NOVEDIR/$file $GRUPO/$RECHDIR listener
				
				elif [ $fecha \< 20140100 ]
					then $GRUPO/$BINDIR/logging.sh listener  " $file tiene una fecha menor al 01/01/2014." INFO; #log fecha menor al 01/01/2014
					$GRUPO/$BINDIR/mover.sh $GRUPO/$NOVEDIR/$file $GRUPO/$RECHDIR listener
				
				elif [ $dia \< 32 ] && [ $mes \< 13 ] && [ $fecha \< $fecha_actual ] && [ $fecha \> 20140100 ]
					then
					for colaborador in $(grep '.*;.*;.*;1;.*$' $GRUPO/$MAEDIR/asociados.mae | sed 's-\(.*\);\(.*\);\(.*\);\(1\);\(.*\)-\3-g')
					do
						if [ "$usuario" = "$colaborador" ]
							then $GRUPO/$BINDIR/mover.sh $GRUPO/$NOVEDIR/$file $GRUPO/$MAEDIR/listas listener
							$GRUPO/$BINDIR/logging.sh listener  " $file es una lista de precios aceptada, se mueve a $GRUPO/$MAEDIR/listas" INFO
							movido=1
						fi
					done				
				fi
			if [ $movido = 0 ] 
				then $GRUPO/$BINDIR/logging.sh listener  " $file no cumple con el formato super-fecha.usuario." INFO; #Log el archivo no cumple con el formato super-fecha.usuario
				$GRUPO/$BINDIR/mover.sh $GRUPO/$NOVEDIR/$file $GRUPO/$RECHDIR listener
				#mv $NOVEDIR/$file --target-directory=$RECHDIR #reemplazar por el mover
			fi
		
		elif ( echo "$file" | grep '^.*\..*$') #LISTA DE COMPRAS usuario.xxx
			then usuario=`echo "$file" | sed 's-\(.*\)\.\(.*\)-\1-g'`
			movido=0
			for maestro in $(sed 's-\(.*\);\(.*\);\(.*\);\(.*\);\(.*\)-\3-g' $GRUPO/$MAEDIR/asociados.mae)
			do	#echo "el usuario es $usuario y el maestro $maestro"
				if [ "$usuario" = "$maestro" ]
					then $GRUPO/$BINDIR/mover.sh $GRUPO/$NOVEDIR/$file $GRUPO/$ACEPDIR listener
					movido=1
					$GRUPO/$BINDIR/logging.sh listener  " $file es una lista de compras aceptada y se mueve a $GRUPO/$NOVEDIR"
					#echo "EL ARCHIVO $file ES UNA LISTA DE COMPRAS Y ES ACEPTADO PORQUE EL USUARIO ESTA EN LA LISTA DE MAESTROS"
				fi
			done
			if [ $movido = 0 ] 
				$GRUPO/$BINDIR/logging.sh listener  " $file el usuario no esta en la lista de maestros" INFO #log el usuario no esta en la lista de maestros
				then $GRUPO/$BINDIR/mover.sh $GRUPO/$NOVEDIR/$file $GRUPO/$RECHDIR listener
			fi
		else
			$GRUPO/$BINDIR/logging.sh listener  " $file no cumple con el formato usuario.xxx." INFO #Log el archivo no cumple con el formato usuario.xxx
			$GRUPO/$BINDIR/mover.sh $GRUPO/$NOVEDIR/$file $GRUPO/$RECHDIR listener
		fi	

	done

	cantidadMae=`find $GRUPO/$MAEDIR/listas -maxdepth 1 -not -type d | grep -c ''`
	cantidadAcep=`find $GRUPO/$ACEPDIR -maxdepth 1 -not -type d | grep -c ''`
	if (( $cantidadMae > 0 ))
		then 
		masterlistID="$(ps -u $EUID | grep 'masterlist.sh' | awk '{ print $1 }')"
		#masterlistID=$GRUPO/$BINDIR/obtenerpid masterlist
		ratingID="$(ps -u $EUID | grep 'rating.sh' | awk '{ print $1 }')"
		#ratingID=$GRUPO/$BINDIR/obtenerpid rating
		if [ "$masterlisID" = "" ] && [ "$ratingID" = "" ] #if (no se esta corriendo MASTERLIST and no se esta corriendo RATING)
			then 
			"$GRUPO/$BINDIR"/masterlist.sh &
			#"$GRUPO/$BINDIR"/. masterlist.sh
			PID=$!
			$GRUPO/$BINDIR/logging.sh listener  "Masterlist corriendo bajo el PID: $PID" INFO
			echo "Masterlist corriendo bajo el PID: $PID"
		else
		$GRUPO/$BINDIR/logging.sh listener  "Invocacion de Masterlist pospuesta para el siguiente ciclo" INFO
		fi
	


	
	elif (( $cantidadAcep > 0 ))
		then  
		masterlistID="$(ps -u $EUID | grep 'masterlist.sh' | awk '{ print $1 }')"
		#masterlistID=$GRUPO/$BINDIR/obtenerpid masterlist
		ratingID="$(ps -u $EUID | grep 'rating.sh' | awk '{ print $1 }')"
		#ratingID=$GRUPO/$BINDIR/obtenerpid rating
		if [ "$masterlisID" = "" ] && [ "$ratingID" = "" ] #if (no se esta corriendo MASTERLIST and no se esta corriendo RATING)
			then 
			"$GRUPO/$BINDIR"/rating.sh &
			#"$GRUPO/$BINDIR"/. rating.sh
			PID=$!
			$GRUPO/$BINDIR/logging.sh listener  "Rating corriendo bajo el PID: $PID" INFO
			echo "Rating corriendo bajo el PID: $PID" INFO
		else
		$GRUPO/$BINDIR/logging.sh listener  "Invocacion de Rating pospuesta para el siguiente ciclo" INFO
		fi
	fi

	AUX=`expr $AUX "+" 1`
	sleep 1m #DUERME POR 10 MINUTOS
done
