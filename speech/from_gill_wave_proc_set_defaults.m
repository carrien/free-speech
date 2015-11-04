global event_params sigproc_params allaxinfo h_slider_preemph2 h_edit_preemph2 hf h_edit_ampl_thresh4voicing
warning('off','MATLAB:interp1:NaNinY'); %this turns off matlabs warnings about plotting NaNs, NOTE: it is turned on again when you close the figure.

%% Size of the entire figure
%display stuff change the values for width percent and height to change the
%percentage of the screen that the figure will take up. If want to use
%direct values, change positionfigure.
nummonitorpixels = get(0,'ScreenSize');
widthpercent = 0.8;
heightpercent = 0.8;
leftpercent = (1 - widthpercent) / 2;
bottompercent = (1 - heightpercent) / 2;

pixelleft = nummonitorpixels(1,3) * leftpercent;
pixelbottom = nummonitorpixels(1,4) * bottompercent;
pixelwidth = nummonitorpixels(1,3) * widthpercent;
pixelheight = nummonitorpixels(1,4) * heightpercent;

positionfigure = [pixelleft pixelbottom pixelwidth pixelheight]; % note that this goes into plot_params.figpos

%% Default values for each trial.
all_ms_framespecs = get_all_ms_framespecs();
numsubinfig = 5;

params.sigproc_params = struct('fs', 11025, ...
    'ms_framespec_gram', 'broadband', ...
    'ms_framespec_form', 'narrowband', ...
    'all_ms_framespecs', all_ms_framespecs, ...
    'nfft', 4096, ...
    'nlpc', 15, ...
    'nlpc_choices', (7:20), ...
    'nformants', 3, ...
    'preemph', 0.95, ...
    'preemph_range', [-2 3], ...
    'pitchlimits', [50 300], ...
    'yes_smooth_amplitude', 0, ... %do you want to smooth the amplitude signal? (takes a lot of time)
    'yes_autosetampl', 0, ... % do you want to automatically set the ampl for thresh value?
    'indices2regress', 442, ... % number of indices to be used in the regressions for autosetting the amplitude.
    'ampl_thresh4voicing', 0.0271, ... % manual setting of amplitude for thresh. MAKE SURE THAT YES_AUTOSETAMPL IS 0 FOR MANUAL SETTING!!!!! determines what areas are NaNs (not spoken areas)
    'wave_viewer_logshim', 1, ...   %makes 20*log10(0 + wave_viewer_logshim) = 0
    'yes_just_thresh',0, ... % used by set_edit_ampl_threshold to signify that we only are changing the threshold and don't need to recalculate stuff.
    'yes_create_hplayer', 1, ...
    'yes_gray', 1, ... % do you want the spectogram to be gray or blue with red marked as intensity. (also flipped upside down)
    'thresh_gray', 0, ... % for the spectogram of the formants.
    'max_gray', 1, ... % for the spectogram of the formants.
    'dummy_param','test');
