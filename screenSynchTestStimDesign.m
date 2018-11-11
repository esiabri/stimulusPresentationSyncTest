% Clear the workspace and the screen
sca;
close all;
clearvars;

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Get the screen numbers. This gives us a number for each of the screens
% attached to our computer.
screens = Screen('Screens');

% To draw we select the maximum of these numbers. So in a situation where we
% have two screens attached to our monitor we will draw to the external
% screen.
screenNumber = max(screens);%

% Define black and white (white will be 1 and black 0). This is because
% in general luminace values are defined between 0 and 1 with 255 steps in
% between. All values in Psychtoolbox are defined between 0 and 1
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);

% Do a simply calculation to calculate the luminance value for grey. This
% will be half the luminace values for white
grey = white / 2;

% Open an on screen window using PsychImaging and color it grey.
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, white);

% Measure the vertical refresh rate of the monitor
ifi = Screen('GetFlipInterval', window);

% Retreive the maximum priority number
topPriorityLevel = MaxPriority(window);
Priority(topPriorityLevel);

% Length of time and number of frames we will use for each drawing test
recordingDurSec = 10;

waitframes = 5;

numStim = 20;%round(numSecs / ifi);

% Numer of frames to wait when specifying good timing. Note: the use of
% wait frames is to show a generalisable coding. For example, by using
% waitframes = 2 one would flip on every other frame. See the PTB
% documentation for details. In what follows we flip every frame.


%--------------------------------------------------------------------------
% NOTE: The aim in the following is to demonstrate how one might setup code
% to present a stimulus that changes on each frame. One would not for
% instance present a uniform screen of a fixed colour using this approach.
% The only reason I do this here to to make the code as simple as possible,
% and to avoid a screen which flickers a different colour every, say,
% 1/60th of a second. Virtually all the remianing demos show a stimulus
% which changes on each frame, so I want to show an approach which will
% generalise to the rest of the demos. Therefore, one would clearly not
% write a script in this form for an experiment; it is to demonstrate
% principles.
%
% Specifically,
%
% vbl + (waitframes - 0.5) * ifi
%
% is the same as
%
% vbl + 0.5 * ifi
%
% As here waitframes is set to 1 (i.e. (1 - 0.5) == 0.5)
%
% For discussion see PTB forum thread 20178 for discussion.
%
%--------------------------------------------------------------------------

stimIDSession = daq.createSession('ni');
stimTagSession = daq.createSession('ni');
recStartStopSession = daq.createSession('ni');

%sessions with different number of digital channels don't work! why? So we
%define three sessions in three ports each with 8 channels: stimIDSession
%which delivers the stimulus ID to the Intan (port 2/line0:7). stimTagSession contanis two
%channels (port0/line0:1) that toggle before and after Scrren('Flip',...).
%recStartStopSession contains a channel (port1/line1) to send the start/stop recording
%trigger to the Intan. Port 0 is dedicated to the tag signals, since it is
%the only port which could be accompanied by an analog channel in a same
%session.

stimTagSession.addDigitalChannel('Dev1','port0/line0:7','OutputOnly');
tagsDefaultValue = [1,1,0,0,0,0,0,0];
beforeStimOnFlip = [0,1,0,0,0,0,0,0];
afterStimOnFlip = [0,0,0,0,0,0,0,0];
afterStimOffFlip = [1,1,0,0,0,0,0,0];

stimTagSession.outputSingleScan(tagsDefaultValue);

recStartStopSession.addDigitalChannel('Dev1','port1/line0:7','OutputOnly');
recStartTrigger = [0,1,0,0,0,0,0,0];
recStopTrigger = [0,0,0,0,0,0,0,0];

recStartStopSession.outputSingleScan(recStopTrigger);


% toggeling the digital tag before recording since it behaves wieredly
% during the first toggles!
for loop=1:3
    stimTagSession.outputSingleScan(afterStimOffFlip);
    pause(1);
    stimTagSession.outputSingleScan(tagsDefaultValue);
end



vblStimAll = zeros(numStim,1);
stimTime = zeros(numStim,1);
BeamposStimAll = zeros(numStim,1);
MissedStimAll = zeros(numStim,1);
FlipTimestampStimAll = zeros(numStim,1);

timeBeforeDigitalTagBeforeStimFlipAll = zeros(numStim,1);
timeAfterDigitalTagBeforeStimFlipAll = zeros(numStim,1);

