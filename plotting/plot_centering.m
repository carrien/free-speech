function [] = plot_centering(dataPaths,condtype,condinds,plotinds,ntile,bSave)
%PLOT_CENTERING  Plot vowel centering in center and peripheral trials.
%   PLOT_CENTERING reads formants from a subject's fdata file and plots
%   them with respect to the median at both the beginning (first50ms) and
%   middle (mid50p) of each trial. PLOTINDS determines which type of view
%   is plotted: 1 for normalized init->mid, 2 for non-normalized init->mid,
%   and/or 3 for periph->median.
%
%CN 8/2013

if nargin < 1 || isempty(dataPaths), dataPaths = cd; end
if ischar(dataPaths), dataPaths = {dataPaths}; end
if nargin < 2 || isempty(condtype), condtype = 'vowel'; end
if nargin < 3 || isempty(condinds), condinds = [1 2 3]; end
if nargin < 4 || isempty(plotinds), plotinds = 1; end
if nargin < 5 || isempty(ntile), ntile = 5; end
if nargin < 6 || isempty(bSave), bSave = 0; end

%% set plotting params
xpos = 265;
ypos = 355;
width = 820;
height = 299;
pphColor = [.8 0 0];
cenColor = [0 .8 0];

if any(plotinds == 4)
    for c = 1:length(condinds)
        h(c) = figure;
    end
    meandist_init_all{c} = [];
    meandist_mid_all{c} = [];
    overlayColor = [.5 .5 .5];
end

