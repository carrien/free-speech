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
instruct.moveintro={'During the task' '' 'stay still and minimize your head and jaw movement' };
instruct.restintro={'You will be given rest time when finish each session.' '' 'Press the space bar to continue.'};
instruct.starttxt_speaking={'Get ready to SPEAK.' '' 'Press the space bar to start.' 'Stay still.' };
instruct.starttxt_listening={'Get ready to LISTEN.' '' 'Press the space bar to start.' 'Stay still.' };
instruct.resttxt={'Rest time' '' 'Press the space bar to continue when ready.'};
end
