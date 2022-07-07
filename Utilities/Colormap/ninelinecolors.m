function c=ninelinecolors(num)
% DEFINE COLOR PROGRESSION
% 12 colors, if num>9, colors will cyle
% based on ColorBrewer2.org (qualitative, 9 classes), and
% and matplotlib.org/user/colormaps (qualitative colormaps, set1)
c=[0 0 0];
if num>9; num=mod(num,9); end
switch num
    case 1
        c=[228 26 28]./255;
    case 2
        c=[55 126 184]./255;
    case 3
        c=[77 175 74]./255;
    case 4
        c=[152 78 163]./255;
    case 5
        c=[255 127 0]./255;
    case 6
        c=[255 255 51]./255;
    case 7
        c=[166 86 40]./255;
    case 8
        c=[247 129 191]./255;
    case 9
        c=[153 153 153]./255;
end