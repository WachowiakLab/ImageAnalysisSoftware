function rps=av_rps(trace,method)
    
    %method = 1 : detect on thermocouple trace, i.e. measure between troughs
    %method = 2 : detect on pressure trace, i.e. zero crossings
    %vps = volume per sniff
    %rps = rate per sniff, i.e. vps / duration of sniff cycle

    samp_freq=500;
    filt_trace=lpf(trace,500,1,20);
    if method==1
        delta=(max(filt_trace)-min(filt_trace))./2;               %delta parameter for peakdet is half the highest amplitude in the trace
        [maxtab,mintab]=peakdet(filt_trace,delta);           %getting position of peaks and troughs from the trace
    elseif method==2
        
        
    end
    if maxtab(1,1)<mintab(1,1)
        maxtab=maxtab(2:end,:);
    end
    if maxtab(end,1)>mintab(end,1)
        maxtab=maxtab(1:end-1,:);
    end
    if length(mintab)==length(maxtab)+1
        disp('check')
    end
    num_cycles=length(mintab)-1;
    
    vps=zeros(1,num_cycles);
    rps=zeros(1,num_cycles);
    
    figure
    plot(trace)
    hold on
    plot(filt_trace,'Color','g')
    line([mintab(:,1) mintab(:,1)],ylim,'Color','r');
    
    for i=1:num_cycles
        sniff_area=cumtrapz(trace(mintab(i,1):mintab(i+1,1)));
        vps(i)=sniff_area(end);
        rps(i)=vps(i)./(mintab(i+1,1)-mintab(i,1))./samp_freq;
        
        text(maxtab(i,1),max(ylim)-(max(ylim)./20),num2str(vps(i)));
        text(maxtab(i,1),max(ylim)-(max(ylim)./10),num2str(rps(i)));
    end
end