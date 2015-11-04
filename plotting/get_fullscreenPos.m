function [pos] = get_fullscreenPos()
%GET_BIGFIGPOS  Get dimensions of figure to fill the screen.

screen_pts = get(0,'ScreenSize');
pos = [screen_pts(1)+50 screen_pts(2)+35 screen_pts(3)-100 screen_pts(4)-110];

end