function [] = draw_amplFB_ptb(win,currAmp,params)

lx = 1500;
uy = 450;
rx = 1600;
ly = 850;
bary = (uy + ly) /2;
lineWidth = 1;

if ~currAmp
    %% initialize feedback bar
    Screen('FrameRect',win, [255 255 255], ([lx uy rx ly]), lineWidth)
    Screen('DrawLine', win ,[255 255 255], lx, bary, rx, bary, lineWidth);    
%    rectangle('Position',[x ymid width 0.0001],'FaceColor','w','EdgeColor','w','LineWidth',0.1);
else
    %% update feedback bar
    
    % convert currAmp to volume bar values (0.25 to 0.75)
    minPerc = 0.25;
    maxPerc = 1 - minPerc;
    tolerance = .075;
    
    if currAmp >= params.max_ampl
        dispAmp = ceil(maxPerc*10)/10;
        dispColor = [1 0 0]; % red
    elseif currAmp <= params.min_ampl
        dispAmp = floor(minPerc*10)/10;
        dispColor = [1 0 0]; % red
    else
        dispAmp = (currAmp-params.min_ampl)/(params.max_ampl-params.min_ampl) * (maxPerc-minPerc) + minPerc;
        if dispAmp > maxPerc - tolerance || dispAmp < minPerc + tolerance
            dispColor = [1 1 0]; % yellow
        else
            dispColor = [0 1 0]; % green
        end
    end
    
    dispColor = dispColor*255;
    fullheight = ly-uy; % linguist's y-axis
    fillheight = dispAmp*fullheight;
    filluy = ly-fillheight
    Screen('FrameRect',win, [255 255 255], ([lx uy rx ly]), lineWidth)
    Screen('DrawLine', win ,[255 255 255], lx, bary, rx, bary, lineWidth);
    Screen('FillRect',win, dispColor, [lx+5 filluy rx-5 ly-5])    
end