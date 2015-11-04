function [ ] = plot_overlay(figvec)
%PLOT_OVERLAY  Overlay axes from multiple plots.

figure;
destination = axes;

for i = 1:length(figvec)
    source = get(figvec(i),'Children');
    for j = 1:length(source)
        copyobj(get(source(j), 'Children'), destination);
    end
end

end

