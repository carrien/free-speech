function [fs,tstep] = get_fs_from_taxis(taxis)
%GET_FS_FROM_TAXIS  Computes fs and step size from a time axis.

if iscell(taxis)
    tdiffs = [];
    for c = 1:length(taxis)
        tdiffs = [tdiffs; diff(taxis{c})];
    end
else
    tdiffs = diff(taxis);
end

if all(tdiffs==tdiffs(1))
    tstep = tdiffs(1);
else
    terror = tdiffs - tdiffs(1);
    maxterror = max(abs(terror));
    tstep = mean(tdiffs);
    if maxterror > 0.00001
        warning('Not all time steps are the same size (max error = %d). Returning mean time step (%d).',maxterror,tstep)
    end
end

fs = 1/tstep;

end

