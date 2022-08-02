function [se, m] = ste(x)
%STE Standard error.
%   For vectors, SE = STE(X) returns the standard error. For matrices, Y is
%   a row vector containing the standard error of each column.
%
%   [SE,M] = STE(X) also returns the mean M of the values in X that was
%   used to calculate the standard error.

if isvector(x)
    n = length(x);
else
    n = size(x,1);
end

%check if 'std' returns mean
v = version('-date');
year = str2double(v(end-4:end));
if year >= 2022
    [sd,m] = std(x);
else
    sd = std(x);
    sz = size(sd);
    m = nan(sz(1),sz(2));
end
se = sd/sqrt(n);

end
