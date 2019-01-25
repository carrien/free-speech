function [ ] = copy_ax(hcopyfrom,hcopyto)
%COPY_AX  Copy axis scaling from one figure to another.
%  COPY_AX(HCOPYFROM,HCOPYTO) applies one figure's axis to another.
%  HCOPYFROM is the figure handle to be copied; HCOPYTO is the figure whose
%  axis will be changed.

figure(hcopyfrom)
ax = axis;

for h=1:length(hcopyto)
    figure(hcopyto(h))
    axis(ax);
end
