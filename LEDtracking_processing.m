function [LEDtracking_processed] =  LEDtracking_processing(RawDir) 
% description 
%%%%%%%%%%%%%%%%%%%%



% prepare some things:

load('color_pred_model_august'); 
color_names = color_pred_model_august.ClassificationSVM.ClassNames;    % should be this: {'az','ch','gr','or','rd','re','sp','vi'}' 
numberOfcolors = size(color_names,1); 
pred_more_then_once = zeros(1,8);  
Numofblobs_all =[];
Lab_all = [];
pred_centroids = zeros(1,8); 

% (1) remove duplicates in prediction 
for MovieNum = 2:size(centroidLocs,2) 
    for frame_k = 1:size(centroidLocs{1,MovieNum},2)  
        for color_k = 1:numberOfcolors 
        current_color_idx = strcmp(predColors{MovieNum}{frame_k},color_names{color_k}); 
            if sum(current_color_idx) > 1 
            pred_class_idx = strcmp(color_names,color_names(color_k,:)); 
            current_pred_posteriors = predPosterior{MovieNum}{frame_k}(current_color_idx,pred_class_idx);  
                if length(unique(current_pred_posteriors)) == 1 
                pred_centroids(frame_k,color_k,:) = NaN; 
                    continue
                else % This catches all times when we have more then one prediction of a specifc color, and usues max posterior choose one. 
                [~,pred_posterior_idx] = max(current_pred_posteriors);
                current_color_idx = find(current_color_idx);
                current_color_idx = current_color_idx(pred_posterior_idx);
                pred_more_then_once(color_k) = pred_more_then_once(color_k)+1;
                end
         elseif sum(current_color_idx) == 0
            pred_centroids(frame_k,color_k,:) = NaN;
                continue
         end
        pred_centroids(frame_k,color_k,:) = centroidLocs{MovieNum}{frame_k}(current_color_idx,:); 
        end
    end
    Day_prediction(MovieNum) = {pred_centroids};  
end 


% (2) processing of movements 
locs = cat(1,Day_prediction{:}); 
locsx = locs(:,:,1); 
locsxdiff = [nan(1,8); abs(diff(locsx))]; 
locsx_mediFilt = medfilt1(locsx,5); % rank 5 median filter, 5 is ~250ms  
locsy = locs(:,:,2); 
locsydiff = [nan(1,8); abs(diff(locsy))]; 
locsy_mediFilt = medfilt1(locsy,5); % rank 5 median filter, 5 is ~250ms  


%% some plotting may be needed 
rgb_colors = {0 0.5 1;0.5 1 0;0 1 0;1 0.5 0;1 0 0;1 0 0.5;0 1 0.5;0.5 0 1}; % this makes sense for AgustModel. it might not if we make another...

figure(1); % plot raw data of x and y 
set(gcf,'Color','white','Position',[80 80 850 550]);
for colorIdx = 1:numberOfcolors
    subplot(2,4,colorIdx)
    plot(locsx(:,colorIdx),'k'); hold on; plot(locsy(:,colorIdx),'b'); 
    title(color_names(colorIdx)); legend('x','y','Location','southwest'); 
end 
suptitle('x,y locs - Raw data');  

figure(2); % plot of diff between adjecent points on x or y in abs values 
set(gcf,'Color','white','Position',[80 80 850 550]);
for colorIdx = 1:numberOfcolors
    subplot(2,4,colorIdx)
    plot(locsxdiff(:,colorIdx),'k'); hold on; plot(locsydiff(:,colorIdx),'b'); 
    title(color_names(colorIdx)); legend('x','y','Location','southwest'); ylim([0 500]) 
end 
suptitle('x,y abs(diff)');  

figure(3); % plot of x,y after median filter
set(gcf,'Color','white','Position',[80 80 850 550]);
for colorIdx = 1:numberOfcolors
    subplot(2,4,colorIdx)
    plot(locsx_mediFilt(:,colorIdx),'k'); hold on; plot(locsy_mediFilt(:,colorIdx),'b'); 
    title(color_names(colorIdx)); legend('x','y','Location','southwest'); 
end 
suptitle('x,y after median filter');  

figure(4); 
set(gcf,'Color','white','Position',[80 80 950 550]);
for colorIdx = 1:numberOfcolors
    subplot(2,4,colorIdx)
    plot(locsx(:,colorIdx),locsy(:,colorIdx),'Color',cell2mat(rgb_colors(colorIdx,:)))
    title(color_names(colorIdx)); ylim([200 850]), xlim([410 1200])
end 

figure(5); 
set(gcf,'Color','white','Position',[80 80 1100 550]);
for colorIdx = 1:numberOfcolors
    subplot(2,4,colorIdx)
    plot(locsx_mediFilt(:,colorIdx),locsy_mediFilt(:,colorIdx),'Color',cell2mat(rgb_colors(colorIdx,:)))
    title(color_names(colorIdx)); ylim([200 850]), xlim([410 1200]); 
end 

figure(6); 
set(gcf,'Color','white','Position',[80 80 550 550]);
for colorIdx = 1:numberOfcolors
    plot(locsx_mediFilt(:,colorIdx),locsy_mediFilt(:,colorIdx),'Color',cell2mat(rgb_colors(colorIdx,:)))
    title('all colors'); ylim([200 850]), xlim([410 1200]); hold on; 
end 




