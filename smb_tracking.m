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

%% create template

% Mario's head for template matching
head_frame = 150;
head_pix_y = 179:189;
head_pix_x = 115:127;
head_size = [length(head_pix_y) length(head_pix_x)];
head = smb_video{head_frame}(head_pix_y, head_pix_x, :);

% hard code mask to remove the blue background from the head
mask = ones(head_size);
mask(1,[1:4 end-3:end]) = 0;
mask(2,[1 2 end-3:end]) = 0;
mask([3 4],[1 end]) = 0;
mask([5 6 9 10],end) = 0;
mask(end,[1 2 end-3:end]) = 0;
mask = mask==1; % convert to logical
             
% create threshold based on how well the head matches on the first frame
[~,~,thresh] = match_template(smb_video{1}, head, 'mask', mask);

% make it more forgiving
thresh = thresh * 3; 

%% run template tracking algorithm

radius = 10;
rate = 1.05;
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