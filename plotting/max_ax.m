function [ ] = max_ax(hvec)
%MAX_AX  Set common axis scaling, using the min and max across figures.
%  MAX_AX(HVEC) sets the axes of all figures with handles in HVEC to the
%  maximum (and minimum) x and y values.

ax = zeros(length(hvec),4);
for h=1:length(hvec)
    figure(hvec(h))
    ax(h,:) = axis;
end
mins = min(ax); maxes = max(ax);
axis([mins(1) maxes(2) mins(3) maxes(4)]);