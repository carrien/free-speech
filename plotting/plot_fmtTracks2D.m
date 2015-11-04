function [] = plot_fmtTracks2D(exptName,snum,plotfile)
%PLOT_FMTTRACKS2D  Plot mean formant traces in 2D formant space.
%   Plots raw formant traces -- baseline and shifted conditions -- in mel
%   space for a single subject.  PLOTFILE is, e.g., fmtTraces_default.mat.

pos = get_fullscreenPos;
ellipseon = 0;

linecolors = {[0 0 0] [1 0 0] [0.4 0.4 0.4]};
sdcolors = {[0.655 0.655 0.655] [1 .8 .3] [.4 .8 1]};
% colors = [.8 0 0; 1 .6 0; .95 .85 0; .55 .85 0; .2 .6 .8; .7 .4 .9; ...
%     .65 0 0; .85 .45 0; .8 .7 0; .4 .7 0; .05 .45 .55; .55 .25 .75];

% subject data
dataPath = getAcoustSubjPath(exptName,snum);
load(fullfile(dataPath,plotfile)) % e.g. fmtTraces_default.mat
subjInfo = get_subjInfo(exptName,snum); % or load expt
shifts = subjInfo.shifts.mels;
%sdir = ['C:\PROJECTS\carrien_orig\ConstShift\DATA\PS' num2str(snum) '\prod'];
%plotTokens(sdir,'vowels','hz')

conds = fieldnames(rawf1);
tstep = .004;
alltime = 0:tstep:1;
stop = sum(hasquart); m = 64;
%time = 0:.004:.60;

% equalize lengths for F1 and F2
for i=1:length(conds)
    if length(meanf1.(conds{i})) ~= length(meanf2.(conds{i}))
        meanf1.(conds{i}) = meanf1.(conds{i})(1:min(length(meanf1.(conds{i})),length(meanf2.(conds{i}))));
        meanf2.(conds{i}) = meanf2.(conds{i})(1:min(length(meanf1.(conds{i})),length(meanf2.(conds{i}))));
    end
    if size(rawf1.(conds{i}),1) ~= size(rawf2.(conds{i}),1)
        rawf1.(conds{i}) = rawf1.(conds{i})(1:min(size(rawf1.(conds{i}),1),size(rawf2.(conds{i}),1)),:);
        rawf2.(conds{i}) = rawf2.(conds{i})(1:min(size(rawf1.(conds{i}),1),size(rawf2.(conds{i}),1)),:);
    end
    %cmap{i} = [linecolors{i}(1):(1-linecolors{i}(1))/(m-1):1 ; linecolors{i}(2):(1-linecolors{i}(2))/(m-1):1 ; linecolors{i}(3):(1-linecolors{i}(3))/(m-1):1]';
end

figure;
axes('Position',[0.12 0.13 .8 .8],'Visible','off');
%plot(hz2mels(Dmean1(1:stop)),hz2mels(Dmean2(1:stop)),':','LineWidth', 2, 'Color', 'k')
for i=1:length(conds)
    %    plot(F1{i}-Fstd1{i},F2{i}-Fstd2{i},'LineWidth', 1, 'Color', colors(i+2,:))
    %    plot(F1{i}+Fstd1{i},F2{i}+Fstd2{i},'LineWidth', 1, 'Color', colors(i+2,:))
    plot(meanf1.(conds{i})(1:stop),meanf2.(conds{i})(1:stop),'LineWidth', 4, 'Color', linecolors{i}); hold on;
    if ellipseon
        for t = 2:size(rawf1.(conds{i}),1)
            [ell,a,ang] = FitEllipse(rawf1.(conds{i})(t,:),rawf2.(conds{1})(t,:),.8);
            plot(ell(:,1),ell(:,2),'Color',cmap{i}(ceil(t/3),:));
            %plot(rawf1.(conds{i})(t,:),rawf2.(conds{i})(t,:),'.','Color',cmap{i}(ceil(i/3),:))
            plot(meanf1.(conds{i})(t),meanf2.(conds{i})(t),'o','Color',sdcolors{i},'MarkerSize',3)
        end
    end
end