%% plot data
for s=1:length(dataPaths)
    load(fullfile(dataPaths{s},sprintf('fdata_%s.mat',condtype)));
    conds = fieldnames(fmtdata.mels);
    
    for c = 1:length(condinds)
        cnd = conds{condinds(c)}; % current condition name
        
        if ~isfield(fmtdata.mels.(cnd),'first50ms')
            continue % skip if vowel data doesn't exist
        end
        
        first = fmtdata.mels.(cnd).first50ms;
        mid = fmtdata.mels.(cnd).mid50p;
        
        if ntile < 3
            ntiles = median(first.dist);
        else
            ntiles = quantile(first.dist,ntile-1);
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
        dists_init.(cnd).pph = sqrt(initf1norm(pph).^2 + initf2norm(pph).^2); % per-trial distance to median (init)
        dists_mid.(cnd).pph = sqrt(midf1norm(pph).^2 + midf2norm(pph).^2);    % per-trial distance to median (mid)
        dists_init.(cnd).cen = sqrt(initf1norm(cen).^2 + initf2norm(cen).^2);
        dists_mid.(cnd).cen = sqrt(midf1norm(cen).^2 + midf2norm(cen).^2);
        dists_init.(cnd).midd = sqrt(initf1norm(midd).^2 + initf2norm(midd).^2);
        dists_mid.(cnd).midd = sqrt(midf1norm(midd).^2 + midf2norm(midd).^2);

        % calc mean dist for plotting
        meandist_init.pph = nanmean(dists_init.(cnd).pph); % average distance to median (init)
        meandist_mid.pph = nanmean(dists_mid.(cnd).pph);   % average distance to median (mid)
        meandist_init.cen = nanmean(dists_init.(cnd).cen);
        meandist_mid.cen = nanmean(dists_mid.(cnd).cen);
        meandist_init.midd = nanmean(dists_init.(cnd).midd);
        meandist_mid.midd = nanmean(dists_mid.(cnd).midd);

        %% init to mid, normalized
        if any(plotinds == 1)
            figure;

            %%% periphery
            subplot(1,2,1)
            plot(0,0,'ko')
            hold on;
            % plot initial formants (open circles)
            plot(initf1norm(pph),initf2norm(pph),'o', 'Color',pphColor)
            rectangle('Position',[-meandist_init.pph,-meandist_init.pph,meandist_init.pph*2,meandist_init.pph*2],'Curvature',[1,1],'LineStyle','--')
            % plot mid formants (dots)
            plot(midf1norm(pph),midf2norm(pph),'k.')
            rectangle('Position',[-meandist_mid.pph,-meandist_mid.pph,meandist_mid.pph*2,meandist_mid.pph*2],'Curvature',[1,1])
            % plot lines from initial to mid
            for i=1:length(fpph)
                plot([initf1norm(fpph(i)) midf1norm(fpph(i))], ...
                    [initf2norm(fpph(i)) midf2norm(fpph(i))], '-', 'Color',pphColor)
            end
            xlabel('norm F1 (mels)')
            ylabel('norm F2 (mels)')
            box off
            axis square
            axmax = max(abs(axis));
            axis([-axmax axmax -axmax axmax])
            ax = axis;
            
            %%% center
            subplot(1,2,2)
            plot(0,0,'ko')
            hold on;
            % plot initial formants (open circles)
            plot(initf1norm(cen),initf2norm(cen),'o', 'Color',cenColor)
            rectangle('Position',[-meandist_init.cen,-meandist_init.cen,meandist_init.cen*2,meandist_init.cen*2],'Curvature',[1,1],'LineStyle','--')
            % plot mid formants (dots)
            plot(midf1norm(cen),midf2norm(cen),'k.')
            rectangle('Position',[-meandist_mid.cen,-meandist_mid.cen,meandist_mid.cen*2,meandist_mid.cen*2],'Curvature',[1,1])
            % plot lines from initial to mid
            for i=1:length(fcen)
                plot([initf1norm(fcen(i)) midf1norm(fcen(i))], ...
                    [initf2norm(fcen(i)) midf2norm(fcen(i))], '-', 'Color',cenColor)
            end
            xlabel('norm F1 (mels)')
            ylabel('norm F2 (mels)')
            box off
            axis square
            axis(ax);
            
            set(gcf,'Position',[xpos ypos width height],'Name',sprintf('subjind %d %s %d (%s)',s,condtype,condinds(c),cnd))
        end
        
        %% init to mid, non-normalized
        if any(plotinds == 2)
            figure;
            
            %%% periphery
            subplot(1,2,1)
            % plot medians
            plot(initf1med,initf2med,'*','Color',pphColor)
            hold on;
            plot(midf1med,midf2med,'*','Color',pphColor)
            % plot initial formants (open circles)
            plot(initf1(pph),initf2(pph),'o','Color',pphColor)
            rectangle('Position',[initf1med-meandist_init.pph,initf2med-meandist_init.pph,meandist_init.pph*2,meandist_init.pph*2],'Curvature',[1,1],'LineStyle','--','EdgeColor',pphColor)
            % plot mid formants (dots)
            plot(midf1(pph),midf2(pph),'.','Color',pphColor)
            rectangle('Position',[midf1med-meandist_mid.pph,midf2med-meandist_mid.pph,meandist_mid.pph*2,meandist_mid.pph*2],'Curvature',[1,1],'EdgeColor',pphColor)
            % plot lines from initial to mid
            for i=1:length(fpph)
                plot([initf1(fpph(i)) midf1(fpph(i))],[initf2(fpph(i)) midf2(fpph(i))], '-','Color',pphColor)
            end
            xlabel('F1 (mels)')
            ylabel('F2 (mels)')
            box off
            axis square
            ax = axis;
            
            %%% center
            subplot(1,2,2)
            % plot medians
            plot(initf1med,initf2med,'*','Color',cenColor)
            hold on;
            plot(midf1med,midf2med,'*','Color',cenColor)
            % plot initial formants (open circles)
            plot(initf1(cen),initf2(cen),'o','Color',cenColor)
            rectangle('Position',[initf1med-meandist_init.cen,initf2med-meandist_init.cen,meandist_init.cen*2,meandist_init.cen*2],'Curvature',[1,1],'LineStyle','--','EdgeColor',cenColor)
            % plot mid formants (dots)
            plot(midf1(cen),midf2(cen),'.','Color',cenColor)
            rectangle('Position',[midf1med-meandist_mid.cen,midf2med-meandist_mid.cen,meandist_mid.cen*2,meandist_mid.cen*2],'Curvature',[1,1],'EdgeColor',cenColor)
            % plot lines from initial to mid
            for i=1:length(fcen)
                plot([initf1(fcen(i)) midf1(fcen(i))],[initf2(fcen(i)) midf2(fcen(i))], '-','Color',cenColor)
            end
            xlabel('F1 (mels)')
            ylabel('F2 (mels)')
            box off
            axis square
            axis(ax);
            
            set(gcf,'Position',[xpos ypos width height],'Name',sprintf('subjind %d %s %d (%s)',s,condtype,condinds(c),cnd))
        end
        
        %% periph to median
        if any(plotinds == 3)
            figure;

            %%% init
            subplot(1,2,1)
            % plot median
            plot(initf1med,initf2med,'ko')
            hold on;
            % plot initial formants
            plot(initf1,initf2,'k.')
            plot(initf1(cen),initf2(cen),'.', 'Color',cenColor)
            plot(initf1(pph),initf2(pph),'.', 'Color',pphColor)
            % plot vector to median
            for i=1:length(fpph)
                plot([initf1(fpph(i)) initf1med], ...
                    [initf2(fpph(i)) initf2med], '--', 'Color',pphColor)
            end
            xlabel('F1 (mels)')
            ylabel('F2 (mels)')
            box off
            
            %%% mid
            subplot(1,2,2)
            % plot median
            plot(mid.med.f1,mid.med.f2,'ko')
            hold on;
            % plot mid formants
            plot(midf1,midf2,'k.')
            plot(midf1(cen),midf2(cen),'.', 'Color',cenColor)
            plot(midf1(pph),midf2(pph),'.', 'Color',pphColor)
            % plot vector to median
            for i=1:length(fpph)
                plot([midf1(fpph(i)) mid.med.f1], ...
                    [midf2(fpph(i)) mid.med.f2], '--', 'Color',pphColor)
            end
            xlabel('F1 (mels)')
            ylabel('F2 (mels)')
            box off

            set(gcf,'Position',[xpos ypos width height])
        end
        
        %% init to mid, normalized, all subj overlaid
        if any(plotinds == 4)
            figure(h(c))
            % plot initial formants (open circles)
            plot(initf1norm(pph),initf2norm(pph),'o', 'Color',pphColor)
            hold on;
            % plot mid formants (dots)
            %plot(midf1norm(pph),midf2norm(pph),'k.')
            % plot lines from initial to mid
            for i=1:length(fpph)
                plot([initf1norm(fpph(i)) midf1norm(fpph(i))], ...
                    [initf2norm(fpph(i)) midf2norm(fpph(i))], 'Color',overlayColor)
            end
            
            % store per-subject per-condition average distance
            meandist_init_all{c} = [meandist_init_all{c} meandist_init.pph];
            meandist_mid_all{c} = [meandist_mid_all{c} meandist_mid.pph];
        end
        
    end
    
    %% save centering info per subject
    centfilename = fullfile(dataPaths{s},sprintf('centering_cvp_%dtile.mat',ntile));
    if bSave
        bSave = savecheck(centfilename);
    end
    if bSave
        % centering values
        centering_mean.(cnd).pph = meandist_init.pph - meandist_mid.pph;
        centering_mean.(cnd).cen = meandist_init.cen - meandist_mid.cen;
        centering_mean.(cnd).midd = meandist_init.midd - meandist_mid.midd;
        centering.(cnd).pph = dists_init.(cnd).pph - dists_mid.(cnd).pph;
        centering.(cnd).cen = dists_init.(cnd).cen - dists_mid.(cnd).cen;
        centering.(cnd).midd = dists_init.(cnd).midd - dists_mid.(cnd).midd;
        % formant movement in euclidean space
        euclmove = sqrt((midf1-initf1).^2 + (midf2-initf2).^2);
        eucl.(cnd).pph = euclmove(pph);
        eucl.(cnd).cen = euclmove(cen);
        eucl.(cnd).midd = euclmove(midd);

        save(centfilename,'centering','centering_mean','dists_init','dists_mid','eucl');

        if exist('durdata','var')
            % store duration values (periph only)
            dur.(cnd).pph = durdata.s.(cnd)(pph);
            dur.(cnd).cen = durdata.s.(cnd)(cen);
            dur.(cnd).midd = durdata.s.(cnd)(midd);
            save(centfilename,'dur','-append');
        end

        fprintf('Saved %s\n',centfilename);
    end
    
end

%% overlay init to mid norm summary (circles) for all subjects
if any(plotinds == 4)
    maxax = 200;
    tick = -maxax:maxax/2:maxax;

    for c = 1:length(condinds)
        cnd = conds{condinds(c)};
        di = nanmean(meandist_init_all{c});
        dm = nanmean(meandist_mid_all{c});

        figure(h(c));
        plot(0,0,'ko')
        hold on;
        rectangle('Position',[-di,-di,di*2,di*2],'Curvature',[1,1],'LineStyle','--','LineWidth',2)
        rectangle('Position',[-dm,-dm,dm*2,dm*2],'Curvature',[1,1],'LineWidth',2)
        xlabel('norm F1 (mels)')
        ylabel('norm F2 (mels)')
        box off
        axis([-maxax maxax -maxax maxax]);
        axis square
        set(gca,'XTick',tick);
        set(gca,'YTick',tick);
        makeFig4Screen;

        set(gcf,'Name',sprintf('All-subject overlay, %s %d (%s)',condtype,condinds(c),cnd))
    end

end
