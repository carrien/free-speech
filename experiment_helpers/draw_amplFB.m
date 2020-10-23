function [h] = draw_amplFB(h_fig,currAmp,params)

get_figinds_audapter;
figure(h_fig(stim)); % make stimulus window current

width = 0.1;
height = 0.4;
x = 0.9;
ymid = 0.5; % middle of bar
y = ymid-(height/2);

if ~currAmp
    %% initialize feedback bar
    h(1) = rectangle('Position',[x y width height],'EdgeColor','w','LineWidth',4);
    h(2) = rectangle('Position',[x ymid width 0.0001],'FaceColor','w','EdgeColor','w','LineWidth',0.1);
else
    %% update feedback bar
    
    % convert currAmp to volume bar values (0.25 to 0.75)
    minPerc = 0.25;
    maxPerc = 1 - minPerc;
    tolerance = .075;
    
    if currAmp >= params.max_ampl
        dispAmp = ceil(maxPerc*10)/10;
        dispColor = 'r';
    elseif currAmp <= params.min_ampl
        dispAmp = floor(minPerc*10)/10;
        dispColor = 'r';
    else
        dispAmp = (currAmp-params.min_ampl)/(params.max_ampl-params.min_ampl) * (maxPerc-minPerc) + minPerc;
        if dispAmp > maxPerc - tolerance || dispAmp < minPerc + tolerance
            dispColor = 'y';
        else
            dispColor = 'g';
        end
    end
        
    % plot bar
    h(3) = rectangle('Position',[x+0.005 y+0.01 width-0.01 height*dispAmp],'FaceColor',dispColor,'EdgeColor',dispColor,'LineWidth',0.3);
end

CloneFig(h_fig(stim),h_fig(dup))
