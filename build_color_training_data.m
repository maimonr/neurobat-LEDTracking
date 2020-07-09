function trainingTable = build_color_training_data(gTruth)
v = VideoReader(gTruth.DataSource.Source);
varNames = gTruth.LabelData.Properties.VariableNames;
trainingData= cell(size(gTruth.LabelData));
frame_k = 1;
minLum = 10;
f = waitbar(0,'processing video');
while hasFrame(v)
    f = readFrame(v);
    for color_k = 1:length(varNames)
        if ~isempty(gTruth.LabelData{frame_k,color_k}{1})
            coords = round(mean(gTruth.LabelData{frame_k,color_k}{1},1));
            roiIdx = {coords(1):coords(1)+coords(3);coords(2):coords(2)+coords(4)};
            trainingData{frame_k,color_k} = f(roiIdx{2},roiIdx{1},:);
        end
    end
    waitbar(frame_k/size(trainingData,1));
    frame_k = frame_k + 1;
end

idx = ~cellfun(@isempty,trainingData);
trainingData_lab = cell(size(trainingData));
trainingData_lab(idx) = cellfun(@rgb2lab,trainingData(idx),'UniformOutput',false);
trainingData_lab_thresh = cell(size(trainingData));
for k = find(idx)'
    frameData = reshape(trainingData_lab{k},[],3);
    trainingData_lab_thresh{k} = frameData(frameData(:,1) > minLum,2:3);
end

color_training_label = {};
color_training_mat = [];
for color_k = 1:size(trainingData,2)
    color_training_data = cellfun(@(x) median(x,1),trainingData_lab_thresh(:,color_k),'un',0);
    idx = ~cellfun(@isempty,color_training_data);
    color_training_mat = [color_training_mat; vertcat(color_training_data{idx})];
    color_training_label = [color_training_label;repmat(varNames(color_k),sum(idx),1)];
end

trainingData = [num2cell(color_training_mat) color_training_label];
trainingTable = cell2table(trainingData,'VariableNames',{'a','b','color'});
end