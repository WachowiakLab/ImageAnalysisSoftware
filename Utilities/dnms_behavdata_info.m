match=[];order=[];odornum=[];odortrialnum=[];
trialcategories=table(match,order,odornum,odortrialnum,'VariableNames',{'Match','PulseOrder','OdorNum','OdorTrialNum'});
for t = 1:length(behaviordata.trials)
   odornum(t)=behaviordata.trials(t).odornumber;
   odortrialnum(t)=behaviordata.trials(t).trialnumber;
   if behaviordata.trials(t).ephys.odor(10) > 1
       order(t)=2;
   else order(t)=1;
   end
   if max(behaviordata.trials(t).ephys.valence)>1
       match(t)=0;
   else match(t)=1;
   end
end
trialcategories=table(match',order',odornum',odortrialnum','VariableNames',{'Match','PulseOrder','OdorNum','OdorTrialNum'});
   
   
    