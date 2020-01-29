function [] = plot_vowel2vowel_vectors(dataPath,startConds,endConds,freqscale,avgfn,condtype,colors,bPlotCond)
%PLOT_FMTDATA_VOWELS  Plot vowel production space.
%   PLOT_FMTDATA_VOWELS(DATAPATH,FREQSCALE,AVGFN,CONDTYPE) plots the
%   vowel production space from the fdata_vowel file found in DATAPATH.

if nargin < 1 || isempty(dataPath), dataPath = cd; end

if nargin < 2 || isempty(startConds), startConds = {'red' 'green' 'blue'}; end
if nargin < 3 || isempty(endConds), endConds = {{'rid' 'rad'},{'grin' 'grain'},{'bleed' 'blow'}}; end

if nargin < 4 || isempty(freqscale), freqscale = {'hz','mels'};
elseif ischar(freqscale), freqscale = {freqscale};
end

if nargin < 5 || isempty(avgfn), avgfn = {'mid50p','first50ms'};
elseif ischar(avgfn), avgfn = {avgfn};
end

if nargin < 6 || isempty(condtype), condtype = 'vowel'; end

if nargin < 8, bPlotCond = 0; end

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

for f = 1:length(freqscale)
    frq = freqscale{f};
    conds = fieldnames(fmtdata.(frq));
    
    if nargin < 7
        colors = get_colorStruct(conds);
    elseif ~isstruct(colors)
        colors = get_colorStruct(conds,colors);
    end
    for a = 1:length(avgfn)
        avg = avgfn{a};
        figure;
        for c = 1:length(conds)
            cnd = conds{c};
            % get formants
            f1 = fmtdata.(frq).(cnd).(avg).rawavg.f1;
            f2 = fmtdata.(frq).(cnd).(avg).rawavg.f2;
            % get median formants
            medf1 = fmtdata.(frq).(cnd).(avg).med.f1;
            medf2 = fmtdata.(frq).(cnd).(avg).med.f2;
            % get token closest to median
            [~,minind] = min(fmtdata.(frq).(cnd).(avg).dist);
            medindf1 = fmtdata.(frq).(cnd).(avg).rawavg.f1(minind);
            medindf2 = fmtdata.(frq).(cnd).(avg).rawavg.f2(minind);
            
            % plot words or points
            if bPlotCond
                text(f1, f2, cnd, 'Color',colors.(cnd), 'FontSize',14);
            else
                plot(f1, f2, '.', 'Color',colors.(cnd), 'MarkerSize',15);
                hold on;
                text(medf1, medf2, cnd, 'FontSize',16, 'HorizontalAlignment','center', 'VerticalAlignment','bottom')
            end
            hold on;
            % plot median
            plot(medf1, medf2, 'o', 'Color',colors.(cnd), 'MarkerSize',2);
            plot(medindf1, medindf2, 'o', 'Color',[.6 .6 .6], 'MarkerSize',8);
            
            if any(strcmp(startConds,cnd))
                vowLog = strcmp(startConds,cnd);
                for v2 = 1:length(endConds{vowLog})
                    vow2 = endConds{vowLog}{v2};
                    medf1vow2 = fmtdata.(frq).(vow2).(avg).med.f1;
                    medf2vow2 = fmtdata.(frq).(vow2).(avg).med.f2;
                    plot([medf1 medf1vow2], [medf2 medf2vow2], 'Color',colors.(cnd), 'LineWidth',1.5);
                end
            end
        end
        title(sprintf('Vowel production space (%s), %s',avg,name));
        xlabel(sprintf('F1 (%s)',frq));
        ylabel(sprintf('F2 (%s)',frq));
    end
    makeFig4Screen;
end

