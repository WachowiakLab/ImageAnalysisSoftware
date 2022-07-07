function aux3 = defineAux3(aux1, varargin)
%function aux3 = defineAux3(aux1, varargin)
%A program to create an aux 3(odornumber) signal
%create aux3 signal (odornumbers) aux1(odor) and optional varargin{1}(vector of odor numbers)
%   varargin{1} = odornumbers; e.g. [ 0 127 46 52 ] should match #trials in aux1
if nargin > 1; odornums = varargin{1}; else odornums = []; end
aux3.times = aux1.times;
aux3.signal = zeros(size(aux1.signal));
iDelay = find(aux1.times>0.1,1); iStep = find(aux1.times>=0.25,1);
i = 2;
odortrial = 0;
while i < length(aux1.signal)
    if aux1.signal(i) > aux1.signal(i-1) %odor on
        odortrial = odortrial+1;
        if isempty(odornums) || length(odornums)<odortrial
            disp(odortrial);
            odornums(odortrial) =  input('Enter odornumber:'); 
        end
        odornum = odornums(odortrial);
        spikes = dec2bin(odornum); spikes = flip(spikes);
        for b = 1:length(spikes)
            if str2num(spikes(b))
                aux3.signal(i+iDelay+(b-1)*iStep) = 1;
            end
        end
    end
    i = i+1;
end 
aux3.odors = odornums;

