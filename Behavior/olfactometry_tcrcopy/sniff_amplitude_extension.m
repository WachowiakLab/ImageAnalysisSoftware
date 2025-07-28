function sniff_amplitude_extension(interface)

    interface.add(extract_sniff_amplitude(interface.getBlankInitializer()))

    function init = extract_sniff_amplitude(init)
        init.uid = 'extract_sniff_amplitude';
        init.name = 'Extract sniff amplitude';
        init.group = 'Scripts';
        init.type = 'script';
        init.onExecute = @calcAmp;
        
        function calcAmp
            o = interface.getOlfact();
            trials = interface.getSelectedItems();
            for t = trials'
                tr = lpf(denoise(o.trials(t).other.sniff_pressure),o.trials(1).other.samplingrate,2,25);
                dtr = diff(tr);
                samps = round(o.trials(t).measurement.stim_times .* o.trials(t).other.samplingrate);
                minima = zeros(size(samps));
                maxima = minima;

                for i = 1:length(samps)
                    minsamp = find(dtr(samps(i):-1:1) < 0, 1);
                    if isempty(minsamp)
                        minsamp = 1;
                    end
                    minima(i) = tr(samps(i)-minsamp+2);
                    maxsamp = find(dtr(samps(i):end) < 0, 1);
                    if isempty(maxsamp)
                        maxsamp = length(dtr)-samps(i)+2;
                    end
                    maxima(i) = tr(samps(i)+maxsamp-1);
                end
                %figure,plot(tr);
                %hold all

                interface.updateOlfact(...
                    ['trials(' num2str(t) ').measurement.sniff_amplitudes'], maxima - minima);

                %scatter(samps,minima)
                %scatter(samps,maxima)
                %maxima - minima
            end
        end
    end
    

end