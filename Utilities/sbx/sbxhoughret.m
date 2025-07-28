
function [r,err] = sbxhoughret(th,d,w)

% Finds the point closest to a set of lines weighted by w

A = [cos(th).^2 sin(th).*cos(th)] ; 
A = [A ; sin(th).*cos(th) sin(th).^2];
A = A .* ([w; w] * ones(1,2));
D = [d.*cos(th); d.*sin(th)] .* ([w; w]);

r = pinv(A)*D;

% compute error

err = mean(([cos(th) sin(th)] * r - d).^2);




    
