function [h] = plot_vowelspace_comparison(vowelgroups,avgfn)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if nargin < 2, avgfn = 'first50ms'; end

h = figure;
colors = get_colors(length(vowelgroups));

for g=1:length(vowelgroups)
    vowellist = fieldnames(vowelgroups{g});
    for v=1:length(vowellist)
        vowelname = vowellist{v};
        vowel = vowelgroups{g}.(vowelname);
        %plot(vowel.(avgfn).rawavg.f1,vowel.(avgfn).rawavg.f2,'.',Color,colors(g,:));
        text(vowel.(avgfn).rawavg.f1,vowel.(avgfn).rawavg.f2,vowelname,'Color',colors(g,:));
        hold on;
        plot(vowel.(avgfn).med.f1,vowel.(avgfn).med.f2,'+','Color',colors(g,:));
    end
end

xlabel('F1')
ylabel('F2')
    
