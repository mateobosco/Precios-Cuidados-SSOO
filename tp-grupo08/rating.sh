#!/bin/bash


#CONFIGURACION=../conf/installer.conf
 

#GRUPO=`grep '^GRUPO' $CONFIGURACION | sed 's-\(.*\)=\(.*\)=\(.*\)=\(.*\)-\2-g'`
#MAEDIR=`grep '^MAEDIR' $CONFIGURACION | sed 's-\(.*\)=\(.*\)=\(.*\)=\(.*\)-\2-g'`
#NOVEDIR=`grep '^NOVEDIR' $CONFIGURACION | sed 's-\(.*\)=\(.*\)=\(.*\)=\(.*\)-\2-g'`
#RECHDIR=`grep '^RECHDIR' $CONFIGURACION | sed 's-\(.*\)=\(.*\)=\(.*\)=\(.*\)-\2-g'`
#ACEPDIR=`grep '^ACEPDIR' $CONFIGURACION | sed 's-\(.*\)=\(.*\)=\(.*\)=\(.*\)-\2-g'`
#BINDIR=`grep '^BINDIR' $CONFIGURACION | sed 's-\(.*\)=\(.*\)=\(.*\)=\(.*\)-\2-g'`
#INFODIR=`grep '^INFODIR' $CONFIGURACION | sed 's-\(.*\)=\(.*\)=\(.*\)=\(.*\)-\2-g'`


PROCESADAS=procesadas
ACEPTADOS=$GRUPO/$ACEPDIR


$GRUPO/$BINDIR/logging.sh rating "Inicio de Rating" INFO

cantidad=$(ls -l "$GRUPO/$ACEPDIR" | grep -v total  | wc -l) # calculo la cantidad de archivos a leer

$GRUPO/$BINDIR/logging.sh rating "Cantidad de Listas de compras a procesar:<$cantidad>" INFO
for file in $(ls -1 $GRUPO/$ACEPDIR  ) # recorro todos los files en la carpeta de aceptados
do
	if (file $GRUPO/$ACEPDIR/$file | grep '^.*.*\..*$') #lo proceso si tiene el formato correcto
	then
		$GRUPO/$BINDIR/logging.sh rating "Archivo a procesar: <$file>" 
		if [ -s $GRUPO/$ACEPDIR/$file ] # si existe y no esta vacio
		then	
			if [ -f $GRUPO/$ACEPDIR/$PROCESADAS/$file ] # si esta duplicado, se lo rechaza
			then
				rechazado=1 # se rechaza el archivo por duplicado
				$GRUPO/$BINDIR/logging.sh rating "Se rechaza el archivo $file por estar DUPLICADO"
				$GRUPO/$BINDIR/mover.sh $GRUPO/$ACEPDIR/$file $GRUPO/$RECHDIR
			else
				echo "Procesando archivo $file"	
				uno=1
				lineaactual=1 # linea actual que se procesa
				while read line	# recorre todas las lineas del archivo
				do 
					#rm $GRUPO/$BINDIR/temporal					
					numdepalabras=`echo -n "$line" | wc -w | sed 's/ //g' ` # cantidad de palabras de la linea
					ultimapalabrarenglon=`echo ${line##* }` # agarro la ultima palabra del renglon
					line=`echo $line | awk '{print tolower($0)}'` # la pongo en minusculas
					uno=1
					contador=0
					coincidencia=1
					nro_item=$(echo "$line" | cut -d';' -f1) # GUARDO EL NRO DE ITEM DEL PRODUCTO
					line=$(echo "$line" | cut -d';' -f2)  # GUARDO EL NOMBRE DEL PRODUCTO 
					input=$GRUPO/$MAEDIR/precios.mae
					for word in $line; do # recorro las palabras de la linea
						if [ "$word" != "$ultimapalabrarenglon" ]; then
							actual=`cat "$input" | awk '{print tolower($0)}' | grep "$word "` 
							echo "$actual" > temporal
						fi
						count=`echo $actual | wc -w`
						input=$GRUPO/$BINDIR/temporal
						if [ $count -gt 0 ]; then # si existe y no esta vacio	
							contador=$(($contador+$uno))
						fi
						numdepalabrasmenosuno=$(($numdepalabras-$uno))													
						if [ "$word" = "$ultimapalabrarenglon" ] && [ "$contador" -eq "$numdepalabrasmenosuno" ]; then
							while read line4 # RECORRO LA LISTA DE CONVERSIONES
							do
								if (echo "$line4" | grep "$ultimapalabrarenglon" ) ; then
									contador=$(($contador+$uno))
									fi
							done	< $GRUPO/$MAEDIR/um.tab
				 					
						fi			
					done
					#if [ $contador -eq $numdepalabras ]; then
					#	 echo "======================================= COINCIDE $line ==============================="
					#fi
					if [ $coincidencia = 1 ]; then #si llego hasta aca con coincidencia igual a 1 es porque encontro todas las palabras
						#echo "======================================= COINCIDEN =======================+======"			
						while read linea
						do
							Super_ID=$(echo "$linea" | cut -d';' -f1)  # extraigo el campo NroItem
							ProductoPedido=$(echo "$line" | tr -d "\r" | tr -d "\n")
							ProductoEncontrado=$(echo "$linea" | cut -d';' -f4)
							Precio=$(echo "$linea" | cut -d';' -f5 | tr -d "\r" | tr -d "\n")  # extraigo el campo PROVINCIA

							echo "$nro_item;$ProductoPedido;$Super_ID;$ProductoEncontrado;$Precio" >> $GRUPO/$INFODIR/listas/$file
						done < temporal
					fi
					uno=1
					lineaactual=$(($lineaactual+$uno))
				done < $GRUPO/$ACEPDIR/$file
				$GRUPO/$BINDIR/mover.sh $GRUPO/$ACEPDIR/$file $GRUPO/$ACEPDIR/$PROCESADAS 		
			fi
		else
			$GRUPO/$BINDIR/logging.sh rating "Se rechaza el archivo $file por estar VACIO" WAR
			$GRUPO/$BINDIR/mover.sh $GRUPO/$ACEPDIR/$file $GRUPO/$RECHDIR
		fi
	else
		if [ ! -d $GRUPO/$ACEPDIR/$file ] # si no es un directorio lo mueve
		then
			if [ $GRUPO/$ACEPDIR/$file != $LOGFILE ] # si no es el log lo mueve
			then
				$GRUPO/$BINDIR/logging.sh rating "Se rechaza el archivo $file por formato invalido" WAR
				$GRUPO/$BINDIR/mover.sh $GRUPO/$ACEPDIR/$file $GRUPO/$RECHDIR
			fi
		fi
	fi
done

$GRUPO/$BINDIR/logging.sh rating "Fin del Rating" INFO




