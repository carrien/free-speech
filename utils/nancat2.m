function [newmatrix] = nancat(matrix,newline)

nrows = size(matrix,1);
ncols = size(matrix,2);

if length(newline) <= nrows
    newmatrix = nan(nrows,ncols+1);
else
    newmatrix = nan(length(newline),ncols+1);
end

newmatrix(1:nrows,1:ncols) = matrix;
newmatrix(1:length(newline),ncols+1) = newline;