function newaux3 = ePhysValence2Odors(aux3,ephys)
%converts aux3 to odors 0 or 1 using  ephys valence signal
%March 2023, TCR
newaux3.times = aux3.times;
newaux3.signal = zeros(1,length(aux3.times));
if ~isempty(aux3)
    odors = []; nOdors = 0;
    i=2; jump=find(aux3.times>2.1,1,'first'); %8x0.25sec intervals
    while i<length(aux3.signal) %skip first frame in case signal is on at scan start
        if aux3.signal(i)==1 && aux3.signal(i-1)==0 %find odor onset
            newaux3.signal(i) = 1; %create the odor on/off signal
            ind = find(ephys.times>aux3.times(i)-.25); %search valence from 0.25sec before odor on
            val = max(ephys.valence(ind:ind+50)); %search for 50 frames at 150Hz = .33sec
            if val>0.5 %valence positive
                odor = 1;
                newaux3.signal(i+16) = 1; %add a spike in new aux3, .1 after odor on signal
            else %valence negative
                odor = 0;
            end
            if isempty(odors)
                nOdors = 1;
                odors(1) = odor; 
            else
                if ~max(odor == odors)
                    nOdors = nOdors+1;
                    odors(nOdors)= odor; %add 1 for correct indexing
                end
            end
            i=i+jump; %jump forward
        else
            i=i+1;
        end
    end
    newaux3.odors = odors;
end