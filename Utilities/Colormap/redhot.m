function cmap = redhot(m)

if nargin < 1
   f = get(groot,'CurrentFigure');
   if isempty(f)
      m = size(get(groot,'DefaultFigureColormap'),1);
   else
      m = size(f.Colormap,1);
   end
end

cmap = zeros(256,3);
cmap(1:128,1) = linspace(0,1,128);
cmap(129:256,1) = 1;
cmap(129:256,2) = linspace(0,213/255, 128);
cmap(129:256,3) = 0;

P = size(cmap,1);
cmap = interp1(1:P, cmap, linspace(1,P,m), 'linear');