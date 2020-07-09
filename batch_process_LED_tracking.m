function [centroidLocs, predColors, props, predPosterior, t2] = batch_process_LED_tracking(videoDir)

video_fNames = dir(fullfile(videoDir,'*.mp4'));
nVideo = length(video_fNames);

ROIIdx(1,:) = [35 1060 80 1420];
s = load('color_prediction_model');
color_pred_model = s.color_pred_model;

[centroidLocs, predColors, props, predPosterior] = deal(cell(1,nVideo));
t2 = zeros(1,nVideo);
parfor video_k = 1:nVideo
    v = VideoReader(fullfile(video_fNames(video_k).folder,video_fNames(video_k).name));
    t = tic;
    [centroidLocs{video_k}, predColors{video_k}, props{video_k}, predPosterior{video_k}] = deal(cell(1,v.NumFrames ));
    for frame_k = 1:v.NumFrames
        f = readFrame(v);
        [centroidLocs{video_k}{frame_k}, predColors{video_k}{frame_k}, props{video_k}{frame_k}, predPosterior{video_k}{frame_k}] =...
            predict_LED_location(f,'ROI',ROIIdx,'color_pred_model',color_pred_model);
    end
    t2(video_k) = toc(t);
    fprintf('%d / %d videos processed, %d s elapsed for this video\n',video_k,nVideo,t2(video_k));
end

end