function flowrate_analysis(odor_st,epoch,arg_st)
    dataset=getfield(odor_st,epoch); %#ok<GFLD>
    rois_used=unique([dataset.roi]);
    odor_name=unique({dataset.odor});
    session_name=unique({dataset.session});
    epoch=unique({dataset.odor_pres});
    if length(odor_name)>1
        odor_name='All odors';
    else
        odor_name=char(odor_name);
    end
    fix_flow=str2double(get(arg_st.fix_flow,'String'));
    num_roi=length(rois_used);
    grid_col=ceil(sqrt(num_roi));
    grid_row=ceil(num_roi./grid_col);
    figure_name=[odor_name ' session: ' char(session_name) ' Epoch: ' char(epoch)];
    
   
    freq_limit=arg_st.freq;
    if freq_limit && freq_limit~=0
            figure_name=[ figure_name ' Freq limit = ' num2str(freq_limit) ' Hz'];
    end
    
    noise=arg_st.noise;
    if noise
            figure_name=[ figure_name ' Noise Thresholding ON'];
    end
    
    
    figure('Name',figure_name);
    
    each_sbplt=zeros(length(rois_used),2);
    export_corr(num_roi)=struct('all',[],'first',[]);
    for i=1:num_roi
        roi=rois_used(i);
        subset=dataset([dataset.roi]==roi);
        if freq_limit && freq_limit~=0
            subset=filter_breathing_freq(subset,freq_limit);
        end
        if isnan(fix_flow)
            flow_all=[subset.flow_mag];
        else
            flow_all=fix_flow;
        end

        amps_all=[subset.amplitude];
        delay_all=[subset.delay];
        risetime_all=[subset.rise_time];
        if isempty(flow_all) || isempty(amps_all)
            continue
        end
        
        
        %% what we consider to be the first sniff is really the first sniff that shows some response. I'll limit this to the first 3 sniffs however.
         
        get_firstsniff_bool=false(1,length(subset));  % vector of boolean, set to zero
        [~,first_sniff_pos,~]=unique([subset.trial_num],'first');     % getting the position in subset of the first sniff of each trial 
        get_firstsniff_bool(first_sniff_pos)=true;     % setting bools to 1 indicating first sniff of each trial
        get_firstsniff_bool([subset.sniff_num]>3)=false;    % if first sniff_num is above 3, trial is discarded.
        
        subset_firstsniff=subset(get_firstsniff_bool);
        %%
        
        if isnan(fix_flow)
            flow_first=[subset_firstsniff.flow_mag];
        else
            flow_first=fix_flow;
        end
        
        amps_first=[subset_firstsniff.amplitude];
        delay_first=[subset_firstsniff.delay];
        risetime_first=[subset_firstsniff.rise_time];
        if isempty(flow_first) || isempty(amps_first)
            continue
        end
        
        

        each_sbplt(i,1)=subplot(grid_row,grid_col,i);each_sbplt(i,2)=roi;           %creating subplots, getting the handle for each associated with roi
        hold on
        x_lim(1)=str2double(get(arg_st.xlim.low,'String'));
        x_lim(2)=str2double(get(arg_st.xlim.high,'String'));
        y_lim1(1)=str2double(get(arg_st.ylim1.low,'String'));
        y_lim1(2)=str2double(get(arg_st.ylim1.high,'String'));
        y_lim2(1)=str2double(get(arg_st.ylim2.low,'String'));
        y_lim2(2)=str2double(get(arg_st.ylim2.high,'String'));
        
        
        if get(arg_st.latency,'Value') || get(arg_st.rise,'Value')
            if ~get(arg_st.first,'Value')
                if get(arg_st.rise,'Value')
                    [ax1,h1,h2]=plotyy(flow_all,amps_all,flow_all,risetime_all);
                    set(h1,'Color','r','Marker','o','MarkerSize',3,'linestyle','None');
                    set(h2,'Color','k','Marker','+','MarkerSize',3,'linestyle','None');
                    
                end
                if get(arg_st.latency,'Value')
                    [ax2,h1,h3]=plotyy(flow_all,amps_all,flow_all,delay_all);
                    set(h1,'Color','r','Marker','o','MarkerSize',3,'linestyle','None');
                    set(h3,'Color','k','Marker','^','MarkerSize',3,'linestyle','None');
                    
                end
            end

            [ax3,h1,h2]=plotyy(flow_first,amps_first,flow_first,risetime_first);
                set(h1,'Color','b','Marker','d','MarkerSize',3,'linestyle','None');
                set(h2,'Color','g','Marker','+','MarkerSize',3,'linestyle','None');
                

            [ax4,h1,h3]=plotyy(flow_first,amps_first,flow_first,delay_first);
                set(h1,'Color','b','Marker','d','MarkerSize',3,'linestyle','None');
                set(h3,'Color','g','Marker','^','MarkerSize',3,'linestyle','None');
                

            if ~isnan(x_lim(1)) && ~isnan(x_lim(2))
                if ~get(arg_st.first,'Value')
                    if get(arg_st.rise,'Value')
                        set(ax1(1),'xlim',[x_lim(1) x_lim(2)]);
                        set(ax1(2),'xlim',[x_lim(1) x_lim(2)]);
                    end
                    if get(arg_st.latency,'Value')
                        set(ax2(1),'xlim',[x_lim(1) x_lim(2)]);
                        set(ax2(2),'xlim',[x_lim(1) x_lim(2)]);
                    end
                end
                if get(arg_st.rise,'Value')
                    set(ax3(1),'xlim',[x_lim(1) x_lim(2)]);
                    set(ax3(2),'xlim',[x_lim(1) x_lim(2)]);
                end
                if get(arg_st.latency,'Value')
                    set(ax4(2),'xlim',[x_lim(1) x_lim(2)]);
                    set(ax4(1),'xlim',[x_lim(1) x_lim(2)]);
                end
               
                
            elseif isnan(x_lim(1)) && ~isnan(x_lim(2))
                if ~get(arg_st.first,'Value')
                    if get(arg_st.rise,'Value')
                        set(ax1(1),'xlim',[0 x_lim(2)]);set(ax1(2),'xlim',[0 x_lim(2)]);
                    end
                    if get(arg_st.latency,'Value')
                        set(ax2(1),'xlim',[0 x_lim(2)]);set(ax2(2),'xlim',[0 x_lim(2)]);
                    end
                end
                if get(arg_st.rise,'Value')
                    set(ax3(1),'xlim',[0 x_lim(2)]);set(ax3(2),'xlim',[0 x_lim(2)]);
                end
                if get(arg_st.latency,'Value')
                    set(ax4(2),'xlim',[0 x_lim(2)]);set(ax4(1),'xlim',[0 x_lim(2)]);
                end
                
            else
                xaxislim=max(max(flow_all),max(flow_first));
                if isempty(xaxislim); xaxislim=1; end
