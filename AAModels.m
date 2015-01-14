
function AAModels(varargin)
prompt={'SUBJECT ID'};
defAns={'4444'};

answer=inputdlg(prompt,'Please input subject info',1,defAns);

ID=str2double(answer{1});
% COND = str2double(answer{2});
% SESS = str2double(answer{3});
% prac = str2double(answer{4});


rng(ID); %Seed random number generator with subject ID
d = clock;

KEYS = struct;
KEYS.rt = KbName('SPACE');
% KEYS.left = KbName('c');
% KEYS.right = KbName('m');
KEYS.up = KbName('c');
KEYS.down = KbName('m');
KEYS.ONE= KbName('1!');
KEYS.TWO= KbName('2@');
KEYS.THREE= KbName('3#');
KEYS.FOUR= KbName('4$');
KEYS.all = KEYS.ONE:KEYS.FOUR;


COLORS = struct;
COLORS.BLACK = [0 0 0];
COLORS.WHITE = [255 255 255];
COLORS.RED = [255 0 0];
COLORS.BLUE = [0 0 255];
COLORS.GREEN = [0 255 0];
COLORS.YELLOW = [255 255 0];
COLORS.rect = COLORS.GREEN;

STIM = struct;
STIM.blocks = 1;
STIM.trials = 40;
STIM.totes = STIM.blocks*STIM.trials;
STIM.trialdur = 4;
STIM.framedelay = 1;
STIM.jit = [1 1.5 2];
STIM.minside = 200;
STIM.maxside = 200;


%% Find & load in pics
[mdir,~,~] = fileparts(which('AAModels.m'));
imgdir = [mdir filesep 'Pics'];
cd(imgdir);

 PICS.in.T = dir('*_T*');
 PICS.in.H = dir('*_H*');

%Check if pictures are present. If not, throw error.
%Could be updated to search computer to look for pics...
if isempty(PICS.in.T) || isempty(PICS.in.H) %|| isempty(PICS.in.neut)
    error('Could not find pics. Please ensure pictures are found in a folder names IMAGES within the folder containing the .m task file.');
end


%% Fill in rest of pertinent info

%Half of total trials will be Thin (1); half will be Healthy (0)
pictype = [ones(STIM.totes/2,1); zeros(STIM.totes/2,1)];

