#!/bin/bash

COMANDO="Masterlist"

# Directorios
LISTAS="$GRUPO/$MAEDIR/listas"
PROCESADAS="$LISTAS/procesadas"

# Archivos
SUPERMAE="$GRUPO/$MAEDIR/super.mae"
ASOCSMAE="$GRUPO/$MAEDIR/asociados.mae"
PRECIOSMAE="$GRUPO/$MAEDIR/precios.mae"

#--------------------

if [ ! -f $PRECIOSMAE ]  # si no existe precios.mae, lo creo
then	
	touch $PRECIOSMAE
fi

#1) Inicializa el log
$GRUPO/$BINDIR/logging.sh $COMANDO "Inicio de $COMANDO"
cantidad=$(find $LISTAS -maxdepth 1 -not -type d | wc -w)  # obtiene la cantidad de listas
$GRUPO/$BINDIR/logging.sh $COMANDO "Cantidad de Listas de Precios a procesar: <$cantidad>"

#11) Procesa todas las listas
for file in $(find $LISTAS -maxdepth 1 -not -type d)  # recorre todos los files en la carpeta de aceptados
do
	#2) Procesa un archivo
	file=$(echo ${file##*/})  # elimina la ruta y deja solo el nombre del archivo
	$GRUPO/$BINDIR/logging.sh $COMANDO "Archivo a procesar: <$file>"  # registra el nombre de los archivos que va procesando
	
	motivoRechazo=""

	#3) Verifica si el archivo es duplicado
	if [ ! -f $PROCESADAS/$file ]  # si no esta duplicado
	then
		echo "Procesando archivo $file"  #feedback por stdout
		fechaLista=$(echo "$file" | sed 's/.*-\(.*\)\..*/\1/')  # extraigo la fecha de generacion de la lista
		usuario=$(echo ${file##*.})  # extraigo el usuario que confeccionó la lista

		#4) Valida el registro cabecera
		cabecera=$(head -1 "$LISTAS/$file")  # leo solo la primer linea del archivo

		super=$(echo "$cabecera" | cut -d';' -f1)  # extraigo el campo NOMBRE_SUPER
		prov=$(echo "$cabecera" | cut -d';' -f2)  # extraigo el campo PROVINCIA
		nroCampos=$(echo "$cabecera" | cut -d';' -f3)  # extraigo el campo CANTIDAD_CAMPOS
		posProd=$(echo "$cabecera" | cut -d';' -f4)  # extraigo el campo UBICACION_PRODUCTO
		posPrecio=$(echo "$cabecera" | cut -d';' -f5)  # extraigo el campo UBICACION_PRECIO
		correo=$(echo "$cabecera" | cut -d';' -f6)  # extraigo el campo CORREO_COLABORADOR

		if [ `grep -c "$prov;$super" $SUPERMAE` = 0 ]  # si no existe el supermercado con la provincia
		then
			motivoRechazo="Supermercado inexistente"
		elif !(("$nroCampos" > 1))  # si la cantidad de campos no es > 1
		then
			motivoRechazo="Cantidad de campos inválida"
		elif !(("$posProd" > 0)) || !(("$posProd" <= "$nroCampos")) || !(("$posProd" != "$posPrecio")) # valido posicion del producto
		then
			motivoRechazo="Posición de producto inválida"
		elif !(("$posPrecio" > 0)) || !(("$posPrecio" <= "$nroCampos")) || !(("$posProd" != "$posPrecio"))  # valido posicion del precio
		then
			motivoRechazo="Posición de precio inválida"
		elif [ `grep -c "$usuario;.*;$correo" $ASOCSMAE` = 0 ]  # si el correo no existe en asociados.mae
		then
			motivoRechazo="Correo electrónico del colaborador inválido"
		fi
		
		if [ "$motivoRechazo" = "" ]  # si la validación de cabecera no tuvo problemas
		then
			#5) Determinar el SUPER_ID
			linea=`grep "$prov;$super" $SUPERMAE`
			superId=`echo ${linea%%;*}`
			
			regsEliminados=0

			#6) Determinar si es un ALTA, REEMPLAZO o RECHAZO
			if [ `grep -c "$superId;$usuario" $PRECIOSMAE` != 0 ]  # si existe algún registro con super+usuario
			then
				fechaReemplazo=""

				while read fechaReg  # recorre los registros con super+usuario
				do
					if (("$fechaLista" < "$fechaReg"))  # si la fecha de la lista es menor que la del registro
					then
						motivoRechazo="fecha anterior a la existente"  # RECHAZO
						break
					else
						fechaReemplazo="$fechaReg"  # guardo la fecha anterior a la de la lista que se está procesando
					fi
				done < <(sed -n "s/$superId;$usuario;\([^;]*\).*/\1/p" "$PRECIOSMAE")

				if [ "$motivoRechazo" = "" ]  # si la lista no se rechazó
				then
					#8) Procesar REEMPLAZO
					regCount1=`grep -c "$superId;$usuario;$fechaReemplazo.*" $PRECIOSMAE`
					sed -i "/$superId;$usuario;$fechaReemplazo.*/d" "$PRECIOSMAE"  # borro los registros con super+usuario+fechaReemplazo 
					regCount2=`grep -c "$superId;$usuario;$fechaReemplazo.*" $PRECIOSMAE`
					regsEliminados=$(($regCount1 - $regCount2))
				fi
			fi
			
			if [ "$motivoRechazo" = "" ]  # si la lista no se rechazó
			then
				regsOk=0
				regsNok=0
				
				while read line  # recorre todas las lineas del archivo desde la 2da
				do
					#7) Procesar ALTA
					producto=$(echo "$line" | cut -d';' -f"$posProd")
					precio=$(echo "$line" | cut -d';' -f"$posPrecio")
					
					producto=$(echo "$producto" | sed 's/^ *$/null/')  # valido el campo
					precio=$(echo "$precio" | sed 's/^ *$/null/')  # valido el campo

					if [ "$producto" = "null" ] || [ "$precio" = "null" ]  # el registro es inválido
					then
						regsNok=$(($regsNok + 1))
					else
						#9) Grabar registro en lista maestra de precios
						echo "$superId;$usuario;$fechaLista;$producto;$precio" >> $PRECIOSMAE
						regsOk=$(($regsOk + 1))
					fi
				done < <(more +2 "$LISTAS/$file")

				#10) Fin de archivo
				$GRUPO/$BINDIR/logging.sh $COMANDO "Registros eliminados: $regsEliminados"
				$GRUPO/$BINDIR/logging.sh $COMANDO "Registros OK: $regsOk"
				$GRUPO/$BINDIR/logging.sh $COMANDO "Registros NOK: $regsNok"
				$GRUPO/$BINDIR/mover.sh $LISTAS/$file $PROCESADAS  # mueve el archivo a procesados
			fi
		fi  # cabecera OK
	else
		motivoRechazo="estar DUPLICADO"
	fi # archivo no duplicado

	if [ "$motivoRechazo" != "" ]  # si hubo problemas rechazo el archivo
	then
		$GRUPO/$BINDIR/logging.sh $COMANDO "Se rechaza el archivo por $motivoRechazo" WAR
		$GRUPO/$BINDIR/mover.sh $LISTAS/$file $GRUPO/$RECHDIR  # mueve el archivo a rechazados
	fi
done

#12) Cierra el log
$GRUPO/$BINDIR/logging.sh $COMANDO "Fin de $COMANDO"

