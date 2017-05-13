% SMB_TRACKING  Track Mario in SMB gameplay via template matching.
%
%   Requires TRACK_TEMPLATE.m, MATCH_TEMPLATE.m, and the Computer Vision
%   System Toolbox for nice input and output and to draw the tracked box 
%   around Mario.
%
%   Author
%   ------ 
%   Alexander Reynolds
%   ar@reynoldsalexander.com
%   https://github.com/alkasm

clear all;

%% read input

fprintf('Reading video file...');
vr = vision.VideoFileReader('input/smb_w4-1.mp4');

% read video frames into cell array
k = 1;
while ~isDone(vr)
    smb_video{k} = step(vr);
    k = k+1;
end
release(vr)
qty_frames = length(smb_video);

fprintf('done. \n');

%% read template

% load Mario's head, and a mask to remove the background, for the template
template = matfile('input/template.mat');
head = template.head;
head_size = [size(head,1) size(head,2)];
mask = template.mask;

% values for template tracking algorithm
radius = 10;
rate = 1.05; 

% create threshold based on how well the head matches on the first frame
[~,~,thresh] = match_template(smb_video{1}, head, 'mask', mask);
thresh = thresh * 3; % make it more forgiving


%% run template tracking algorithm

fprintf('Running template tracking algorithm (might take a minute)...');
[X,Y] = track_template(smb_video,head, ...
    'radius',radius,'mask',mask,'threshold',thresh,'rate',rate);
fprintf('done. \n');

%% write video with box around Mario

fprintf('Writing video file...');
vw = vision.VideoFileWriter('tracked.mp4',...
    'FileFormat','MPEG4','FrameRate',vr.info.VideoFrameRate);

for k = 1:qty_frames
    
    if ~isnan(X(k)*Y(k)) % if the match is accepted, draw box around Mario
        box_pos = [X(k)-4 Y(k)-2 head_size(2)+5 head_size(1)+22];
        curr_frame = insertShape(smb_video{k},...
            'Rectangle',box_pos,'LineWidth',2,'Color','Y');
    else % don't draw a box around Mario
        curr_frame = smb_video{k};
    end
    
    step(vw,curr_frame)
    
end

release(vw);

fprintf('done. \nOperation complete!\n');