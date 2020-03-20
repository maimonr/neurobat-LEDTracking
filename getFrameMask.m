function bw = getFrameMask(f,varargin)

% create a binary image mask based either on a fixed threshold
% or a user defined intensity interval in the HSV color space.
% INPUTS:
% f: one image (h x w x 3), assumed to be in RGB color space
% hsvLims: a 3 x 2 matrix defining the lower (first column) and upper
% (second column) bounds for each of the 3 channels in HSV color that
% determines what is included in the mask
% ROI: Region of interest as a rectangle within the image defined as:
%      [firstRow lastRow firstColumn lastColumn]
% fixed_thresh: the fraction of the range of the intensity values in f over
% which is considered to be included in the mask (only used if hsvLims is
% empty)
% strel_radius: radius of the circular "structural element" used to fill in
% small gaps in the mask
% OUTPUTS:
% bw: binary mask of pixels that pass the user defined threshold(s)

pnames = {'hsvLims','ROI','fixed_thresh','strel_radius'};
dflts  = {[],[],0.1,10};
[hsvLims,ROI,fixed_thresh,strel_radius] = internal.stats.parseArgs(pnames,dflts,varargin{:});

if isempty(ROI) % If no ROI is defined, use entire image
   ROI = [1 size(f,1) 1 size(f,2)]; 
end

f = f(ROI(1):ROI(2),ROI(3):ROI(4),:);

if isempty(hsvLims)
    f = rgb2gray(f); % if no HSV lim is defined, determine threshold based on grayscale intensity values
    if isa(f,'uint8')
        thresh = fixed_thresh*(2^8);
    else
        thresh = fixed_thresh*range(f(:));
    end
    bw = f > thresh;
else
    bw = createMaskFilter(f,hsvLims);
end

SE = strel('disk',strel_radius); % define circular "structural element"
bw = imclose(bw,SE); % remove gaps in mask 

end