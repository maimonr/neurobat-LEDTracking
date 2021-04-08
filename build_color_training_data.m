function trainingTable = build_color_training_data(gTruth,varargin)

pnames = {'minLum','maxLum','ab_averaging_method'};
dflts  = {10,100,'allPixels'};
[minLum,maxLum,ab_averaging_method] = internal.stats.parseArgs(pnames,dflts,varargin{:});

v = VideoReader(gTruth.DataSource.Source);
varNames = gTruth.LabelData.Properties.VariableNames;
trainingData= cell(size(gTruth.LabelData));
frame_k = 1;

switch ab_averaging_method
    case 'median'
        lab_avg_func = @(lab) nanmedian(lab(:,2:3));
    case 'weightedMean'
        lab_avg_func = @(lab) nanmean(lab(:,2:3).*rescale(lab(:,1)));
    case 'allPixels'
        lab_avg_func = @(lab) lab(~any(isnan(lab),2),2:3);
end


waitH = waitbar(0,'processing video');

emptyLabels = cellfun(@isempty,gTruth.LabelData.Variables);
lastFrame = find(~all(emptyLabels,2),1,'last');

while hasFrame(v) && frame_k <= lastFrame
    f = readFrame(v);
    for color_k = 1:length(varNames)
        currentCoord = gTruth.LabelData{frame_k,color_k}{1};
        if ~isempty(currentCoord) && ~isstruct(currentCoord)
            coords = round(mean(currentCoord,1));
            roiIdx = {coords(1):coords(1)+coords(3);coords(2):coords(2)+coords(4)};
            trainingData{frame_k,color_k} = f(roiIdx{2},roiIdx{1},:);
        end
    end
    waitbar(frame_k/size(trainingData,1),waitH);
    frame_k = frame_k + 1;
end

idx = ~cellfun(@isempty,trainingData);
trainingData_lab = cell(size(trainingData));

trainingData_lab(idx) = cellfun(@(frame) colorspace('Lab<-rgb',im2double(frame)),trainingData(idx),'UniformOutput',false);
% trainingData_lab(idx) = cellfun(@rgb2lab,trainingData(idx),'UniformOutput',false);
% trainingData_lab(idx) = cellfun(@rgb2hsv,trainingData(idx),'UniformOutput',false);

trainingData_lab_thresh = cell(size(trainingData));
for k = find(idx)'
    trainingData_lab_thresh{k} = reshape(trainingData_lab{k},[],3);
    L = trainingData_lab_thresh{k}(:,1) ;
    lumIdx = L < minLum | L > maxLum;
    trainingData_lab_thresh{k}(lumIdx,:) = NaN;
end
%%
color_training_label = {};
color_training_mat = [];
for color_k = 1:size(trainingData,2)
    idx = ~cellfun(@isempty,trainingData_lab_thresh(:,color_k));
    color_training_data = cellfun(@(lab) lab_avg_func(lab),trainingData_lab_thresh(idx,color_k),'un',0);
    current_training_mat = vertcat(color_training_data{:});
    color_training_mat = [color_training_mat; current_training_mat];
    color_training_label = [color_training_label;repmat(varNames(color_k),size(current_training_mat,1),1)];
end

trainingData = [num2cell(color_training_mat) color_training_label];
trainingTable = cell2table(trainingData,'VariableNames',{'a','b','color'});
%%

close(waitH)
end