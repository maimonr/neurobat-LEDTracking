function [centroidLocs, predColors, props, predPosterior] = track_LED_location_movie(baseDir,video_fName)
v = VideoReader(fullfile(baseDir,video_fName));
frame_k = 1;
nFrame = ceil(v.frameRate*v.Duration);
[centroidLocs, predColors, props, predPosterior] = deal(cell(1,nFrame));
ROIIdx = [1 1000 22 1380];
s = load('color_prediction_model');
color_pred_model = s.color_pred_model;
waitF = waitbar(0,'Initializing');
t = tic;
while hasFrame(v) && frame_k 
    f = readFrame(v);
    [centroidLocs{frame_k}, predColors{frame_k}, props{frame_k}, predPosterior{frame_k}] = predict_LED_location(f,'ROI',ROIIdx,'color_pred_model',color_pred_model);
    waitbar(frame_k/nFrame,waitF,sprintf('Processing Video %d',round(toc(t))))
    frame_k = frame_k + 1;
end
close(waitF);
end