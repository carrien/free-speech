function [rp] = get_trialOrder_noConsecSameShifts(condbank,shiftConds)
%GET_TRIALORDER_NOCONSECSHIFTS  Construct trial order to meet constraints.
%   GET_TRIALORDER_NOCONSECSHIFTS(CONDBANK,SHIFTINDS)

ntrials = length(condbank);
maxConsecNoShifts = 5;
restarts = 0; % counter for restarting
tic;

bTrialOrderOK = 0;
while ~bTrialOrderOK
    
    % reset vars
    condlist = condbank;
    trialinds = 1:ntrials;
    allConds = zeros(1,ntrials);
    rp = zeros(1,ntrials);
    lastShiftCond = 0;
    nConsecNoShifts = 0;
    
    % first trial: disallow shift
    b = 1;
    while b
        rind = randi(length(condlist));
        cond2try = condlist(rind);
        if ~any(shiftConds == cond2try)
            b = 0;
        end
    end
    allConds(1) = cond2try;
    rp(1) = rind;
    condlist(rind) = [];
    trialinds(rind) = [];
    
    % all other trials: no consecutive shifts
    for t = 2:ntrials
        
        % check whether next trial is impossible
        remainingConds = unique(condlist);
        bPrevTrialWasShift = any(shiftConds == allConds(t-1));
        bOnlyShifts = isempty(setdiff(remainingConds,shiftConds));
        if (bPrevTrialWasShift && bOnlyShifts) % if remaining conds are all shifts,
            restarts = restarts + 1;           % cannot complete list; start over
            if ~mod(restarts, 100)
                fprintf('%d ',restarts);
            end
            break;
        end
        
        % if not, continue
        b = 1;
        while b
            rind = randi(length(condlist));
            cond2try = condlist(rind);
            if bPrevTrialWasShift               % if previous trial was shift,
                if ~any(shiftConds == cond2try) % choose unshifted trial
                    b = 0;
                end
            elseif nConsecNoShifts > maxConsecNoShifts                % if too many unshifted,
                if any(setdiff(shiftConds,lastShiftCond) == cond2try) % choose shifted trial (but not lastShiftCond)
                    b = 0;
                end
            else                                % otherwise,
                if cond2try ~= lastShiftCond    % choose any trial except lastShiftCond 
                    b = 0;
                end
            end
        end
        
        % assign trial
        allConds(t) = cond2try;
        rp(t) = trialinds(rind);
        condlist(rind) = [];
        trialinds(rind) = [];
        
        % log last shift
        if any(shiftConds == cond2try)
            lastShiftCond = cond2try;
            nConsecNoShifts = 0;
        else
            nConsecNoShifts = nConsecNoShifts + 1;
        end

    end
    
    if allConds(end)
        fprintf('Randomized %d trials in %.2f seconds (%d attempts).\n',ntrials,toc,restarts);
        bTrialOrderOK = 1;
    end
    
end
