function [varargout] = gen_gammaMetronome(saveAs, isis, frontPad, fs, tSavePlay, gammaParams)
% Function that generates a metronome using a predetermined gamma tone and a list of ISIs in seconds. ISI is generated from
% middle of gamma tone to middle of gamma tone (or start to start), not end of gamma tone 1 to start of gamma tone 2. 
% 
% Inputs: 
% 
%       saveAs                  The full path that you would like to save as, if you want to save (including filename). This
%                               is only used if you set tSavePlay to 'save', but defaults to metronome.wav in Robin's paced
%                               VOT task folder on the server. 
% 
%       isis                    A vector of ISIs you would like to use. Note: if you would like to create a UNIFORM metronome
%                               you should provide a uniform vector, or use gen_sinetoneTempos with the 'gamma' option for
%                               f0. This is specified in seconds. Defaults to a dummy train. 
%
%       frontPad                How long (in seconds) you would like silence in the vector before the first gammatone.
%                               Defaults to 0. 
%
%       fs                      The sampling rate of the sound you would like to create. Defaults to 24,000
% 
%       tSavePlay               A 'toggle' option for whether you would like to save the resulting sound or play it. Defaults
%                               to 'save'. RPK 08/17/2022 added option to 'output' to just get the vector to be used in the
%                               equipment check in cerebPacedVot
% 
%       gammaParams             A structure with the following fields to customize the gamma tone: 
%                                   - duration
%                                   - gamma
%                                   - frequency
%                                   - bandwidth
%                                   - initPhase
%                                   - addFactor
%                               See below for defaults. See
%                               https://www.fon.hum.uva.nl/praat/manual/Create_Sound_as_gammatone___.html for more info
% 
% Outputs:
% 
%       metronomeSound          A vector that produces the sound
% 
% Initiated RPK 2022-06-15
% 

dbstop if error

%% Default arguments
if nargin < 1 || isempty(saveAs), saveAs = fullfile(get_acoustLoadPath('cerebPacedVot'), 'stimuli', 'metronome.wav'); end
if nargin < 2 || isempty(isis), isis = [repmat(0.5, 1, 4) repmat(0.4, 1, 4) repmat(0.3, 1, 4)]; end
if nargin < 3 || isempty(fs), fs = 24000; end
if nargin < 4 || isempty(frontPad), frontPad = 0; end
if nargin < 5 || isempty(tSavePlay), tSavePlay = 'save'; end

% Properties of gammatone
if nargin < 6 || isempty(gammaParams)
    gammaParams.duration = 0.015; 
    gammaParams.gamma = 4; 
    gammaParams.frequency = 1000; 
    gammaParams.bandwidth = 150; 
    gammaParams.initPhase = 0; 
    gammaParams.addFactor = 0; 
else
    addedFields = {}; 
    if ~isfield(gammaParams, 'duration') || isempty(gammaParams.duration), gammaParams.duration = 0.015; addedFields = [addedFields, 'duration']; end
    if ~isfield(gammaParams, 'gamma') || isempty(gammaParams.gamma), gammaParams.gamma = 4; addedFields = [addedFields, 'gamma']; end 
    if ~isfield(gammaParams, 'frequency') || isempty(gammaParams.frequency), gammaParams.frequency = 1000; addedFields = [addedFields, 'frequency']; end
    if ~isfield(gammaParams, 'bandwidth') || isempty(gammaParams.bandwidth), gammaParams.bandwidth = 150; addedFields = [addedFields, 'bandwidth']; end
    if ~isfield(gammaParams, 'initPhase') || isempty(gammaParams.initPhase), gammaParams.initPhase = 0; addedFields = [addedFields, 'initPhase']; end
    if ~isfield(gammaParams, 'addFactor') || isempty(gammaParams.addFactor), gammaParams.addFactor = 0; addedFields = [addedFields, 'addFactor']; end
    if numel(addedFields) == 1
        warning('Added %s parameter as default.', addedFields{1}); 
    elseif numel(addedFields) > 1
        warning('Added following parameters as default: %s', [sprintf('%s, ', addedFields{1:end-1}) sprintf('%s', addedFields{end})]); 
    end    
end

gp = gammaParams; 
clear gammaParams


%% Create gammatone metronome sound
taxis = 0:(1/fs):gp.duration;
gammaTone = taxis.^(gp.gamma - 1) .* exp(-2*pi*gp.bandwidth*taxis) .* cos(2*pi*gp.frequency*taxis + gp.addFactor*log(taxis) + gp.initPhase); 
peakGamma = max(abs(gammaTone)); 
gammaTone = gammaTone / peakGamma; 

% Initial padding
frontZeros = []; 
if frontPad, frontZeros = zeros(1, frontPad*fs); end


%% String blips together
adjustedIsis = isis - gp.duration;             % ISIs, accounting for the duration of the metronome impulse
fprintf('Generating metronome... ')

metronome = [frontZeros gammaTone]; 
for i = 1:length(adjustedIsis)     
    adjustedIsi = adjustedIsis(i); 
    isiZeros = zeros(1, ceil(adjustedIsi*fs)); 
    metronome = [metronome isiZeros gammaTone]; 
end

%% Toggle saving/playing

switch tSavePlay
    case 'save'
        fprintf('Saving... ')
        audiowrite(saveAs, metronome, fs);   
        fprintf('Done.')
        
    case 'play'
        soundsc(metronome, fs); 

    case 'output'
        varargout{1} = metronome; 
end
fprintf('\n'); 

end% EOF
