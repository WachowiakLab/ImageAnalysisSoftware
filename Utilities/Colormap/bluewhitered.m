function map = bluewhitered(m)
%BLUEWHITERED Blue-White-Red color map. This is a diverging colormap, useful
%   for showing data with positive values in red, negative values in blue,
%   and middle values in white.
%
%   BLUEWHITERED(M) returns an M-by-3 matrix containing a colormap. The colors
%   begin with blue and increase through white to bright red. This is
%   a diverging colormap, useful for showing data with positive and 
%   negative values. To set zeros to white, use the command:
%       tmp= caxis(gca); caxis([max(tmp) max(tmp)]);
%
%   BLUEWHITERED returns a colormap with the same number of colors
%   as the current figure's colormap. If no figure exists, MATLAB uses
%   the length of the default colormap.
%
%   EXAMPLE
%
%   This example shows how to reset the colormap of the current figure.
%
%       colormap(bluewhitered)
%
%   See also PARULA, AUTUMN, BONE, COLORCUBE, COOL, COPPER, FLAG, GRAY,
%   HOT, HSV, JET, LINES, PINK, PRISM, SPRING, SUMMER, WHITE, WINTER,
%   COLORMAP, RGBPLOT.

%   Created by Thomas C. Rust, 2018
%   Acknowledgements to Mathworks (parula.m)

if nargin < 1
   f = get(groot,'CurrentFigure');
   if isempty(f)
      m = size(get(groot,'DefaultFigureColormap'),1);
   else
      m = size(f.Colormap,1);
   end
end

values = [
	0	0	1	%"Blue"
	1	1	1	%"White"
	1	0	0	%"Red"
   ];

P = size(values,1);
map = interp1(1:size(values,1), values, linspace(1,P,m), 'linear');
