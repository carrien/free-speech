function [rp] = get_trialOrder_noConsecShifts(condbank,shiftConds)
%GET_TRIALORDER_NOCONSECSHIFTS  Construct trial order to meet constraints.
%   GET_TRIALORDER_NOCONSECSHIFTS(CONDBANK,SHIFTINDS)

ntrials = length(condbank);
restarts = 0; % counter for restarting
tic;

bTrialOrderOK = 0;
while ~bTrialOrderOK
    
    % reset vars
    condlist = condbank;
    trialinds = 1:ntrials;
    allConds = zeros(1,ntrials);
    rp = zeros(1,ntrials);
    
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
        if any(shiftConds == allConds(t-1))
            % if prev trial is a shift, check whether next trial is impossible
            remainingConds = unique(condlist);
            if isempty(setdiff(remainingConds,shiftConds)) % if remaining conds are all shifts,
                restarts = restarts + 1;                   % cannot complete list; start over
                break;
            end
            % if not, continue
            b = 1;
            while b
                rind = randi(length(condlist));
                cond2try = condlist(rind);
                if ~any(shiftConds == cond2try) % choose unshifted trial
                    b = 0;
                end
            end
            
        else
            % if prev trial is not a shift, add anything
            rind = randi(length(condlist));
            cond2try = condlist(rind);
        end
        
        allConds(t) = cond2try;
        rp(t) = trialinds(rind);
        condlist(rind) = [];
        trialinds(rind) = [];

    end
    
    if allConds(end)
        fprintf('Randomized %d trials in %.2f seconds (%d attempts).\n',ntrials,toc,restarts);
        bTrialOrderOK = 1;
    end
    
end
