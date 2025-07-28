function flowrate_across_trials(olf)


    dataset=getfield(olf,'trials');
    
    mes=[dataset.measurement];
    det=[dataset.detail];
    
    odors=unique({det.odorant_name});
    figure;
    subplot(211);
    hold on;
    stat=zeros(length(mes),2);
    for i=1:length(mes)
        timestamp=dataset(i).timestamp;
        flow=mes(i).flowrate(:,5);
        sniff_bound=mes(i).flowrate(:,1:2);
        onset=mes(i).odor_onoff.odor_onset;
        offset=mes(i).odor_onoff.odor_offset;
        flow_during=flow(sniff_bound(:,1)>=onset & sniff_bound(:,2)<=offset);
        ts=repmat(timestamp,length(flow_during),1);
        plot(ts,flow_during,'.k')
        stat(i,:)=[ mean(flow_during) std(flow_during)];
    end

    tsvec=[dataset.timestamp];
    plot(tsvec,stat(:,1),'s','MarkerSize',8,'MarkerFaceColor','y','MarkerEdgeColor','r');
    errorbar(tsvec,stat(:,1),stat(:,2),'.r');
    xlabel('trial');
    ylabel('flowrate (der)');
    title('all odors, during presentation');
    
    subplot(212);
    hold on
    col_all=zeros(length(odors),3);
    for n=1:length(odors)
        col=[ rand rand rand];
        col_all(n,:)=col;
        odor=odors(n);
        subdataset=dataset(strcmp({det.odorant_name},odor));
        submes=[subdataset.measurement];
        stat=zeros(length(submes),2);
        for i=1:length(submes)
            timestamp=subdataset(i).timestamp;
            flow=submes(i).flowrate(:,5);
            sniff_bound=submes(i).flowrate(:,1:2);
            onset=submes(i).odor_onoff.odor_onset;
            offset=submes(i).odor_onoff.odor_offset;
            flow_during=flow(sniff_bound(:,1)>=onset & sniff_bound(:,2)<=offset);
            ts=repmat(timestamp,length(flow_during),1);
            plot(ts,flow_during,'*','Color',col)
            stat(i,:)=[ mean(flow_during) std(flow_during)];
        end
        tsvec=[subdataset.timestamp];
        plot(tsvec,stat(:,1),'s','MarkerSize',8,'MarkerFaceColor',col,'MarkerEdgeColor','r');
        errorbar(tsvec,stat(:,1),stat(:,2),'.','Color',col);
    end
    
    [~,hobj,~,~]=legend(odors);                                 %this legend function is crappy so i have to set the right colors using object handles. Lame!!
    hobj=hobj(length(odors)+1:end);
    for i=1:length(odors)
        set(hobj(2*i),'Color',col_all(i,:));
    end
    xlabel('trial');
    ylabel('flowrate (der)');
    title('all odors, during presentation');
    
    
    
end