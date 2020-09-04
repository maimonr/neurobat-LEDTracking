function [centroidLocs, predColors, props, predPosterior, predLab, t2] = batch_process_LED_tracking(videoDir)

video_fNames = dir(fullfile(videoDir,'*.mp4'));
nVideo = length(video_fNames);

%ROIIdx(1,:) = [35 1060 80 1420];
ROIIdx(1,:) = [35 810 300 1420]; % for fisheye correction  

s = load('color_prediction_model_august');
color_pred_model = s.color_pred_model;

fisheyeModel = load('fisheye_model.mat'); 
cameraParams = fisheyeModel.cameraParams; % not needed, but...

lightsTh = exp(16.5); % threshold for excluding frames that the room lights were on 
FramesWith_LightsOn = 0;  

[centroidLocs, predColors, props, predPosterior,predLab] = deal(cell(1,nVideo));
t2 = zeros(1,nVideo);
parfor video_k = 1:nVideo
    v = VideoReader(fullfile(video_fNames(video_k).folder,video_fNames(video_k).name));
    t = tic;
    [centroidLocs{video_k}, predColors{video_k}, props{video_k}, predPosterior{video_k}] = deal(cell(1,v.NumFrames ));
    for frame_k = 1:v.NumFrames
        f = readFrame(v);
        if sum(f,'all') < lightsTh 
            f = undistortFisheyeImage(f, cameraParams.Intrinsics);
        [centroidLocs{video_k}{frame_k}, predColors{video_k}{frame_k}, props{video_k}{frame_k}, predPosterior{video_k}{frame_k},predLab{video_k}{frame_k}] =...
            predict_LED_location(f,'ROI',ROIIdx,'color_pred_model',color_pred_model);
             
        else 
            FramesWith_LightsOn(video_k) = FramesWith_LightsOn+1 
        end 
    end
        t2(video_k) = toc(t);
    fprintf('%d / %d videos processed, %d s elapsed for this video\n',video_k,nVideo,t2(video_k));
end

end