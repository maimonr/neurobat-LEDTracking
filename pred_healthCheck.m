
function [Predcition_HealthCheck] = pred_healthCheck(centroidLocs,predColors,predPosterior,props,videoDir,varargin) 
% This function is still being made ready. its not for use Maimon!  


%This function cacl. estimaitons for the preformance of the LED prediction from a given day 
%INPUTS: 
% (1) centroidLocs,predColors,predPosterior,props: the results of
% predict_LED_predict. 
% (2) model: the prediction model object, loaded to the predict_LED. needed for getting meta data on the prediction.     
% (3) plot: optional plotting of the resutls. displayed on if 'ture'.  % (4) JumpTh: pixel 
% ...
% OUTPUTS: 

pnames = {'model','plot','JumpTh'};
dflts  = {[];'true',15};
[plot,JumpTh] = internal.stats.parseArgs(pnames,dflts,varargin{:});

% prepare some things:
color_names = color_pred_model.ClassificationSVM.ClassNames;    % should be this: {'az','ch','gr','or','rd','re','sp','vi'}' 
numberOfcolors = size(color_names,1); 
pred_more_then_once = zeros(1,8);  
Numofblobs_all =[];

% (1) Remove times when a color is predicted more then once by taking only the max posterior predcition blob. 
% also, add up the number of blobs for each frame.  
 

for MovieNum = 2:size(centroidLocs,2) 
    for frame_k = 1:size(centroidLocs{1,MovieNum},2)  
     Numofblobs(frame_k) = size(cell2mat(centroidLocs{1,MovieNum}(frame_k)),1); % just add the blobs up 
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
    Numofblobs_all = cat(2, Numofblobs_all, Numofblobs); % add blobs from this movie to other movies
end 

% (2) now, for fun, we arrange the x-y loocations over time, and calc. also how many missed frames we have for each color  
 
for MovieNum = 1:size(centroidLocs,2)   
predicted = cell2mat(Day_prediction(MovieNum));
for color_index = 1:nColor 
xP(:,color_index) = predicted(:,color_index,1);  
yP(:,color_index) = predicted(:,color_index,2);  
Number_pred(color_index) = nnz(~isnan(xP(:,color_index)));
end
xP_all = cat(1,xP_all,xP);
yP_all = cat(1,yP_all,yP);
predictedFrames = cat(1, predictedFrames,Number_pred); 
Number_pred = []; xP = []; yP = [];
end



 
%% Ploting the Plots as it were...

rgb_colors = {0 0.5 1;0.5 1 0;0 1 0;1 0.5 0;1 0 0;1 0 0.5;0 1 0.5;0.5 0 1}; % this makes sense for AgustModel. it might not if we make another...




end 