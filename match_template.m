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
%   send a logical MASK the same size as TEMPLATE indicating which pixels 
%   to include in TEMPLATE (1: include, 0: exclude).
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
img_classes = {'uint8','uint16','double','logical','single','int16'};
check_img = @(I) validateattributes(I,img_classes,{'nonempty'});
defaultThresh = -1;
defaultMask = 1;

% add arguments to parser
addRequired(p,'image',check_img);
addRequired(p,'template',check_img);
addParameter(p,'threshold',defaultThresh,@isnumeric);
addParameter(p,'mask',defaultMask,@islogical);

% parse inputs
parse(p,image,template,varargin{:});
image = im2double(p.Results.image);
template = im2double(p.Results.template);
thresh = p.Results.threshold;
mask = p.Results.mask;

%% initialize

% compute size of the scanning window
image_sz = size(image);
template_sz = size(template);
algo_sz = image_sz(1:2) - template_sz(1:2) + [1 1];

% initialize the difference image
diff = zeros(algo_sz);

% if 1-ch mask is given and the image is 3-ch, convert mask to 3-ch
if (length(mask)>1 && length(size(mask))==2 && length(image_sz)==3) 
    mask = repmat(mask, [1 1 3]);
end

%% compute sum of square differences

for ii = 1:algo_sz(1)
    for jj = 1:algo_sz(2)
        diff(ii,jj) = sum(sum(sum(...
            mask .* (template - image(ii:template_sz(1)+ii-1, jj:template_sz(2)+jj-1, :)).^2)));
    end
end   

%% scale SSD to between 0 and 1

% find maximum possible difference between the template and any image
max_vals = max([template(mask)'; 1-template(mask)']);

% sum the max square differences
max_ssd = sum(max_vals.^2);

% scale to values between 0 and 1
diff = diff/max_ssd;

%% find match location(s)

if thresh < 0 % return minimum location and associated scaled SSD
    
    [~,min_ind] = min(diff(:));
    [Y,X] = ind2sub(algo_sz, min_ind);
    D = diff(Y,X);
    
else % return all locations with diff<=thresh and associated scaled SSDs 
    
    thresh_ind = find(diff(:) <= thresh);
    [Y,X] = ind2sub(algo_sz, thresh_ind);
    D = diff(thresh_ind);
    
end

end