%Based on how many pics present & how many needed, bring in random ordering
%of pic (# assingment based on sorting in PICS.in.T or .H)
picdiff = (STIM.totes/2) - length(PICS.in.T);
if picdiff > 0;
    piclist_T = [randperm(length(PICS.in.T))'; randi(length(PICS.in.T),picdiff,1)];
elseif picdiff <= 0;
    piclist_T = randperm(length(PICS.in.T),(STIM.totes/2))';
end


picdiff = (STIM.totes/2) - length(PICS.in.H);
if picdiff > 0;
    piclist_H = [randperm(length(PICS.in.H))'; randi(length(PICS.in.H),picdiff,1)];
elseif picdiff <= 0;
    piclist_H = randperm(length(PICS.in.H),(STIM.totes/2))';
end

piclist = [piclist_T; piclist_H];

%mash together pictype & piclist
piclist = [pictype piclist];

%shuffle that list...
piclist = piclist(randperm(length(piclist)),:);

%assign names to numbers
picnames = cell(STIM.totes,1);
for tt = 1:STIM.totes;
    if piclist(tt,1) == 1;
        picnames{tt,1}= PICS.in.T(piclist(tt,2)).name;
    else
        picnames{tt,1}= PICS.in.H(piclist(tt,2)).name;
    end
end

jitter = BalanceTrials(STIM.totes,1,[STIM.jit]);

AAM = struct;

for trl = 1:length(piclist);
    
    AAM.data(trl).trial = trl;
    AAM.data(trl).pictype = piclist(trl,1);
    AAM.data(trl).picname = picnames(trl,1);
    AAM.data(trl).jitter = jitter(trl);
    AAM.data(trl).fix_onset = NaN;
    AAM.data(trl).pic_onset = NaN;
    AAM.data(trl).rect_onset = NaN;
    AAM.data(trl).rt = NaN;
    AAM.data(trl).aa = NaN;
    
end

    AAM.info.ID = ID;
    AAM.info.date = sprintf('%s %2.0f:%02.0f',date,d(4),d(5));
    
commandwindow;

%%
%change this to 0 to fill whole screen
DEBUG=0;

%set up the screen and dimensions

%list all the screens, then just pick the last one in the list (if you have
%only 1 monitor, then it just chooses that one)
Screen('Preference', 'SkipSyncTests', 1);

screenNumber=max(Screen('Screens'));

if DEBUG==1;
    %create a rect for the screen
    winRect=[0 0 640 480];
    %establish the center points
    XCENTER=320;
    YCENTER=240;
else
    %change screen resolution
%     Screen('Resolution',0,1024,768,[],32);
    
    %this gives the x and y dimensions of our screen, in pixels.
    [swidth, sheight] = Screen('WindowSize', screenNumber);
    XCENTER=fix(swidth/2);
    YCENTER=fix(sheight/2);
    %when you leave winRect blank, it just fills the whole screen
    winRect=[];
end

%open a window on that monitor. 32 refers to 32 bit color depth (millions of
%colors), winRect will either be a 1024x768 box, or the whole screen. The
%function returns a window "w", and a rect that represents the whole
%screen. 
[w, wRect]=Screen('OpenWindow', screenNumber, 0,winRect,32,2);

%%
%you can set the font sizes and styles here
Screen('TextFont', w, 'Arial');
%Screen('TextStyle', w, 1);
Screen('TextSize',w,30);

KbName('UnifyKeyNames');
%% image position matters.
STIM.framerect = [XCENTER-300; YCENTER-400; XCENTER+300; YCENTER+400];
STIM.imgrect = STIM.framerect + [30; 30; -30; -30];


%% Do that intro stuff.
DrawFormattedText(w,'You are about to see a series of photos.  When a photo appears on the screen, your job is to decide if you like or dislike it.  Soon after the photo is shown, a green border will appear around the photo.  This indicates that it is time to respond.\n\nPress any key to continue.','center','center',COLORS.WHITE,60,[],[],1.5);
Screen('Flip',w);
KbWait([],2);

DrawFormattedText(w,'When you see the green border, push photos you dislike away from you and pull photos you like towards you using the joystick.  Respond to every photo as quickly as possible.\n\nPress any key to begin the task.','center','center',COLORS.WHITE,60,[],[],1.5);
Screen('Flip',w);
KbWait([],2);

%% Do that trial stuff.

for block = 1:STIM.blocks
    for trial = 1:STIM.trials;
        side = 0;
        %before starting trial, load image...
        trialpic = imread(char(AAM.data(trial).picname));
        tpic = Screen('MakeTexture',w,trialpic);
        
        %Jittered Crosshair
        DrawFormattedText(w,'+','center','center',COLORS.WHITE);
        Screen('Flip',w);
        AAM.data(trial).fix_onset = GetSecs();
        WaitSecs(AAM.data(trial).jitter);
        
        %Present image.
        Screen('DrawTexture',w,tpic,[],STIM.imgrect);
        Screen('Flip',w);
        AAM.data(trial).pic_onset = GetSecs();
        WaitSecs(STIM.framedelay);
        
        %Present image with frame.
        Screen('FillRect',w,COLORS.GREEN,STIM.framerect);
        Screen('DrawTexture',w,tpic,[],STIM.imgrect);
        RT_start = Screen('Flip',w);
        AAM.data(trial).rect_onset = GetSecs();
        
        %Do the zoomy thing
        telap = 0;
        while telap <= (STIM.trialdur - STIM.framedelay);
            telap = GetSecs() - RT_start;
            FlushEvents();
            
            [Down, ~, Code] = KbCheck();            %wait for key to be pressed
            if Down == 1
                rt = GetSecs()- RT_start;
                if any(find(Code) == KEYS.up)
                    %They pushed it away, make it smaller.
                    AAM.data(trial).aa = 0;
                    AAM.data(trial).rt = rt;
                    break
                elseif any(find(Code) == KEYS.down)
                    %They pulled it; make it bigger.
                    AAM.data(trial).aa = 1;
                    AAM.data(trial).rt = rt;
                    break
                end
                
            end
        end
        %zoom that pic.
        if AAM.data(trial).aa == 0;
            while side < STIM.minside
                side = side + 4;
                zoom = STIM.imgrect + [side;side;-side;-side];
                Screen('DrawTexture',w,tpic,[],zoom);
                Screen('Flip',w);
            end
            
        elseif AAM.data(trial).aa == 1;
            while side < STIM.maxside
                side = side + 4;
                zoom = STIM.imgrect + [-side; -side; side; side];
                Screen('DrawTexture',w,tpic,[],zoom);
                Screen('Flip',w);
            end
           
        end
                    
    end
end

%% Save that data. 
savedir = [mdir filesep 'Results' filesep];
cd(savedir);
try
save([savedir 'AAM_' num2str(ID) '.mat'],'AAM');
catch
    warning('Something is amiss with this save. Retrying to save in a more general location...');
    try
        save([mdir filesep 'AAM_' num2str(ID) '.mat'],'AAM');
    catch
        warning('STILL problems saving....Try right-clicking on ''AAM'' and Save as...');
        AAM
    end
end
    
end