%                 xlim([0 xaxislim+(xaxislim./10)]);
                
                if ~get(arg_st.first,'Value')
                    if get(arg_st.rise,'Value')
                        set(ax1(1),'xlim',[0 xaxislim+(xaxislim./10)]);set(ax1(2),'xlim',[0 xaxislim+(xaxislim./10)]);
                    end
                    if get(arg_st.latency,'Value')
                        set(ax2(1),'xlim',[0 xaxislim+(xaxislim./10)]);set(ax2(2),'xlim',[0 xaxislim+(xaxislim./10)]);
                    end
                end
                if get(arg_st.rise,'Value')
                    set(ax3(1),'xlim',[0 xaxislim+(xaxislim./10)]);set(ax3(2),'xlim',[0 xaxislim+(xaxislim./10)]);
                end
                if get(arg_st.latency,'Value')
                    set(ax4(2),'xlim',[0 xaxislim+(xaxislim./10)]);set(ax4(1),'xlim',[0 xaxislim+(xaxislim./10)]);
                end
            end

            if ~isnan(y_lim1)
                if ~get(arg_st.first,'Value')
                    if get(arg_st.rise,'Value')
                        set(ax1(1),'ylim',[y_lim1(1) y_lim1(2)]);
                    end
                    if get(arg_st.latency,'Value')
                        set(ax2(1),'ylim',[y_lim1(1) y_lim1(2)]);
                    end
                end
                if get(arg_st.rise,'Value')
                    set(ax3(1),'ylim',[y_lim1(1) y_lim1(2)]);
                end
                if get(arg_st.latency,'Value')
                    set(ax4(1),'ylim',[y_lim1(1) y_lim1(2)]);
                end
            end
            if ~isnan(y_lim2)
                if ~get(arg_st.first,'Value')
                    if get(arg_st.rise,'Value')
                        set(ax1(2),'ylim',[y_lim1(1) y_lim1(2)]);
                    end
                    if get(arg_st.latency,'Value')
                        set(ax2(2),'ylim',[y_lim1(1) y_lim1(2)]);
                    end
                end
                if get(arg_st.rise,'Value')
                    set(ax3(2),'ylim',[y_lim1(1) y_lim1(2)]);
                end
                if get(arg_st.latency,'Value')
                    set(ax4(2),'ylim',[y_lim1(1) y_lim1(2)]);
                end
            end
