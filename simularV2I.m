function [matrizTrenV2I,matrizInterestacionesV2I,KPIv2i] = simularV2I(matrizParametrosIniciales,matrizInterEstaciones,numeroTrenes,numeroInterEstaciones,matrizInfoCanal,errorPosicionamiento,longitudLinea,umbralVelocidadCero,curvas)
%function [matrizTrenV2I,matrizInterestacionesV2I,KPIv2i] = simularV2I(matrizParametrosIniciales,matrizInterEstaciones,numeroTrenes,numeroInterEstaciones,matrizInfoCanal,errorPosicionamiento,longitudLinea,umbralVelocidadCero,curvas)
    %
    % Función que simula el funcionamiento de un sistema CBTC-V2I
    %
    % Datos de entrada:
    %
    % matrizParametrosIniciales = matriz que contiene los parametros
    % iniciales de cada tren
    % matrizInterEstaciones = matriz que contiene informacion sobre las interestaciones
    % numeroTrenes = numero de trenes en la linea
    % numeroInterestaciones = numero de interestaciones de la linea
    % matrizInfoCanal = matriz que contiene informacion sobre los
    % parámetros del canal de comunicaciones
    % errorPosicionamiento: error de posicion provocado por la medida de
    % las balizas
    % longitudLinea = longitud total de la linea
    % umbralVelocidadCero = Umbral para la deteccion de velocidad cero en torno a los 2km/h
    % curvas = vector que contiene las zonas de curva de la linea
    %
    % Datos de salida:
    %
    % matrizTrenV2I = matriz de parametros del tren relativos a la
    % utilizacion de CBTC-V2I
    % matrizInterestacionesV2I = matriz de parametros de la interestacion relativos a la
    % utilizacion de CBTC-V2I
    % KPIv2i = matriz de KPIs del tren relativos a la utilizacion de CBTC-V2I
    % Fecha: 15-06-2017
    %
    
    aceleracionMax = 1.2; %aceleración maxima del tren en m/s^2
    condicionFinalizacion = 12000;%condicion de finalizacion del del sistema CBTC-V2I(12000 segundos de simulacion total)
    incrementoTiempoMovimiento = 0.1;%incremento de tiempo de movimiento del tren(100 milisegundos)
    A = 21.5;
    B = 44.2;
    C = 20;
    c = 3*10^8;%Velocidad de la luz en el vacio

    matrizInterestacionesV2I = matrizInterEstaciones;
    matrizTrenV2I = matrizParametrosIniciales;

    %Extraemos la información del documento Parametros_canal
    frecuencia = matrizInfoCanal(1,1);%frecuencia de trabajo en GHz
    longitudOnda = c/(frecuencia*10^9);%longitud de onda en metros
    anchoTunel = random('norm',matrizInfoCanal(1,2),0.5);%ancho del tunel en metros
    alturaTunel = random('norm',matrizInfoCanal(1,3),0.5);%altura del tunel en metros
    Gananciatx = random('norm',matrizInfoCanal(1,4),0.25);%Ganancia de transmisor en dB
    Gananciarx = random('norm',matrizInfoCanal(1,5),0.25);%Ganancia de receptor en dB
    erv = random('norm',matrizInfoCanal(1,6),0.5);%permitividad relativa en las paredes verticales del túnel
    erh = random('norm',matrizInfoCanal(1,7),0.5);%permitividad relativa en las paredes horizontales del túnel
    factorForma = matrizInfoCanal(1,8);%factor de forma del túnel. En este caso se utiliza un túnel de forma arqueada
    potenciaTransmitida = matrizInfoCanal(1,10);%Potencia transmitida en dBm
    sensibilidadReceptor = matrizInfoCanal(1,11);%Sensibilidad del receptor en dBm
    fading = matrizInfoCanal(1,16);%Atenuacion adicional (dB) debido al shadow fading

    %Se calcula el numero de estaciones base y la  distancia  a la que habrá que colocarlas para dar
    %cobertura a toda la línea a partir del modelo de canal V2I. Este  vector solo se utiliza para el sistema CBTC-V2I
    
    %Valor real de las perdidas de propagacion al restar potencia transmitida
    %menos sensibilidad del receptor (dB)
    perdidas = abs((sensibilidadReceptor + random('norm',1,1)) - potenciaTransmitida);
    %Perdidas relativas a la geometria del tunel (dB)
    perdidasGeometria = abs(log10(factorForma*(longitudOnda.^2).*(((erh)./((sqrt(erh-1)).*(anchoTunel.^3))) + (1./((sqrt(erv-1)).*(alturaTunel.^3)))))); 
    %Se calcula la distancia maxima entre estaciones base teniendo en cuenta
    %todas las perdidas posibles, incluyendo zona de curvatura
    distanciaMax = 10.^((perdidas - fading + perdidasGeometria + Gananciatx + Gananciarx - (random('norm',10,1)) - B - (C*log10(frecuencia/5)))./(A));
    %Se establece un margen del 10% para que se produzca solapamiento de
    %cobertura y pueda existir comunicacion en toda la linea
    distanciaReal = distanciaMax - 0.1*(distanciaMax);
    %Numero de estaciones base totales a colocar en la linea
    numeroEstacionesBase = round(longitudLinea/distanciaReal);
    
    %Se inicializa el vector de infraestructuras
    infraestructuras = zeros(1,numeroEstacionesBase);
    
    for j=1:numeroEstacionesBase 
        %Se establece la posición de cada infraestructura en la linea con
        infraestructuras(1,j) = j*distanciaReal;   
    end

    %Creamos la matriz de KPIs para el sistema CBTC-V2I
    KPIv2i = zeros(numeroTrenes,13);
    n = 1;%Variable auxiliar para recorrer el array de los parámetros del tren
    tiempoSimulacion = 0;%Contador del tiempo de simulacion

    while tiempoSimulacion < condicionFinalizacion%Condicion de finalizacion

        %Si el tren sigue parado en la estacion, no realizará movimiento hasta que transcurra el tiempo de parada en la estacion
        if ((matrizTrenV2I(n,8) == (matrizInterestacionesV2I(matrizTrenV2I(n,7),4))) || (matrizTrenV2I(n,2) == longitudLinea)) && (matrizTrenV2I(n,11) < (matrizInterestacionesV2I(matrizTrenV2I(n,7),2)))
            matrizTrenV2I(n,11) = matrizTrenV2I(n,11) + 1;%Se incrementa el tiempo en la estación
            tiempoSimulacion = tiempoSimulacion + 1;%Se le suma al tiempo de simulacion el tiempo que el tren este parado en la estacion
            KPIv2i(n,6) = KPIv2i(n,6) + 1;%Se incrementa el tiempo total de uso del sistema
            KPIv2i(n,12) = KPIv2i(n,12) + 1;%Se incrementa el tiempo total de uso del sistema
        else
        
            %Se comprueba si el tren n ha llegado al final de la linea o ha sobrepasado este valor
            %Si es así, vuelve a comenzar desde el inicio de la linea(linea circular)
            if matrizTrenV2I (n,2) >= longitudLinea
        
                matrizTrenV2I(n,1) = 1;%El tren empieza desde el principio de la linea
                matrizTrenV2I(n,2) = 1;%El tren empieza desde el principio de la linea
                matrizTrenV2I(n,8) = matrizInterestacionesV2I(1,4);%Su límite será ahora el limite de la primera interestacion
        
            %Se comprueba que el tren no haya hecho un frenado de emergencia en la iteracion anterior
            %si el tren está parado por haber realizado un frenado de emergencia, no se produce movimiento
            elseif (matrizTrenV2I(n,10) == 0)
        
                if (matrizTrenV2I (n,2) + (matrizTrenV2I(n,9)/2)) < (matrizTrenV2I(n,8))
                %Si la parte delantera del tren no ha llegado a la zona de frenado segun el perfil de velocidad ATP, estará en fase de
                %aceleración: acelerando o circulando con velocidad constante (deriva)
        
                    %Zona de aceleracion V < Vmax: el tren acelera hasta alcanzar su velocidad maxima 
                    if matrizTrenV2I(n,3) < matrizTrenV2I(n,12)
            
                        matrizTrenV2I(n,4) = random('norm',aceleracionMax,0.1);%en el primer tramo, el tren acelera con aproximadamente aceleracion maxima
                        matrizTrenV2I(n,3) = (matrizTrenV2I(n,4)).*(matrizTrenV2I(n,5)) + abs(random('norm',1,0.5));%velocidad del tren en el tramo de aceleracion 
                        matrizTrenV2I(n,2) = 0.5.*((matrizTrenV2I(n,4)).*((matrizTrenV2I(n,5)).^2)) + (matrizTrenV2I(n,3)).*(matrizTrenV2I(n,5)) + matrizTrenV2I(n,1);%posicion del tren en el tramo de aceleracion

                    else %Zona de deriva: v >= vmax

                        matrizTrenV2I(n,4) = abs(random('norm',0,0.25));%aceleracion proxima a 0 ya que se ha alcanzado la velocida máxima y no se acelera mas
                        matrizTrenV2I(n,3) = matrizTrenV2I(n,12);%la velocidad en este tramo es la maxima
                        matrizTrenV2I(n,2) = 0.5.*((matrizTrenV2I(n,4)).*((matrizTrenV2I(n,5)).^2)) + (matrizTrenV2I(n,3)).*(matrizTrenV2I(n,5)) + matrizTrenV2I(n,1);%posicion del tren en el tramo de velocidad constante

                    end%Fin de zona de aceleración

                    matrizTrenV2I(n,5) = matrizTrenV2I(n,5) + incrementoTiempoMovimiento; %Se incrementa el tiempo de aceleración del tren
                    %Se actualiza la posicion calculada debido al error en la medida por parte de las balizas
                    matrizTrenV2I(n,2) = matrizTrenV2I(n,2) + errorPosicionamiento(floor(matrizTrenV2I(n,2)));
    
                else
                    %Se inicia la fase de frenado del tren
                    %El tren ha llegado a la siguiente estación ya que su su posición es igual o mayor a la posición límite de la
                    %interestacion o su velocidad es menor que el umbral de velocidad cero, por lo que estaria parado
                    if ((matrizTrenV2I(n,2) + (matrizTrenV2I(n,9)/2)) >=  matrizInterestacionesV2I(matrizTrenV2I(n,7),4)) || (matrizTrenV2I(n,2) < umbralVelocidadCero)
                
                        matrizTrenV2I(n,4) = 0;%no hay aceleracion al estar el tren parado
                        matrizTrenV2I(n,3) = 0;%la velocidad es nula al estar el tren parado
                        matrizTrenV2I(n,2) = matrizInterestacionesV2I(matrizTrenV2I(n,7),4);%el tren está en la siguiente interestacion,se actualiza su posición al inicio de la siguiente interestación
                        matrizTrenV2I(n,1) = matrizInterestacionesV2I(matrizTrenV2I(n,7),4);%el tren está en la siguiente interestacion,se actualiza su posición inicial al inicio de la siguiente interestación
                        %Se comprueba si el tren ha llegado a la ultima estacion
                        if matrizTrenV2I(n,2) == longitudLinea
                            matrizTrenV2I(n,7) = numeroInterEstaciones;
                            matrizTrenV2I(n,7) = 1;%El tren empieza desde la linea 1 (linea circular)
                        else
                            matrizTrenV2I(n,7) = matrizTrenV2I (n,7) + 1;%Se pasa al tren a la siguiente interestación
                            matrizTrenV2I(n,8) = matrizInterestacionesV2I(matrizTrenV2I(n,7),4);%Su límite estara en la zona de frenado de la interestación en la que se encuentra ahora
                            KPIv2i(n,11) = KPIv2i(n,11) + matrizInterestacionesV2I(matrizTrenV2I(n,7) - 1,1);%Se incrementa el tiempo total de uso del sistema
                        end
                    
                        matrizTrenV2I(n,5) = incrementoTiempoMovimiento; %Se reinicia el contador del tiempo de aceleración
                        matrizTrenV2I(n,6) = incrementoTiempoMovimiento; %Se reinicia el contador del tiempo de frenado
                        matrizTrenV2I(n,11) = 0;%Se reinicia el contador de tiempo de parada en la estacion
                        matrizTrenV2I(n,13) = 1;%El tren que lleva detrás sabrá que este tren se ha parado en la estacion
                        matrizInterestacionesV2I(n,3) = matrizInterestacionesV2I(n,3) + 1;%Se incrementa el contador de interestaciones por las que pasa el tren

                    else%Si la velocidad calculada es mayor que el umbral o no se ha llegado al limite de frenado con el obstaculo,el tren estará frenando con aceleración negativa
            
                        matrizTrenV2I(n,4) = -(random('norm',aceleracionMax,0.1));%la aceleración es negativa al estar el tren frenando
                        matrizTrenV2I(n,3) = abs(matrizTrenV2I(n,4).*(matrizTrenV2I(n,6)) + matrizTrenV2I(n,3));%velocidad del tren en el tramo de frenado
                        matrizTrenV2I(n,2) = matrizTrenV2I(n,2) + abs((0.5.*((matrizTrenV2I(n,4)).*((matrizTrenV2I(n,6)).^2))) + ((matrizTrenV2I(n,3)).*(matrizTrenV2I(n,6)))); %Posición actual del tren: Se suma la posición que ocupaba anteriormente mas la que ha avanzado en esta iteración
                        matrizTrenV2I(n,6) = matrizTrenV2I(n,6) + incrementoTiempoMovimiento; %Se incrementa el tiempo de frenado del tren 1 milisegundo
            
                    end%fin de la zona de frenado

                end%fin de la zona de aceleracion

            end%fin de la zona de comprobacion de final de linea
    
            %Fin del bloque de movimiento
       
            %Después de realizar el calculo de los parámetros de movimiento, se procede a realizar un modelo de canal para determinar la cobertura
    
            %El ultimo tren no tiene otro tren por delante, por lo que su LMA sera la siguiente estacion
            if n >= numeroTrenes
                %Se calcula el limite maximo que el tren puede acelerar hasta la
                %zona de frenado de la siguiente estacion
                if matrizTrenV2I(n,3) > 0
                    tiempoFrenado = (matrizTrenV2I(n,3))./(matrizTrenV2I(n,4));%Tiempo que el tren estará frenando
                    distanciaFrenado = abs(((-1*matrizTrenV2I(n,4)).*(tiempoFrenado.^2))/2 + (matrizTrenV2I(n,3).*tiempoFrenado) + random('norm',5,1));%distancia maxima que recorrera el tren cuando este frenando 
                    matrizTrenV2I(n,8) = matrizInterestacionesV2I(matrizTrenV2I(n,7),4) - distanciaFrenado;%Al ser el último tren,su límite está en la zona de frenado de la interestación en la que se encuentra
                    tiempoSimulacion = tiempoSimulacion + incrementoTiempoMovimiento;%Se incrementa el tiempo de simulacion
                end
            else
          
                posicionTrenPrecedente = matrizTrenV2I(n+1,2);
                velocidadTrenPrecedente = matrizTrenV2I(n+1,3);
            
                %Se realiza el modelo de canal para CBTC-V2I. Si existe comunicacion, V2I valdra 1 y se podra simular el sistema CBTC. 
                %Si no es posible establecer comunicación con la infraestructura o el tren , V2I valdra cero, no se simulará CBTC 
                [V2I,potenciaRecibidaFinal] = comunicacionesV2I (matrizInfoCanal,matrizTrenV2I,n,curvas,infraestructuras);
            
                if V2I == 1%Si V2I = 1, es posible establecer comunicacions V2I

                    KPIv2i(n,10) = KPIv2i(n,10) + potenciaRecibidaFinal;
                    KPIv2i(n,1) = matrizTrenV2I(n,2);
                    %Se obtienen los parametros actualizados tras la simulacion de CBTC
                    [posicionActualizada,velocidadActualizada,aceleracionActualizada,limiteMax,contadorFrenados,frenadoEmergencia,distanciaTrenes,tiempoCBTC,incrementoTiempoSimulacion,posicionTrenPrecedenteActualizada,contadoraux] = cbtcV2I (matrizTrenV2I,matrizInterestacionesV2I,matrizInfoCanal,KPIv2i,n,posicionTrenPrecedente,velocidadTrenPrecedente);
                    matrizTrenV2I(n,4) = aceleracionActualizada;
                    matrizTrenV2I(n,3) = velocidadActualizada;
                    matrizTrenV2I(n,2) = posicionActualizada;
                    matrizTrenV2I(n,8) = limiteMax;
                    matrizTrenV2I(n,10) = frenadoEmergencia;
                    matrizTrenV2I(n+1,2) = posicionTrenPrecedenteActualizada;
                    %Si se ha producido un frenado de emergencia, se reinician los contadores de tiempo de movimiento
                    if (matrizTrenV2I(n,10) == 1)
                        matrizTrenV2I(n,1) = posicionActualizada;
                        matrizTrenV2I(n,5) = incrementoTiempoMovimiento;
                        matrizTrenV2I(n,6) = incrementoTiempoMovimiento;
                    end
                    %Se introducen los datos obtenidos en la matriz de KPIs
                    KPIv2i(n,2) = distanciaTrenes;
                    KPIv2i(n,3) = KPIv2i(n,3) + 1;
                    KPIv2i(n,4) = contadorFrenados;
                    KPIv2i(n,5) = KPIv2i(n,5) + (matrizTrenV2I(n,2) - KPIv2i(n,1));%Se suma la distancia recorrida con este sistema
                    KPIv2i(n,6) = tiempoCBTC;%Se incrementa el tiempo que se utiliza este sistema
                    KPIv2i(n,7) = KPIv2i(n,7) + incrementoTiempoSimulacion;%Se incementa el tiempo total del tren en la interestacion usando CBTC-V2I
                    KPIv2i(n,13) = contadoraux;    
                    
                    %Se comprueba si el tren precedente ya ha pasado por la estacion
                    if matrizTrenV2I (n+1,13) == 1
                        %Se comprueba si el tren n ha llegado a la estacion por la que ha pasado el tren n+1
                        if matrizTrenV2I(n,7) == matrizTrenV2I(n+1,7)
                            matrizTrenV2I (n+1,13) = 0;%Se reinicia el contador del tiempo entre trenes
                            KPIv2i(n,8) = KPIv2i(n,8) + 1;%Se incrementa el numero de veces que se ha realizado este calculo
                        else %el tren n no ha llegado a la estacion por la que ha pasado el tren n+1
                            KPIv2i(n,9) = KPIv2i(n,9) + incrementoTiempoSimulacion + incrementoTiempoMovimiento;%Se incrementa el tiempo entre trenes
                        end
                    end

                end%Fin de la comprobacion de uso del sistema CBTC-V2I
            
                tiempoSimulacion = tiempoSimulacion + incrementoTiempoMovimiento + incrementoTiempoSimulacion;%Se incrementa el tiempo de simulacion
            
            end%Fin de la comprobacion del ultimo tren
        
        end%Fin de la comprobacion del tiempo de parada en la estacion
    
        if n >= numeroTrenes
            n = 1;%Se reinicia el contador de trenes
        else
            n = n + 1;%Se incrementa el contador de trenes
        end
    
    end%Fin de la simulacion