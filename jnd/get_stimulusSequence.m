function [stimSeq, answerPos] = get_stimulusSequence(stimuli, taskType)
% Function to give you back a stimulus presentation order, given a vector of stimuli (n = 2) and a task type
% 
% Inputs: 
%       stimuli:                a vector of 2 stimuli. Can be cell or double. 
%           --- NOTE: for AX tasks, the correct answer should be in FIRST position. I.e. if you are asking "which one is
%           longer?" and you have two durations, 150 ms and 300 ms, you should provide the stimuli as [300 150]. For the
%           other two supported task types, it does not matter (same/oddball tasks). 
%
%       taskType:               a string indicating what kind of perceptual task is being used. Options: 
%           --- AX: Participant hears two stimuli, and indicates which stimulus satisfies the question being asked. E.g.
%           "which sound was longer?" "which sound was higher?" Works best for tasks that aren't within-category
%
%           --- AXB: Participant hears three stimuli. The middle stimulus is the same as either 1 or 3. The participant
%           responds to the question, "Which token was the middle token most like, 1 or 3?" Works well for linguistic
%           questions where participants may be comparing within category. 
% 
%           --- AAXA: Participant hears four stimuli. Stimuli 1 and 4 are the same. Either stimulus 2 or 3 is the oddball,
%           and the remaining stimulus is the same as 1 and 4. This is similar to AXB, but psychologically a slightly
%           different task. 
% 
% Outputs: 
% 
%       stimSeq:                The sequence of stimuli. Will be length 2, 3, 4 depending on taskType
% 
%       answer:                 The position of the correct answer in the sequence. Returns based on task: 
%           --- AX: Options 1, 2 (1 is the correct answer, or 2 is the correct answer) 
%           --- AXB: Options 1, 3 (like A/1, or like B/3)
%           --- AAXA: Options 2, 3 (2 is oddball, or 3 is oddball) 
%           --- AAXA_fixedEndPoint similar to AAXA, but the endpoint base
%           token always appear in 1/4 position added by HSC 2023-10-26
% 
% Initiated RPK 2022-06-10, adapted from Gorilla tasks in timitate

dbstop if error


if nargin < 2 || isempty(taskType), taskType = 'AX'; end

%% Set up stimulus sequence variable

nPresentations = length(taskType); 
if strcmp(taskType,'AAXA_fixedEndPoint') %% to get the correct length for other types of AAXA task
   nPresentations = 4;
end

if isnumeric(stimuli)
    stimSeq = zeros(1, nPresentations); 
else
    stimSeq = repmat({}, 1, nPresentations); 
end




%% Make stimulus sequence/get answer

rng('shuffle'); % Random seed

switch taskType
    case 'AX'
        answerPos = round(rand); % This gets a 0 or 1
        
        if answerPos 
            % If 1, then put correct answer into X position 
            stimSeq(2) = stimuli(1); 
            stimSeq(1) = stimuli(2); 
        else 
            % If 0, then put correct answer into A position 
            stimSeq(1) = stimuli(1); 
            stimSeq(2) = stimuli(2); 
        end
        answerPos = answerPos + 1; % Transforms from 0 indexing into Matlab indexing 
        
    case 'AXB'        
        randAB = round(rand); % Get 0 or 1 to randomize which stimulus gets put into A and B positions        
        if randAB
            stimSeq(3) = stimuli(1); 
            stimSeq(1) = stimuli(2); 
        else
            stimSeq(1) = stimuli(1); 
            stimSeq(3) = stimuli(2); 
        end
        
        sameas = round(rand); % Get 0 or 1 to determine if the middle stimulus is the same as A or B
        if sameas
            answerPos = 3; 
        else
            answerPos = 1; 
        end
        stimSeq(2) = stimSeq(answerPos);         
        
    case 'AAXA'        
        rand14 = round(rand); % Determine which stimulus goes into the 1/4 position 
        if rand14
            stim14 = stimuli(2); 
            oddStim = stimuli(1); 
        else
            stim14 = stimuli(1); 
            oddStim = stimuli(2); 
        end
        oddball = round(rand); % Get 0 or 1 to determine which position has the oddball token 
        if oddball
            stimSeq([1 2 4]) = stim14; 
            stimSeq(3) = oddStim; 
        else
            stimSeq([1 3 4]) = stim14; 
            stimSeq(2) = oddStim; 
        end
        answerPos = oddball + 2; % Transforms to 2/3 vs. 0/1

    case 'AAXA_fixedEndPoint'   % the base token always goes into the 1/4 position 
        
        stim14 = stimuli(2);
        oddStim = stimuli(1);

        oddball = round(rand); % Get 0 or 1 to determine which position has the oddball token 
        if oddball
            stimSeq([1 2 4]) = stim14; 
            stimSeq(3) = oddStim; 
        else
            stimSeq([1 3 4]) = stim14; 
            stimSeq(2) = oddStim; 
        end
        answerPos = oddball + 2; % Transforms to 2/3 vs. 0/1                
        
        
end


end