function [V2I,potenciaRecibidaFinal] = comunicacionesV2I (matrizCanal,matrizTren,n,curvas,infraestructuras)
    %function [V2I,potenciaRecibidaFinal] = comunicacionesV2I (matrizCanal,matrizTren,n,curvas,infraestructuras)
    %
    % Función que simula el modelo de canal de un sistema CBTC-V2I
    %
    % Datos de entrada:
    % matrizInfoCanal = matriz que contiene informacion sobre los
    % parámetros del canal de comunicaciones
    % matrizTren = matriz que contiene datos de movimiento del tren
    % n = numero del tren de la linea 
    % curvas = vector que contiene las zonas de curva de la linea
    % infraestructuras = vector que contiene la posición de todas las
    % estaciones base a lo largo de la linea
    %
    % Datos de salida:
    % V2I = devuelve un valor positivo si es posible establecer
    % comunicaciones tren-infraestructura y viceversa
    % potenciaRecibidaFinal = potencia recibida por el el ten
    %
    % Fecha: 08/03/2017
    %
    
    %Declaración de constantes
    %A,B y C son coeficientes utilizados en el calculo de pathloss segun el modelo WINNER
    A = 21.5;
    B = 44.2;
    C = 20;
    c = 3*10^8;%Velocidad de la luz en el vacio
    
    posicionTren = matrizTren (n,2);% posicionTren = posicion en metros del tren n
    posicionTrenPrecedente = matrizTren (n+1,2);% posicionTrenPrecedente = posicion en metros del tren n+1
    
    %Extraemos la frecuencia de trabajo del documento Parametros_canal
    frecuencia = matrizCanal(1,1);%frecuencia de trabajo en GHz
    longitudOnda = c/(frecuencia*10^9);%longitud de onda en metros
    anchoTunel = random('norm',matrizCanal(1,2),0.5);%ancho del tunel en metros
    alturaTunel = random('norm',matrizCanal(1,3),0.5);%altura del tunel en metros
    Gananciatx = random('norm',matrizCanal(1,4),0.25);%Ganancia de transmisor en dB
    Gananciarx = random('norm',matrizCanal(1,5),0.25);%Ganancia de receptor en dB
    erv = random('norm',matrizCanal(1,6),0.5);%permitividad relativa en las paredes verticales del túnel
    erh = random('norm',matrizCanal(1,7),0.5);%permitividad relativa en las paredes horizontales del túnel
    factorForma = matrizCanal(1,8);%factor de forma del túnel. En este caso se utiliza un túnel de forma arqueada
    potenciaTransmitida = matrizCanal(1,10);%Potencia transmitida en dBm
    sensibilidadReceptor = matrizCanal(1,11);%Sensibilidad del receptor en dBm
    fading = matrizCanal(1,16);%Perdidas debidas a shadow fading
    potenciaRecibidaFinal = 0;
    
    distanciaInfraestructura = min(abs(infraestructuras - posicionTrenPrecedente));%Se obtiene la distancia del tren precedente a la infraestructura mas cercana
	distanciaTren = min(abs(infraestructuras - posicionTren));%Se obtiene la distancia del tren n a la infraestructura mas cercana

    %Perdidas relativas a la geometria del tunel (dB)
    perdidasGeometria = abs(log10(factorForma*(longitudOnda.^2).*(((erh)./((sqrt(erh-1)).*(anchoTunel.^3))) + (1./((sqrt(erv-1)).*(alturaTunel.^3))))));
    
	%Se comprueba si el tren precedente esta en una zona de curvas.Si es así, se añade una atenuación adicional a las pérdidas de propagación
	if ((posicionTrenPrecedente > curvas(1)) && (posicionTrenPrecedente < curvas(2))) || ((posicionTrenPrecedente > curvas(3)) && (posicionTrenPrecedente < curvas(4)))
            
         perdidasIniciales = (A*log10(distanciaInfraestructura)) + B + (C*log10(frecuencia/5)) + perdidasGeometria + fading - Gananciatx - Gananciarx + (random('norm',10,1));
         potenciaRecibidaInicial = potenciaTransmitida - perdidasIniciales;%Se calcula la potencia recibida total por la infraestructura mas cercano respecto al tren
        
	else%Si no está en zona de curva, no se añade atenuación adicional a las perdidas de propagacion
        
        perdidasIniciales = (A*log10(distanciaInfraestructura)) + B + (C*log10(frecuencia/5)) + perdidasGeometria + fading - Gananciatx - Gananciarx;
        potenciaRecibidaInicial = potenciaTransmitida - perdidasIniciales;%Se calcula la potencia recibida total por el tren
        
	end%Fin de la comprobación de zona de curva

	%Se comprueba si la potencia recibida por la infraestructura mas cercana es menor que la sensibilidad de su receptor 
	if potenciaRecibidaInicial > (sensibilidadReceptor + random('norm',1,1))
           
        %Se comprueba si el tren esta en una zona de curvas.Si es así, se añade una atenuación adicional a las pérdidas de propagación
        if ((posicionTren> curvas(1)) && (posicionTren < curvas(2))) || ((posicionTren > curvas(3)) && (posicionTren < curvas(4)))
            
            perdidasFinales = (A*log10(distanciaTren)) + B + (C*log10(frecuencia/5)) + perdidasGeometria + fading - Gananciatx - Gananciarx + (random('norm',10,1));
            potenciaRecibidaFinal = potenciaTransmitida - perdidasFinales;%Se calcula la potencia recibida total por la infraestructura mas cercano respecto al tren
        
        else%Si no está en zona de curva, no se añade atenuación adicional a las perdidas de propagacion
        
            perdidasFinales = (A*log10(distanciaTren)) + B + (C*log10(frecuencia/5)) + perdidasGeometria + fading - Gananciatx - Gananciarx;
            potenciaRecibidaFinal = potenciaTransmitida - perdidasFinales;%Se calcula la potencia recibida total por el tren
        
        end%Fin de la comprobación de zona de curva
        
        %Si se puede establecer la comunicación, se comprobará que la
        %infraestructura pueda comunicarse con el tren que va detras.
        if potenciaRecibidaFinal > (sensibilidadReceptor + random('norm',1,1))
            
            %Si V2I = 1,se podrá establecer la comunicación con la infraestructura y se realizará el cálculo del sistema CBTC en el tren. 
            V2I = 1;
            
        else
            %Si V2I = 0, no será posible la comunicación con la
            %infraestructura y no se reciben datos, por lo que el sistema
            %se queda con los datos recibidios anteriormente
            V2I = 0;
            
        end%Fin de la comprobacion de la potencia recibida por el tren n
        
    else
        
        %No se podrá establecer comunicación con la infraestructura    
        V2I = 0;
            
	end%Fin comprobacion de potencia recibida por la infraestructura
    
end%Fin funcion comunicacionesV2I
      