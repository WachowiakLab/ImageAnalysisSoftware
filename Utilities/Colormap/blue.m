function cmap = blue(m)

if nargin < 1
   f = get(groot,'CurrentFigure');
   if isempty(f)
      m = size(get(groot,'DefaultFigureColormap'),1);
   else
      m = size(f.Colormap,1);
   end
end

cmap = [ 0 0 0;
    0 0 1];

P = size(cmap,1);
cmap = interp1(1:P, cmap, linspace(1,P,m), 'linear');