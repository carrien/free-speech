function [err] = nanse(data)
%NANSE  Standard error of the mean, ignoring NaNs.

err = nanstd(data) / sqrt(sum(~isnan(data)));

end
