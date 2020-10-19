function [h] = draw_durFB_bar(h_fig,vowel_dur,params)

get_figinds_audapter;
figure(h_fig(stim)); % make stimulus window current

width = 0.4;
height = 0.1;
x = 0.2;
xmid = x + (width/2); % middle of bar
y = 0.1; 

if ~vowel_dur
    %% initialize feedback bar
    h(1) = rectangle('Position',[x y width height],'EdgeColor','w','LineWidth',4);
    h(2) = rectangle('Position',[xmid y 0.0001 height],'FaceColor','w','EdgeColor','w','LineWidth',0.1);
else
    %% update feedback bar
    
    % convert currAmp to volume bar values (0.25 to 0.75)
    minPerc = 0.25;
    maxPerc = 1 - minPerc;
    tolerance = .075;
    
    if vowel_dur >= params.max_dur
        dispDur = ceil(maxPerc*10)/10;
        dispColor = 'r';
    elseif vowel_dur <= params.min_dur
        dispDur = floor(minPerc*10)/10;
        dispColor = 'r';
    else
        dispDur = (vowel_dur-params.min_dur)/(params.max_dur-params.min_dur) * (maxPerc-minPerc) + minPerc;
        if dispDur > maxPerc - tolerance || dispDur < minPerc + tolerance
            dispColor = 'r';
        else
            dispColor = 'g';
        end
    end
        
    % plot bar
    h(3) = rectangle('Position',[x+0.005 y+0.01 width*dispDur height-0.02],'FaceColor',dispColor,'EdgeColor',dispColor,'LineWidth',0.3);
end

CloneFig(h_fig(stim),h_fig(dup))
