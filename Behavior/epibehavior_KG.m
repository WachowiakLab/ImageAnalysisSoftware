function epibehavior()
    cd (uigetdir);
    load ("workspace.mat");
    clearvars -except TSdata Valence csplus csminus hitnum crnum
    
    odornumber = []
    
    for i = 1:length(Valence);
        if Valence(i) == 1
            odornumber(i,1) = 1
        else 
         odornumber(i,1) = 8
        end 
    end 
    
    %Make behavior data
    behaviordata=[];
    behaviordata.stim2use='Aux1(odor)';
    behaviordata.prestimtime=4
    behaviordata.poststimtime=6
    behaviordata.trials=[];
    load("dummysignal.mat")
    
    for i = 1:length(TSdata.file);
        behaviordata.trials(i).dir = TSdata.file(i).dir;
        behaviordata.trials(i).name= TSdata.file(i).name;
        behaviordata.trials(i).type= TSdata.file(i).type;
        behaviordata.trials(i).frameRate= TSdata.file(i).frameRate;
        behaviordata.trials(i).odornumber=odornumber(i);
        behaviordata.trials(i).trialnumber=i;
        behaviordata.trials(i).valence=Valence(i);
        if any(TSdata.file(i).aux1.signal == 1)
            behaviordata.trials(i).aux1.times= TSdata.file(i).aux1.times; 
            behaviordata.trials(i).aux1.signal= TSdata.file(i).aux1.signal;
        else 
             behaviordata.trials(i).aux1.times = TSdata.file(i).aux1.times;
             behaviordata.trials(i).aux1.signal = dummysignal; 
        end 
        behaviordata.trials(i).aux2=behaviordata.trials(i).aux1;
        behaviordata.trials(i).ephys.times=TSdata.file(i).ephys.times;
        behaviordata.trials(i).ephys.sniff= TSdata.file(i).ephys.sniff;
        behaviordata.trials(i).ephys.sniff(end) =  behaviordata.trials(i).ephys.sniff(end-1);
        behaviordata.trials(i).ephys.lick= TSdata.file(i).ephys.lick;
        behaviordata.trials(i).ephys.odor=TSdata.file(i).ephys.odor;
        behaviordata.trials(i).roi(1).time = TSdata.file(i).roi(end).time
        behaviordata.trials(i).roi(1).series = TSdata.file(i).roi(end).series
    end 
    clearvars -except behaviordata
    save("behavior.mat",'behaviordata')

end 