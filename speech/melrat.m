function [pertval] = melrat(hertz,step)
% Gives ratio (pertval) in hertz for a given step up or down
% on the mel scale.

mels = hz2mels(hertz);  % convert to mels
mels = mels + step;     % step up a constant value
hz = mels2hz(mels);     % convert back

pertval = hz/hertz;     % compare new/old hertz values
                        % = pertval