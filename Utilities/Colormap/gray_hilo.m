function ghl = gray_hilo(m)
%GRAYHILO   Linear gray-scale color map
%   GRAYHILO(M) returns an M-by-3 matrix containing a gray-scale colormap.
%   GRAYHILO, by itself, is the same length as the current figure's
%   colormap. If no figure exists, MATLAB uses the length of the
%   default colormap.
%
%   For example, to reset the colormap of the current figure:
%
%             colormap(grayHiLo)
%
%   See also HSV, HOT, COOL, BONE, COPPER, PINK, FLAG, 
%   COLORMAP, RGBPLOT.

%   Copyright 1984-2015 The MathWorks, Inc.
%   Modified by Thomas Rust, October, 2018

if nargin < 1
   f = get(groot,'CurrentFigure');
   if isempty(f)
      m = size(get(groot,'DefaultFigureColormap'),1);
   else
      m = size(f.Colormap,1);
   end
end
m = m-2; %make space for red and blue lines
g = (0:m-1)'/max(m-1,1);
g = [g g g];
ghl=[[0 0 1]; g; [1 0 0]];
