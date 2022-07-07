function cmap = greenhot(m)

if nargin < 1
   f = get(groot,'CurrentFigure');
   if isempty(f)
      m = size(get(groot,'DefaultFigureColormap'),1);
   else
      m = size(f.Colormap,1);
   end
end

cmap = zeros(256,3);
cmap(1:128,2) = linspace(0,1,128);
cmap(129:256,1) = linspace(0,218/255, 128);
cmap(129:256,2) = 1;
cmap(129:256,3) = linspace(0,71/255, 128);

P = size(cmap,1);
cmap = interp1(1:P, cmap, linspace(1,P,m), 'linear');