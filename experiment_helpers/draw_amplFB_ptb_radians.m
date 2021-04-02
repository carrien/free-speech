function [h] = draw_amplFB_ptb(win,currAmp,params)

% figure(h_fig); % make stimulus window current

% width = 0.1;
% height = 0.4;
% x = 0.9;
% ymid = 0.5; % middle of bar
% y = ymid-(height/2);

xCenter = 1560;
yCenter = 640;
radius = 200;
lineWidth = 10;

toX = xCenter + radius*abs(cos(105))
fromX = xCenter - radius*abs(cos(105))



anglesDeg = [255, 105, 75, 285, 255+360];
anglesRad = anglesDeg * (pi / 180);
xPosVector = cos(anglesRad) .* radius + xCenter;
yPosVector = sin(anglesRad) .* radius + yCenter;%ybarcenter;




if ~currAmp
    %% initialize feedback bar
    Screen('FramePoly', win, [1 1 1], [xPosVector; yPosVector]', lineWidth);
    Screen('DrawLine', win ,[1 1 1], fromX, yCenter, toX, yCenter, lineWidth);
    Screen('Flip', win);
    
%    rectangle('Position',[x ymid width 0.0001],'FaceColor','w','EdgeColor','w','LineWidth',0.1);
else
    %% update feedback bar

    % center of filled rectangle
    
    fullbarheight = abs(sin(105)).* radius;
    
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
    
    fillheight = (fullbarheight * dispAmp); % twice the height for the rectangle...
    fillwidth = (radius*abs(cos(105))) - 1
    fillradius = sqrt((fillwidth^2) + ((fillheight)^2));
    theta = acosd(fillheight/fillradius);
    fillycenter = yCenter + (((fullbarheight/2) * (1-dispAmp)) + (0.5*fillheight))
    fillxcenter = xCenter;
    
   % fillheight =    fillradius .* sin(theta)
    
    fillAngles = [theta 270+(270-theta) theta-180  270+(270-theta)-180 theta+360]
    fillRad = fillAngles * (pi/180);
    fillxPosVector = cos(fillRad) .* fillradius + fillxcenter;
    fillyPosVector = sin(fillRad) .* fillradius + fillycenter;%ybarcenter;

    
    % plot bar
    h(3) = rectangle('Position',[x+0.005 y+0.01 width-0.01 height*dispAmp],'FaceColor',dispColor,'EdgeColor',dispColor,'LineWidth',0.3);
end

CloneFig(win,h_fig(dup))