% plot "beads"
for i=1:length(conds)
    plot(meanf1.(conds{i})(1:stop),meanf2.(conds{i})(1:stop),'LineWidth', 4, 'Color', linecolors{i}); hold on;
    plot(meanf1.(conds{i})(1:4:stop),meanf2.(conds{i})(1:4:stop),'o','Color', linecolors{i},'MarkerFaceColor', linecolors{i}); hold on;
end

% set where the shift vectors will be plotted
%setpoint = [925 1310]; sclfact = .15; %s47
setpoint = [890 1435]; sclfact = .05; %s56 
%setpoint = [730 1407]; %s21 


% plot shifts from set point
for i=1:2
%    plot([setpoint(1) setpoint(1)+shifts{i}(1)*sclfact],[setpoint(2) setpoint(2)+shifts{i}(2)*sclfact],'Color',linecolors{i+1})
    arrow([setpoint(1) setpoint(2)],[setpoint(1)+shifts{i}(1)*sclfact setpoint(2)+shifts{i}(2)*sclfact],'EdgeColor',linecolors{i+1},'FaceColor',linecolors{i+1})
end
legend('base','within','across', 'Location','SouthWest'); legend boxoff;


%x1 = xlabel('F1 (mels)', 'VerticalAlignment', 'middle', 'FontWeight', 'bold');
%x1pos = get(x1,'Position');
%set(x1,'Position',[x1pos(1) x1pos(2)-5 x1pos(3)]);
%ylabel('F2 (mels)', 'FontWeight', 'bold', 'FontSize', 9);
%title('Compensation in vowel space, subject 12')
%set(gca, 'TickLength', [0.0 0.0]);
set(gca, 'FontSize',16,'xtick',[800:50:900],'ytick',[1275:25:1325],'xticklabel',[],'yticklabel',[],'LineWidth',3);

% for s21
%set(gca, 'FontSize',12,'xtick',[625:25:750],'ytick',[1375:25:1425],'LineWidth',3); axis([610 750 1370 1415])

% for s47
%set(gca, 'FontSize',12,'ytick',[1300:50:1400],'LineWidth',3); axis([700 950 1275 1425])

% for s56
%set(gca, 'FontSize',12,'xtick',[825:25:900],'ytick',[1375:25:1450],'LineWidth',3); axis([820 900 1360 1450])

xlabel('F1 (mels)')
ylabel('F2 (mels)')

%% fade out traces with time
% figure;
% Z = 1:stop; m = 64;
% axes('Position',[0.12 0.13 .8 .8]);
% %plot(hz2mels(Dmean1(1:stop)),hz2mels(Dmean2(1:stop)),':','LineWidth', 2, 'Color', 'k')
% for i=1:length(conds)
%     %    plot(F1{i}-Fstd1{i},F2{i}-Fstd2{i},'LineWidth', 1, 'Color', colors(i+2,:))
%     %    plot(F1{i}+Fstd1{i},F2{i}+Fstd2{i},'LineWidth', 1, 'Color', colors(i+2,:))
%     cl(i) = cline(meanf1.(conds{i})(Z),meanf2.(conds{i})(Z),Z); hold on;
%     %    plot([setpoint(1) setpoint(1)+Shifts{i}(1)],[setpoint(2) setpoint(2)+Shifts{i}(2)])
%     cmap{i} = [linecolors{i}(1):(1-linecolors{i}(1))/(m-1):1 ; linecolors{i}(2):(1-linecolors{i}(2))/(m-1):1 ; linecolors{i}(3):(1-linecolors{i}(3))/(m-1):1]';
% end
% 
% set(cl,'FaceColor','interp','EdgeColor','interp')
% colormap([cmap{1};cmap{2};cmap{3}])
% m = m/2;
% zmin = min(Z(:));
% zmax = max(Z(:));
% cdx = min(m,round((m-1)*(Z-zmin)/(zmax-zmin))+1);
% cdy = cdx+m;
% cdz = cdy+m;
% set(cl(1),'CData',[cdx NaN])
% set(cl(2),'CData',[cdy NaN])
% set(cl(3),'CData',[cdz NaN])
% caxis([min(cdx(:)) max(cdz(:))])
% set(cl,'LineWidth',5)

%legend('base','within','across', 'Location','SouthWest'); legend boxoff;
