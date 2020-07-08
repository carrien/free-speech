function [rp] = get_trialOrder(condBank,shiftConds,constraints)
%GET_TRIALORDER  Construct trial order to meet given constraints.
%   GET_TRIALORDER(CONDBANK,SHIFTINDS,CONSTRAINTS)
%   %%% in progress

if nargin < 3, constraints = {'startNormal' 'no2same'}; end

ntrials = length(condBank);
trialinds = 1:ntrials;
bTrialOrderOK = 0;

while ~bTrialOrderOK
    
    allConds = zeros(1,ntrials);
    rp = zeros(1,ntrials);
    
    for t = 1:ntrials
        
        % first trial
        if t == 1 && any(strcmp(constraints,'startNormal'))
            startConds = setdiff(unique(condBank),shiftConds); % acceptible starting conditions
            b = 0;
            while ~b
                rind = randi(length(condBank));
                cond2try = condBank(rind);
                if any(cond2try == startConds)
                    b = 1;
                end
            end
            allConds(t) = cond2try;
            rp(t) = trialinds(rind);
            condBank(rind) = [];
            trialinds(rind) = [];
        
        % all other trials
        else
            
            % No two consecutive shifts of the same kind
            if any(strcmp(constraints,'no2same'))
                b = 0;
                % check to make sure next trial is possible
                remainingConds = unique(condBank);
                
                while ~b
                    rind = randi(length(condBank));
                    cond2try = condBank(rind);
                    if ~any(cond2try == shiftConds) || cond2try ~= allConds(t-1)
                        b = 1;
                    end
                end
                
            % No two consecutive shifts of any kind
            elseif any(strcmp(constraints,'no2shift'))
                b = 0;
                % check to make sure next trial is possible
                remainingConds = unique(condBank);

                while ~b
                    rind = randi(length(condBank));
                    cond2try = condBank(rind);
                    if ~any(cond2try == shiftConds) || ~any(allConds(t-1) == shiftConds)
                        b = 1;
                    end
                end
            end
            allConds(t) = cond2try;
            rp(t) = trialinds(rind);
            condBank(rind) = [];
            trialinds(rind) = [];
            
        end
        
    end
    
end
