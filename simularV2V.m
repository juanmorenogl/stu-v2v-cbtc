function [matrizTrenV2V,matrizInterestacionesV2V,KPIv2v] = simularV2V(matrizParametrosIniciales,matrizInterEstaciones,numeroTrenes,numeroInterEstaciones,matrizInfoCanal,errorPosicionamiento,longitudLinea,umbralVelocidadCero,curvas)
%function [matrizTrenV2V,matrizInterestacionesV2V,KPIv2v] = simularV2V(matrizParametrosIniciales,matrizInterEstaciones,numeroTrenes,numeroInterEstaciones,matrizInfoCanal,errorPosicionamiento,longitudLinea,umbralVelocidadCero,curvas)
    %
    % Función que simula el funcionamiento de un sistema CBTC-V2V
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
    % matrizTrenV2V = matriz de parametros del tren relativos a la
    % utilizacion de CBTC-V2V
    % matrizInterestacionesV2V = matriz de parametros de la interestacion relativos a la
    % utilizacion de CBTC-V2V
    % KPIv2v = matriz de KPIs del tren relativos a la utilizacion de CBTC-V2V
    %
    % Fecha: 15-06-2017
    %
    
    incrementoTiempoMovimiento = 0.1;%incremento de tiempo de movimiento del tren(100 milisegundos)
    condicionFinalizacion = 12000;%condicion de finalizacion del del sistema CBTC-V2V(12000 segundos de simulacion total)
    aceleracionMax = 1.2; %aceleración maxima del tren en m/s^2

    matrizInterestacionesV2V = matrizInterEstaciones;
    matrizTrenV2V = matrizParametrosIniciales;%inicializamos la matriz de trenes a cero

    %Creamos la matriz de KPIs para el sistema CBTC-V2V
    KPIv2v = zeros(numeroTrenes,13);
    n = 1;%Variable auxiliar para recorrer el array de los parámetros del tren
    tiempoSimulacion = 0;%Contador del tiempo de simulacion

    while tiempoSimulacion < condicionFinalizacion%Condicion de finalizacion

        %Si el tren sigue parado en la estacion, no realizará movimiento hasta que transcurra el tiempo de parada en la estacion
        if ((matrizTrenV2V(n,8) == (matrizInterestacionesV2V(matrizTrenV2V(n,7),4))) || (matrizTrenV2V(n,2) == longitudLinea)) && (matrizTrenV2V(n,11) < (matrizInterestacionesV2V(matrizTrenV2V(n,7),2)))
            matrizTrenV2V(n,11) = matrizTrenV2V(n,11) + 1;%Se incrementa el tiempo en la estación
            tiempoSimulacion = tiempoSimulacion + 1;%Se le suma al tiempo de simulacion el tiempo que el tren este parado en la estacion
            KPIv2v(n,6) = KPIv2v(n,6) + 1;%Se incrementa el tiempo total de uso del sistema
            KPIv2v(n,12) = KPIv2v(n,12) + 1;%Se incrementa el tiempo total de parada
        else
        
            %Se comprueba si el tren n ha llegado al final de la linea o ha sobrepasado este valor
            %Si es así, vuelve a comenzar desde el inicio de la linea(linea circular)
            if matrizTrenV2V (n,2) >= longitudLinea
        
                matrizTrenV2V(n,1) = 1;%El tren empieza desde el principio de la linea
                matrizTrenV2V(n,2) = 1;%El tren empieza desde el principio de la linea
                matrizTrenV2V(n,8) = matrizInterestacionesV2V(1,4);%Su límite será ahora el limite de la primera interestacion
        
            %Se comprueba que el tren no haya hecho un frenado de emergencia en la iteracion anterior
            %si el tren está parado por haber realizado un frenado de emergencia, no se produce movimiento
            elseif (matrizTrenV2V(n,10) == 0)
        
                if (matrizTrenV2V (n,2) + (matrizTrenV2V(n,9)/2)) < (matrizTrenV2V(n,8))
                %Si la parte delantera del tren no ha llegado a la zona de frenado segun el perfil de velocidad ATP, estará en fase de
                %aceleración: acelerando o circulando con velocidad constante (deriva)
        
                    %Zona de aceleracion V < Vmax: el tren acelera hasta alcanzar su velocidad maxima 
                    if matrizTrenV2V(n,3) < matrizTrenV2V(n,12)
            
                        matrizTrenV2V(n,4) = random('norm',aceleracionMax,0.1);%en el primer tramo, el tren acelera con aproximadamente aceleracion maxima
                        matrizTrenV2V(n,3) = (matrizTrenV2V(n,4)).*(matrizTrenV2V(n,5)) + abs(random('norm',1,0.5));%velocidad del tren en el tramo de aceleracion 
                        matrizTrenV2V(n,2) = 0.5.*((matrizTrenV2V(n,4)).*((matrizTrenV2V(n,5)).^2)) + (matrizTrenV2V(n,3)).*(matrizTrenV2V(n,5)) + matrizTrenV2V(n,1);%posicion del tren en el tramo de aceleracion

                    else %Zona de deriva: v >= vmax

                        matrizTrenV2V(n,4) = abs(random('norm',0,0.25));%aceleracion proxima a 0 ya que se ha alcanzado la velocida máxima y no se acelera mas
                        matrizTrenV2V(n,3) = matrizTrenV2V(n,12);%la velocidad en este tramo es la maxima
                        matrizTrenV2V(n,2) = 0.5.*((matrizTrenV2V(n,4)).*((matrizTrenV2V(n,5)).^2)) + (matrizTrenV2V(n,3)).*(matrizTrenV2V(n,5)) + matrizTrenV2V(n,1);%posicion del tren en el tramo de velocidad constante

                    end%Fin de zona de aceleración

                    matrizTrenV2V(n,5) = matrizTrenV2V(n,5) + incrementoTiempoMovimiento; %Se incrementa el tiempo de aceleración del tren
                    %Se actualiza la posicion calculada debido al error en la medida por parte de las balizas
                    matrizTrenV2V(n,2) = matrizTrenV2V(n,2) + errorPosicionamiento(floor(matrizTrenV2V(n,2)));
    
                else
                    %Se inicia la fase de frenado del tren
                    %El tren ha llegado a la siguiente estación ya que su su posición es igual o mayor a la posición límite de la
                    %interestacion o su velocidad es menor que el umbral de velocidad cero, por lo que estaria parado
                    if ((matrizTrenV2V(n,2) + (matrizTrenV2V(n,9)/2)) >=  matrizInterestacionesV2V(matrizTrenV2V(n,7),4)) || (matrizTrenV2V(n,2) < umbralVelocidadCero)
                
                        matrizTrenV2V(n,4) = 0;%no hay aceleracion al estar el tren parado
                        matrizTrenV2V(n,3) = 0;%la velocidad es nula al estar el tren parado
                        matrizTrenV2V(n,2) = matrizInterestacionesV2V(matrizTrenV2V(n,7),4);%el tren está en la siguiente interestacion,se actualiza su posición al inicio de la siguiente interestación
                        matrizTrenV2V(n,1) = matrizInterestacionesV2V(matrizTrenV2V(n,7),4);%el tren está en la siguiente interestacion,se actualiza su posición inicial al inicio de la siguiente interestación
                        %Se comprueba si el tren ha llegado a la ultima estacion
                        if matrizTrenV2V(n,2) == longitudLinea
                            matrizTrenV2V(n,7) = numeroInterEstaciones;
                            matrizTrenV2V(n,7) = 1;%El tren empieza desde la linea 1 (linea circular)
                        else
                            matrizTrenV2V(n,7) = matrizTrenV2V (n,7) + 1;%Se pasa al tren a la siguiente interestación
                            matrizTrenV2V(n,8) = matrizInterestacionesV2V(matrizTrenV2V(n,7),4);%Su límite estara en la zona de frenado de la interestación en la que se encuentra ahora
                            KPIv2v(n,11) = KPIv2v(n,11) + matrizInterestacionesV2V(matrizTrenV2V(n,7) - 1,1);%Se incrementa el tiempo total de uso del sistema
                        end
                    
                        matrizTrenV2V(n,5) = incrementoTiempoMovimiento; %Se reinicia el contador del tiempo de aceleración
                        matrizTrenV2V(n,6) = incrementoTiempoMovimiento; %Se reinicia el contador del tiempo de frenado
                        matrizTrenV2V(n,11) = 0;%Se reinicia el contador de tiempo de parada en la estacion
                        matrizTrenV2V(n,13) = 1;%El tren que lleva detrás sabrá que este tren se ha parado en la estacion
                        matrizInterestacionesV2V(n,3) = matrizInterestacionesV2V(n,3) + 1;%Se incrementa el contador de interestaciones por las que pasa el tren

                    else%Si la velocidad calculada es mayor que el umbral o no se ha llegado al limite de frenado con el obstaculo,el tren estará frenando con aceleración negativa
            
                        matrizTrenV2V(n,4) = -(random('norm',aceleracionMax,0.1));%la aceleración es negativa al estar el tren frenando
                        matrizTrenV2V(n,3) = abs(matrizTrenV2V(n,4).*(matrizTrenV2V(n,6)) + matrizTrenV2V(n,3));%velocidad del tren en el tramo de frenado
                        matrizTrenV2V(n,2) = matrizTrenV2V(n,2) + abs((0.5.*((matrizTrenV2V(n,4)).*((matrizTrenV2V(n,6)).^2))) + ((matrizTrenV2V(n,3)).*(matrizTrenV2V(n,6)))); %Posición actual del tren: Se suma la posición que ocupaba anteriormente mas la que ha avanzado en esta iteración
                        matrizTrenV2V(n,6) = matrizTrenV2V(n,6) + incrementoTiempoMovimiento; %Se incrementa el tiempo de frenado del tren 1 milisegundo
            
                    end%fin de la zona de frenado

                end%fin de la zona de aceleracion

            end%fin de la zona de comprobacion de final de linea
    
            %Fin del bloque de movimiento
       
            %Después de realizar el calculo de los parámetros de movimiento, se procede a realizar un modelo de canal para determinar la cobertura
    
            %El ultimo tren no tiene otro tren por delante, por lo que su LMA sera la siguiente estacion
            if n >= numeroTrenes
                %Se calcula el limite maximo que el tren puede acelerar hasta la
                %zona de frenado de la siguiente estacion
                if matrizTrenV2V(n,3) > 0
                    tiempoFrenado = (matrizTrenV2V(n,3))./(matrizTrenV2V(n,4));%Tiempo que el tren estará frenando
                    distanciaFrenado = abs(((-1*matrizTrenV2V(n,4)).*(tiempoFrenado.^2))/2 + (matrizTrenV2V(n,3).*tiempoFrenado) + random('norm',5,1));%distancia maxima que recorrera el tren cuando este frenando 
                    matrizTrenV2V(n,8) = matrizInterestacionesV2V(matrizTrenV2V(n,7),4) - distanciaFrenado;%Al ser el último tren,su límite está en la zona de frenado de la interestación en la que se encuentra
                    tiempoSimulacion = tiempoSimulacion + incrementoTiempoMovimiento;%Se incrementa el tiempo de simulacion
                end
            else
          
                posicionTrenPrecedente = matrizTrenV2V(n+1,2);
                velocidadTrenPrecedente = matrizTrenV2V(n+1,3);
            
                %Se simula el modelo de canal para comprobar si son posibles las comunicaciones V2V
                [V2V,potenciaRecibida] = comunicacionesV2V(matrizInfoCanal,matrizTrenV2V,n,curvas);

                %Si V2V = 1, se puede simular el sistema CBTC-V2V.
                if V2V == 1
          
                    KPIv2v(n,10) = KPIv2v(n,10) + potenciaRecibida;
                    KPIv2v(n,1) = matrizTrenV2V(n,2);
                    %Se simula el sistema CBTC-V2V
                    [posicionActualizada,velocidadActualizada,aceleracionActualizada,limiteMax,contadorFrenados,frenadoEmergencia,distanciaTrenes,tiempoCBTC,incrementoTiempoSimulacion,posicionTrenPrecedenteActualizada,contadoraux] = cbtcV2V(matrizTrenV2V,matrizInterestacionesV2V,matrizInfoCanal,KPIv2v,n,posicionTrenPrecedente,velocidadTrenPrecedente);
                    %Se obtienen los parametros actualizados tras la simulacion
                    matrizTrenV2V(n,4) = aceleracionActualizada;
                    matrizTrenV2V(n,3) = velocidadActualizada;
                    matrizTrenV2V(n,2) = posicionActualizada;
                    matrizTrenV2V(n,8) = limiteMax;
                    matrizTrenV2V(n,10) = frenadoEmergencia;
                    matrizTrenV2V(n+1,2) = posicionTrenPrecedenteActualizada;
                    %Si se ha producido un frenado de emergencia, se reinician los contadores de tiempo de movimiento
                    if (matrizTrenV2V(n,10) == 1)
                        matrizTrenV2V(n,1) = posicionActualizada;
                        matrizTrenV2V(n,5) = incrementoTiempoMovimiento;
                        matrizTrenV2V(n,6) = incrementoTiempoMovimiento;
                    end
                    %Se introducen los datos obtenidos en la matriz de KPIs
                    KPIv2v(n,2) = distanciaTrenes;
                    KPIv2v(n,3) = KPIv2v(n,3) + 1;
                    KPIv2v(n,4) = contadorFrenados;
                    KPIv2v(n,5) = KPIv2v(n,5) + (matrizTrenV2V(n,2) - KPIv2v(n,1));%Se suma la distancia recorrida con este sistema
                    KPIv2v(n,6) = tiempoCBTC;%Se incrementa el tiempo que se utiliza este sistema
                    KPIv2v(n,7) = KPIv2v(n,7) + incrementoTiempoSimulacion;%Se incrementa el tiempo total del tren en la interestacion usando CBTC-V2V
                    KPIv2v(n,13) = contadoraux; 
                    
                    %Se comprueba si el tren precedente ya ha pasado por la estacion
                    if matrizTrenV2V (n+1,13) == 1
                        %Se comprueba si el tren n ha llegado a la estacion por la que ha pasado el tren n+1
                        if matrizTrenV2V(n,7) == matrizTrenV2V(n+1,7)
                            matrizTrenV2V (n+1,13) = 0;%Se reinicia el contador del tiempo entre trenes
                            KPIv2v(n,8) = KPIv2v(n,8) + 1;%Se incrementa el numero de veces que se ha realizado este calculo
                        else %el tren n no ha llegado a la estacion por la que ha pasado el tren n+1
                            KPIv2v(n,9) = KPIv2v(n,9) + incrementoTiempoSimulacion + incrementoTiempoMovimiento;%Se incrementa el tiempo entre trenes
                        end
                    end

                end%Fin de la comprobacion de uso del sistema CBTC-V2V
            
                tiempoSimulacion = tiempoSimulacion + incrementoTiempoMovimiento + incrementoTiempoSimulacion;%Se incrementa el tiempo de simulacion
            
            end%Fin de la comprobacion del ultimo tren
        
        end%Fin de la comprobacion del tiempo de parada en la estacion
    
        if n >= numeroTrenes
            n = 1;%Se reinicia el contador de trenes
        else
            n = n + 1;%Se incrementa el contador de trenes
        end
    
    end%Fin de la simulacion
    
    
    