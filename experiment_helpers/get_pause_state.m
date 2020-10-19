function [bPaused] = get_pause_state(h,pausekey)

for i = 1:length(h)
    kkey{i} = get(h(i),'CurrentCharacter');
end
bPaused = any(strcmp(pausekey,kkey));

end
