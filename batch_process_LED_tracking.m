function [centroidLocs, predColors, props, predPosterior, predLab, t2] = batch_process_LED_tracking(videoDir,LEDtrackingParams)

video_fNames = dir(fullfile(videoDir,'*.mp4'));
nVideo = length(video_fNames);

%ROIIdx(1,:) = [35 1060 80 1420];
ROIIdx(1,:) = [35 810 300 1420]; % for fisheye correction  

s = load('color_pred_model_august.mat');
color_pred_model = s.color_pred_model_august;

fisheyeModel = load('fisheye_model.mat'); 
cameraParams = fisheyeModel.cameraParams; % not needed, but...

lightsTh = exp(16.5); % threshold for excluding frames that the room lights were on 
FramesWith_LightsOn = 0;  

[centroidLocs, predColors, props, predPosterior,predLab] = deal(cell(1,nVideo));
t2 = zeros(1,nVideo);
parfor video_k = 1:nVideo
    v = VideoReader(fullfile(video_fNames(video_k).folder,video_fNames(video_k).name));
    NumFrames = round(v.FrameRate * v.Duration)-1 % this is only used for my 1min videos. for a full video delete this and replace it in the code with v.NumFrames (in 2 places)
    t = tic;
    [centroidLocs{video_k}, predColors{video_k}, props{video_k}, predPosterior{video_k}] = deal(cell(1,NumFrames ));
    for frame_k = 1: NumFrames %v.NumFrames
        f = readFrame(v);
        if sum(f,'all') < lightsTh 
            f = undistortFisheyeImage(f, cameraParams.Intrinsics);
        [centroidLocs{video_k}{frame_k}, predColors{video_k}{frame_k}, props{video_k}{frame_k}, predPosterior{video_k}{frame_k},predLab{video_k}{frame_k}] =...
            predict_LED_location(f,'ROI',ROIIdx,'color_pred_model',color_pred_model,'params',LEDtrackingParams);
             
        else 
            %FramesWith_LightsOn(video_k) = FramesWith_LightsOn+1 
        end 
    end
        t2(video_k) = toc(t);
    fprintf('%d / %d videos processed, %d s elapsed for this video\n',video_k,nVideo,t2(video_k));
end

end