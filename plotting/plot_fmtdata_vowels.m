function [] = plot_fmtdata_vowels(dataPath,freqscale,avgfn,condtype)
%PLOT_FMTDATA_VOWELS  Plot vowel production space.
%   PLOT_FMTDATA_VOWELS(DATAPATH,FREQSCALE,AVGFN,CONDTYPE) plots the
%   vowel production space from the fdata_vowel file found in DATAPATH.

if nargin < 1 || isempty(dataPath), dataPath = cd; end

if nargin < 2 || isempty(freqscale), freqscale = {'hz','mels'};
elseif ischar(freqscale), freqscale = {freqscale};
end

if nargin < 3 || isempty(avgfn), avgfn = {'mid50p','first50ms'};
elseif ischar(avgfn), avgfn = {avgfn};
end

if nargin < 4 || isempty(condtype), condtype = 'vowel'; end

% load formant data
load(fullfile(dataPath,sprintf('fdata_%s.mat',condtype)));
% load experiment info, if it exists, for figure title
exptFile = fullfile(dataPath,'expt.mat');
if exist(exptFile,'file')
    load(exptFile);
    name = sprintf('%s %d',expt.name,expt.snum);
else
    name = dataPath;
end

for f=1:length(freqscale)
    frq = freqscale{f};
    vowels = fieldnames(fmtdata.(frq));
    colors = get_colors(length(vowels));
    for a=1:length(avgfn)
        avg = avgfn{a};
        figure;
        for v=1:length(vowels)
            vow = vowels{v};
            f1 = fmtdata.(frq).(vow).(avg).rawavg.f1;
            f2 = fmtdata.(frq).(vow).(avg).rawavg.f2;
            plot(f1,f2,'.','Color',colors(v,:),'MarkerSize',15);
            hold on;
            medf1 = fmtdata.(frq).(vow).(avg).med.f1;
            medf2 = fmtdata.(frq).(vow).(avg).med.f2;
            plot(medf1,medf2,'o','Color',colors(v,:),'MarkerSize',2);
            text(medf1,medf2,vow, 'HorizontalAlignment','center', 'VerticalAlignment','bottom')
            [~,minind] = min(fmtdata.(frq).(vow).(avg).dist);
            medindf1 = fmtdata.(frq).(vow).(avg).rawavg.f1(minind);
            medindf2 = fmtdata.(frq).(vow).(avg).rawavg.f2(minind);
            plot(medindf1,medindf2,'o','Color',[.6 .6 .6],'MarkerSize',8);
        end
        title(sprintf('Vowel production space (%s), %s',avg,name));
        xlabel(sprintf('F1 (%s)',frq));
        ylabel(sprintf('F2 (%s)',frq));
    end
end

