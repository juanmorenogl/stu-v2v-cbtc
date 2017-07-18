function calcularKPIs(KPIv2v,KPIv2i,matrizTrenV2V,matrizTrenV2I,matrizInterestacionesV2V,matrizInterestacionesV2I,numeroTrenes,numeroInterestaciones,longitudLinea)
%function calcularKPIs(KPIv2v,KPIv2i,matrizTrenV2V,matrizTrenV2I,matrizInterestacionesV2V,matrizInterestacionesV2I,numeroTrenes,numeroInterestaciones,longitudLinea)
    %
    % Función que calcula estadísticas relativas a los modelos CBTC-V2V y CBTC-V2I diseñado
    %
    % Datos de entrada:
    %
    % KPIv2v = matriz que contiene información sobre estadísticas de los
    % trenes trenes del modelo CBTC-V2V
    % KPIv2i = matriz que contiene información sobre estadísticas de los
    % trenes del modelo CBTC-V2I
    % matrizTrenV2V: matriz de parametros del tren relativos a la
    % utilizacion de CBTC-V2V
    % matrizTrenV2I: matriz de parametros del tren relativos a la
    % utilizacion de CBTC-V2I
    % matrizInterestacionesV2V: matriz de parametros de interesatciones relativos a la
    % utilizacion de CBTC-V2V
    % matrizInterestacionesV2I: matriz de parametros de interesatciones relativos a la
    % utilizacion de CBTC-V2I
    % numeroTrenes = numero de trenes en la linea
    % numeroEstaciones = numero de estaciones de la linea
    % longitudLinea = longitud total de la linea
    %
    % Fecha: 15/06/2017
    %

    %Se escriben los datos obtenidos de los KPIs durante la simulacion en una hoja de excel
    xlswrite('KPI.xlsx',KPIv2v,'CBTC-V2V','A2')
    xlswrite('KPI.xlsx',KPIv2i,'CBTC-V2I','A2')
    
    %Se inicializan las matrices de KPIs adicionales
    matrizKPIV2V = zeros(numeroTrenes,11);
    matrizKPIV2I = zeros(numeroTrenes,11);

    %Bucle para los KPIS de CBTC-V2V
     for k = 1:(numeroTrenes-1)
        
        %Se comprueba que ningun valor de la division es cero
        if  (matrizInterestacionesV2V(k,3) - 1) == 0
            matrizKPIV2V(k,6) = matrizInterestacionesV2V(matrizTrenV2V(k,7),1);
        else
            matrizKPIV2V(k,6) = KPIv2v(k,11) ./ (matrizInterestacionesV2V(k,3) - 1);%Obtiene la longitud media de interestacion que recorre el tren
        end
        matrizKPIV2V(numeroTrenes,6) = matrizKPIV2V(numeroTrenes,6) +  matrizKPIV2V(k,6);%Obtiene un acumulado de la longitud de la interestacion media de todos los trenes
        
        %Se comprueba que ningun valor de la division es cero
        if  (matrizInterestacionesV2V(k,3) - 1) == 0 || (KPIv2v(k,12) < 20)
            matrizKPIV2V(k,7) = matrizInterestacionesV2V(matrizTrenV2V(k,7)+1,2);
        else
            matrizKPIV2V(k,7) = round(KPIv2v(k,12) ./ (matrizInterestacionesV2V(k,3) - 1));%Obtiene el tiempo medio de parada del tren en la estacion
        end
        
        %Se comprueba que ningun valor de la division es cero
        if  (KPIv2v(k,2) == 0) || (KPIv2v(k,13) == 0)
            matrizKPIV2V(k,1) = 0;
        else
            matrizKPIV2V(k,1) = abs((KPIv2v(k,2))./(KPIv2v(k,13)));%Se calcula la distancia media del tren con su precedente
        end
        matrizKPIV2V(numeroTrenes,1) = matrizKPIV2V(numeroTrenes,1) +  matrizKPIV2V(k,1);%Obtiene un acumulado de la distancia entre trenes de todos los trenes con su precedente
        
        %Se comprueba que ningun valor de la division es cero
        if  (KPIv2v(k,5) == 0) || (KPIv2v(k,6) == 0)|| (KPIv2v(k,3) < 10)
            matrizKPIV2V(k,2) = 0;
        else
            matrizKPIV2V(k,2) = abs((KPIv2v(k,5))./(KPIv2v(k,6)));%Se calcula la velocidad media del tren
        end
        matrizKPIV2V(numeroTrenes,2) = matrizKPIV2V(numeroTrenes,2) + matrizKPIV2V(k,2);%Obtiene un acumulado de la velocidad media de todos los trenes
    
        %Se comprueba si el valor de la division es cero
        if(KPIv2v(k,9) <= 0) || (KPIv2v(k,8) == 0)
            matrizKPIV2V(k,3) = KPIv2v(k,9);
        else
            matrizKPIV2V(k,3) = (KPIv2v(k,9))./(KPIv2v(k,8));%Se calcula el tiempo medio entre el tren y su precedente
        end
        
        matrizKPIV2V(k,4) = (KPIv2v(k,7))./(matrizInterestacionesV2V(k,3));%Se calcula el tiempo medio que ha estado el tren por interestacion
        
        if matrizKPIV2V(k,1) == 0%Se comprueba que la distancia media con el tren delantero no resulte nula
            matrizKPIV2V(k,5) = 0;
        else
            matrizKPIV2V(k,5) = round(((longitudLinea)./(matrizKPIV2V(k,1))));%Se calcula la capacidad de la linea con CBTC-V2V
        end
        
        %Se comprueba si el valor de la division es cero
        if(KPIv2v(k,3) == 0)
            matrizKPIV2V(k,8) = KPIv2v(k,10);
        else
            matrizKPIV2V(k,8) = (KPIv2v(k,10))./(KPIv2v(k,3));%Se calcula la potencia media recibida por el tren
        end
        
        %Se calcula un acumulado de la capacidad de la linea para cada
        %longitud del tren
        if matrizTrenV2V(k,9) == 80
            matrizKPIV2V(1,9) = matrizKPIV2V(1,9) + 1;
            matrizKPIV2V(1,10) = matrizKPIV2V(1,10) + matrizKPIV2V(k,5);
        elseif matrizTrenV2V(k,9) == 90
            matrizKPIV2V(2,9) = matrizKPIV2V(2,9) + 1;
            matrizKPIV2V(2,10) = matrizKPIV2V(2,10) + matrizKPIV2V(k,5);
        elseif matrizTrenV2V(k,9) == 100
            matrizKPIV2V(3,9) = matrizKPIV2V(3,9) + 1;
            matrizKPIV2V(3,10) = matrizKPIV2V(3,10) + matrizKPIV2V(k,5);
        elseif matrizTrenV2V(k,9) == 110
            matrizKPIV2V(4,9) = matrizKPIV2V(4,9) + 1;
            matrizKPIV2V(4,10) = matrizKPIV2V(4,10) + matrizKPIV2V(k,5);
        end
        
        matrizKPIV2V(k,11) = matrizTrenV2V(k,12);
     end%Fin del bucle de KPIs CBTC-V2V
     
     %Se calcula la capacidad media para cada longitud del tren que utiliza
     %CBTC-V2V
     matrizKPIV2V(1,10) = round((matrizKPIV2V(1,10))./(matrizKPIV2V(1,9)));
     matrizKPIV2V(2,10) = round((matrizKPIV2V(2,10))./(matrizKPIV2V(2,9)));
     matrizKPIV2V(3,10) = round((matrizKPIV2V(3,10))./(matrizKPIV2V(3,9)));
     matrizKPIV2V(4,10) = round((matrizKPIV2V(4,10))./(matrizKPIV2V(4,9)));
     matrizKPIV2V(1,9) = 80;
     matrizKPIV2V(2,9) = 90;
     matrizKPIV2V(3,9) = 100;
     matrizKPIV2V(4,9) = 110;
     %Se calcula la distancia media entre trenes usando CBTC-V2V
     matrizKPIV2V(numeroTrenes,1) = matrizKPIV2V(numeroTrenes,1) / (numeroTrenes-1);
     %Se calcula la longitud media de interestacion recorrida por los
     %trenes usando CBTC-V2V
     matrizKPIV2V(numeroTrenes,6) = matrizKPIV2V(numeroTrenes,6) / (numeroTrenes-1);
     %Se calcula la velocidad media de los trenes usando CBTC-V2V
     matrizKPIV2V(numeroTrenes,2) = matrizKPIV2V(numeroTrenes,2) ./ (numeroTrenes-1);
     
     %Se guardan en el excel anterior los resultados obtenidos a continuacion de los anteriores
     xlswrite('KPI.xlsx',matrizKPIV2V,'CBTC-V2V','N2');
     
     %Bucle para los KPIS de CBTC-V2I
     for m = 1:(numeroTrenes-1)
        
        %Se comprueba que ningun valor de la division es cero
        if  (matrizInterestacionesV2I(m,3) - 1) == 0
            matrizKPIV2I(m,6) = matrizInterestacionesV2I(matrizTrenV2I(m,7),1);
        else
            matrizKPIV2I(m,6) = KPIv2i(m,11) ./ (matrizInterestacionesV2I(m,3) - 1);%Obtiene la longitud media de interestacion que recorre el tren
        end
        matrizKPIV2I(numeroTrenes,6) = matrizKPIV2I(numeroTrenes,6) +  matrizKPIV2I(m,6);%Obtiene un acumulado de la longitud de la interestacion media de todos los trenes
        
        %Se comprueba que ningun valor de la division es cero
        if  (matrizInterestacionesV2I(m,3) - 1) == 0 || (KPIv2i(m,12) < 20)
            matrizKPIV2I(m,7) = matrizInterestacionesV2I(matrizTrenV2I(m,7)+1,2);
        else
            matrizKPIV2I(m,7) = round(KPIv2i(m,12) ./ (matrizInterestacionesV2I(m,3) - 1));%Obtiene el tiempo medio de parada del tren en la estacion
        end
        
        %Se comprueba que ningun valor de la division es cero
        if  (KPIv2i(m,2) == 0) || (KPIv2i(m,13) == 0)
            matrizKPIV2I(m,1) = 250;
        else
            matrizKPIV2I(m,1) = abs((KPIv2i(m,2))./(KPIv2i(m,13)));%Se calcula la distancia media del tren con su precedente
        end
        matrizKPIV2I(numeroTrenes,1) = matrizKPIV2I(numeroTrenes,1) +  matrizKPIV2I(m,1);%Obtiene un acumulado de la distancia entre trenes de todos los trenes con su precedente

        %Se comprueba que ningun valor de la division es cero
        if  ((KPIv2i(m,5) == 0) || (KPIv2i(m,6) == 0)) || (KPIv2i(m,3) < 10)
            matrizKPIV2I(m,2) = 0;
        else
            matrizKPIV2I(m,2) = (KPIv2i(m,5))./(KPIv2i(m,6));%Se calcula la velocidad media del tren
        end
        matrizKPIV2I(numeroTrenes,2) = matrizKPIV2I(numeroTrenes,2) + matrizKPIV2I(m,2);%Obtiene un acumulado de la velocidad media de todos los trenes
        
        %Se comprueba que ningun valor de la division es cero
        if(KPIv2i(m,9) <= 0) || (KPIv2i(m,8) == 0)
            matrizKPIV2I(m,3) = random('norm',90,1);
        else
            matrizKPIV2I(m,3) = (KPIv2i(m,9))./(KPIv2i(m,8));%Se calcula el tiempo medio entre el tren y su precedente
        end
        
        matrizKPIV2I(m,4) = (KPIv2i(m,7))./(matrizInterestacionesV2I(m,3));%Se calcula el tiempo medio que ha estado el tren por interestacion
        
        %Se comprueba que la distancia media con el tren delantero no resulte nula
        if matrizKPIV2I(m,1) == 0
            matrizKPIV2I(m,5) = 0;
        else
            matrizKPIV2I(m,5) = round(((longitudLinea)./(matrizKPIV2I(m,1))));%Se calcula la capacidad de la linea con CBTC-V2I
        end
        
        %Se comprueba que ningun valor de la division es cero
        if(KPIv2i(m,3) == 0)
            matrizKPIV2I(m,8) = KPIv2i(m,10);
        else
            matrizKPIV2I(m,8) = (KPIv2i(m,10))./(KPIv2i(m,3));%Se calcula la potencia media recibida por el tren
        end

        %Se calcula un acumulado de la capacidad de la linea para cada
        %longitud del tren
        if matrizTrenV2I(m,9) == 80
            matrizKPIV2I(1,9) = matrizKPIV2I(1,9) + 1;
            matrizKPIV2I(1,10) = matrizKPIV2I(1,10) + matrizKPIV2I(m,5);
        elseif matrizTrenV2I(m,9) == 90
            matrizKPIV2I(2,9) = matrizKPIV2I(2,9) + 1;
            matrizKPIV2I(2,10) = matrizKPIV2I(2,10) + matrizKPIV2I(m,5);
        elseif matrizTrenV2I(m,9) == 100
            matrizKPIV2I(3,9) = matrizKPIV2I(3,9) + 1;
            matrizKPIV2I(3,10) = matrizKPIV2I(3,10) + matrizKPIV2I(m,5);
        elseif matrizTrenV2I(m,9) == 110
            matrizKPIV2I(4,9) = matrizKPIV2I(4,9) + 1;
            matrizKPIV2I(4,10) = matrizKPIV2I(4,10) + matrizKPIV2I(m,5);
        end

        matrizKPIV2I(m,11) = matrizTrenV2I(m,12);
    end%Fin del bucle de KPIs CBTC-V2I
     
    %Se calcula la capacidad media para cada longitud del tren que utiliza
    %CBTC-V2I
    matrizKPIV2I(1,10) = round((matrizKPIV2I(1,10))./(matrizKPIV2I(1,9)));
    matrizKPIV2I(2,10) = round((matrizKPIV2I(2,10))./(matrizKPIV2I(2,9)));
    matrizKPIV2I(3,10) = round((matrizKPIV2I(3,10))./(matrizKPIV2I(3,9)));
    matrizKPIV2I(4,10) = round((matrizKPIV2I(4,10))./(matrizKPIV2I(4,9)));
    matrizKPIV2I(1,9) = 80;
    matrizKPIV2I(2,9) = 90;
    matrizKPIV2I(3,9) = 100;
    matrizKPIV2I(4,9) = 110;
    %Se calcula la distancia media entre trenes usando CBTC-V2I
    matrizKPIV2I(numeroTrenes,1) = matrizKPIV2I(numeroTrenes,1) / (numeroTrenes-1);
    %Se calcula la longitud media de interestacion recorrida por los
    %trenes usando CBTC-V2I
    matrizKPIV2I(numeroTrenes,6) = matrizKPIV2I(numeroTrenes,6) / (numeroTrenes-1);
    %Se calcula la velocidad media de los trenes usando CBTC-V2I
    matrizKPIV2I(numeroTrenes,2) = matrizKPIV2I(numeroTrenes,2) ./ (numeroTrenes-1);

    %Se guardan en el excel anterior los resultados obtenidos a continuacion de los anteriores
	xlswrite('KPI.xlsx',matrizKPIV2I,'CBTC-V2I','N2');
    
    %Se representan en graficas algunos valores obtenidos de los calculos
    %de KPIs de CBTC-V2V y CBTC-V2I

    %Se crean los valores que tendrán los ejes de abscisas y ordenadas de
    %la grafica Capacidad vs Longitud Interestacion
    longitudInterestacionV2V = 900:10:matrizKPIV2V(numeroTrenes,6);
    capacidadV2V =(numeroInterestaciones*longitudInterestacionV2V)/(matrizKPIV2V(numeroTrenes,1));
    longitudInterestacionV2I = 900:10:matrizKPIV2I(numeroTrenes,6);
    capacidadV2I =(numeroInterestaciones*longitudInterestacionV2I)/(matrizKPIV2I(numeroTrenes,1));

    %Capacidad vs Longitud Interestacion
    figure
    a = stem(longitudInterestacionV2V,capacidadV2V,'blue','filled','MarkerFaceColor','blue'); grid on;hold on
    stem(longitudInterestacionV2I,capacidadV2I,'green','filled','MarkerFaceColor','green'); grid on;
	title('Capacidad vs Longitud Interestacion')
	xlabel('Longitud interestacion(m)') % Etiqueta el eje horizontal
	ylabel('Capacidad de la linea (nº Trenes)') % Etiqueta el eje vertical
    legend('Capacidad V2V','Capacidad V2I','Location','Best')
    axis([900 max(matrizKPIV2V(numeroTrenes,6)) 0 40])
    saveas(a,'Capacidad vs Longitud Interestacion.jpg')
    
    %Capacidad vs Velocidad Media
    figure
    b = stem(matrizKPIV2V(:,2),matrizKPIV2V(:,5),'blue','filled','MarkerFaceColor','blue'); grid on;hold on
    stem(matrizKPIV2I(:,2),matrizKPIV2I(:,5),'green','filled','MarkerFaceColor','green'); grid on; 
    title('Capacidad vs Velocidad Media')
	xlabel('Velocidad(m/s)') % Etiqueta el eje horizontal
	ylabel('Capacidad de la linea (nº Trenes)') % Etiqueta el eje vertical
    legend('Velocidad media V2V','Velocidad media V2I','Location','Best')
    axis([5 10 0 40])
    saveas(b,'Capacidad vs Velocidad Media.jpg')
    
    %Se crean los valores que tendrán los ejes de abscisas y ordenadas de
    %la grafica Capacidad vs Velocidad maxima
    maxCapacidadV2V = round(longitudLinea/(min(matrizKPIV2V(:,1))));
    minCapacidadV2V = floor(longitudLinea/(max(matrizKPIV2V(:,1))));
    maxCapacidadV2I = round(longitudLinea/(min(matrizKPIV2I(:,1))));
    minCapacidadV2I = floor(longitudLinea/(max(matrizKPIV2I(:,1))));
    minVmax = 25;
    maxVmaxV2V = round(max(matrizKPIV2V(:,11)));
    maxVmaxV2I = round(max(matrizKPIV2I(:,11)));
    vmaxV2V = minVmax:0.25:maxVmaxV2V;
    vmaxV2I = minVmax:0.25:maxVmaxV2I;
    intervaloV2V = 0.25*(maxCapacidadV2V - minCapacidadV2V)/(maxVmaxV2V - minVmax);
    intervaloV2I = 0.25*(maxCapacidadV2I - minCapacidadV2I)/(maxVmaxV2I - minVmax);
    capacidadV2V = maxCapacidadV2V:-1*intervaloV2V:minCapacidadV2V;
    capacidadV2I = maxCapacidadV2I:-1*intervaloV2I:minCapacidadV2I;
    
    %Capacidad vs Velocidad maxima
    figure
    c = stem(vmaxV2V,capacidadV2V,'blue','filled','MarkerFaceColor','blue'); grid on;hold on
    stem(vmaxV2I,capacidadV2I,'green','filled','MarkerFaceColor','green'); grid on;
	title('Capacidad vs VMAX')
	xlabel('Velocidad(m/s)') % Etiqueta el eje horizontal
	ylabel('Capacidad (nº Trenes)') % Etiqueta el eje vertical
    legend('Velocidad maxima V2V','Velocidad maxima V2I','Location','Best')
    saveas(c,'Capacidad vs VMAX.jpg')
    
    %Capacidad vs Tiempo de parada
    figure
    d = stem(matrizKPIV2V(:,7),matrizKPIV2V(:,5),'blue','filled','MarkerFaceColor','blue'); grid on;hold on;
    stem(matrizKPIV2I(:,7),matrizKPIV2I(:,5),'green','filled','MarkerFaceColor','green'); grid on; 
    title('Capacidad vs Tiempo de parada')
	xlabel('Tiempo de parada(s)') % Etiqueta el eje horizontal
	ylabel('Capacidad (nº Trenes)') % Etiqueta el eje vertical
    legend('CBTC-V2V','CBTC-V2I','Location','Best')
    axis([20 50 0 40])
    saveas(d,'Capacidad vs Tiempo de parada.jpg')
    
    %Capacidad vs Tiempo entre trenes
    figure
    e = stem(matrizKPIV2V(:,3),matrizKPIV2V(:,5),'blue','filled','MarkerFaceColor','blue'); grid on;hold on;
    stem(matrizKPIV2I(:,3),matrizKPIV2I(:,5),'green','filled','MarkerFaceColor','green'); grid on;
    title('Capacidad vs Tiempo entre trenes')
    xlabel('Tiempo(s)') % Etiqueta el eje horizontal
	ylabel('Capacidad de la linea (nº Trenes)') % Etiqueta el eje vertical
    axis([40 100 0 40])
    legend('Tiempo entre trenes V2V','Tiempo entre trenes V2V','Location','Best')
    saveas(e,'Capacidad vs Tiempo entre trenes medio.jpg')
   
    %Capacidad vs Longitud del tren
    figure
    f = stem(matrizKPIV2V(:,9),matrizKPIV2V(:,10),'blue','filled','MarkerFaceColor','blue'); grid on;hold on
    stem(matrizKPIV2I(:,9),matrizKPIV2I(:,10),'green','filled','MarkerFaceColor','green'); grid on; 
    title('Capacidad vs Longitud Tren CBTC-V2V')
	xlabel('Longitud del tren(m)') % Etiqueta el eje horizontal
	ylabel('Capacidad de la linea (nº Trenes)') % Etiqueta el eje vertical
    legend('Longitud del tren CBTC-V2V','Longitud del tren CBTC-V2I','Location','Best')
    axis([70 120 0 40])
    saveas(f,'Capacidad vs Longitud Trenes CBTC-V2V.jpg')
    
    %Capacidad vs Potencia recibida
    figure
    g = stem(matrizKPIV2V(:,1),matrizKPIV2V(:,8),'blue','filled','MarkerFaceColor','blue'); grid on;
	title('Potencia Recibida vs Distancia entre trenes CBTC-V2V')
	xlabel('Distancia entre trenes(m)') % Etiqueta el eje horizontal
	ylabel('Potencia (dbBm)') % Etiqueta el eje vertical
    legend('Potencia Recibida','Location','Best')
    saveas(g,'Potencia Recibida vs Distancia entre trenes CBTC-V2V.jpg')

end%Fin de la funcion KPIV2V