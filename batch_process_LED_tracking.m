function LEDTracks = batch_process_LED_tracking(videoDir,LEDtrackingParams,cameraParams,color_pred_model,sessionType)

video_fNames = dir(fullfile(videoDir,'*.mp4'));
nVideo = length(video_fNames);

lightsTh = exp(16.5); % threshold for excluding frames that the room lights were on

[centroidLocs, predColors, props, predPosterior, predLab, file_frame_number, fileIdx] = deal(cell(1,nVideo));

parfor video_k = 1:nVideo
    try
        v = VideoReader(fullfile(video_fNames(video_k).folder,video_fNames(video_k).name)); %#ok<TNMLP>
    catch err
        if strcmp(err.identifier,'MATLAB:audiovideo:VideoReader:InitializationFailed')
            continue
        else
            rethrow(err)
        end
    end
        
    nFrame = v.NumFrames;
    [centroidLocs{video_k}, predColors{video_k}, props{video_k}, predPosterior{video_k}, predLab{video_k}] = deal(cell(1,nFrame));
    file_frame_number{video_k} = 1:nFrame;
    fileIdx{video_k} = video_k*ones(1,nFrame);
    for frame_k = 1:nFrame
        f = readFrame(v);
        if sum(f,'all') < lightsTh
            
            %f = undistortFisheyeImage(f, cameraParams.Intrinsics);
            [centroidLocs{video_k}{frame_k}, predColors{video_k}{frame_k}, props{video_k}{frame_k}, predPosterior{video_k}{frame_k},predLab{video_k}{frame_k}] =...
                predict_LED_location(f,'color_pred_model',color_pred_model,'params',LEDtrackingParams,'sessionType',sessionType);
        else
            [centroidLocs{video_k}{frame_k}, predColors{video_k}{frame_k}, props{video_k}{frame_k}, predPosterior{video_k}{frame_k},predLab{video_k}{frame_k}] = deal(NaN);
        end
    end
    fprintf('%d / %d videos processed\n',video_k,nVideo);
end

centroidLocs = [centroidLocs{:}];
predColors = [predColors{:}];
props = [props{:}];
predPosterior = [predPosterior{:}];
predLab = [predLab{:}];
file_frame_number = [file_frame_number{:}];
fileIdx = [fileIdx{:}];

LEDTracks = struct('centroidLocs', {centroidLocs}, 'predColors', {predColors},...
    'props', {props}, 'predPosterior', {predPosterior}, 'predLab', {predLab},...
    'video_fNames', video_fNames, 'cameraParams', cameraParams,...
    'color_pred_model', color_pred_model,'lightsTh', lightsTh,...
    'LEDtrackingParams', LEDtrackingParams,'fileIdx', fileIdx,...
    'file_frame_number', file_frame_number); 

end