timeBeforeDigitalTagAfterStimFlipAll = zeros(numStim,1);
timeAfterDigitalTagAfterStimFlipAll = zeros(numStim,1);


vblStimEndAll = zeros(numStim,1);
stimEndTime = zeros(numStim,1);
BeamposStimEndAll = zeros(numStim,1);
MissedStimEndAll = zeros(numStim,1);
FlipTimestampStimEndAll = zeros(numStim,1);

timeBeforeDigitalTagAfterStimEndFlipAll = zeros(numStim,1);
timeAfterDigitalTagAfterStimEndFlipAll = zeros(numStim,1);

% toggling the screen before the recording since the Screen behavios
% wieredly during the first Flips: It didn't work!
% for loop = 1:3
%     Screen('FillRect', window, white);
%     [vblStim StimulusOnsetTime FlipTimestampStim MissedStim BeamposStim] = Screen('Flip', window);
%     
%     Screen('FillRect', window, black);
%     [vblStim StimulusOnsetTime FlipTimestampStim MissedStim BeamposStim] = Screen('Flip', window, vblStim + (waitframes - 0.5) * ifi);
% end

% White is the default value under the photodiode
Screen('FillRect', window, white);
Screen('Flip', window);

pause(2); %Wait for the black screen before dtrating the recording 

recStartStopSession.outputSingleScan(recStartTrigger); %Start the recording

for stim = 1:numStim

        
    pause(rand); %random pause (0-1 sec) between two successive stimuli
    
    timeBeforeDigitalTagBeforeStimFlip = GetSecs;
    stimTagSession.outputSingleScan(beforeStimOnFlip);
    timeAfterDigitalTagBeforeStimFlip = GetSecs;
    
    Screen('FillRect', window, black);
    [vblStim StimulusOnsetTime FlipTimestampStim MissedStim BeamposStim] = Screen('Flip', window); %Stimulus Onset which could happen anytime, (no reference point for the design here)

    timeBeforeDigitalTagAfterStimFlip = GetSecs;
    stimTagSession.outputSingleScan(afterStimOnFlip);
    timeAfterDigitalTagAfterStimFlip = GetSecs;

    Screen('FillRect', window, white);
    [vblStimEnd PostStimulusOnsetTime FlipTimestampStimEnd MissedStimEnd BeamposStimEnd] = Screen('Flip', window, vblStim + (waitframes - 0.5) * ifi); %Stimulus End by sending black signal to the photodiode

    timeBeforeDigitalTagAfterStimEndFlip = GetSecs;
    stimTagSession.outputSingleScan(afterStimOffFlip);
    timeAfterDigitalTagAfterStimEndFlip = GetSecs;
        
    
    vblStimAll(stim) = vblStim;
    stimTime(stim) = StimulusOnsetTime;
    BeamposStimAll(stim) = BeamposStim;
    MissedStimAll(stim) = MissedStim;
    FlipTimestampStimAll(stim) = FlipTimestampStim;
    
    timeBeforeDigitalTagBeforeStimFlipAll(stim) = timeBeforeDigitalTagBeforeStimFlip;
    timeAfterDigitalTagBeforeStimFlipAll(stim) = timeAfterDigitalTagBeforeStimFlip;
    
    timeBeforeDigitalTagAfterStimFlipAll(stim) = timeBeforeDigitalTagAfterStimFlip;
    timeAfterDigitalTagAfterStimFlipAll(stim) = timeAfterDigitalTagAfterStimFlip;
    
    
    vblStimEndAll(stim) = vblStimEnd;
    stimEndTime(stim) = PostStimulusOnsetTime;
    BeamposStimEndAll(stim) = BeamposStimEnd;
    MissedStimEndAll(stim) = MissedStimEnd;
    FlipTimestampStimEndAll(stim) = FlipTimestampStimEnd;
    
    timeBeforeDigitalTagAfterStimEndFlipAll(stim) = timeBeforeDigitalTagAfterStimEndFlip;
    timeAfterDigitalTagAfterStimEndFlipAll(stim) = timeAfterDigitalTagAfterStimEndFlip;
    

end



recStartStopSession.outputSingleScan(recStopTrigger); % reset the triggers and stop the recording

WaitSecs(5);
sca;

estimatedTagDelayStimStart = stimTime - timeAfterDigitalTagBeforeStimFlipAll;