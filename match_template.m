function [ X, Y, D ] = match_template( image, template, varargin )
% MATCH_TEMPLATE  Finds a template inside an image.
% 
%   [X,Y] = MATCH_TEMPLATE(IMAGE,TEMPLATE) finds the location of TEMPLATE
%   inside IMAGE. Takes the sum of squared differences (SSD) between SCENE 
%   and TEMPLATE at every location; returned match location corresponds to 
%   the minimum difference. X and Y hold the (x,y)-coordinate of the match.
%   
%   [X,Y,D] = MATCH_TEMPLATE(IMAGE,TEMPLATE,...) also returns a vector D 
%   containing scaled SSD values corresponding to the match locations X,Y.
%   The SSD is scaled by the max possible SSD of TEMPLATE with any IMAGE.
% 
%   [X,Y] = MATCH_TEMPLATE(...,'THRESHOLD',THRESH) matches are returned for
%   locations where the scaled SSD<=THRESH. Set THRESH=0 to locate exact 
%   matches. X and Y hold the (x,y)-coordinates of matches.
% 
%   [X,Y] = MATCH_TEMPLATE(...,'MASK',MASK) for a non-rectangular TEMPLATE, 
%   send a logical MASK to indicate which pixels to include in TEMPLATE
%   (where 1: include, 0: exclude). MASK must have same height/width as
%   TEMPLATE: size(MASK)==size(TEMPLATE) or size(MASK)==size(TEMPLATE(1:2)) 
% 
%   Class Support
%   -------------
%   If IMAGE or TEMPLATE is an intensity or truecolor image, it can be 
%       uint8, uint16, double, logical, single, or int16.
%   If IMAGE or TEMPLATE is an indexed image, it can be 
%       uint8, uint16, double or logical.
% 
%   Example
%   -------
%   % create image, template, and mask
%   I = randi([0 1], [96 96]); % image is a 96x96 random b&w image 
%   I(11:14,1:24) = 0; I(1:24,11:14) = 0; % draw a plus sign
%   T = I(1:24,1:24); % the template contains the plus sign
%   M = T*0; M(11:14,1:24) = 1; M(1:24,11:14) = 1; M=M==1; % mask template
% 
%   % run template matching algorithm
%   [X,Y] = match_template(I, T, 'mask', M); % find where T is in I
% 
%   % display
%   figure(1); imshow(I); hold on;
%   R = [X Y 23 23]; % rectangle to draw around template
%   rectangle('Position',R,'EdgeColor','R','LineWidth',2);
%   hold off;
% 
%   Author
%   ------ 
%   Alexander Reynolds
%   ar@reynoldsalexander.com
%   https://github.com/alkasm

%% argument parsing

% create parser
p = inputParser;

% validation functions
img_classes = {'uint8','uint16','double','logical','single','int16'};
is_img = @(x) validateattributes(x,img_classes,{'nonempty'});
is_thresh = @(x) assert(isnumeric(x) && isscalar(x) && (x>=0) && (x<1), ...
    'Threshold must be numeric, scalar, and in [0, 1).');

defaultThresh = -1;
defaultMask = 1;

% add arguments to parser
addRequired(p,'image',is_img);
addRequired(p,'template',is_img);
addParameter(p,'threshold',defaultThresh,is_thresh);
addParameter(p,'mask',defaultMask,@islogical);

% parse inputs
parse(p,image,template,varargin{:});
image = im2double(p.Results.image);
template = im2double(p.Results.template);
thresh = p.Results.threshold;
mask = p.Results.mask;

% get sizes
image_h = size(image,1);
image_w = size(image,2);
template_h = size(template,1);
template_w = size(template,2);

% check if mask exists and is the right size
err_mask = ['MASK must have the same height and width as TEMPLATE: '...
        'size(MASK)==size(TEMPLATE) or size(MASK)==size(TEMPLATE(1:2)).'];
if all(mask(:)) % no mask, or equivalently, all true mask
    mask_exists = false;
elseif size(mask,1) == template_h && size(mask,2) == template_w
    if size(mask,3) == 1 && size(template,3) == 3
        mask_exists = true;
        mask = repmat(mask,[1 1 3]);
    elseif size(mask,3) == size(template,3)
        mask_exists = true;
    else
        error(err_mask);
    end
else
    error(err_mask);
end


%% compute sum of square differences

% initialize the difference image
nrows = image_h - template_h + 1;
ncols = image_w - template_w + 1;
diff = zeros([nrows ncols]);

% loop through each pixel
if mask_exists
    template = template(mask); % linearize and remove values
    for r = 1:nrows
        for c = 1:ncols
            roi = image(r:template_h+r-1,c:template_w+c-1,:);
            diff(r,c) = sum((template - roi(mask)).^2);
        end
    end   
else
    template = template(:); % linearize
    for r = 1:nrows
        for c = 1:ncols
            roi = image(r:template_h+r-1,c:template_w+c-1,:);
            diff(r,c) = sum((template - roi(:)).^2);
        end
    end   
end

%% scale SSD to between 0 and 1

% find maximum possible difference between the template and any image
max_vals = max([template'; 1-template']);

% sum the max square differences
max_ssd = sum(max_vals.^2);

% scale to values between 0 and 1
diff = diff/max_ssd;

%% find match location(s)

if thresh < 0 % return minimum location and associated scaled SSD
    
    [~,min_ind] = min(diff(:));
    [Y,X] = ind2sub([nrows ncols], min_ind);
    D = diff(Y,X);
    
else % return all locations with diff<=thresh and associated scaled SSDs 
    
    thresh_ind = find(diff(:) <= thresh);
    [Y,X] = ind2sub([nrows ncols], thresh_ind);
    D = diff(thresh_ind);
    
end

end