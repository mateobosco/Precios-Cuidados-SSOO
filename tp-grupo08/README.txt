#--------------------------------------------------------------#
  Universidad de Buenos Aires		Facultad de Ingeniería
  Primer Cuatrimestre 2014		Sistemas Operativos

			Trabajo Práctico: Sistema RETAILD
						GRUPO 8
#--------------------------------------------------------------#


Requisitos
----------
* No tiene permisos de escitura en el directorio de instalación
* Para instalar RETAILD es necesario contar con  Perl 5 o superior instalado

Instrucciones de instalacion
----------------------------

1. Acceda a la terminal.
2. Copie el archivo tp-grupo08.tgz a la carpeta en la que quiere realizar la instalacion:
	$ cp [ruta_paquete]/tp-grupo08.tgz [ruta_instalacion]
3. Vaya a la carpeta de instalacion y extraiga el contenido del paquete de instalacion:
	$ cd [ruta_instalacion]
	$ tar -xvf tp-grupo08.tgz
4. Dele permisos al instalador installer.sh:
	$ cd tp-grupo08
	$ chmod u+rx installer.sh
5. Ejecute el instalador:
	$ ./installer.sh

En este punto el programa ya esta instalado y listo para usar.

Inicializacion
--------------

Una vez instalado, acceda a la carpeta en la que instalo los ejecutables de RETAILD y ejecute el comando initializer.sh:
	$ . initializer.sh

Esto inicializara el entorno para poder utilizar los demas comandos, y dejara corriendo el daemon listener, de manera que éste llame pueda llamar a los scripts de masterlist.sh y rating.sh cada cierta cantidad de tiempo de acuerdo a si hay nuevos en donde se instaló la carpeta novedades.

Generación de Reportes
----------------------

Para poder generar los distintos reportes, en la terminal se debe ejecutar reporting.pl con el interprete de perl llendo a la carpeta donde se instalaron los ejecutables de RETAILD asi: 
	$ cd [ruta_instalacion]/[carpeta_ejecutables]
	$ perl reporting.pl

Finalizacion
------------

Para detener el programa, ejecute en la terminal, desde a carpeta en la que instalo los ejecutables de RETAILD:
	$ ./stop.sh