%             if (isnan(y_lim1) && ~isnan(y_lim2)) || (~isnan(y_lim1) && isnan(y_lim2))
%             end
            if isnan(y_lim1) & isnan(y_lim2) %#ok<AND2>
                
                if ~get(arg_st.first,'Value')
                    if get(arg_st.latency,'Value') & get(arg_st.rise,'Value')
                        upper_ylim= max([get(ax1(2),'ylim'),get(ax2(2),'ylim'),get(ax3(2),'ylim'),get(ax4(2),'ylim')]);
                    end
                    if get(arg_st.latency,'Value') 
                        upper_ylim= max([get(ax2(2),'ylim'),get(ax4(2),'ylim')]);
                    end
                    if get(arg_st.rise,'Value')
                        upper_ylim= max([get(ax1(2),'ylim'),get(ax3(2),'ylim')]);
                    end
                else
                    if get(arg_st.latency,'Value') & get(arg_st.rise,'Value')
                        upper_ylim= max([get(ax3(2),'ylim'),get(ax4(2),'ylim')]);
                    end
                    if get(arg_st.latency,'Value') & ~get(arg_st.rise,'Value')
                        upper_ylim= max([get(ax4(2),'ylim')]);
                    end
                    if ~get(arg_st.latency,'Value') & get(arg_st.rise,'Value')
                        upper_ylim= max([get(ax3(2),'ylim')]);
                    end
                    
                    
                end
                
                
                
                
                
                if ~get(arg_st.first,'Value')
                    if get(arg_st.rise,'Value')
                        set(ax1(2),'ylim',[0 upper_ylim]);
                    end
                    if get(arg_st.latency,'Value')
                        set(ax2(2),'ylim',[0 upper_ylim]);
                    end
                end
                if get(arg_st.rise,'Value')
                    set(ax3(2),'ylim',[0 upper_ylim]);
                end
                if get(arg_st.latency,'Value')
                    set(ax4(2),'ylim',[0 upper_ylim]);
                end
            end
            set(get(ax3(2),'Ylabel'),'string','Delay (sec)');
        else 
            plot(flow_all,amps_all,'or','MarkerSize',3);
            
            plot(flow_first,amps_first,'db','MarkerSize',3);
            if ~isnan(x_lim(1)) && ~isnan(x_lim(2))
                xlim([x_lim(1) x_lim(2)]);
            elseif isnan(x_lim(1)) && ~isnan(x_lim(2))
                xlim([0 x_lim(2)])
            else
                xaxislim=max(max(flow_all),max(flow_first));
                if isempty(xaxislim); xaxislim=1; end
                xlim([0 xaxislim+(xaxislim./10)]);
            end

            if ~isnan(y_lim1(1)) && ~isnan(y_lim1(2))
                ylim([y_lim1(1) y_lim1(2)]);
            end
        end
            
        xlabel('flowrate');ylabel('Response (DF/F)');
%         legend('amplitude_all','amplitude_first')
        
        
        if isnan(fix_flow)
            if ~get(arg_st.first,'Value')
                [cor_all,p_all]=corr(flow_all',amps_all');
                all=[' A: ' num2str(cor_all) ' p: ' num2str(p_all)];
                export_corr(i).all.corr=cor_all;
                export_corr(i).all.p_val=p_all;
            else
                p_all=1;
                all='';
            end
                
            [cor_first,p_first]=corr(flow_first',amps_first');
            export_corr(i).first.corr=cor_first;
            export_corr(i).first.p_val=p_first;
            
            first=[' F: ' num2str(cor_first) ' p: ' num2str(p_first)];
            if p_all<=0.05 || p_first<=0.05
                title_col='r';
            else
                title_col='k';
            end
        else
            all='';first='';
            title_col='k';
        end

        
        title(['ROI: ' num2str(roi) all first],'Color',title_col);
        %disp(['First sniffs, ROI: ' num2str(roi)]);
      
    end
    assignin('base','corr_matrix',export_corr);
    
    dcm_obj=datacursormode(gcf);
    set(dcm_obj,'UpdateFcn',@give_data);
    
    
    function filt_subset=filter_breathing_freq(subset,br_frq)
        time_diff=1./br_frq;
        start_time=[subset.start];
        filt_subset=subset(find(start_time(2:end)-start_time(1:end-1) >= time_diff)); %#ok<FNDSB>
    end

    function output_text=give_data(~,event_obj)
        pos=event_obj.Position;
        this_roi=each_sbplt(each_sbplt(:,1)==gca,2);
        point_data=dataset([dataset.flow_mag]==pos(1) & [dataset.amplitude]==pos(2) & [dataset.roi]==this_roi);
        disp(point_data)
        output_text=char(point_data.trial_name);
        
    end
    
    datacursormode on


end