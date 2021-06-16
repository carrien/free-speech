function [] = test_button
%%
load('data.mat')
load('expt.mat')
h_fig = setup_exptFigs(expt); 

for i = 1:10
    soundsc([data(i).signalIn], 48000); 
    pause(2)
    
end