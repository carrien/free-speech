function [M] = nancat(a,b)
% NANCAT - concatenate arrays of different dimensions by padding with NaN
%
%   M = NANCAT(A,B) concatenates the array A and the column B into one
%   matrix. A is a 2D matrix of any size. B is a column vector. The arrays
%   do not need to have the same number of rows; the shorter one is padded
%   with NaNs.

% check which is the bigger column
aheight = size(a,1);
bheight = size(b,1);

if isempty(a)
elseif aheight == bheight
elseif aheight > bheight
    b(end+1:aheight,:) = NaN;
elseif aheight < bheight
    a(end+1:bheight,:) = NaN;
end
M = cat(2,a,b);