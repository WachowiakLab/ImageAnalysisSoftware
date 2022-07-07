function newmap = azublare_auto(varargin)
%AZUBLARE_AUTO Azure-Black-Red color map. This is a diverging colormap,
%   useful for showing data with positive values in red, negative values
%   in blue, and values of zero in black.
%
%   AZUBLARE_AUTO(M,CLIM) returns an M-by-3 matrix containing a colormap. 
%   The colors may range from azure blue increasing through black to red.
%   Uses CLIM property to automatically scale maximal red/blue shading.
%
%   AZUBLARE_AUTO(M) returns an M-by-3 matrix containing a colormap. 
%   The colors may range from azure blue increasing through black to red.
%   Uses current axes CLIM property to automatically scale maximal red/blue
%   shading. If no axes exists, CLIM = [-1 1].
%
%   AZUBLARE_AUTO returns a colormap with the same number of colors as
%   the current figure's colormap. If no figure exists, MATLAB uses the
%   length of the default colormap. The colors may range from azure blue
%   increasing through black to red. Uses current axes CLIM property to
%   automatically scale maximal red/blue shading. If no axes exists,
%   CLIM = [-1 1].
%
%   EXAMPLE
%
%   This example shows how to reset the colormap of the current figure.
%
%       colormap(azublare_auto)
%
%   See also PARULA, AUTUMN, BONE, COLORCUBE, COOL, COPPER, FLAG, GRAY,
%   HOT, HSV, JET, LINES, PINK, PRISM, SPRING, SUMMER, WHITE, WINTER,
%   COLORMAP, RGBPLOT.

%   Created by Thomas C. Rust, 2018
%   Acknowledgements to Mathworks (parula.m)

if isempty(varargin)
    hFig = get(groot,'CurrentFigure');
    if isempty(hFig)
        m = size(get(groot,'DefaultFigureColormap'),1);
        clim = [-1 1];
    else
        m = size(hFig.Colormap,1);
        hAx = get(hFig,'CurrentAxes');
        if isempty(hAx); clim = [-1 1];
        else; clim = hAx.CLim;
        end
    end
elseif numel(varargin)==1
    if min(size(varargin{1})==[1 1])
        m=varargin{1};
        hFig = get(groot,'CurrentFigure'); hAx=get(hFig,'CurrentAxes');
        if isempty(hAx); clim = [-1 1];
        else; clim = hAx.CLim;
        end
    elseif min(size(varargin{1})==[1 2])
        clim = varargin{1};
        hFig = get(groot,'CurrentFigure');
        if isempty(hFig); m = size(get(groot,'DefaultFigureColormap'),1);
        else; m = size(hFig.Colormap,1);
        end
    else; disp('Error: varargin is the wrong size'); return;
    end
elseif numel(varargin)==2
    for v = 1:2
        if min(size(varargin{v})==[1 1]); m = varargin{v};
        elseif min(size(varargin{v})==[1 2]); disp('tcr');clim = varargin{v};
        else; sprintf('Error: varargin{%d} is the wrong size',v); return;
        end
    end
else; disp('Error: incorrect number of inputs'); return;
end

%Define base colors
bottom = [0 0.5 1];%"Azure"
middle = [0 0 0]; %"White"
top = [1 0 0]; %"Red"

if (clim(1) < 0) && (clim(2) > 0)% It has both negative and positive
    range = clim(2)-clim(1);
    if clim(2) >= abs(clim(1)) %more positive than negative
        poslevels = round((clim(2)/range)*m);
        neglevels = m-poslevels;
        pos = [middle; top];
        for i = 1:3
            newmappos(:,i) = min(max(interp1([0 1], pos(:,i), linspace(0,1,poslevels)'), 0), 1);
        end
        neg = [bottom; middle];
        for i = 1:3
            newmapneg(:,i) = min(max(interp1([0 1], neg(:,i), linspace(0,1,poslevels)'), 0), 1);
        end
        newmapneg = newmapneg(end-neglevels+1:end,:);
        newmap = [newmapneg(1:end-1,:); middle; newmappos(2:end,:)];
    else %more negative
        neglevels = round((-clim(1)/range)*m);
        poslevels = m-neglevels;
        neg = [bottom; middle];
        for i = 1:3
            newmapneg(:,i) = min(max(interp1([0 1], neg(:,i), linspace(0,1,neglevels)'), 0), 1);
        end
        pos = [middle; top];
        for i = 1:3
            newmappos(:,i) = min(max(interp1([0 1], pos(:,i), linspace(0,1,neglevels)'), 0), 1);
        end
        newmappos = newmappos(1:poslevels,:);
        newmap = [newmapneg(1:end-1,:); middle; newmappos(2:end,:)];
    end
elseif clim(1) >= 0 % Just positive
    pos = [middle; top];
    for i = 1:3
        newmap(:,i) = min(max(interp1([0 1], pos(:,i), linspace(0,1,m)'), 0), 1);
    end
else
    neg = [bottom; middle];
    for i = 1:3
        newmap(:,i) = min(max(interp1([0 1], neg(:,i), linspace(0,1,m)'), 0), 1);
    end
end