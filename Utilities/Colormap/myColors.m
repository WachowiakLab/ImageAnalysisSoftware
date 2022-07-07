function c=myColors(num)
% DEFINE COLOR PROGRESSION
% 26 colors, if num>26, colors will cyle
% based on MATLAB DefaultAxesColorOrder, and uisetcolor()
c=[0 0 0];
if num>26; num=mod(num,26); end
switch num
    case 1
        c=[0 .4470 .7410];
    case 2
        c=[0.8500 0.3250 0.0980];
    case 3
        c=[0.9290 0.6940 0.1250];
    case 4
        c=[0.4940 0.1840 0.5560];
    case 5
        c=[0.4660 0.6740 0.1880];
    case 6
        c=[0.3010 0.7450 0.9330];
    case 7
        c=[0.6350 0.0780 0.1840];
    case 8
        c=[0.6784 0.9216 1.0000];
    case 9
        c=[0.7490 0.7490 0];
    case 10
        c=[0.7490 0 0.7490];
    case 11
        c=[0 0.4980 0];
    case 12
        c=[0 0.7490 0.7490];
    case 13
        c=[0.0784 0.1686 0.5490];
    case 14
        c=[0.8549 0.7020 1.0000];
    case 15
        c=[1.0000 0.8431 0];
    case 16
        c=[0.8706 0.4902 0];
    case 17
        c=[1 0 0];
    case 18
        c=[1 0 1];
    case 19
        c=[0 0 1];
    case 20
        c=[0 1 0];
    case 21
        c=[0 1 1];
    case 22
        c=[1 1 0];
    case 23
        c=[0.6000 0.2000 0];
    case 24
        c=[1.0000 0.6000 0.7843];
    case 25
        c=[0.4 0.4 0.4];  
    case 26
        c=[0.6 0.6 0.6];  
end