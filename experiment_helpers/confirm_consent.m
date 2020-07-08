function [ConsentReady] = confirm_consent()

instruct = get_defaultInstructions;

txt2display_subj = sprintf('Did you sign a consent form? \n\n Hold down y for yes and n for no.');
txt2display_exptr = 'Did you have the participant sign a consent form?';


h_fig = setup_exptFigs;
get_figinds_audapter % names figs: stim = 1, ctrl = 2, dup = 3;
figure(h_fig(stim))
h_subjscrn = text(.5,.5,txt2display_subj,instruct.txtparams);
figure(h_fig(dup))
h_exptrcrn = text(.5,.5,txt2display_exptr,instruct.txtparams);
% 

sub_response = input('Wait for subject response.','s');
exptr_response = input('Did you remember to have the subject sign the consent form? y/n','s');

consentReady = {sub_response exptr_response};

% end
