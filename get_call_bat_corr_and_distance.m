function [callCorr, callDist] = get_call_bat_corr_and_distance(bat_pair_corr_info,call_bat_pos_info,all_bat_nums,included_call_type,callType)
if isnumeric(all_bat_nums)
    all_bat_nums = cellfun(@num2str,num2cell(all_bat_nums),'un',0);
end
corr_k = arrayfun(@(x) strcmp(x.includedCalls,included_call_type) & strcmp(x.callType,callType),bat_pair_corr_info);
f_k = 3;
nCalls = length(bat_pair_corr_info(corr_k).all_included_call_nums);
callIDs = [call_bat_pos_info.callNums];
calling_bat_nums = cell(1,nCalls);
batPairs = bat_pair_corr_info(corr_k).all_bat_pairs;
nPair = size(batPairs,1);
[callCorr,callDist] = deal(cell(1,nCalls));
t_idx = 8:12;
for call_k = 1:nCalls
    current_call_nums = bat_pair_corr_info(corr_k).all_included_call_nums{call_k};
    callIdx = ismember(callIDs,current_call_nums);
    current_calling_bat_nums = {call_bat_pos_info(callIdx).batNums};
    multi_bat_idx = cellfun(@iscell,current_calling_bat_nums);
    calling_bat_nums{call_k} = unique([current_calling_bat_nums{multi_bat_idx} current_calling_bat_nums(~multi_bat_idx)]);
    n_calling_bats = length(calling_bat_nums{call_k});
    
    callCorr{call_k} = nan(1,nPair);
    callDist{call_k} = nan(n_calling_bats,nPair);
    
    if any(strcmp(calling_bat_nums{call_k},'unidentified'))
        continue
    end
    
    switch included_call_type
        case 'either_included'
            bat_pair_idx = any(ismember(batPairs,calling_bat_nums{call_k}),2);
        case 'neither_included'
            bat_pair_idx = ~any(ismember(batPairs,calling_bat_nums{call_k}),2);
    end
    
    callCorr{call_k}(bat_pair_idx) = squeeze(nanmean(bat_pair_corr_info(corr_k).bat_pair_corr(call_k,bat_pair_idx,f_k,t_idx),4));
    call_bat_pos = nanmean(cat(3,call_bat_pos_info(callIdx).pos),3);
    
    for call_bat_k = 1:n_calling_bats
        
        calling_bat_num = calling_bat_nums{call_k}(call_bat_k);
        calling_bat_idx = strcmp(all_bat_nums,calling_bat_num);
        for bat_pair_k = find(bat_pair_idx)'
            listening_bat_num = setdiff(batPairs(bat_pair_k,:),calling_bat_num);
            listening_bat_idx = ismember(all_bat_nums,listening_bat_num);
            callDist{call_k}(call_bat_k,bat_pair_k) = nanmean(vecnorm(call_bat_pos(:,listening_bat_idx) - call_bat_pos(:,calling_bat_idx)));
        end
        
    end
    
    callDist{call_k} = nanmean(callDist{call_k},1);
end