params.plot_params    = struct('hzbounds4plot', [], ...
    'name', 'signal', ...
    'axfracts', [1,1/numsubinfig], ... %used in the heightening of windows
    'yax_fact', 0.05, ...  %used for setting the axlimits to make plots look better. (set_viewer_axlims)
    'ax_heighten_inc', 0.1, ... %percentage increase height when you press h
    'max_dist_fract2del_event', 0.03, ... %must be within 3% of ax_tlims of event marker to delete it
    'formant_colors', {{'b','r','g','k','c','m'}}, ... %colors for more formants than you'll ever use
    'tmarker_colors', {{'g-','y-','r-','k-','m-','c-'}}, ... %colors for the tmarkers {t_low,t_spec,t_hi,t_play,t_event,t_uev}
    'yes_new_key_verbose', 0, ... % do you want to see the key values and name when you press a key that is not set to do anything?
    'axborder_xl', 0.1, ...
    'axborder_xr', 0.05, ...
    'axborder_yl', 0.02, ...
    'axborder_yu', 0.075, ...
    'figborder_xl', 0.02, ...
    'figborder_xr', 0, ...
    'figborder_yl', 0.033, ...
    'figborder_yu', 0.05, ...
    'default_tmarker_width', 2, ... % width of the vertical tmarkers (includes all tmarkers, currently doesn't distinguish between different tmarkers such as event markers or user events).
    'default_formant_width', 3, ... % width of the horizontal formant track lines in gramax
    'formant_marker_width', 4, ... %width of the vertical formant lines in sliceax
    'tmarker_init_border', 0.05, ... %used to set the default locations of the higher and lower tmarkers (green and red line tmarkers) (0.05 means that they will be placed 0.05*range of axis to the right and left of the edges of the axis)
    'nsubplotsinfig', numsubinfig, ... %number of subplots to put in the figure; must equal sum(iordersubplots >= 1) and sum(axinfo4plotting)
    'axinfo4plotting', [1, 1, 1, 1, 1], ...          % [wave ampl pitch gram spec] binary indicating which axinfo to plot in the subplots. Length must match length of iordersubplots. enter 0 if don't want in fig
    'iordersubplots', [1, 4, 3, 2, 5], ...   % [wave ampl pitch gram slice] order of subplots. Higher number = lower in the figure; 1 = top of figure and will be hsubplot(1,1). enter 0 for indices not in fig
    'figpos',positionfigure); % default fig position. note that when we change the size of the figure, it saves it when the figure is closed so the next time we open the figure, it will be the same size.
params.event_params   = struct('event_names', {{'ee','aa'}}, ... %must be cell array
    'event_times', [0.5,1.5], ...
    'user_event_name_prefix','uev', ...
    'user_event_names', [], ... %must be cell array
    'user_event_times', [], ...
    'is_good_trial', 1, ...
    'nclicked', 0, ...
    'marker_captured', 0, ...
    'current_axes', 0, ...
    'cur_ax', 0, ...
    'fu', 'bar');

% this bit of code seems to make each subgoup in params into its own
% variable and then deletes params. (why do this?? why not save them as event_params, sigproc_params, and plot_params above??)
param_struct_names = fieldnames(params);
n_param_structs = length(param_struct_names);

for i_param_struct = 1:n_param_structs
    eval(sprintf('%s = params.%s;',param_struct_names{i_param_struct},param_struct_names{i_param_struct}));
end
clear params

if isempty(plot_params.hzbounds4plot)
    plot_params.hzbounds4plot = [0 sigproc_params.fs/2];
end

%% Plotting axis position and configuration (done to extend the size of the individual axis as hsubplot by default doesn't make the axis very big.
% This is for the placement of the subplots in the figure.

numsubplotsinfig = plot_params.nsubplotsinfig;

axborder_xl = plot_params.axborder_xl; 
axborder_xr = plot_params.axborder_xr;
axborder_yl = plot_params.axborder_yl;
axborder_yu = plot_params.axborder_yu;
figborder_xl = plot_params.figborder_xl; 
figborder_xr = plot_params.figborder_xr;
figborder_yl = plot_params.figborder_yl; 
figborder_yu = plot_params.figborder_yu;

axarea_xo = figborder_xl;
axarea_yo = figborder_yl;
axarea_xw = 1.0 - figborder_xl - figborder_xr;
axarea_yw = 1.0 - figborder_yl - figborder_yu;
figspace = (figborder_yl + figborder_yu)/3;

axfract_x = 1;
axfract_y = 1/numsubplotsinfig;

axtile_xo = axarea_xo;
axtile_xw = axarea_xw;
axtile_yw_acc = figspace;

axpos_xo  = axtile_xo + axborder_xl*axtile_xw;
axpos_xw2  = (1.0 - axborder_xl - axborder_xr)*axtile_xw;
extendgraphs = (1-axpos_xw2)/4.2 + axpos_xw2;
axpos_xw = extendgraphs;
axtile_yw = axfract_y*axarea_yw;
axpos_yw  = (1.0 - axborder_yl - axborder_yu)*axtile_yw;

subplotpositions = zeros(numsubplotsinfig,4);
for loop = 1:numsubplotsinfig
    axtile_yo = axarea_yo + axtile_yw_acc;
    axpos_yo  = axtile_yo + axborder_yl*axtile_yw;
    subplotpositions(loop,:) = [axpos_xo axpos_yo axpos_xw axpos_yw];
    axtile_yw_acc = axtile_yw_acc + axtile_yw;
end

plot_params.subplotpositions = subplotpositions;

%% Placement for uicontrol objects (mainly just for the bottom and height of the objects);
% This is for the placement of the uicontrol objects.

numuielementsinfig = 13;
numbuttons = 6;
numpanels = 7;
numrelatedpanels = 4;
numsmallpanels = 2;
numregularsizedpanels = 1;
regularsizedspaces = 10;
panelsizedspaces = 2;
uisizes = [1 1 1 1 1 1 1.4 .8 .8 1 1 1 1];
uispaces = [1 1 1 1 1 1 1 .5 1 .5 1 1];

if numrelatedpanels + numsmallpanels + numregularsizedpanels ~= numpanels
    disp('Error: numpanels is not divided into its sizes properly!!!!!')
end
if numbuttons + numpanels ~= numuielementsinfig
    disp('Error: numuielementsinfig is not divided into its subtypes properly');
end

spacebetweenplotandbutton = 0.0022;
buttonleft = 0.0092;
buttonbottomi = subplotpositions(1,2) - 0.05;
buttonwidth = 1 - axpos_xw - axborder_xr - buttonleft - spacebetweenplotandbutton;
%buttonheight = (1-numspaces*buttonbottom)/numtotalbuttons;

spaceforuielementsandintermittentspaces = 1 - 2*buttonbottomi;
spacebetweenbuttons = buttonbottomi/1.5;
spacebetweenpanels = spacebetweenbuttons/2;
spaceleftforuielements = spaceforuielementsandintermittentspaces - spacebetweenbuttons*regularsizedspaces - spacebetweenpanels*panelsizedspaces;

% 1 = 7x + 3x.    1/10 = x
xsumss = ((numrelatedpanels + numsmallpanels)) + (numbuttons + numregularsizedpanels);
xfactor = spaceleftforuielements / xsumss;
% if button, then use xfactor for height. otherwise, use xfactor / 2; need
% to modify buttonbottom and buttonheight.

buttonheight = zeros(1,numuielementsinfig);
buttonbottom = zeros(1,numuielementsinfig);

for loopz = 1:numuielementsinfig
    if uisizes(1,loopz) == 1
        buttonheight(1,loopz) = xfactor;
    else
        buttonheight(1,loopz) = xfactor * uisizes(1,loopz);
    end
    
    if loopz ~= 1
        prevloop = loopz - 1;
        if uispaces(1,prevloop) == 1
            buttonbottom(1,loopz) = buttonbottom(1,prevloop) + spacebetweenbuttons + buttonheight(1,prevloop);
        else
            buttonbottom(1,loopz) = buttonbottom(1,prevloop) + spacebetweenpanels + buttonheight(1,prevloop);
        end
    else
        buttonbottom(1,loopz) = buttonbottomi;
    end
end

plot_params.buttonleft = buttonleft;
plot_params.buttonbottom = buttonbottom;
plot_params.buttonwidth = buttonwidth;
plot_params.buttonheight = buttonheight;
plot_params.buttonbottomi = buttonbottomi;

%% Set default values for uicontrol textboxes, sliders, and pulldown menus
% This is used to set the default / previously set values in the uicontrol
% objects. 

n_framespecs = length(sigproc_params.all_ms_framespecs.name);
all_ms_framespecs = sigproc_params.all_ms_framespecs;
sigproc_params.framespec_choice_str{1,n_framespecs} = [];
for i_framespec = 1:n_framespecs
    sigproc_params.framespec_choice_str{i_framespec} = sprintf('%.0f/%.1fms, %s',all_ms_framespecs.ms_frame(i_framespec),all_ms_framespecs.ms_frame_advance(i_framespec),all_ms_framespecs.name{i_framespec});
end

nchoices = length(sigproc_params.nlpc_choices);
nlpc_choices = sigproc_params.nlpc_choices;
sigproc_params.nlpc_choice_strs{1,nchoices} = [];
for ichoice = 1:nchoices
    sigproc_params.nlpc_choice_strs{ichoice} = sprintf('%d',nlpc_choices(ichoice));
end

if ~ischar(sigproc_params.ms_framespec_gram)
    error('sorry: we only support char string ms_framespecs right now'); 
end
if ~ischar(sigproc_params.ms_framespec_form)
    error('sorry: we only support named ms_framespecs right now'); 
end

sigproc_params.initial_pulldown_value_gram = strmatch(sigproc_params.ms_framespec_gram,sigproc_params.all_ms_framespecs.name);
if isempty(sigproc_params.initial_pulldown_value_gram)
    sigproc_params.initial_pulldown_value_gram = 1;
end

sigproc_params.initial_pulldown_value_form = strmatch(sigproc_params.ms_framespec_form,sigproc_params.all_ms_framespecs.name);
if isempty(sigproc_params.initial_pulldown_value_form)
    sigproc_params.initial_pulldown_value_form = 1;
end

sigproc_params.initial_pulldown_value_nlpc = find(sigproc_params.nlpc_choices == sigproc_params.nlpc); 
if isempty(sigproc_params.initial_pulldown_value_nlpc)
    sigproc_params.initial_pulldown_value_nlpc = 1; 
end

disp('initial default values set');

%% Actually setting the values for the data that will be used in the plots. (signal processing)

