function [centroidLocs, predColors, props, predPosterior, predLab] = predict_LED_location(f,varargin)

% take a frame from a video, (optionally) filter by preset color ranges,
% find regions of color, and predict based on a pre-trained classifier the
% color in the image.
% INPUTS:
% f: h x w x 3 image to be processed
% minLum: minimum value of L in L*a*b color space to consider for color
% prediction (higher value = higher luminance)
% mergeThresh: number of pixels below which nearby regions are recursively
% merged. Leave empty if merging is not requested.
% minArea: minimum area for an region to be considered
% maxArea: maximum area above which, blob splitting is attempted
% color_pred_model: prediction model using a and b of L*a*b color space
% (output from matlab's ClassificationLearner)
% ROI: Region of interest as a rectangle within the image defined as:
%      [firstRow lastRow firstColumn lastColumn], all pixels outside of ROI
%      are set to NaN. Leave blank to consider entire image.
% OUTPUTS: 
% centroidLocs: location (in pixels) of centroids of region(s) in bw
% predColors: predicted color for each region. if hsv lims are included,
% only one prediction is returned for each color range provided (selected
% based on highest posterior probability of the prediction model).
% props: regionprops output regarding the region(s) in bw
 

pnames = {'minLum','mergeThresh','minArea','color_pred_model','ROI','maxArea','params','sessionType'};
dflts  = {[],5,10,25,[],[],200,[],[]};
[minLum,mergeThresh,minArea,color_pred_model,ROIIdx,maxArea,params,sessionType] = internal.stats.parseArgs(pnames,dflts,varargin{:});

if ~isempty(params)
    minLum = params.minLum;
    mergeThresh = params.mergeThresh;
    minArea = params.minArea;
    maxArea = params.maxArea;
    ROIIdx = params.ROIIdx;
end

if ~isempty(sessionType)
   ses = strcmp(sessionType,'social'); 
   if ses == 0 
       ROIIdx = params.ROIIdx;  
   else % else bugger off mate, nothing doing   
   end 
end 
    

if isempty(color_pred_model)
    [file,path] = uigetfile('*.mat','Select file containing color prediction model');
    color_pred_model = load(fullfile(path,file));
end


lab_avg_func = @(lab) median(lab(:,2:3));


if ~isempty(ROIIdx) % If no ROI is defined, use entire image, otherwise set values outside of ROI to zero. do this just once to save on performance
    ROI = true(size(f));
    for roi_k = 1:size(ROIIdx,1)
        ROI(ROIIdx(roi_k,1):ROIIdx(roi_k,2),ROIIdx(roi_k,3):ROIIdx(roi_k,4),:) = false;
    end
    f(ROI) = NaN;
end

bw = getFrameMask(f,'ROI',ROIIdx);

if exist('colorspace','file')
    labFunc = @(frame) colorspace('Lab<-rgb',im2double(frame)); % this function is much faster than the native matlab code
else
    labFunc = @rgb2lab;
end

[centroidLocs, props, cc] = findLEDcentroid(bw,'mergeThresh',mergeThresh,'minArea',minArea);
if any([props.Area] > maxArea)
    fGray = rgb2gray(f);
    bw = split_blobs(fGray,bw,props,maxArea);
    [centroidLocs, props, cc] = findLEDcentroid(bw,'mergeThresh',[],'minArea',minArea);
end
predLab = nan(length(props),2); % pre allocated array for median color values in each region

regionLabels = 1:cc.NumObjects; % prepare to iterate through each region detected in findLEDCentroid
if ~isempty(regionLabels)
    f = reshape(f,[],3);
    for region_k = regionLabels
        regionIdx = cc.PixelIdxList{region_k};
        regionRGB = f(regionIdx,:);
        regionLab = labFunc(regionRGB);
        regionLab = regionLab(regionLab(:,1) > minLum,:);
        predLab(region_k,:) = squeeze(lab_avg_func(regionLab)); % take the median a and b values for those pixels
    end
    nanIdx = any(isnan(predLab),2);
    predLab = predLab(~nanIdx,:);
    centroidLocs = centroidLocs(~nanIdx,:);
    props = props(~nanIdx);
    [predColors,predPosterior] = predict(color_pred_model.mdl,predLab); % predict which color based on median pixel a and b value
else
    predColors = {};
    predPosterior = [];
    predLab = zeros(0,2);
end

end

function bw = split_blobs(fGray,bw,props,maxArea)
smoothSpan = 16;
K = (1/smoothSpan )*ones(smoothSpan);
blobIdx = [props.Area] > maxArea;

for blob_k = find(blobIdx)    
    bb = round(props(blob_k).BoundingBox);
    bbIdx = {bb(2):bb(2)+bb(4),bb(1):bb(1)+bb(3)};
    imChunk = fGray(bbIdx{1},bbIdx{2});
    bwChunk = bw(bbIdx{1},bbIdx{2});
    IMSmooth = conv2(imChunk,K,'same');
    L = watershed(-IMSmooth);
    L(~bwChunk) = 0;
    
    bw(bb(2):bb(2)+bb(4),bb(1):bb(1)+bb(3)) = L~=0;
end

end
