function [] = draw_durFB_bar_ptb(win,vowel_dur,params)


lx = 1300;
uy = 750;
rx = 1700;
ly = 850; % linguist's y-axis
barx = (lx + rx) /2;
lineWidth = 1;



if ~vowel_dur
    %% initialize feedback bar
    Screen('FrameRect',win, [255 255 255], ([lx uy rx ly]), lineWidth)
    Screen('DrawLine', win ,[255 255 255], barx, uy, barx, ly, lineWidth);    
else
    %% update feedback bar
    
    % convert currAmp to volume bar values (0.25 to 0.75)
    minPerc = 0.25;
    maxPerc = 1 - minPerc;
    tolerance = .075;
    
    if vowel_dur >= params.max_dur
        dispDur = ceil(maxPerc*10)/10;
        dispColor = [1 0 0];
    elseif vowel_dur <= params.min_dur
        dispDur = floor(minPerc*10)/10;
        dispColor = [1 0 0];
    else
        dispDur = (vowel_dur-params.min_dur)/(params.max_dur-params.min_dur) * (maxPerc-minPerc) + minPerc;
        if dispDur > maxPerc - tolerance || dispDur < minPerc + tolerance
            dispColor = [1 1 0];
        else
            dispColor = [0 1 0];
        end
    end
    
    % plot bar
    dispColor = dispColor * 255;
    fullwidth = rx-lx;
    fillwidth = dispDur*fullwidth;
    fillrx = lx+fillwidth;
    Screen('FrameRect',win, [255 255 255], ([lx uy rx ly]), lineWidth);
    Screen('DrawLine', win ,[255 255 255], barx, uy, barx, ly, lineWidth);
    Screen('FillRect',win, dispColor, [lx+5 uy+5 fillrx ly-5]);
    
end

