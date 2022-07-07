function map = mycolors19(m)
%NAWHIMAR Navy-Azure-White-Red-Maroon color map. This is a diverging
%   colormap, useful for showing data with positive values in red, negative
%   values in blue, and middle values in white.
%
%   NAWHIMAR(M) returns an M-by-3 matrix containing a colormap. 
%   The colors begin with navy (dark blue) and increase through azure 
%   (bright blue) to white, then increase to bright red through maroon
%   (dark red). This is a diverging colormap, useful for showing data
%   with positive and negative values from a mean. Use the command:
%   tmp= caxis(gca); caxis([max(tmp) max(tmp)]) to set white to zero.
%
%   NAWHIMAR returns a colormap with the same number of colors
%   as the current figure's colormap. If no figure exists, MATLAB uses
%   the length of the default colormap.
%
%   EXAMPLE
%
%   This example shows how to reset the colormap of the current figure.
%
%       colormap(nawhimar)
%
%   See also PARULA, AUTUMN, BONE, COLORCUBE, COOL, COPPER, FLAG, GRAY,
%   HOT, HSV, JET, LINES, PINK, PRISM, SPRING, SUMMER, WHITE, WINTER,
%   COLORMAP, RGBPLOT.

%   Created by Thomas C. Rust, 2018
%   Acknowledgements to Mathworks (parula.m), and Nathan Childress
%   (bluewhitered.m)

if nargin < 1
   f = get(groot,'CurrentFigure');
   if isempty(f)
      m = size(get(groot,'DefaultFigureColormap'),1);
   else
      m = size(f.Colormap,1);
   end
end

values = [
	0 0.447000000000000 0.741000000000000
    0.850000000000000 0.325000000000000 0.0980000000000000
    0.929000000000000 0.694000000000000 0.125000000000000
    0.494000000000000 0.184000000000000 0.556000000000000
    0.466000000000000 0.674000000000000 0.188000000000000
    0.301000000000000 0.745000000000000 0.933000000000000
    0.635000000000000 0.0780000000000000 0.184000000000000
    0.678400000000000 0.921600000000000 1
    0.749000000000000 0.749000000000000 0
    0.749000000000000 0 0.749000000000000
    0 0.498000000000000 0
    0 0.749000000000000 0.749000000000000
    0.0784000000000000 0.168600000000000 0.549000000000000
    0.854900000000000 0.702000000000000 1
    1 0.843100000000000 0
    0.870600000000000 0.490200000000000 0
    1 0 0
    1 0 1
    0 0 1
   ];

P = size(values,1);
map = interp1(1:size(values,1), values, linspace(1,P,m), 'linear');
