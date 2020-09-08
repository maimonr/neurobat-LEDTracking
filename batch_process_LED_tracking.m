function LEDTracks = batch_process_LED_tracking(videoDir,LEDtrackingParams,cameraParams,color_pred_model)

video_fNames = dir(fullfile(videoDir,'*.mp4'));
nVideo = length(video_fNames);

lightsTh = exp(16.5); % threshold for excluding frames that the room lights were on

[centroidLocs, predColors, props, predPosterior, predLab, frameIdx, frame_file_idx] = deal(cell(1,nVideo));
t2 = zeros(1,nVideo);
parfor video_k = 1:nVideo
    v = VideoReader(fullfile(video_fNames(video_k).folder,video_fNames(video_k).name)); %#ok<TNMLP>
    t = tic;
    [centroidLocs{video_k}, predColors{video_k}, props{video_k}, predPosterior{video_k}] = deal(cell(1,NumFrames ));
    frameIdx{video_k} = 1:v.NumFrames;
    frame_file_idx{video_k} = video_k*ones(1,v.NumFrames);
    for frame_k = 1: v.NumFrames
        f = readFrame(v);
        if sum(f,'all') < lightsTh
            f = undistortFisheyeImage(f, cameraParams.Intrinsics);
            [centroidLocs{video_k}{frame_k}, predColors{video_k}{frame_k}, props{video_k}{frame_k}, predPosterior{video_k}{frame_k},predLab{video_k}{frame_k}] =...
                predict_LED_location(f,'color_pred_model',color_pred_model,'params',LEDtrackingParams);
        end
    end
    t2(video_k) = toc(t);
    fprintf('%d / %d videos processed, %d s elapsed for this video\n',video_k,nVideo,t2(video_k));
end

centroidLocs = [centroidLocs{:}];
predColors = [predColors{:}];
props = [props{:}];
predPosterior = [predPosterior{:}];
predLab = [predLab{:}];
frameIdx = [frameIdx{:}];
frame_file_idx = [frame_file_idx{:}];

LEDTracks = struct('centroidLocs', centroidLocs, 'predColors', predColors,...
    'props', props, 'predPosterior', predPosterior, 'predLab', predLab,...
    'video_fNames', video_fNames, 'cameraParams', cameraParams,...
    'color_pred_model', color_pred_model,'lightsTh', lightsTh,...
    'LEDtrackingParams', LEDtrackingParams,'frameIdx', frameIdx,...
    'frame_file_idx', frame_file_idx); 

end