function [ ] = plot_sine_sum_arrows(sinewaves,t,t_arrow)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

for a=1:size(sinewaves,1)
    thissinewave = sinewaves(a,:);
    ind = get_index_at_time(t,t_arrow);
    line([t_arrow t_arrow],[0 thissinewave(ind)]);
    hold on;
end

