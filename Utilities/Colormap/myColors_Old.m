function c=myColors(num)
% DEFINE COLOR PROGRESSION
c=[0 0 0];
num=mod(num,15);
switch num
    case 1
        c=[255 0  0]/255;     
    case 2
        c=[0 160 0]/255;   
    case 3
        c=[0 0 255]/255;     
    case 4
        c=[104 34 139]/255;        
    case 5
        c=[225 118 0]/255;   
    case 6  
        c=[240 220 0]/255;  
    case 7
        c=[255 175 0]/255;   
    case 8
        c=[255 131 250]/255;
    case 9
        c=[205 0 205]/255;  
    case 10
        c=[50 153 204]/255;
    case 11
        c=[112 219 147]/255;     
    case 12
        c=[151 105 79]/255;   
    case 13
        c=[107 66 38]/255;
    case 14
        c=[0.4 0.4 0.4];  
    case 0
        c=[140 140 140]/255;  
end
% MATLAB default colors as of R2014b are as follows
%          0    0.4470    0.7410
%     0.8500    0.3250    0.0980
%     0.9290    0.6940    0.1250
%     0.4940    0.1840    0.5560
%     0.4660    0.6740    0.1880
%     0.3010    0.7450    0.9330
%     0.6350    0.0780    0.1840 