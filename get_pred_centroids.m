function pred_centroids = get_pred_centroids(LEDTracks,color_pred_model)
%% Inputs: 
% LEDTracks: results of LED tracking on an entire session (includes
% centroidLocs, predColors, and predPosterior).
% color_pred_model: classification model used to distinguish colors, used
% here as an index into the prediction posterior matrix that the model
% produces.
%% Outputs:
% pred_centroids: a [num. of frames X 2 X num. of colors] matrix of
% prediction centroid locations in X and Y for each frame and each color.

color_names = color_pred_model.ClassificationSVM.ClassNames;
nColor = length(color_names);

nFrames = length(LEDTracks.centroidLocs);
pred_centroids = nan(nFrames,2,nColor);
for frame_k = 1:nFrames
    for color_k = 1:nColor
        current_color_idx = strcmp(LEDTracks.predColors{frame_k},color_names{color_k}); % which color relative to the list used in the prediction model are we looking at?
        if sum(current_color_idx) > 1 % if the model predicted more than 1 of the same color, decide which to use
            current_pred_posteriors = LEDTracks.predPosterior{frame_k}(current_color_idx,color_k);
            if length(unique(current_pred_posteriors)) == 1 % if multiple locations have the same posterior (e.g. both at maximum posterior), we can't decide between them, discard
                pred_centroids(frame_k,:,color_k) = NaN;
                continue
            else
                [~,pred_posterior_idx] = max(current_pred_posteriors); % take the prediction with the higher posterior as the correct prediction
                current_color_idx = find(current_color_idx);
                current_color_idx = current_color_idx(pred_posterior_idx);
            end
        elseif sum(current_color_idx) == 0 % if this color isn't present in the predictin mark as NaN
            pred_centroids(frame_k,:,color_k) = NaN;
            continue
        end
        pred_centroids(frame_k,:,color_k) = LEDTracks.centroidLocs{frame_k}(current_color_idx,:);
    end
end