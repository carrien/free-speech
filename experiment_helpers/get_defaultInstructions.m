function [instruct] = get_defaultInstructions()
%GET_DEFAULTINSTRUCTIONS  Return default experiment instructions

instruct.introtxt = {'Read each word out loud as it appears.' '' 'Press the space bar to continue when ready.'};
instruct.introtxtlisten = {'Listen to a recording of the presented word.' '' 'Press the space bar to continue when ready.'};
instruct.readytxt = 'Get ready to SPEAK.';
instruct.readylisten = 'Get ready to LISTEN';
instruct.breaktxt = 'Time for a break!\n\n%d of %d trials done.\n\n\n\nPress the space bar to continue.';
instruct.thankstxt = 'Thank you!\n\n\n\nPlease wait.';
instruct.waittxt = 'Please wait.';
instruct.txtparams.Color = 'white';
instruct.txtparams.FontSize = 45;
instruct.txtparams.HorizontalAlignment = 'Center';
instruct.moveintro={'When you are speaking or listening, remember to' '' 'stay as still as possible ' '' 'and minimize your head and jaw movement.'};
instruct.restintro={'You will be given' '' 'short or long breaks throughout the experiment.'};% 
instruct.speaking={'Get ready to SPEAK.' '' 'Stay still' '' 'keep your eyes open and look at the screen .' };
instruct.listening={'Get ready to LISTEN.' '' 'Stay still' '' 'keep your eyes open and look at the screen.'};
instruct.checktxt_speak={'Ready to SPEAK?'};
instruct.checktxt_listen={'Ready to LISTEN?'};
% instruct.headcorr={'Time for head position correction.' '' 'stay still' 'This section will start within 1 min.'};
% instruct.starttxt={'Start.'};
% instruct.resttxt={'Rest time' '' 'Press the space bar to continue when ready.'};
end
