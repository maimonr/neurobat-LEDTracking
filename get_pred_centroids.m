function pred_centroids = get_pred_centroids(LEDTracks,color_pred_model)
color_names = color_pred_model.ClassificationSVM.ClassNames;
nColor = length(color_names);
centroidLocs = [LEDTracks.centroidLocs{:}];
predColors = [LEDTracks.predColors{:}];
predPosteriors = [LEDTracks.predPosterior{:}];

nFrames = length(centroidLocs);
pred_centroids = nan(nFrames,nColor,2);
for frame_k = 1:nFrames
    for color_k = 1:nColor
        current_color_idx = strcmp(predColors{frame_k},color_names{color_k});
        if sum(current_color_idx) > 1
            current_pred_posteriors = predPosteriors{frame_k}(current_color_idx,color_k);
            if length(unique(current_pred_posteriors)) == 1
                pred_centroids(frame_k,color_k,:) = NaN;
                continue
            else
                [~,pred_posterior_idx] = max(current_pred_posteriors);
                current_color_idx = find(current_color_idx);
                current_color_idx = current_color_idx(pred_posterior_idx);
            end
        elseif sum(current_color_idx) == 0
            pred_centroids(frame_k,color_k,:) = NaN;
            continue
        end
        pred_centroids(frame_k,color_k,:) = centroidLocs{frame_k}(current_color_idx,:);
    end
end