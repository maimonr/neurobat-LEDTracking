function [centroidLocs, predColors, props, predPosterior, predLab] = predict_LED_location(f,varargin)

% take a frame from a video, (optionally) filter by preset color ranges,
% find regions of color, and predict based on a pre-trained classifier the
% color in the image.
% INPUTS:
% f: h x w x 3 image to be processed
% hsvTable: output of either "get_hsv_lim_mats" (better performance) or
% "get_hsv_lims"
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
 

pnames = {'hsvTable','minLum','mergeThresh','minArea','color_pred_model','ROI','maxArea','params','sessionType'};
dflts  = {[],5,10,10,[],[],200,[],[]};
[hsvTable,minLum,mergeThresh,minArea,color_pred_model,ROIIdx,maxArea,params,sessionType] = internal.stats.parseArgs(pnames,dflts,varargin{:});

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
       ROIIdx = params.ROIIdxVocal; % the only other ROI is for vocal, so we use it if its not social  
   else % else bugger off mate, nothing doing   
   end 
end 
    

if isempty(color_pred_model)
    try 
        s = load('color_prediction_model');
        color_pred_model = s.color_pred_model;
    catch
        [file,path] = uigetfile('*.mat','Select file containing color prediction model');
        s = load(fullfile(path,file));
        color_pred_model = s.color_pred_model;
    end
end

fHsv = rgb2hsv(f);

if ~isempty(ROIIdx) % If no ROI is defined, use entire image, otherwise set values outside of ROI to zero. do this just once to save on performance
    ROI = true(size(f));
    for roi_k = 1:size(ROIIdx,1)
        ROI(ROIIdx(roi_k,1):ROIIdx(roi_k,2),ROIIdx(roi_k,3):ROIIdx(roi_k,4),:) = false;
    end
    f(ROI) = NaN;
end

if ~isempty(hsvTable) % if provided, create a binary mask for each color filter
    n_hsv_colors = size(hsvTable,2);
    bw = cell(1,n_hsv_colors);
    for color_k = 1:n_hsv_colors
        bw{color_k} = getFrameMask(fHsv,'hsvLims',hsvTable{:,color_k},'params',params); 
    end
else
    n_hsv_colors = 1;
    bw{1} = getFrameMask(f,'ROI',ROIIdx);
end

if exist('colorspace','file')
    labFunc = @(frame) colorspace('Lab<-rgb',im2double(frame)); % this function is much faster than the native matlab code
else
    labFunc = @rgb2lab;
end
[centroidLocs,predColors,props,predPosterior, predLab] = deal(cell(1,n_hsv_colors));

for color_k = 1:n_hsv_colors
    [centroidLocs{color_k}, props{color_k}, cc] = findLEDcentroid(bw{color_k},'mergeThresh',mergeThresh,'minArea',minArea);
    if any([props{color_k}.Area] > maxArea)
        fGray = rgb2gray(f);
        bw{color_k} = split_blobs(fGray,bw{color_k},props{color_k},maxArea);
        [centroidLocs{color_k}, props{color_k}, cc] = findLEDcentroid(bw{color_k},'mergeThresh',[],'minArea',minArea);
    end
    color_mat = nan(length(props{color_k}),2); % pre allocated array for median color values in each region
    
    regionLabels = 1:cc.NumObjects; % prepare to iterate through each region detected in findLEDCentroid
    if ~isempty(regionLabels)
        for region_k = regionLabels
            regionIdx = cc.PixelIdxList{region_k};
            f = reshape(f,[],3);
            regionRGB = f(regionIdx,:);
            regionLab = labFunc(regionRGB);
            regionLab = regionLab(regionLab(:,1) > minLum,:);
            color_mat(region_k,:) = squeeze(median(regionLab(:,2:3))); % take the median a and b values for those pixels
        end
        [predColors{color_k},predPosterior{color_k}] = predict(color_pred_model.ClassificationSVM  ,color_mat); % predict which color based on median pixel a and b values
        if length(regionLabels) == 1 && n_hsv_colors > 1 % if there's only one region in this filtered image, use it
            predColors{color_k} = predColors{color_k}{1}; 
        elseif n_hsv_colors > 1 % if there's more than one region in this filtered image, select the one with the highest posterior probability
            [~,max_posterior_idx] = max(predPosterior{color_k},[],'all','linear');
            [row,~] = ind2sub(size(predPosterior{color_k}),max_posterior_idx);          
            centroidLocs{color_k} = centroidLocs{color_k}(row,:);
            props{color_k} = props{color_k}(row,:);
            predColors{color_k} = predColors{color_k}{row};
            predPosterior{color_k} = predPosterior{color_k}{row};
        else % if we're not color filtering, use all predicted colors
            predColors = predColors{1};
            predPosterior = predPosterior{1};
            centroidLocs = centroidLocs{1};
            predLab = color_mat; 
        end
    end
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
