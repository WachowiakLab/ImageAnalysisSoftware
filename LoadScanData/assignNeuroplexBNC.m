function aux2bncmap = assignNeuroplexBNC()
% bncmap = assignNeuroplexBNC()
%   Assigns BNC signals in Neuroplex data to Aux(1-3) signals (see loadNeuroplex.m)
%   output: bncmap is a vector, where values(1:3) correspond to aux(1-3) signals, 
%   usual values are bncmap = [1 3 2]

prompt = {'Enter BNC# for Odor Signal:','Enter BNC# for Sniff Signal:','Enter BNC# for Odor Number Signal:'};
title = 'Assign Neuroplex BNC inputs to Auxiliary Signals';
dims = [1 40];
usual = {'1','3','2'};
answer = inputdlg(prompt,title,dims,usual);
aux2bncmap = [str2double(answer{1}) str2double(answer{2}) str2double(answer{3})];