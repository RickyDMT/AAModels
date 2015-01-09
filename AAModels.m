
function AAModels(varargin)


global KEYS COLORS w wRect XCENTER YCENTER PICS STIM AAM rects mids

prompt={'SUBJECT ID' 'Condition' 'Session (1, 2, or 3)' 'Practice? 0 or 1'};
defAns={'4444' '1' '1' '0'};

answer=inputdlg(prompt,'Please input subject info',1,defAns);

ID=str2double(answer{1});
COND = str2double(answer{2});
SESS = str2double(answer{3});
prac = str2double(answer{4});


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
STIM.jit = [.5 .25 .1];
STIM.minside = 200;
STIM.maxside = 200;


%% Find & load in pics
[imgdir,~,~] = fileparts(which('ModelPairPics.m'));
% picratefolder = fullfile(imgdir,'SavingsRatings');

% try
%     cd(picratefolder)
% catch
%     error('Could not find and/or open the image directory.');
% end
% 
% filen = sprintf('PicRate_%03d.mat',ID);
% try
%     p = open(filen);
% catch
%     warning('Could not find and/or open the rating file.');
%     commandwindow;
%     randopics = input('Would you like to continue with a random selection of images? [1 = Yes, 0 = No]');
%     if randopics == 1
%         p = struct;
%         p.PicRating.go = dir('Healthy*');
%         p.PicRating.no = dir('Unhealthy*');
%         %XXX: ADD RANDOMIZATION SO THAT SAME 80 IMAGES AREN'T CHOSEN
%         %EVERYTIME
%     else
%         error('Task cannot proceed without images. Contact Erik (elk@uoregon.edu) if you have continued problems.')
%     end
%     
% end

cd(imgdir);
 


    % Update for appropriate pictures.
     PICS.in.T = dir('*_T*');
     PICS.in.H = dir('*_H*');

%Check if pictures are present. If not, throw error.
%Could be updated to search computer to look for pics...
if isempty(PICS.in.T) || isempty(PICS.in.H) %|| isempty(PICS.in.neut)
    error('Could not find pics. Please ensure pictures are found in a folder names IMAGES within the folder containing the .m task file.');
end


%% Fill in rest of pertinent info

pictype = [ones(STIM.totes/2,1); zeros(STIM.totes/2,1)];

picdiff = (STIM.totes/2) - length(PICS.in.T);
if picdiff > 0;
    piclist_T = [randperm(length(PICS.in.T))'; randi(length(PICS.in.T),picdiff,1)];
elseif picdiff <= 0;
    piclist_T = randperm(length(PICS.in.T),(STIM.totes/2))';
end
% piclist_T = reshape(piclist_T,STIM.trials,STIM.blocks/2);


picdiff = (STIM.totes/2) - length(PICS.in.H);
if picdiff > 0;
    piclist_H = [randperm(length(PICS.in.H))'; randi(length(PICS.in.H),picdiff,1)];
elseif picdiff <= 0;
    piclist_H = randperm(length(PICS.in.H),(STIM.totes/2))';
end
% piclist_H = reshape(piclist_H,STIM.trials,STIM.blocks/2);

piclist = [piclist_T; piclist_H];
piclist = [pictype piclist];
piclist = piclist(randperm(length(piclist)),:);

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
% AAM.var(1).trial = [];
% AAM.var(1).pictype = [];
% AAM.var(1).picname = [];
% AAM.var(1).jitter = [];

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
DEBUG=1;

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
STIM.framerect = [XCENTER-330; YCENTER-400; XCENTER+330; YCENTER+400];
STIM.imgrect = STIM.framerect + [30; 30; -30; -30];


%% Do that intro stuff.
DrawFormattedText(w,'Instructions go here','center','center',COLORS.WHITE);
Screen('Flip',w);
KbWait();

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
                if any(find(Code) == KEYS.up)
                    %They pushed it away, make it smaller.
                    AAM.data(trial).aa = 0;
                    
          
                    
                elseif any(find(Code) == KEYS.down)
                    %They pulled it; make it bigger.
                    AAM.data(trial).aa = 1;
                   
                    
                end
                break
            end
        end
        %zoom here instead.
        if AAM.data(trial).aa == 0;
            while side < STIM.minside
                side = side + 10;
                zoom = STIM.imgrect + [side;side;-side;-side];
%                 Screen('FillRect',w,COLORS.GREEN,STIM.framerect);
                Screen('DrawTexture',w,tpic,[],zoom);
                Screen('Flip',w);
            end
            
        elseif AAM.data(trial).aa == 1;
            while side < STIM.maxside
                side = side + 10;
                zoom = STIM.imgrect + [-side; -side; side; side];
%                 Screen('FillRect',w,COLORS.GREEN,STIM.framerect);
                Screen('DrawTexture',w,tpic,[],zoom);
                Screen('Flip',w);
            end
           
        end
                    
    end
end

%% Save that data. 

    
end