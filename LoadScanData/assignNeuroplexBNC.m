function aux2bncmap = assignNeuroplexBNC()
% bncmap = assignNeuroplexBNC()
%   Assigns BNC signals in Neuroplex data to Aux(1-3) signals (see loadNeuroplex.m)
%   output: bncmap is a vector, where values(1:3) correspond to aux(1-3) signals, 
%   usual values are bncmap = [1 2 3 4]

%prompt = {'Enter BNC# for Odor Signal:','Enter BNC# for Sniff Signal:','Enter BNC# for Odor Number Signal:','Enter BNC# for fourth Signal:'};
prompt = {'Enter BNC# for Odor Signal:','Enter BNC# for Valence Signal:','Enter BNC# for Licking (3)/Odor ID Signal (5)','Enter BNC# for Sniff (4)/Reward (6) Signal:',...
    'Use Valence for OdorID (y/n)','Enter BNC# for Velocity Signal:', 'Enter BNC# for Odor ID Signal:'};
title = 'Assign Neuroplex BNC inputs to Auxiliary Signals';
dims = [1 40];
usual = {'1','2','3','4','y','5','6'};
answer = inputdlg(prompt,title,dims,usual);
if answer{5} == 'y'
        yn = 1;
else yn = 0;
end
aux2bncmap = [str2double(answer{1}) str2double(answer{2}) str2double(answer{3}) str2double(answer{4}) yn str2double(answer{6}) str2double(answer{7})];