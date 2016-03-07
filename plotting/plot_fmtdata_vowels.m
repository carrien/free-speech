function [] = plot_fmtdata_vowels(exptName,snum,freqscale,avgfn,subdirname,condtype)
%PLOT_FMTDATA_VOWELS  Plot vowel production space.
%   PLOT_FMTDATA_VOWELS(EXPTNAME,SNUM,FREQSCALE,AVGFN,SUBDIRNAME) plots the
%   vowel production space from subject SNUM's fdata_vowels file.

if nargin < 3 || isempty(freqscale), freqscale = {'hz','mels'};
else freqscale = {freqscale};
end
if nargin < 4 || isempty(avgfn), avgfn = {'mid50p','first50ms'};
else avgfn = {avgfn};
end
if nargin < 5 && strcmp(exptName,'mvSIS')
    subdirname = 'speak';
elseif nargin < 5 && strcmp(exptName,'cat')
    subdirname = fullfile('pert','formant_analysis');
end

dataPath = getAcoustSubjPath(exptName,snum,subdirname);
load(fullfile(dataPath,sprintf('fdata_%s.mat',condtype)));
colors = setcolors;

for f=1:length(freqscale)
    for a=1:length(avgfn)
        figure;
        vowels = fieldnames(fmtdata.(freqscale{f}));
        for v=1:length(vowels)
            f1 = fmtdata.(freqscale{f}).(vowels{v}).(avgfn{a}).rawavg.f1;
            f2 = fmtdata.(freqscale{f}).(vowels{v}).(avgfn{a}).rawavg.f2;
            plot(f1,f2,'.','Color',colors(v,:),'MarkerSize',15);
            hold on;
            medf1 = fmtdata.(freqscale{f}).(vowels{v}).(avgfn{a}).med.f1;
            medf2 = fmtdata.(freqscale{f}).(vowels{v}).(avgfn{a}).med.f2;
            plot(medf1,medf2,'o','Color',colors(v,:),'MarkerSize',2);
            [~,minind] = min(fmtdata.(freqscale{f}).(vowels{v}).(avgfn{a}).dist);
            medindf1 = fmtdata.(freqscale{f}).(vowels{v}).(avgfn{a}).rawavg.f1(minind);
            medindf2 = fmtdata.(freqscale{f}).(vowels{v}).(avgfn{a}).rawavg.f2(minind);
            plot(medindf1,medindf2,'o','Color',[.6 .6 .6],'MarkerSize',8);
        end
        title(sprintf('Vowel production space, %s s%d, %s',exptName,snum,avgfn{a}));
        xlabel(sprintf('F1 (%s)',freqscale{f}));
        ylabel(sprintf('F2 (%s)',freqscale{f}));
    end
end

