#!usr/local/bin/perl
use Switch;


$dir_informes = $ENV{'GRUPO'}."/".$ENV{'INFODIR'}."/";
$dir_maestros = $ENV{'GRUPO'}."/".$ENV{'MAEDIR'}."/";

%ids_prov_supers;
%supers_elegidos;
%ids_users;
%users_elegidos;


#retorna en un string el nombre de supermercado y provincia separados por un guion para el super_id pasado
sub get_super_prov
{
	$codigo = @_[0];
	my ($super_prov);
	if (opendir(DIR, $dir_maestros))		
	{
		$path = $dir_maestros . 'super.mae';
		if (open(ARCH_SUPER, $path))				#abro el archivo y lo asocio al handler
		{
			while ($linea = <ARCH_SUPER>)			#leo linea a linea el archivo
			{
				chomp($linea);	
				@datos_super = split (";", $linea);

				if (@datos_super[0] == $codigo)	#si encontro el id, retorna super-prov
				{
					close(ARCH_SUPER);
					closedir(DIR);
					$super_prov = @datos_super[2] . "-" . @datos_super[1];
					return $super_prov;
				}
			}
		}
	}
		
}



# imprime con formato para las opciones p y m
sub salida_m_p
{
	%hash = @_;
	$n_arch = $dir_informes."temp.txt";
	open (TEMP, ">>$n_arch");      
	foreach $clave (sort {$a <=> $b} keys %hash)
	{			
		@array = @{$hash{$clave}};

		$producto_pedido = @array[0];
		$super_id = @array[1];
		$super_prov = &get_super_prov($super_id);
		$producto_encontrado = @array[2];
		$precio = @array[3];

		$salida = $super_prov."-".$clave."-".$producto_pedido."-".$producto_encontrado."-".$precio."\n";
		print $salida;
		print TEMP $salida;
	}
	close(TEMP);
}



# imprime con formato para la opcion f
sub salida_f
{
	%hash = @_;
	$n_arch = $dir_informes."temp.txt";
	open (TEMP, ">>$n_arch");
	foreach $clave (sort {$a <=> $b} keys %hash)
	{			
		@array = @{$hash{$clave}};
		$salida = $clave."-".@array[0]."\n";
		print $salida;
		print TEMP $salida;
	}	
	close(TEMP);
}




# imprime con formato para la opcion d
sub salida_d
{
	%hash = @_;	
	$n_arch = $dir_informes."temp.txt";
	open (TEMP, ">>$n_arch");
	foreach $clave (sort {$a <=> $b} keys %hash)
	{
		@array = @{$hash{$clave}};
		$salida = &get_super_prov($clave)."\n";
		print $salida;
		print TEMP $salida;
		$cant_arrays = @array / 4;
		$ind = 0;
		for ($i = 0; $i < $cant_arrays; $i++)
		{
			$salida = "   ".@array[$ind]."-".@array[$ind+1]."-".@array[$ind+2]."-".@array[$ind+3]."\n";
			print $salida;
			print TEMP $salida;
			$ind = $ind + 4;
		}
		print "\n";
		print TEMP "\n";
	}	
	close(TEMP);
}




# PRE: recibe el nombre del archivo a procesar y los lugares a filtrar
# POST: retorna un hash con los items con precio de referencia
sub precio_por_referencia
{
	$path = $dir_informes ."listas/". @_[0];
	my (%precios_por_ref, @campos);

	if (open(ARCH, $path))
	{
		while ($linea = <ARCH>)
		{
			chomp($linea);			
			@campos = split(";", $linea);
			if (@campos[2] != 0 and @campos[2] < 100)
			{			
				if ( (@_[1] eq "x" and exists($supers_elegidos{@campos[2]})) or (@_[1] ne "x") )
				{
					$clave = shift(@campos);
					@{$precios_por_ref{$clave}} = @campos;
				}
			}
		}
	}
	close(ARCH);
	return %precios_por_ref;
}




