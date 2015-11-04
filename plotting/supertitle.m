function [] = supertitle(titletext)
%SUPERTITLE  Create a supertitle for a plot with subplots.

set(gcf,'NextPlot','add');
axes;
h = title(titletext);
set(gca,'Visible','off');
set(h,'Visible','on');