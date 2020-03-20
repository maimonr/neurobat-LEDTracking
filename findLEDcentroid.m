function [centroidLocs,props,labelIm] = findLEDcentroid(bw,varargin)

pnames = {'mergeThresh','connectivity'};
dflts  = {[],8};
[mergeThresh,conn] = internal.stats.parseArgs(pnames,dflts,varargin{:});

labelIm = bwlabel(bw,conn); % find connected regions (everything that is near a pixl (8 options))
props = regionprops(logical(labelIm)); % regionprops is the function that gives us centorides and such
centroidLocs = round(vertcat(props.Centroid)); % store centroids for use using cat function to put them together. also round them as they represent a pixel

% merge close by centrodis
if size(centroidLocs,1) > 1 && ~isempty(mergeThresh)
    [centroidLocs,props,labelIm]  = mergeCentroids(labelIm,mergeThresh);
    usedIdx = ~all(isnan(centroidLocs),2);
    centroidLocs = centroidLocs(usedIdx,:);
    props = props(usedIdx);
end

end

function [centroidLocs,props,labelIm] = mergeCentroids(labelIm,mergeThresh)

props = regionprops(labelIm); % regionprops is the function that gives us centorides and such
centroidLocs = round(vertcat(props.Centroid)); % store centroids for use using cat function to put them together. also round them as they represent a pixel

D = pdist(centroidLocs);
D = squareform(D);

mergeIdx = D < mergeThresh;
mergeIdx(logical(eye(size(mergeIdx)))) = false;
[row,col] = find(mergeIdx);

if ~isempty(row)
    mergePairs = [row col];
    mergePairs = sort(mergePairs,2);
    mergePairs = unique(mergePairs,'rows');
    
    n_merge_pairs = size(mergePairs,1);
    mergeDist = zeros(1,n_merge_pairs);
    for pair_k = 1:n_merge_pairs
        mergeDist(pair_k) = D(mergePairs(pair_k,1),mergePairs(pair_k,2));
    end
    
    [~,min_dist_idx] = min(mergeDist);
    min_dist_pair = mergePairs(min_dist_idx,:);
    labelIm(labelIm == min_dist_pair(2)) = min_dist_pair(1);
    
    [centroidLocs,props,labelIm] = mergeCentroids(labelIm,mergeThresh);
    
else
    return
end

end