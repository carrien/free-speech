function [ ] = hideFromLegend(h)
%HIDEFROMLEGEND  Hide object from legend.
%   HIDFROMLEGEND(H) causes a plotted object H to not appear in the legend.

set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle', 'off');

%hasbehavior(h,'legend','false');