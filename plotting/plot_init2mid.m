function [h] = plot_init2mid(data2plot,p)
%PLOT_INIT2MID  Plot initial to midpoint data with options for normalizing. 
%
%   PLOT_INIT2MID reads in DATA2PLOT structure from the PLOT_CENTERING 
%   wrapper (or from a specific structure provided) and plots the data it 
%   contains with respect to the median at both the beginning (first50ms) 
%   and middle (mid50p) of each trial. 
%                   
%                      DATA2PLOT: contents of a fdata_vowel or fdata_word
%                      .mat file
%                      P: structure of plotting parameters, eg. ntile,
%                      p.bNorm, conds2plot, etc. 
%
%NC 4/2020

%% Default parameters
%% Set missing arguments to defaults
if nargin < 1 || isempty(data2plot), ...
fprintf('Please provide a fmtdata structure to plot from');
return
end
if nargin < 2, p = []; end
pTemplate.xpos = 100;
pTemplate.ypos = 50;
pTemplate.width = 750;
pTemplate.height = 500;
pTemplate.pphColor = [.8 0 0];
pTemplate.cenColor = [0 .8 0];
pTemplate.LineStyle = '--';
pTemplate.Curvature = [1,1];
pTemplate.units = 'mels';
pTemplate.ntile = 5; 
pTemplate.bNorm = 1; 
p = set_missingFields(p,pTemplate);

%% plotting loop
%Make new figure h to house the subplots, this will be returned.
h = figure;

