function [centroidLocs, predColors, props, predPosterior, t2] = track_LED_location_movie(baseDir,video_fName)
chunkSize = 500;
process_by_chunk = false;
v = VideoReader(fullfile(baseDir,video_fName));
frameChunks = unique([1:chunkSize:v.NumFrames v.NumFrames]);
nChunk = length(frameChunks)-1;

[centroidLocs, predColors, props, predPosterior] = deal(cell(1,v.NumFrames ));
ROIIdx(1,:) = [35 1060 80 1420];
s = load('color_prediction_model');
color_pred_model = s.color_pred_model;
t = tic;

if ~process_by_chunk
    for frame_k = 1:v.NumFrames
        f = readFrame(v);
        [centroidLocs{frame_k}, predColors{frame_k}, props{frame_k}, predPosterior{frame_k}] = predict_LED_location(f,'ROI',ROIIdx,'color_pred_model',color_pred_model);
    end
else
    waitF = waitbar(0,'Initializing');
    for frame_chunk_k = 1:nChunk
        frameIdx = [frameChunks(frame_chunk_k) frameChunks(frame_chunk_k+1)];
        frameChunk = read(v,frameIdx);
        for frame_k = 1:size(frameChunk,4)
            f = frameChunk(:,:,:,frame_k);
            [centroidLocs{frame_k}, predColors{frame_k}, props{frame_k}, predPosterior{frame_k}] = predict_LED_location(f,'ROI',ROIIdx,'color_pred_model',color_pred_model);
        end
        waitbar(frame_chunk_k/nChunk,waitF,sprintf('Processing Video %d s, %d%% done',round(toc(t)),round(100*frame_chunk_k/nChunk)))
    end
    close(waitF);
end

t2 = toc(t);

end