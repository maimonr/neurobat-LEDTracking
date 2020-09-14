function [callCorr, callDist] = get_call_bat_corr_and_distance(bat_pair_corr_info,call_bat_pos_info,all_bat_nums,included_call_type)
if isnumeric(all_bat_nums)
    all_bat_nums = cellfun(@num2str,num2cell(all_bat_nums),'un',0);
end
corr_k = strcmp({bat_pair_corr_info.includedCalls},included_call_type);
f_k = 3;
nCalls = length(bat_pair_corr_info(corr_k).all_included_call_nums);
callIDs = [call_bat_pos_info.callNums];
calling_bat_nums = cell(1,nCalls);
batPairs = bat_pair_corr_info(corr_k).all_bat_pairs;
nPairs = size(batPairs,1);
[callCorr,callDist] = deal(cell(1,nCalls));
for call_k = 1:nCalls
    current_call_nums = bat_pair_corr_info(corr_k).all_included_call_nums{call_k};
    callIdx = ismember(callIDs,current_call_nums);
    current_calling_bat_nums = {call_bat_pos_info(callIdx).batNums};
    multi_bat_idx = cellfun(@iscell,current_calling_bat_nums);
    calling_bat_nums{call_k} = unique([current_calling_bat_nums{multi_bat_idx} current_calling_bat_nums(~multi_bat_idx)]);
    
    if any(strcmp(calling_bat_nums{call_k},'unidentified'))
        continue
    end
    
    n_calling_bats = length(calling_bat_nums{call_k});
    
    switch included_call_type
        case 'either_included'
            bat_pair_idx = any(ismember(batPairs,calling_bat_nums{call_k}),2);
        case 'neither_included'
            bat_pair_idx = ~any(ismember(batPairs,calling_bat_nums{call_k}),2);
    end
    
    callCorr{call_k} = squeeze(bat_pair_corr_info(corr_k).bat_pair_corr(call_k,bat_pair_idx,f_k,:));
    
    used_bat_pairs = batPairs(bat_pair_idx,:);
    n_used_bat_pairs = sum(bat_pair_idx);
    call_bat_pos = nanmean(cat(3,call_bat_pos_info(callIdx).pos),3);
    callDist{call_k} = nan(n_used_bat_pairs,n_calling_bats);
    
    for call_bat_k = 1:n_calling_bats
        
        calling_bat_num = calling_bat_nums{call_k}(call_bat_k);
        calling_bat_idx = strcmp(all_bat_nums,calling_bat_num);
        
        for bat_pair_k = 1:n_used_bat_pairs
            listening_bat_num = setdiff(used_bat_pairs(bat_pair_k,:),calling_bat_num);
            listening_bat_idx = ismember(all_bat_nums,listening_bat_num);
            callDist{call_k}(bat_pair_k,call_bat_k) = nanmean(vecnorm(call_bat_pos(:,listening_bat_idx) - call_bat_pos(:,calling_bat_idx)));
        end
        
    end
    
    callDist{call_k} = nanmean(callDist{call_k},2)';
    
    
    
end