# PRE: recibe el nombre del archivo a procesar y los lugares a filtrar
# POST: retorna un hash con los menores precios por item excluyendo los de referencia
sub menor_precio
{
	$path = $dir_informes ."listas/". @_[0];
	my (%menores_precios, @campos);

	if (open(ARCH, $path))
	{
		while ($linea = <ARCH>)				
		{	
			chomp($linea);			
			@campos = split(";", $linea);
			if (@campos[2] != 0 and @campos[2] >= 100)
			{
				if ( (@_[1] eq "x" and exists($supers_elegidos{@campos[2]})) or (@_[1] ne "x") )
				{				
					$clave = shift(@campos);				
					if (!exists($menores_precios{$clave}))
					{
						@{$menores_precios{$clave}} = @campos;
					}
					else
					{
						if (@campos[3] < @{$menores_precios{$clave}}[3])
						{
							@{$menores_precios{$clave}} = @campos;
						}

					}
				}
			}	
		}
	}	
	close(ARCH);
	return %menores_precios;
}




# PRE: recibe el nombre del archivo a procesar y los lugares a filtrar
# POST: retorna un hash con los datos de los items faltantes
sub faltante
{
	$path = $dir_informes ."listas/". @_[0];
	my (%faltantes);

	if (open(ARCH, $path))
	{
		while ($linea = <ARCH>)				
		{	
			chomp($linea);			
			@campos = split(";", $linea);	
			if (@campos[2] == 0)
			{	
				if ( (@_[1] eq "x" and exists($supers_elegidos{@campos[2]})) or (@_[1] ne "x") )
				{
					$clave = shift(@campos);
					@{$faltantes{$clave}} = @campos;
				}
			}
		}
	}
	close(ARCH);
	return %faltantes;
}



# PRE: recibe el nombre del archivo a procesar y los lugares a filtrar
# POST: retorna un hash con los lugares donde comprar los productos a mas bajo costo
sub donde_comprar
{
	my (%menores_precios_cop, %donde_comprar, @array);	
	%menores_precios_cop = &menor_precio(@_[0], @_[1]);
	foreach $clave (sort {$a <=> $b} keys %menores_precios_cop)
	{
		@array = @{$menores_precios_cop{$clave}};
		$clave_donde_comprar = @array[1];
		@array[1] = @array[0];
		@array[0] = $clave;
		push(@{$donde_comprar{$clave_donde_comprar}}, @array);
	}
	return %donde_comprar;	
}



# PRE: recibe el nombre del archivo a procesar y los lugares a filtrar
# POST: muestra por pantalla los lugares donde comprar y una descripcion con respecto a la relacion del precio del producto con el de ref
sub salida_dp
{
	my (%donde_comprar_cop, %precio_por_ref_cop, @array, @campos);
	%donde_comprar_cop = &donde_comprar(@_[0], @_[1]);
	%precio_por_ref_cop = &precio_por_referencia(@_[0]);
	$n_arch = $dir_informes."temp.txt";
	open (TEMP, ">>$n_arch");
	foreach $clave (sort {$a <=> $b} keys %donde_comprar_cop)
	{
		@array = @{$donde_comprar_cop{$clave}};
		$cant_arrays = @array / 4;
		$ind = 0;
		$salida = &get_super_prov($clave)."\n";
		print $salida;
		print TEMP $salida;
		for ($i = 0; $i < $cant_arrays; $i++)
		{
			$salida = "   ".@array[$ind]."-".@array[$ind+1]."-".@array[$ind+2]."-".@array[$ind+3];
			print $salida;
			print TEMP $salida;

			$nro_item = @array[$ind];
			@campos = @{$precio_por_ref_cop{$nro_item}};
			$precio_ref = @campos[3];
			
			if ($precio_ref >= @array[$ind+3])
			{
				$salida = "-$precio_ref-*\n";
				print $salida;
				print TEMP $salida;
			}
			elsif ($precio_ref == 0)
			{
				$salida = "-No encontrado\n";
				print $salida;
				print TEMP $salida;
			}
			else
			{
				$salida = "-$precio_ref-**\n";
				print $salida;
				print TEMP $salida;
			}

			$ind = $ind + 4;
		}
		print "\n";
		print TEMP "\n";
	}
	close(TEMP);
}




