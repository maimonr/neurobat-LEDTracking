n_train_frames = size(gTruth.LabelData,1);
nColor = size(gTruth.LabelData,2);
train_centroids_mat = nan(n_train_frames,nColor,2);
train_box_sizes_mat = nan(n_train_frames,nColor);
for frame_k = 1:n_train_frames
    for color_k = 1:nColor
        if ~isempty(gTruth.LabelData{frame_k,color_k}{1})
            coords = mean(gTruth.LabelData{frame_k,color_k}{1},1);
            train_centroids_mat(frame_k,color_k,:) = round([coords(1)+coords(3)/2 coords(2)+coords(4)/2]);
            train_box_sizes_mat(frame_k,color_k) = coords(3)*coords(4);
        end
    end
end

%%
nColor = size(gTruth.LabelData,2);
color_names = gTruth.LabelData.Properties.VariableNames(1:end);
pred_centroids = nan(n_train_frames,nColor,2);
for frame_k = 1:n_train_frames
    for color_k = 1:nColor
        current_color_idx = strcmp(predColors2{frame_k},color_names{color_k});
        if sum(current_color_idx) > 1
            pred_class_idx = strcmp(color_pred_model.ClassificationDiscriminant.ClassNames,color_names{color_k});
            current_pred_posteriors = predPosterior2{frame_k}(current_color_idx,pred_class_idx);
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
        pred_centroids(frame_k,color_k,:) = centroidLocs2{frame_k}(current_color_idx,:);
    end
end

%%


%%
rgb_colors = [0 0 1; 1 0.5 0; 1 0 0; 1 1 0; 0.5 1 0; 0 1 0; 0 1 0.5; 0 1 1; 0.5 0 1; 1 0 1];
cla
hold on
p1 = [];
p2 = [];
nP = 1;
v = VideoReader(gTruth.DataSource.Source);
imObj = imshow(f);
for frame_k = 1:n_train_frames
    f = readFrame(v);
    set(imObj, 'CData', f);
    hold on
%     fLabel = f;
%     for color_k = 1:length(predColors{frame_k})
%         fLabel = insertObjectAnnotation(fLabel,'circle',[centroidLocs{frame_k}(color_k,:) 10],predColors{frame_k}{color_k},'FontSize',18);
%     end
%     
%     set(imObj, 'CData', fLabel);
%     
    
    p1_current = scatter(pred_centroids(frame_k,:,1),pred_centroids(frame_k,:,2),50,rgb_colors,'o');
    p2_current = scatter(train_centroids_mat(frame_k,:,1),train_centroids_mat(frame_k,:,2),50,rgb_colors,'x');
    
    if nP < 10
        p1(nP) = p1_current;
        p2(nP) = p2_current;
        nP = nP + 1;
    else
        delete([p1(1) p2(1)]);
        p1 = [p1(2:end) p1_current];
        p2 = [p2(2:end) p2_current];
    end
    pause(0.05)
end