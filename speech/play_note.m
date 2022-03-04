function [ ] = play_note(notenames,octave,dur,fs,bRamp,bPlot,logscale)
%PLAY_NOTE  Play a sine wave with a given note's pitch.
%   PLAY_NOTE(NOTENAME,OCTAVE,DUR,FS,BRAMP) plays a sine wave tone with
%   frequency determined by NOTENAME and OCTAVE and duration DUR seconds at
%   sampling rate FS. BRAMP determines whether to ramp the tone on and off.

notelist = {'C' 'C#' 'D' 'D#' 'E' 'F' 'F#' 'G' 'G#' 'A' 'A#' 'B'};
indA = find(strcmp(notelist,'A'));

if nargin < 1 || isempty(notenames), notenames = notelist; end
if nargin < 2 || isempty(octave), octave = 5; end
if nargin < 3 || isempty(dur), dur = 1; end
if nargin < 4 || isempty(fs), fs = 44100; end
if nargin < 5 || isempty(bRamp), bRamp = 0; end
if nargin < 6 || isempty(bPlot), bPlot = 1; end
if nargin < 7 || isempty(logscale), logscale = 'Bark'; end

% match notes and octaves
if ischar(notenames)
    notenames = {notenames};
end
if length(notenames)~=length(octave)
    if length(notenames) == 1
        notenames = repmat(notenames,1,length(octave));
    elseif length(octave) == 1
        octave = repmat(octave,1,length(notenames));
    else
        warning('Note list and octave list are not the same length.');
    end
end

nNotes = length(notenames);

% set up plot
if bPlot
    h = figure;
    hax(1) = subplot(2,2,1);
    hax(1).XLim = [.5 nNotes+.5];
    ylabel('frequency (Hz)')
    hax(2) = subplot(2,2,2);
    ylabel('frequency difference (Hz)')
    hax(3) = subplot(2,2,3);
    hax(3).XLim = [.5 nNotes+.5];    
    ylabel(sprintf('frequency (%s)',logscale))    
    hax(4) = subplot(2,2,4);
    ylabel(sprintf('frequency difference (%s)',logscale))
end

% get notes
f = zeros(1,nNotes);
flog = zeros(1,nNotes);
for n = 1:nNotes
    notename = notenames{n};
    oct = octave(n);
    
    switch notename % convert to sharp notation
        case 'Bb'
            notename = 'A#';
        case 'Db'
            notename = 'C#';
        case 'Eb'
            notename = 'D#';
        case 'Gb'
            notename = 'F#';
        case 'Ab'
            notename = 'G#';
    end
    
    % get frequency
    indX = find(strcmp(notelist,notename));
    A = 440*2^(oct-4);
    f(n) = A*2^((indX-indA)/12);
    switch lower(logscale)
        case 'mels'
            flog(n) = hz2mels(f(n));
        case 'bark'
            flog(n) = hz2bark(f(n));
    end
    
    % get sine wave
    y = get_sine(f(n),[],[],dur,fs);
    if bRamp
        t = 1/fs:1/fs:dur;
        env = sin(pi*t/t(length(t)));
        y = y .* env;
    end
    
    % play note
    sound(y,fs);
    fprintf('Now playing %s%d (%0.2f Hz, %0.2f mels, %0.2f Bark)\n',notename,oct,f(n),hz2mels(f(n)),hz2bark(f(n)));
    pause(dur);
    
    % plot
    if bPlot
        % lin
        axes(hax(1));
        hold on;
        plot(n,f(n),'o')
        % log
        axes(hax(3));
        hold on;
        plot(n,flog(n),'o')
    end
    
end

axes(hax(1));
plot(f,'k--');
axes(hax(2));
plot(1.5:nNotes-.5,diff(f),'o')
hax(2).XLim = [.5 nNotes+.5];

axes(hax(3));
plot(flog,'k--')
axes(hax(4));
plot(1.5:nNotes-.5,diff(flog),'o')
hax(4).XLim = [.5 nNotes+.5];
