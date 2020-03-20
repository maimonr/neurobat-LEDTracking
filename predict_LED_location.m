function [centroidLocs, predColors, props] = predict_LED_location(f,varargin)

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

if ~isempty(ROIIdx) % If no ROI is defined, use entire image, otherwise set values outside of ROI to zero
    ROI = true(size(f));
    ROI(ROIIdx(1):ROIIdx(2),ROIIdx(3):ROIIdx(4),:) = false;
    f(ROI) = NaN;
end

if ~isempty(hsvTable)
    n_hsv_colors = size(hsvTable,2);
    bw = cell(1,n_hsv_colors);
    for color_k = 1:n_hsv_colors
        bw{color_k} = getFrameMask(fHsv,'hsvLims',hsvTable{:,color_k}); 
    end
else
    n_hsv_colors = 1;
    bw{1} = getFrameMask(fHsv,'ROI',ROIIdx);
end

fLab = colorspace('Lab<-rgb',im2double(f));
[centroidLocs,predColors,props] = deal(cell(1,n_hsv_colors));

for color_k = 1:n_hsv_colors
    [centroidLocs{color_k}, props{color_k}, labelIm] = findLEDcentroid(bw{color_k},'mergeThresh',mergeThresh,'minArea',minArea);
    color_mat = nan(length(props{color_k}),2);
    
    regionLabels = labelIm(labelIm~=0);
    regionLabels = setdiff(unique(regionLabels(:)),0)';
    if ~isempty(regionLabels)
        k = 1;
        for region_k = regionLabels
            regionIdx = labelIm == region_k;
            regionIdx = regionIdx & fLab(:,:,1) > minLum;
            [row,col] = find(regionIdx);
            color_mat(k,:) = squeeze(median(fLab(row,col,2:3),[1 2]));
            k = k + 1;
        end
        color_table = table(color_mat(:,1),color_mat(:,2));
        [predColors{color_k},predPosterior] = color_pred_model.predictFcn(color_table);
        if length(regionLabels) == 1
            predColors{color_k} = predColors{color_k}{1};
        else
            [~,max_posterior_idx] = max(predPosterior,[],'all','linear');
            [row,~] = ind2sub(size(predPosterior),max_posterior_idx);          
            centroidLocs{color_k} = centroidLocs{color_k}(row,:);
            props{color_k} = props{color_k}(row,:);
            predColors{color_k} = predColors{color_k}{row};
        end
    end
end
end
