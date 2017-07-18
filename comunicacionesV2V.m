function [V2V,potenciaRecibida] = comunicacionesV2V (matrizCanal,matrizTren,n,curvas)
    %function [V2V,potenciaRecibida] = comunicacionesV2V (matrizCanal,matrizTren,n,curvas)
    %
    % Función que  determina si se pueden llevar a cabo las comunicaciones
    % entre trenes a partir del calculo de la potencia recibida
    %
    % Datos de entrada:
    % matrizInfoCanal = matriz que contiene informacion sobre los
    % parámetros del canal de comunicaciones
    % matrizTren = matriz que contiene datos de movimiento del tren
    % n = numero del tren de la linea 
    % curvas = vector que contiene las zonas de curva de la linea
    %
    % Datos de salida:
    % V2V = devuelve un valor positivo si son posibles las comunicaciones V2V
    % potenciaRecibida: potencia recibida por el tren
    %
    % Fecha: 03/03/2017
    %
    
    %Declaración de constantes
    c = 3*10^8;%Velocidad de la luz en el vacio
    
    posicionTren = matrizTren(n,2);% posicionTren = posicion en metros del tren n
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
    exponentePahtloss = matrizCanal(1,9) + (matrizCanal(2,9)-matrizCanal(1,9)).*rand(1,1);%exponente de perdidas de trayecto en un túnel arqueado para una frecuencia de 5GHz
    potenciaTransmitida = matrizCanal(1,10);%Potencia transmitida en dBm
    sensibilidadReceptor = matrizCanal(1,11);%Sensibilidad del receptor en dBm
    fading = matrizCanal(1,15) + (matrizCanal(2,15)-matrizCanal(1,15)).*rand(1,1);%Perdidas debidas a shadow fading
    
	%Perdidas relativas a la geometria del tunel (dB/100m)
    perdidasGeometria = abs(log10(factorForma*(longitudOnda.^2).*(((erh)./((sqrt(erh-1)).*(anchoTunel.^3))) + (1./((sqrt(erv-1)).*(alturaTunel.^3))))));

	%Se comprueba si el tren esta en una zona de curvas.Si es así, se añade una atenuación adicional a las pérdidas de propagación
	if ((posicionTren > curvas(1)) && (posicionTren < curvas(2))) || ((posicionTren > curvas(3)) && (posicionTren < curvas(4)))
            
         perdidasTotales = exponentePahtloss*10*log10(abs(posicionTrenPrecedente - posicionTren))+ (perdidasGeometria*(abs(posicionTrenPrecedente - posicionTren))/100) + fading - Gananciatx - Gananciarx + (random('norm',10,1));
         potenciaRecibida = potenciaTransmitida - perdidasTotales;%Se calcula la potencia recibida total por el tren
        
	else%Si no está en zona de curva, no se añade atenuación adicional a las perdidas de propagacion
        
        perdidasTotales = exponentePahtloss*10*log10(abs(posicionTrenPrecedente - posicionTren))+ (perdidasGeometria*(abs(posicionTrenPrecedente - posicionTren))/100) + fading - Gananciatx - Gananciarx;
        potenciaRecibida = potenciaTransmitida - perdidasTotales;%Se calcula la potencia recibida total por el tren
        
	end%Fin de la comprobación de zona de curva

	%Se comprueba si la potencia recibida es menor que la sensibilidad del receptor V2V más un margen de error
	if potenciaRecibida > (sensibilidadReceptor + random('norm',1,1))
            
        %Si V2V = 1,serán posibles las comunicaciones V2V. Si V2V = 0, solo serán posibles las comunicaciones V2I
        V2V = 1;
	else
            
        V2V = 0;
            
	end%Fin comprobacion de potencia recibida  
    
end%Fin funcion comunicacionesV2V
           