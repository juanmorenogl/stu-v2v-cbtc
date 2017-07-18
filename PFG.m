%SIMULACIÓN SISTEMA CBTC-V2V y CBTC-V2I
%
%
%Simula el movimiento de n trenes a lo largo de una linea de metro. Así
%mismo, se simula el funcionamiento del sistema de señalización CBTC
%con comunicaciones V2V en primer lugar, y comunicaciones V2I en segundo lugar.
%Por último, se obtienen KPIs y graficas de cada sistema para su comparacion
%
%@autor: Alfonso Ruiz
%@Version: 2.5
%@Fecha: 15-06-2017
%
%
clc,clear

%Declaracion de variables
aceleracionMax = 1.2; %aceleración maxima del tren en m/s^2
velocidadMax = random('norm',30,1); %Velocidad maxima del tren en m/s
umbralVelocidadCero = abs(random('norm',0.5,0.05));%Umbral para la deteccion de velocidad cero en torno a los 2km/h
errorMaxLocalizacion = random('norm',10,1);%Maximo error al localizar el tren en la via por parte de balizas
curvas =[1500+random('norm',100,1)  2000+random('norm',100,1) 3450+random('norm',100,1) 3950+random('norm',100,1)];%Vector que representa el inicio y final de las dos zonas de curva de la linea simulada

%El excel Info_Trenes contiene los parámetros relativos a la linea a simular y su material rodante
%Se lee la información de la línea y el material rodante
%Se guardan en la matriz matrizInfoTrenes
matrizInfoTrenes = xlsread ('Info_Trenes');

%El excel Parámetros_Canal_V2V contiene los parámetros relativos al modelo de canal que se va a simular
%Se extrae del excel Parámetros_canal los parámetros del modelo de canal
%Se guardan en la matriz matrizInfoCanal
matrizInfoCanal = xlsread ('Parámetros_Canal');

%Se extrae la informacion del documento Info_Trenes
numeroTrenes = matrizInfoTrenes(1,1);
numeroInterEstaciones = matrizInfoTrenes(1,7);
tiempoParada = randsrc(1,numeroTrenes,[20 25 30 35 40 45 50]);%Matriz que contiene diferentes tiempos de parada

%La matriz de parametros iniciales está compuesta por 13 columnas en este orden:
%posicion inicial,posicion actual,velocidad,aceleracion,tiempo de aceleracion en la interestacion,
%tiempo de frenado en la interestacion,interestación en la que se encuentra en el instante de simulación,
%limite de momiviento con el siguiente obstaculo (tren o fin de estacion),longitud del tren,variable auxiliar para conocer 
%si ha realizado un frenado de emergencia,tiempo que lleva parado en la estacion,velocidad maxima que puede alcanzar el tren,
%variable auxiliar para calcular el tiempo entre trenes que valdrá uno hasta que el tren n pase por el mismo punto que el tren n+1
%El numero de filas es igual al numero de trenes introducido

%La matriz de estaciones está compuesta por 4 columnas en este orden:
%longitud,numero de interestaciones por las que ha pasado un tren,posicion final de cada interestacion
%El numero de filas es igual al numero de estaciones introducido

matrizParametrosIniciales = zeros(numeroTrenes,13);%inicializamos la matriz de trenes a cero
matrizInterEstaciones = zeros(numeroInterEstaciones,4);%inicializamos la matriz de estaciones a cero

longitudLinea = 0;
finalInterestacion = 0;

%Recorremos la matriz de estaciones para inicializarlo con los valores del excel extraidos anteriormente
for k = 1:numeroInterEstaciones
    matrizInterEstaciones(k,1) = random('norm',matrizInfoTrenes(k,8),50);%introducimos en la matriz la longitud de cada interestacion  
    if k == 1%La ultima estacion tendrá un tiempo de parada mayor
        matrizInterEstaciones(k,2) = 5*tiempoParada(1,k); %introducimos en la matriz el tiempo de parada de la ultima estacion
    else
        matrizInterEstaciones(k,2) = tiempoParada(1,k); %introducimos en la matriz el tiempo de parada de cada estacion
    end
    finalInterestacion = finalInterestacion + matrizInterEstaciones(k,1);%Se obtiene el final de cada interestacion
    matrizInterEstaciones(k,4) = finalInterestacion;%Se guarda para cada interestacion su posicion final
    longitudLinea = longitudLinea + matrizInterEstaciones(k,1);%Se obtiene la longitud exacta de la linea dependiendo de las longitudes de cada interestacion