# PRE: recibe el nombre del archivo a procesar y los lugares a filtrar
# POST: muestra por pantalla los menores precios y una descripcion con respecto a la relacion del precio del producto con el de ref
sub salida_mp
{
	my (%menor_precio_cop, %precio_por_ref_cop, @array, @campos);	
	%menor_precio_cop = &menor_precio(@_[0], @_[1]);
	%precio_por_ref_cop = &precio_por_referencia(@_[0]);
	$n_arch = $dir_informes."temp.txt";
	open (TEMP, ">>$n_arch");
	foreach $clave (sort {$a <=> $b} keys %menor_precio_cop)
	{
		@array = @{$menor_precio_cop{$clave}};
		@campos = @{$precio_por_ref_cop{$clave}};
		$precio_ref = @campos[3];		

		$salida = &get_super_prov(@array[1])."-".$clave."-".@array[0]."-".@array[2]."-".@array[3];
		print $salida;
		print TEMP $salida;
		
		if ($precio_ref >= @array[3])
		{
			$salida = "-$precio_ref-*\n";
			print $salida;
			print TEMP $salida;
		}
		elsif ($precio_ref == 0)
		{
			$salida = "-No encontrado\n";
			print $salida;
			print TEMP $salida;
		}
		else
		{
			$salida = "-$precio_ref-**\n";
			print $salida;
			print TEMP $salida;
		}		
	}
	close(TEMP);
}


# se ejecuta para cargar en un hash los ids de los supermercados
sub cargar_ids_super_prov
{
	if (opendir(DIR, $dir_maestros))		
	{
		$path = $dir_maestros . 'super.mae';
		if (open(ARCH_SUPER, $path))				#abro el archivo y lo asocio al handler
		{
			$cont = 1;			
			while ($linea = <ARCH_SUPER>)
			{
				chomp($linea);			
				@campos = split(";", $linea);	
				if (@campos[0] >= 100)
				{
					$ids_prov_supers{$cont} = @campos[0];
					$cont = $cont + 1;
				}
			}
		}
	}
}



sub mostrar_super_prov
{
	print "Listado de supermercados: \n\n";
	foreach $clave (sort {$a <=> $b} keys %ids_prov_supers)
	{
		$id_super_prov = $ids_prov_supers{$clave};
		print $clave."- ".&get_super_prov($id_super_prov)."\n";
	}	
	print "T/t- Mostrar todos los supermercados\n";
}



# POST: retorna un hash con los ids de los supermercados incluidos en la consulta
sub filtrar_supers
{
	&mostrar_super_prov;
	print "\n"."Ingrese el/los codigos de los supermercados a incluir en la consulta separados por -: ";
	$entrada = <STDIN>;
	chomp($entrada);
	my (%supers_incluidos);
	if (($entrada eq 't') or ($entrada eq 'T'))		#se elijen todos los supers
	{
		foreach $clave (sort keys %ids_prov_supers)
		{
			$valor = $ids_prov_supers{$clave};
			$supers_incluidos{$valor} = $valor;
		}
	}
	else
	{
		@codigos = split("-", $entrada);
		foreach $clave (@codigos)
		{	
			if (exists($ids_prov_supers{$clave}))	
			{
				$valor = $ids_prov_supers{$clave};
				$supers_incluidos{$valor} = $valor;
			}
		}
	}
	return %supers_incluidos;
}



# se ejecuta para cargar en un hash los nombres de los archivos presupuestados
sub cargar_users
{
	$n_dir = $dir_informes."listas/";
	if (opendir(DIR, $n_dir))		#abro el directorio para leer las listas presupuestadas por usuario
	{
		@names_arch = readdir(DIR);
		close(DIR);
		$cont = 1;		
		foreach $name_arch (@names_arch)		#recorro todos los archivos del directorio 
		{
			if ($name_arch !~ /^\./ and $name_arch !~ /~$/)		#excluyo los archivos ocultos
			{	
				$ids_users{$cont} = $name_arch;
				$cont = $cont + 1;
			}
		}
	}
}


sub mostrar_users
{
	print "Listado de listas presupuestadas: \n\n";
	foreach $clave (sort {$a <=> $b} keys %ids_users)
	{
		print $clave."-".$ids_users{$clave}."\n";
	}
}


# POST: retorna un hash con los users incluidos en la consulta
sub filtrar_users
{
	&mostrar_users;
	print "\n"."Ingrese el/los codigos de los usuarios a incluir en la consulta separados por -: ";
	$entrada = <STDIN>;
	chomp($entrada);
	@codigos = split("-", $entrada);

	my (%users_incluidos);
	foreach $clave (@codigos)
	{
		if (exists($ids_users{$clave}))
		{
			$valor = $ids_users{$clave};
			$users_incluidos{$valor} = $valor;
		}
	}
	return %users_incluidos;
}





sub ayudar
{
	system('clear');
	system('cat menuayuda');
	print "\n\nPresione enter para retornar al menu de consulta... ";	 
	getc();
}




