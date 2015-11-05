function [vec] = ind2subv(siz,i)
%IND2SUBV  Multiple subscript vector from linear index (wraps IND2SUB).

[out{1:length(siz)}] = ind2sub(siz,i);
vec = cell2mat(out);