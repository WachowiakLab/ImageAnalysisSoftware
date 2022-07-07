function pctval = qprctile(v, p)
% pctval = qprctile(v,p)
% v is a vector (image values or a time series from ROI)
% p is a percentage, e.g. 99.0; or a percentage range, e.g. [1.0 99.0]
% returns: value or range [min max] of values at p of series (used for Colormap)

%NOTE: might just want to use MATLAB FXN prctile
%pctval = zeros(length(p),1);
p = p./100;
len = length(v); % #pixels
sortv = sort(v, 'ascend');

for i = 1:length(p) %does this once or twice(for pct range)
    val = len*p(i); % len * (p1 or p2)
    ind1 = floor(len*p(i)); % = val
    ind2 = ind1+1; %val + 1
    
    if (ind1 == len) % p is a percent, or 1st time through loop
        pctval(i) = double(sortv(end)); %returns highest image value if p = 100
    elseif (ind1<1)
        pctval(i) = double(sortv(1)); %returns lowest image value if p = 0 (pretty much)
    else
        pctval(i) = double(sortv(ind1)) + (double(sortv(ind2))-double(sortv(ind1))).*(val-ind1); 
        % returns value of pixel located at some percent of index of sortv (e.g. 99 out of 100 pixels)
    end
end