end

%Recorremos la matriz de parametros iniciales para inicializarlo con los valores del excel extraidos anteriormente
for m = 1:numeroTrenes
    matrizParametrosIniciales(m,1) = matrizInfoTrenes(m,5);%Introducimos la posicion inicial del tren
    matrizParametrosIniciales(m,2) = matrizParametrosIniciales(m,1);%Su posicion actual al principio será la misma que la posicion actual
    matrizParametrosIniciales(m,3) = abs(random('normal',1,0.2));%Se actualiza su velocidad inicial
    matrizParametrosIniciales(m,5) = 1;%Inicializamos el tiempo auxiliar de aceleracion a 1 
    matrizParametrosIniciales(m,6) = 1;%Inicializamos el tiempo auxiliar de frenado a 1 
    matrizParametrosIniciales(m,7) = matrizInfoTrenes(m,9);%Introducimos el número de interestación en la que está el tren al inicio de la simulacion
    tiempoFrenado = matrizParametrosIniciales(m,3)/aceleracionMax;%Tiempo que el tren estará frenando con aceleración maxima 
    distanciaFrenado = ((-1*aceleracionMax)*(tiempoFrenado.^2))/2 + matrizParametrosIniciales(m,3)*tiempoFrenado + random('norm',5,1);%distancia maxima que recorrera el tren cuando este frenando 
    matrizParametrosIniciales(m,8) = matrizInterEstaciones(matrizParametrosIniciales(m,7),4) - distanciaFrenado;%Al comienzo, el primer obstaculo del tren es la siguiente estacion
    matrizParametrosIniciales(m,9) = matrizInfoTrenes(m,2);%Introducimos la longitud de cada tren
    matrizParametrosIniciales(m,12) = random('norm',velocidadMax,1);%Introducimos la velocidad maxima de cada tren
    matrizInterEstaciones(m,3) = 1;%Se inicializa el contador de interestaciones por las que pasa un tren
end

%Se calcula un  error de posicionamiento debido a la medida de las balizas 
%por odometria cuyo valor sigue una función dientes de sierra, desde 0 al maximo,
%simulando el tiempo desde que un tren pasa por una baliza hasta que pasa
%por la siguiente y vuelve a reiniciarse. Suponemos que existirá una baliza cada 100 metros
t = 0:1:longitudLinea;
errorPosicionamiento = ((errorMaxLocalizacion*(sawtooth(2*pi*0.01*t))) + errorMaxLocalizacion)/2;

%Se simulan los sistemas CBTC-V2V y CBTC-V2I y se obtienen KPIs de cada uno de ellos
[matrizTrenV2I,matrizInterestacionesV2I,KPIv2i]=simularV2I(matrizParametrosIniciales,matrizInterEstaciones,numeroTrenes,numeroInterEstaciones,matrizInfoCanal,errorPosicionamiento,longitudLinea,umbralVelocidadCero,curvas);
[matrizTrenV2V,matrizInterestacionesV2V,KPIv2v]=simularV2V(matrizParametrosIniciales,matrizInterEstaciones,numeroTrenes,numeroInterEstaciones,matrizInfoCanal,errorPosicionamiento,longitudLinea,umbralVelocidadCero,curvas);
calcularKPIs(KPIv2v,KPIv2i,matrizTrenV2V,matrizTrenV2I,matrizInterestacionesV2V,matrizInterestacionesV2I,numeroTrenes,numeroInterEstaciones,longitudLinea)