sub imprimir_menu
{
	system('clear');
	print "Consultas e Informes\n\n";
	print "-a:  Ayuda"."\n";
	print "-p:  Precio por referencia"."\n";
	print "-m:  Menor precio"."\n";
	print "-d:  Donde comprar"."\n";
	print "-f:  Faltante"."\n";
	print "-mp: Menor precio por referencia"."\n";
	print "-dp: Donde comprar por referencia"."\n";
	print "-x:  Filtrar por supermercado-provincia"."\n";
	print "-u:  Filtrar por usuario"."\n";
	print "-s:  Salir"."\n";
	print "\nIngresar opcion y filtro a ejecutar: ";
	
}



sub recorrer_listas_presupuestadas
{
	$n_dir = $dir_informes."listas/";
	if (opendir(DIR, $n_dir))		#abro el directorio para leer las listas presupuestadas por usuario
	{
		@names_arch = readdir(DIR);
		close(DIR);
		$n_arch = $dir_informes."temp.txt";
		open (TEMP, ">$n_arch");
		close(TEMP);
		foreach $name_arch (@names_arch)		#recorro todos los archivos del directorio 
		{	
			system('clear');
			open (TEMP, ">$n_arch");
			if ($name_arch !~ /^\./ and $name_arch !~ /~$/)		#excluyo los archivos ocultos
			{	
				if ( ((@_[1] eq "u") and exists($users_elegidos{$name_arch})) or (@_[1] ne "u") )
				{
					$salida = $name_arch."\n";
					print $salida;
					print TEMP $salida;
					close (TEMP);
					switch(@_[0])
					{
						case "p" {&salida_m_p(&precio_por_referencia($name_arch, @_[1]))}	
						case "m" {&salida_m_p(&menor_precio($name_arch, @_[1]))}
						case "d" {&salida_d(&donde_comprar($name_arch, @_[1]))}
						case "f" {&salida_f(&faltante($name_arch, @_[1]))}
						case "mp" {&salida_mp($name_arch, @_[1])} 
						case "dp" {&salida_dp($name_arch, @_[1])}
					}
					print "\n";
					open (TEMP, ">>$n_arch");
					print TEMP "\n";
					close (TEMP);
				
					print "\n-g: ¿Desea guardar el resultado del informe? [s/n]: ";
					$guardar = <STDIN>;
					chomp($guardar);
					if ($guardar eq 's')
					{
						$new_name_arch = "info.".$name_arch;
						$comando = "mv $n_arch $dir_informes"."$new_name_arch";
						system($comando);
					}
				}
			}
		}
	}
	if (-e $n_arch)
	{
		$comando = "rm $n_arch";
		system($comando);
	}
	print "\n\nPresione enter para retornar al menu de consulta... ";	 
	getc();
}



sub menu
{
	&cargar_ids_super_prov;
	&cargar_users;	

	$ejecutar = 1;
	while ($ejecutar)
	{
		&imprimir_menu;
		$linea = <STDIN>;
		chomp($linea);
		
		@ops_fts = split("-", $linea);
		$opcion = @ops_fts[0];
		$filtro = @ops_fts[1];
		
		if ($opcion eq "a")
		{
			&ayudar;
		}
		elsif ($opcion eq "s")
		{
			$ejecutar = 0;
		}
		else
		{
			if ($filtro)
			{
				system('clear');
				if ($filtro eq "x")
				{
					%supers_elegidos = &filtrar_supers;	
				}
				elsif ($filtro eq "u")
				{
					%users_elegidos = &filtrar_users;
				} 
				else
				{
					system('clear');
					print "No es posible aplicar el filtro ingresado.";
					print  "\n\nPresione enter para ver el resultado de la consulta sin filtrar...";
					getc();
				}
			}
			if ($opcion =~ /(^p$|^f$|^m$|^d$|^mp$|^dp$)/)
			{					
				&recorrer_listas_presupuestadas($opcion, $filtro);
			}
			else
			{
				system('clear');
				print "La opcion ingresada es incorrecta.";
				print  "\n\nPresione enter para retornar al menu de consulta...";
				getc();
			}
		}
	}
}


		


#salida_dp("usuario.juan");
#&cargar_ids_super_prov;
#&filtrar_supers;

#&cargar_users;
#&filtrar_users;
&menu;





