function auxcombo = doAuxCombo(aux1, aux2, varargin)
%function auxcombo = doAuxCombo(aux1, aux2, varargin)
%compute auxcombo (sniff during odor) signal from aux1(odor) and aux2(sniff)
%   varargin{1} = odorduration; required for scanimage setup where odor
%   does not encode duration (only odor "on" spikes)
    if ~isempty(varargin) %used for scanimage (only gets "on" signal for odor - need to input duration)
        odorDuration = varargin{1};
        auxcombo.odorDuration = odorDuration;
        odor = zeros(size(aux1.signal));
        onFrames = floor(odorDuration/(aux1.times(2)-aux1.times(1))); %duration/sampling period
        i = 2; OnOdor = [];
        while i < length(aux1.signal)
            if aux1.signal(i) > aux1.signal(i-1)
                OnOdor = [OnOdor i];
            end
            i=i+1;
        end
        for nFn = 0:onFrames
            odor(OnOdor+nFn) = 1;
        end 
        ind = find(aux2.signal > 0); %indices of sniffs (note: use >0 instead of ==1 incase of averaging)
        ind2 = (odor(ind) == 1); %sniff indices with odor on
    else %aux1 signal encodes for odor on and off - includes duration
        ind = find(aux2.signal > 0); %sniff indices
        ind2 = aux1.signal(ind) == 1; %subset of sniff indices with odor on
    end
    auxcombo.times = aux2.times;
    auxcombo.signal = zeros(size(aux2.signal));
    auxcombo.signal(ind(ind2))= 1;
end   