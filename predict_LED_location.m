function [centroidLocs, predColors, props, predPosterior] = predict_LED_location(f,varargin)

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
 

pnames = {'hsvTable','minLum','mergeThresh','minArea','color_pred_model','ROI'};
dflts  = {[],20,20,30,[],[]};
[hsvTable,minLum,mergeThresh,minArea,color_pred_model,ROIIdx] = internal.stats.parseArgs(pnames,dflts,varargin{:});

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
    ROI(ROIIdx(1):ROIIdx(2),ROIIdx(3):ROIIdx(4),:) = false;
    f(ROI) = NaN;
end

if ~isempty(hsvTable) % if provided, create a binary mask for each color filter
    n_hsv_colors = size(hsvTable,2);
    bw = cell(1,n_hsv_colors);
    for color_k = 1:n_hsv_colors
        bw{color_k} = getFrameMask(fHsv,'hsvLims',hsvTable{:,color_k}); 
    end
else
    n_hsv_colors = 1;
    bw{1} = getFrameMask(f,'ROI',ROIIdx);
end

if exist('colorspace','file')
    fLab = colorspace('Lab<-rgb',im2double(f)); % this function is much faster than the native matlab code
else
    fLab = rgb2lab(f);
end
[centroidLocs,predColors,props,predPosterior] = deal(cell(1,n_hsv_colors));

for color_k = 1:n_hsv_colors
    [centroidLocs{color_k}, props{color_k}, labelIm] = findLEDcentroid(bw{color_k},'mergeThresh',mergeThresh,'minArea',minArea);
    color_mat = nan(length(props{color_k}),2); % pre allocated array for median color values in each region
    
    regionLabels = labelIm(labelIm~=0); % prepare to iterate through each region detected in findLEDCentroid
    regionLabels = setdiff(unique(regionLabels(:)),0)';
    if ~isempty(regionLabels)
        k = 1;
        for region_k = regionLabels
            regionIdx = labelIm == region_k;
            regionIdx = regionIdx & fLab(:,:,1) > minLum; % select pixels in this region that have at least minLum level of luminance
            [row,col] = find(regionIdx);
            color_mat(k,:) = squeeze(median(fLab(row,col,2:3),[1 2])); % take the median a and b values for those pixels
            k = k + 1;
        end
        [predColors{color_k},predPosterior{color_k}] = predict(color_pred_model.ClassificationDiscriminant,color_mat); % predict which color based on median pixel a and b values
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
        end
    end
end
end
