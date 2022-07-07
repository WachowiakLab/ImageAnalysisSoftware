function map = nawhimar(m)
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
	0	0	0.5	%"Navy"
	0	0.5	1	%"Azure"
	1	1	1	%"White"
	1	0	0	%"Red"
	0.5	0	0	%"Maroon"
   ];

P = size(values,1);
map = interp1(1:size(values,1), values, linspace(1,P,m), 'linear');
