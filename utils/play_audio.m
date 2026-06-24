function play_audio(y, fs)
% Code written by Shanqing Cai. Originally from github.com/shanqing-cai/commonmcode

y = y - mean(y);

vmax = max(abs(y));
y = y / vmax * 0.98;

player = audioplayer(y, fs);
player.play();

dur = length(y) / fs;
pause(dur);

end
