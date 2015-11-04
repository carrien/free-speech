function [zdata,base_mean,base_std] = zscore_from_baseline(data,baseline_itvl,taxis,median4mean)

if nargin < 4, median4mean = 0; end
base = data(taxis >= baseline_itvl(1) & taxis <= baseline_itvl(2));

if median4mean
    base_mean = mean(base);
else
    base_mean = median(base);
end
base_std = std(base);

zdata = (data-base_mean)./base_std;