cnds = fieldnames(data2plot.(p.units));
for c = 1:length(cnds)    %Over each vowel/word specified
    plotpos = c*2 - 1;  %Each row in the figure will be a new word/vowel
    if ~isfield(data2plot.(p.units).(cnds{c}),'first50ms')
        continue % move to the next iteration if word/vowel doesn't exist
    end
    
    %% Compute plotting values
    % same conventions as original plot_centering script, generated at
    % every call to this function and not saved.
    
    %First and middle points
    first = data2plot.(p.units).(cnds{c}).first50ms;
    mid = data2plot.(p.units).(cnds{c}).mid50p;
    
    %Quantiles for defining center and periphery
    if p.ntile < 3
        ntiles = median(first.dist);
    else
        ntiles = quantile(first.dist,p.ntile-1);
    end
    cen = first.dist < ntiles(1); % or meddist
    pph = first.dist > ntiles(end);
    
    midd = setdiff(1:length(first.dist),union(cen,pph));
    fpph = find(pph);
    fcen = find(cen);
    
    % F1,F2 in initial time window (all trials)
    initf1 = first.rawavg.f1;
    initf1med = first.med.f1;
    initf1norm = initf1 - initf1med;
    initf2 = first.rawavg.f2;
    initf2med = first.med.f2;
    initf2norm = initf2 - initf2med;
    
    % F1,F2 in mid time window (all trials)
    midf1 = mid.rawavg.f1;
    midf1med = mid.med.f1;
    midf1norm = midf1 - midf1med;
    midf2 = mid.rawavg.f2;
    midf2med = mid.med.f2;
    midf2norm = midf2 - midf2med;
    
    % store init and final dists
    dists_init.(cnds{c}).pph = sqrt(initf1norm(pph).^2 + initf2norm(pph).^2); % per-trial distance to median (init)
    dists_mid.(cnds{c}).pph = sqrt(midf1norm(pph).^2 + midf2norm(pph).^2);    % per-trial distance to median (mid)
    dists_init.(cnds{c}).cen = sqrt(initf1norm(cen).^2 + initf2norm(cen).^2);
    dists_mid.(cnds{c}).cen = sqrt(midf1norm(cen).^2 + midf2norm(cen).^2);
    dists_init.(cnds{c}).midd = sqrt(initf1norm(midd).^2 + initf2norm(midd).^2);
    dists_mid.(cnds{c}).midd = sqrt(midf1norm(midd).^2 + midf2norm(midd).^2);
    
    % calc mean dist for plotting
    meandist_init.pph = nanmean(dists_init.(cnds{c}).pph); % average distance to median (init)
    meandist_mid.pph = nanmean(dists_mid.(cnds{c}).pph);   % average distance to median (mid)
    meandist_init.cen = nanmean(dists_init.(cnds{c}).cen);
    meandist_mid.cen = nanmean(dists_mid.(cnds{c}).cen);
    meandist_init.midd = nanmean(dists_init.(cnds{c}).midd);
    meandist_mid.midd = nanmean(dists_mid.(cnds{c}).midd);
    
    %% Periphery plot
    subplot(length(cnds),2,plotpos)
    if p.bNorm
        
        plot(0,0,'ko')
        hold on;
        
        % plot initial formants (open circles)
        plot(initf1norm(pph),initf2norm(pph),'o', 'Color',p.pphColor)
        rectangle('Position',[-meandist_init.pph,-meandist_init.pph,...
        meandist_init.pph*2,meandist_init.pph*2],'Curvature',...
        p.Curvature,'LineStyle',p.LineStyle)
        
        % plot mid formants (dots)
        plot(midf1norm(pph),midf2norm(pph),'k.')
        rectangle('Position',[-meandist_mid.pph,-meandist_mid.pph,...
        meandist_mid.pph*2,meandist_mid.pph*2],'Curvature',p.Curvature)
        
        % plot lines from initial to mid
        for i=1:length(fpph)
            plot([initf1norm(fpph(i)) midf1norm(fpph(i))], ...
                [initf2norm(fpph(i)) midf2norm(fpph(i))], '-', ...
                'Color',p.pphColor)
        end
        %X and Y labels
        %TODO: set with p?
        xText ='norm F1 (mels)';
        yText ='norm F2 (mels)';
        
    else
        
        % plot medians
        plot(initf1med,initf2med,'*','Color',p.pphColor)
        hold on;
        plot(midf1med,midf2med,'*','Color',p.pphColor)
        
        % plot initial formants (open circles)
        plot(initf1(pph),initf2(pph),'o','Color',p.pphColor)
        rectangle('Position',[initf1med-meandist_init.pph,...
        initf2med-meandist_init.pph,meandist_init.pph*2,...
        meandist_init.pph*2],'Curvature',p.Curvature,'LineStyle',...
        p.LineStyle,'EdgeColor',p.pphColor)
        
        % plot mid formants (dots)
        plot(midf1(pph),midf2(pph),'.','Color',p.pphColor)
        rectangle('Position',[midf1med-meandist_mid.pph,...
        midf2med-meandist_mid.pph,meandist_mid.pph*2,...
        meandist_mid.pph*2],'Curvature',p.Curvature,'EdgeColor',p.pphColor)
        
        % plot lines from initial to mid
        for i=1:length(fpph)
            plot([initf1(fpph(i)) midf1(fpph(i))],...
            [initf2(fpph(i)) midf2(fpph(i))], '-','Color',p.pphColor)
        end
        %X and Y labels
        xText='F1 (mels)';
        yText='F2 (mels)';
    end
    
    %Add title and x/y labels
    title(sprintf('periphery %s',cnds{c}))
    xlabel(xText)
    ylabel(yText)
    box off
    axis square
    if p.bNorm
        axmax = max(abs(axis));
        axis([-axmax axmax -axmax axmax])
    end
    ax = axis;
    
    %% Center Plot
    subplot(length(cnds),2,plotpos+1) %Second position of the current row
    if p.bNorm
        
        plot(0,0,'ko')
        hold on;
        
        % plot initial formants (open circles)
        plot(initf1norm(cen),initf2norm(cen),'o', 'Color',p.cenColor)
        rectangle('Position',[-meandist_init.cen,-meandist_init.cen,...
        meandist_init.cen*2,meandist_init.cen*2],'Curvature',...
        p.Curvature,'LineStyle',p.LineStyle)
        
        % plot mid formants (dots)
        plot(midf1norm(cen),midf2norm(cen),'k.')
        rectangle('Position',[-meandist_mid.cen,-meandist_mid.cen,...
        meandist_mid.cen*2,meandist_mid.cen*2],'Curvature',p.Curvature)
        
        % plot lines from initial to mid
        for i=1:length(fcen)
            plot([initf1norm(fcen(i)) midf1norm(fcen(i))], ...
                [initf2norm(fcen(i)) midf2norm(fcen(i))], '-',...
                'Color',p.cenColor)
        end
        
        %TODO: only needs to be done in periphery? Unless we wanted to set
        %up some way to plot ONLY center or ONLY periphery in the current
        %set up
        xText ='norm F1 (mels)';
        yText ='norm F2 (mels)';
    
    else
        
        % plot medians
        plot(initf1med,initf2med,'*','Color',p.cenColor)
        hold on;
        plot(midf1med,midf2med,'*','Color',p.cenColor)
        
        % plot initial formants (open circles)
        plot(initf1(cen),initf2(cen),'o','Color',p.cenColor)
        rectangle('Position',[initf1med-meandist_init.cen,...
        initf2med-meandist_init.cen,meandist_init.cen*2,...
        meandist_init.cen*2],'Curvature',p.Curvature,'LineStyle',...
        p.LineStyle,'EdgeColor',p.cenColor)
        
        % plot mid formants (dots)
        plot(midf1(cen),midf2(cen),'.','Color',p.cenColor)
        rectangle('Position',[midf1med-meandist_mid.cen,...
        midf2med-meandist_mid.cen,meandist_mid.cen*2,meandist_mid.cen*2],...
        'Curvature',p.Curvature,'EdgeColor',p.cenColor)
       
        % plot lines from initial to mid
        for i=1:length(fcen)
            plot([initf1(fcen(i)) midf1(fcen(i))],...
                [initf2(fcen(i)) midf2(fcen(i))], '-','Color',p.cenColor)
        end
        
        %TODO: see bottom of center + p.bNorm true code
        xText='F1 (mels)';
        yText='F2 (mels)';
    end
    
    %Add labels and adjust axis for center plot
    title(sprintf('center %s',cnds{c}))
    xlabel(xText)
    ylabel(yText)
    box off
    axis square
    axis(ax);
    
end %End word/vowel loop

set(gcf,'Position',[p.xpos p.ypos p.width p.height],'Name',...
            sprintf('init2mid subject-%d (%s) normalized: True',...
            p.subject, p.condtype))
end %End function