function [posicionActualizada,velocidadActualizada,aceleracionActualizada,limiteMax,contadorFrenados,frenadoEmergencia,distanciaTrenes,tiempoCBTC,incrementoTiempoSimulacion,posicionTrenPrecedenteActualizada,contadoraux] = cbtcV2I (matrizTren,matrizInterEstaciones,matrizCanal,KPIv2i,n,posicionTrenPrecedente,velocidadTrenPrecedente)
    %function [posicionActualizada,velocidadActualizada,aceleracionActualizada,limiteMax,contadorFrenados,frenadoEmergencia,distanciaTrenes,tiempoCBTC,incrementoTiempoSimulacion,posicionTrenPrecedenteActualizada,contadoraux] = cbtcV2I (matrizTren,matrizInterEstaciones,matrizCanal,KPIv2i,n,posicionTrenPrecedente,velocidadTrenPrecedente)
    %
    % Función que simula el funcionamiento de un sistema CBTC-V2VI
    %
    % Datos de entrada:
    %
    % matrizTren = matriz que contiene datos de movimiento del tren
    % matrizInterEstaciones = matriz que contiene informacion sobre las interestaciones
    % matrizInfoCanal = matriz que contiene informacion sobre los
    % parámetros del canal de comunicaciones
    % KPIv2i = matriz que contiene estadísticas relativas al tren
    % n = numero del tren de la linea 
    % posicionTrenPrecedente = posicion que envia el tren precedente
    % velocidadTrenPrecedente = velocidad que envia el tren precedente
    %
    % Datos de salida:
    % posicionActualizada = posicion del tren  tras los calculos del sistema CBTC
    % velocidadActualizada =  velocidad del tren ltras los calculos del sistema CBTC
    % aceleracionActualizada =  aceleracion del tren tras los calculos del sistema CBTC
    % limiteMax = limite maximo hasta donde podra seguir el tren acelerando
    % contadorFrenados = contador de frenos de emergencia activados
    % frenadoEmergencia = determina si se ha realizado un frenado de emergencia anteriormente
    % distanciaTrenes = distancia entre el tren n y el tren n+1 
    % tiempoCBTC = tiempo que el tren ha usado CBTC-V2I
    % incrementoTiempoSimulacion = tiempo que se ha empleado en los
    % calculos CBTC y habra que añadir al tiempo de simulacion
    % posicionTrenPrecedenteActualizada = posicion del tren precedente tras
    % los calculos de CBTC
    %
    % Fecha: 03/06/2017
    %

    margenLMA = random('norm',40,2);%margen de seguridad aplicado al LMA en torno a los 40 metros
    margenSeguridad = random('norm',10,1);%Margen de seguridad en caso de realizar un frenado de emergencia
    errorVelocidad = 0.6 + (0.9 - 0.6).*rand(1,1);%error que se asigna a la velocidad recibida o calculada entre 2-3 km/h
    
    posicionActualizada = matrizTren(n,2);%Posicion del tren antes de realizar los calculos CBTC
    velocidadActualizada = matrizTren(n,3);%Velocidad del tren antes de los calculos CBTC
    aceleracionActualizada = matrizTren(n,4);%Aceleracion del tren antes de los calculos CBTC
    limiteMax = matrizTren(n,8);%limite maximo al que el tren puede acercarse al siguiente obstaculo
    longitudTren = matrizTren(n,9);%Longitud del tren 
    longitudTrenPrecedente = matrizTren(n+1,9);%Longitud del tren precedente
    frenadoEmergencia = matrizTren(n,10);%Variable auxiliar que informa sobre si se ha realizado un frenado de emergencia en la iteracion anterior
    limiteEstacion = matrizInterEstaciones(matrizTren(n,7),4);%Posicion maxima donde acaba la interestacion
    tiempoProcesado = matrizCanal(1,12) + (matrizCanal(2,12)-matrizCanal(1,12)).*rand(1,1);%Retardo de procesamiento de la información recibida por el tren en el equipo de abordo
    retardoTrenInfraestructuraMax = 2*(abs(random('norm',matrizCanal(1,13),0.1)));%Retardo maximo comunicacion tren-infraestructura-tren
    retardoInfraestructura = abs(random('norm',matrizCanal(1,14),0.25));%Tiempo que tarda en procesar la información recibida la infraestructura
    distanciaTrenes = KPIv2i(n,2);%Distancia que se ha calculado entre un tren y su precedente
    contadorFrenados = KPIv2i(n,4);%contador de accionamientos de frenado de emergencia
    tiempoCBTC = KPIv2i(n,6);%Tiempo de uso del sistema CBTC-V2I
    incrementoTiempoSimulacion = 0;
    posicionTrenPrecedenteActualizada = posicionTrenPrecedente;
    contadoraux = KPIv2i(n,13);
	%Vector de retardos de propagacion.Dependiendo de la velocidad del tren precedente, se asignará un error de tiempo distinto debido al retardo de comunicación.
	velocidadRetardo = [retardoTrenInfraestructuraMax/7 (retardoTrenInfraestructuraMax/7)*2 (retardoTrenInfraestructuraMax/7)*3 (retardoTrenInfraestructuraMax/7)*4 (retardoTrenInfraestructuraMax/7)*5 (retardoTrenInfraestructuraMax/7)*6 retardoTrenInfraestructuraMax];
    
    %Si el tren precedente esta parado, su velocidad será cero y ,por tanto, su posicion y velocidad 
    %seran las mismas que tenia anteriormente.No habria que tener en cuenta los retardos de comunicacion para conocer su posicion exacta
	if velocidadTrenPrecedente > 0
        
        velocidadRecibida = velocidadTrenPrecedente + errorVelocidad;%Velocidad recibida real del tren precedente debido a las perdidas de propagacion
        %Se compara la velocidad recibida del tren precedente. 
        %Dependiendo del intervalo en el que se encuentre, se le asigna un retardo de propagacion diferente
        %Luego se calcula la posición real del tren precedente tras los distintos retardos que ha sufrido hasta llegar al tren
        if (velocidadRecibida >= 0) && (velocidadRecibida < 5) % 0 < V < 5 m/s

            retardoTotal = tiempoProcesado + retardoInfraestructura + velocidadRetardo(1);%Se suman los retardos de comunicacion y los de procesamiento
            posicionaux = (velocidadRecibida).* retardoTotal;%Se calcula el espacio que ha avanzado el tren n+1 en el tiempo de retardo
            posicionTrenPrecedenteActualizada = posicionTrenPrecedente + posicionaux;%Se suma a la posicion que envia el tren precedente la posicion que ha avanzado el tren n+1 en el tiempo de comunicacion y procesado
    
        elseif (velocidadRecibida >= 5) && (velocidadRecibida < 10)% 5 <= V < 10 m/s

            retardoTotal = tiempoProcesado + retardoInfraestructura + velocidadRetardo(2);%Se suman los retardos de comunicacion y los de procesamiento
            posicionaux = (velocidadRecibida).* retardoTotal;%Se calcula el espacio que ha avanzado el tren n+1 en el tiempo de retardo
            posicionTrenPrecedenteActualizada = posicionTrenPrecedente + posicionaux;%Se suma a la posicion que envia el tren precedente la posicion que ha avanzado el tren n+1 en el tiempo de comunicacion y procesado

        elseif (velocidadRecibida >= 10) && (velocidadRecibida < 15)% 10 <= V < 15 m/s

            retardoTotal = tiempoProcesado + retardoInfraestructura + velocidadRetardo(3);%Se suman los retardos de comunicacion y los de procesamiento
            posicionaux = (velocidadRecibida).* retardoTotal;%Se calcula el espacio que ha avanzado el tren n+1 en el tiempo de retardo
            posicionTrenPrecedenteActualizada = posicionTrenPrecedente + posicionaux;%Se suma a la posicion que envia el tren precedente la posicion que ha avanzado el tren n+1 en el tiempo de comunicacion y procesado

        elseif (velocidadRecibida >= 15) && (velocidadRecibida < 20)% 15 <= V < 20 m/s

            retardoTotal = tiempoProcesado + retardoInfraestructura + velocidadRetardo(4);%Se suman los retardos de comunicacion y los de procesamiento
            posicionaux = (velocidadRecibida).* retardoTotal;%Se calcula el espacio que ha avanzado el tren n+1 en el tiempo de retardo
            posicionTrenPrecedenteActualizada = posicionTrenPrecedente + posicionaux;%Se suma a la posicion que envia el tren precedente la posicion que ha avanzado el tren n+1 en el tiempo de comunicacion y procesado

        elseif (velocidadRecibida >= 20) && (velocidadRecibida < 25)% 20 <= V < 25 m/s

            retardoTotal = tiempoProcesado + retardoInfraestructura + velocidadRetardo(5);%Se suman los retardos de comunicacion y los de procesamiento
            posicionaux = (velocidadRecibida).* retardoTotal;%Se calcula el espacio que ha avanzado el tren n+1 en el tiempo de retardo
            posicionTrenPrecedenteActualizada = posicionTrenPrecedente + posicionaux;%Se suma a la posicion que envia el tren precedente la posicion que ha avanzado el tren n+1 en el tiempo de comunicacion y procesado

        elseif (velocidadRecibida >= 25) && (velocidadRecibida < 30)% 25 <= V < 30 m/s

            retardoTotal = tiempoProcesado + retardoInfraestructura + velocidadRetardo(6);%Se suman los retardos de comunicacion y los de procesamiento
            posicionaux = (velocidadRecibida).* retardoTotal;%Se calcula el espacio que ha avanzado el tren n+1 en el tiempo de retardo
            posicionTrenPrecedenteActualizada = posicionTrenPrecedente + posicionaux;%Se suma a la posicion que envia el tren precedente la posicion que ha avanzado el tren n+1 en el tiempo de comunicacion y procesado

        elseif velocidadRecibida >= 30%V > 30 m/s

            retardoTotal = tiempoProcesado + retardoInfraestructura + velocidadRetardo(7);%Se suman los retardos de comunicacion y los de procesamiento
            posicionaux = (velocidadRecibida).* retardoTotal;%Se calcula el espacio que ha avanzado el tren n+1 en el tiempo de retardo
            posicionTrenPrecedenteActualizada = posicionTrenPrecedente + posicionaux;%Se suma a la posicion que envia el tren precedente la posicion que ha avanzado el tren n+1 en el tiempo de comunicacion y procesado

        end%Fin del calculo de la posición adicional debido al retardo de comunicación
        
	end%Fin de la comprobacion de velocidad cero del tren precedente

    %Se calcula el LMA con el tren precedente aplicandole un margen de seguridad
	%La posición del tren tiene como referencia el centro del tren, por lo
	%que se resta la mitad de su longitud para tener como referencia la	parte trasera del tren
	LMA = posicionTrenPrecedenteActualizada - (longitudTrenPrecedente/2) - margenLMA;
    
    %Se comprueba si el tren ha realizado un frenado de emergencia anteriormente
    if frenadoEmergencia == 1
        
        %Se comprueba si el tren puede moverse con seguridad respecto al tren delantero
        if (posicionActualizada + longitudTren/2) < LMA
            frenadoEmergencia = 0;%El tren puede retomar su movimiento
        end
        
    else%No ha realizado frenado de emergencia anteriormente, puede seguir circulando con seguridad respecto a su tren delantero
         
        if velocidadActualizada > 0
            
            aceleracionActualizada =  1 + (1.2 - 1).*rand(1,1);%La aceleracion habrá cambiado un poco su valor(oscilará entre 1 y 1.2 m/s^2)
            velocidadActualizada = velocidadActualizada + errorVelocidad; %Se calcula la velocidad que tiene el tren tras calcular el LMA
            posicionActualizada = posicionActualizada + ((tiempoProcesado + retardoTrenInfraestructuraMax/2 + retardoInfraestructura).*(velocidadActualizada));%Se calcula la posicion que tiene el tren tras la comunicacion y el calculo del LMA
            tiempoFrenado = abs(velocidadActualizada/aceleracionActualizada);%Tiempo que el tren estará frenando
            distanciaFrenado = ((-1*aceleracionActualizada)*(tiempoFrenado.^2))/2 + velocidadActualizada*tiempoFrenado + random('norm',10,1);%distancia maxima que recorrera el tren cuando este frenando 
	
            %Se comprueba si la parte delantera del tren ha sobrepasado el LMA
            if (posicionActualizada + (longitudTren/2)) >= LMA
            
                %Si ha sobrepasado esta zona,se accionará el freno de
                %emergencia y el tren frenará, deteniendose antes del tren precedente
                posicionActualizada = posicionTrenPrecedente - (longitudTrenPrecedente/2) - (longitudTren/2) - margenSeguridad;
                %Su aceleracion y velocidad seran cero al estar el tren detenido
                velocidadActualizada = 0;
                aceleracionActualizada = 0;
                contadorFrenados = contadorFrenados + 1;%Se incrementará el numero de veces que ha frenado de emergencia
                frenadoEmergencia = 1;%Se actualiza la variable auxiliar para determinar que se ha producido un frenado de emergencia
                tiempoCBTC = tiempoCBTC + tiempoFrenado;%Se incrementa el tiempo que se usa CBTC de acuerdo al de comunicacion entre trenes,realizacion de calculos
                incrementoTiempoSimulacion = tiempoFrenado;%El tiempo de simulacion empleado sera el retardo en la comunicacion mas el tiempo de procesado+tiempo frenado
            
            else%Si no ha sobrepasado la zona de frenado de emergencia, se comprueba cual es el primer obstaculo que encuentra 
                %y se calcula el limite al que el tren puede llegar acelerando por lo que se resta a este límite la distancia de frenado que tendría en el momento del cálculo 
        
                if LMA < limiteEstacion%El primer obstaculo que encuentra es un tren
            
                    limiteMax = LMA - distanciaFrenado;
                
                else%El primer obstaculo que encuentra es el final de la interestacion en la que se encuentra
            
                    limiteMax = matrizInterEstaciones(matrizTren(n,7),4) - distanciaFrenado;
            
                end%Fin de la comprobacion de obstaculo
                contadoraux = contadoraux + 1;
                distanciaTrenes = distanciaTrenes + (posicionTrenPrecedenteActualizada - (longitudTrenPrecedente/2)) - (posicionActualizada + (longitudTren/2));%Se obtiene la distancia entre trenes actual y se acumula

            end%Fin de la comprobacion de la zona de frenado de emergencia
        
        end
        
    end%Fin de la comprobacion de frenado de emergencia
    tiempoCBTC = tiempoCBTC + tiempoProcesado + retardoTrenInfraestructuraMax/2 + retardoInfraestructura;%Se incrementa el tiempo que se usa CBTC de acuerdo al de realizacion de calculos mas los retardos por la comunicacion entre trenes
	incrementoTiempoSimulacion = incrementoTiempoSimulacion + tiempoProcesado;%El tiempo de simulacion empleado sera el tiempo de procesado+tiempo infraestructura+comunicacion entre trenes
    
end%Fin funcion cbtcV2I
