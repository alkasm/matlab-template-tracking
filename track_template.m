function [ X, Y, D ] = track_template( imgseq, template, varargin )
% TRACK_TEMPLATE  Tracks a template inside a sequence of images.
% 
%   [X,Y] = TRACK_TEMPLATE(IMGSEQ,TEMPLATE) tracks the location of a moving
%   TEMPLATE inside cell array of images IMGSEQ. Uses the function
%   MATCH_TEMPLATE(IMGSEQ{N},TEMPLATE) to compute match locations. X and Y 
%   hold the (x,y)-coordinates of the best match from each video frame. 
%
%   [X,Y,D] = TRACK_TEMPLATE(IMAGE,TEMPLATE,...) also returns a vector D 
%   containing scaled SSD values corresponding to the match locations X,Y.
%
%   [X,Y] = TRACK_TEMPLATE(...,'RADIUS',RADIUS) to reduce the search area, 
%   TEMPLATE is found in IMGSEQ{N} by searching in a RADIUS from the match
%   in IMGSEQ{N-1}. RADIUS can be a scalar or a 4-vector specifying the 
%   radius in each direction, in the order: left, top, right, bottom. 
%   IMGSEQ{1} is found by searching the full image. 
% 
%   [X,Y] = TRACK_TEMPLATE(...,'THRESHOLD',THRESH) matches are returned if
%   they are below THRESH, otherwise [NaN,NaN] is returned as the match
%   location for the frame. If a RADIUS is specified, RADIUS grows around
%   the most recent match by RATE each frame until TEMPLATE is found again.
%
%   [X,Y] = TRACK_TEMPLATE(...,'RATE',RATE) if THRESH and RADIUS are both 
%   supplied, the search area defined through RADIUS grows by RATE when 
%   matches are above THRESH. RATE can be a scalar or a 4-vector specifying
%   the growth rate for each direction independently, in the order: left, 
%   top, right, bottom. By default, RATE = 1.1.
% 
%   [X,Y] = TRACK_TEMPLATE(...,'MASK',MASK) for a non-rectangular TEMPLATE, 
%   send a logical MASK indicating which pixels to include in TEMPLATE
%   (1: include, 0: exclude). MASK must have same height/width as TEMPLATE: 
%   size(MASK)==size(TEMPLATE) or size(MASK)==size(TEMPLATE(1:2)). 
% 
%   Class Support
%   -------------
%   IMGSEQ containing N images must be a 1xN cell array with an image in
%   each cell. Run `help match_template` for image class support.
% 
%   Example
%   -------
%   % create starting image, template, and mask
%   I = randi([0 1], [96 96]); % image is a 96x96 random b&w image 
%   I(11:14,1:24) = 0; I(1:24,11:14) = 0; % draw a plus sign
%   T = I(1:24,1:24); % the template contains the plus sign
%   M = T*0; M(11:14,1:24) = 1; M(1:24,11:14) = 1; M=M==1; % mask template
%   
%   % create image sequence by shuffling sections of the image
%   B = mat2cell(I, 24*ones(1,4), 24*ones(1,4)); % divide image into blocks
%   for k = 1:60
%       B(:) = B(randperm(length(B(:)))); % shuffle blocks w/ random perm
%       S{k} = cell2mat(B); % sequence the shuffled image
%   end
%   
%   % run template tracking algorithm on the image sequence
%   [X,Y] = track_template(S, T, 'mask', M); % track template in sequence
%   
%   % display tracked template
%   figure(1);
%   for k = 1:60
%       R = [X(k) Y(k) 23 23]; % rectangle to draw around template
%       imshow(S{k}); hold on;
%       rectangle('Position',R,'EdgeColor','R','LineWidth',2);
%       hold off; pause(0.05);
%   end
% 
%   Author
%   ------ 
%   Alexander Reynolds
%   ar@reynoldsalexander.com
%   https://github.com/alkasm

%% argument parsing

% create parser
p = inputParser;
img_classes = {'uint8','uint16','double','logical','single','int16'};
is_img = @(I) validateattributes(I,img_classes,{'nonempty'});
is_seq = @(S) assert(isnumeric(S{1}) && isHomogeneous(coder.typeof(S)));
default_radius = -1;
default_thresh = -1;
default_rate = 1.1;
default_mask = 1;

% add arguments to parser
addRequired(p,'imgseq',is_seq);
addRequired(p,'template',is_img);
addParameter(p,'radius',default_radius,@isnumeric);
addParameter(p,'threshold',default_thresh,@isnumeric);
addParameter(p,'rate',default_rate,@isnumeric);
addParameter(p,'mask',default_mask,@islogical);

% parse inputs
parse(p,imgseq,template,varargin{:});
imgseq = p.Results.imgseq;
template = p.Results.template;
radius = p.Results.radius;
thresh = p.Results.threshold;
rate = p.Results.rate;
mask = p.Results.mask;

%% initialize

if isscalar(radius)
    radius = repmat(radius, [4 1]);
end
if isscalar(rate)
    rate = repmat(rate, [4 1]);
end
init_radius = radius;

qty_frames = length(imgseq);
frame_h = size(imgseq{1},1);
frame_w = size(imgseq{1},2);
template_h = size(template,1);
template_w = size(template,2);

X = ones(qty_frames,1); % x locations of matches
Y = X;                  % y locations of matches
D = X;                  % scaled SSD at match locations

%% find template

% first frame
[X(1),Y(1),D(1)] = match_template(imgseq{1},template,'mask',mask);

% the rest of the sequence
if radius < 0 % sequence using the whole frame
    
    for k = 2:qty_frames
        
        [X(k),Y(k),D(k)] = match_template(imgseq{k},template,'mask',mask);

    end
    
elseif thresh < 0 % radius around X(k-1),Y(k-1), w/o thresh
    
    for k = 2:qty_frames

        l = max(X(k-1) - radius(1), 1);
        t = max(Y(k-1) - radius(2), 1);
        r = min(X(k-1) + radius(3) + template_w, frame_w);
        b = min(Y(k-1) + radius(4) + template_h, frame_h);

        roi = imgseq{k}(t:b,l:r,:);
        [X(k),Y(k),D(k)] = match_template(roi,template,'mask',mask);
        
        X(k) = X(k) + l;
        Y(k) = Y(k) + t;
        
    end
    
else % sequence, radius around X(k-1),Y(k-1) w/ thresh
    
    for k = 2:qty_frames

        l = max(X(k-1) - radius(1), 1);
        t = max(Y(k-1) - radius(2), 1);
        r = min(X(k-1) + radius(3) + template_w, frame_w);
        b = min(Y(k-1) + radius(4) + template_h, frame_h);
        
        roi = imgseq{k}(t:b,l:r,:);
        [X(k),Y(k),D(k)] = match_template(roi,template,'mask',mask);

        if D(k)>thresh % grow radius, keep the last known match loc
            radius = round(radius.*rate);
            X(k) = X(k-1);
            Y(k) = Y(k-1);
        else
            radius = init_radius;
            X(k) = X(k) + l;
            Y(k) = Y(k) + t;
        end
        
    end
    
end

if thresh >= 0 % reject values
    X(D>thresh) = NaN;
    Y(D>thresh) = NaN;
end

end
