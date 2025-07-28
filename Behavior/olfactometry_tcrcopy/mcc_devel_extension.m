function mcc_devel_extension(interface)

    interface.add(extract_traces(interface.getBlankInitializer()))
    interface.add(count(interface.getBlankInitializer()))
    interface.add(concat(interface.getBlankInitializer()))
    
     function init = count(init)
	        init.uid = 'count_traces';
	        init.name = 'count';
	        init.group = 'Scripts';
    		init.type = 'script';
            init.onExecute = @countTrace;
%            init.onRightClick = @rightClick;
%	        init.onDrawView = @run_pull_traces;

         function countTrace
                t = interface.getSelectedItems();
                assignin('base','count',length(t));
         end

     end
 
      function init = concat(init)
	        init.uid = 'concat_traces';
	        init.name = 'Concatenate';
	        init.group = 'Scripts';
    		init.type = 'script';
            init.onExecute = @concatTrace;
%            init.onRightClick = @rightClick;


         function concatTrace
            o = interface.getOlfact();
            t = interface.getSelectedItems();
            pressureCatted = [];
            commandCatted = [];
            thermocoupleCatted = [];
                 for l = 1:length(t)
                        pressureCatted = horzcat(pressureCatted,o.trials(t(l)).other.sniff_pressure);
                        commandCatted = horzcat(commandCatted,o.trials(t(l)).other.sniff_control);
                        thermocoupleCatted = horzcat(thermocoupleCatted,o.trials(t(l)).other.sniff_thermocouple);
                 end
            nextPres = availablename('pres_catted');    
            nextComm = availablename('comm_catted');                 
            nextThrm = availablename('thrm_catted');     
            assignin('base', nextPres, pressureCatted);
            assignin('base', nextComm, commandCatted);
            assignin('base', nextThrm, thermocoupleCatted);
         end

     end
    
    
	 function init = extract_traces(init)
	        init.uid = 'extract_traces';
	        init.name = 'Extract Traces';
	        init.group = 'Scripts';
    		init.type = 'script';
            init.onExecute = @getTrace;
            init.onRightClick = @rightClick;
%	        init.onDrawView = @run_pull_traces;

         show_exportCommand = false;
         show_exportPressure = false;
         show_exportThermo = false;
         show_exportSyringe = false;
         show_exportAvg = false;
         show_firstderiv = false;
         show_invert = false;
         show_runbp = false;
         
         function getTrace
            o = interface.getOlfact();
            t = interface.getSelectedItems();
            fil = [0.5 25 0];
            if show_runbp
               fil = run_bp();
            end
           if show_exportAvg == 0            
                for l = 1:length(t)

                        trial = o.trials(t(l));
                        sr = trial.other.samplingrate;
                        trNum = int2str(t(l));
                        if show_exportCommand
                            %assignin('base',['comm' trNum],trial.other.sniff_control);
                           
                               % assignin('base',['diffcomm' trNum],((diff(trial.other.sniff_control))/(1/sr)));
                               namevar = returnName(t(l), 'comm', trNum);
                               sendarr(trial.other.sniff_control,t, 0, (namevar),show_firstderiv,show_invert,fil(1), fil(2),show_runbp,sr);
                            
                            
                        end
                        if show_exportPressure
                            %assignin('base',['pres' trNum],trial.other.sniff_pressure);
                            namevar = returnName(t(l), 'pres', trNum);
                            sendarr(trial.other.sniff_pressure,t, 0, (namevar),show_firstderiv,show_invert,fil(1), fil(2),show_runbp,sr);                            
                        end
                        if show_exportThermo
                            %assignin('base',['thrm' trNum],trial.other.sniff_thermocouple);
                            namevar = returnName(t(l), 'thrm', trNum);                            
                            sendarr(trial.other.sniff_thermocouple,t, 0, (namevar),show_firstderiv,show_invert,fil(1), fil(2),show_runbp,sr);
                        end
                        if show_exportSyringe
                            %assignin('base',['syrn' trNum],trial.other.sniff_syringe_pressure);
                             namevar = returnName(t(l), 'syrn', trNum);                            
                            sendarr(trial.other.sniff_syringe_pressure,t, 0, (namevar),show_firstderiv,show_invert,fil(1),fil(2),show_runbp,sr);
                        end

                end
           else 
                avgTraces(o, t, show_firstderiv,show_invert,fil(1), fil(2), show_runbp);
           end
            
           end

         function avgTraces(o, t, deriv,invert,lc,hc,runfil)
            outArrayp=[];
            outArrayt=[];
            outArrays=[];
            lgth = length(o.trials(t(1)).other.sniff_control);
            sr = o.trials(t(1)).other.samplingrate;
            temp = zeros(1,lgth);
            
            for l = 1:length(t)
                trial = o.trials(t(l)).other.sniff_control;
                if length(trial) < lgth
                    lgth = length(trial);
                end
            end
            
            for m = 1:length(t)
                if show_exportPressure
                    outArrayp = process(o,t,m,outArrayp,'sniff_pressure');
                      if m == length(t)
                          nomen = availablename('avg_pres');
                          sendarr(outArrayp,t, 1, (nomen),deriv,invert,lc,hc,runfil,sr);
                      end
                end

                if show_exportThermo
                    outArrayt = process(o,t,m,outArrayt,'sniff_thermocouple');
                      if m == length(t)
                          nomen = availablename('avg_thrm');
                          sendarr(outArrayt,t, 1, (nomen),deriv,invert,lc,hc,runfil,sr);
                      end                    
                end

                if show_exportSyringe
                    outArrays = process(o,t,m,outArrays,'sniff_syringe_pressure');
                      if m == length(t)
                          nomen = availablename('avg_syrn');                          
                          sendarr(outArrays,t, 1, (nomen),deriv,invert,lc,hc,runfil,sr);
                      end
                end    
            end


             function outArray = process(o,t,m,outArray,y)
                   temp = o.trials(t(m)).other.(y);
                   temp = temp(1:lgth);
                   outArray = cat(1,outArray,temp);
             end




         end
             function nomen = returnName(tr,nom,trNum)
                 if tr < 10
                   nomen=[nom '00' trNum];
                 elseif tr<100
                       nomen=[nom '0' trNum];
                 else
                   nomen=[nom trNum];
                 end
             end
             
            
             
             function params =  run_bp(varargin)
                 if show_runbp
                      dialog = input_dialog('Set filter parameters',{'Input lowcut (-1 to turn off)', 'Input highcut(-1 to turn off)'}, {'0.5', '15'}, 200);
                      lowcut = str2double(dialog{1});
                      highcut = str2double(dialog{2});
                      
                      params = [lowcut, highcut];
                 end
             end
            
             function sendarr(i,t,avg,z,deriv,invert,lc,hc,runfil,sr)
                        if invert
                           i = -i;
                        end
                        if avg == 1
                           i = sum(i);
                           i = i/length(t);
                        end                        
                        if runfil == true 
                           if hc ~= -1
                            i = lpf(i,sr,2,hc);
                           end
                           if lc ~= -1
                            i = hpf(i,sr,2,lc);
                           end
                        end

                        
                       

                        if deriv 
                           assignin('base',['diff' z],(diff(i))/(1/sr));
                        else
                           assignin('base',z,i);  
                        end
             end
               
         
         
         
         function rightClick(menu)
            uimenu(menu, 'Label',  'About', 'Callback', @show_about);
            
            if show_runbp
                checked_runbp = 'on';
            else
                checked_runbp = 'off';
            end
            uimenu(menu, 'Label',  'Run filter?', 'Checked', checked_runbp, 'Callback', @toggle_runbp);
            
            if show_exportAvg
                checkedAvg = 'on';
            else
                checkedAvg = 'off';
            end
            uimenu(menu, 'Label',  'Average Traces?', 'Checked', checkedAvg, 'Callback', @toggle_average);

            if show_invert
                checkedInvert = 'on';
            else
                checkedInvert = 'off';
            end
            uimenu(menu, 'Label',  'Invert?', 'Checked', checkedInvert, 'Callback', @toggle_invert);
            if show_firstderiv
                checkeddiff = 'on';
            else
                checkeddiff = 'off';
            end
            uimenu(menu, 'Label',  'Take first derivative?', 'Checked', checkeddiff, 'Callback', @toggle_diff);            
            
            if show_exportCommand
                checkedCommand = 'on';
            else
                checkedCommand = 'off';
            end
            
            uimenu(menu, 'Label',  'Command', 'Checked', checkedCommand, 'Callback', @toggle_command);
            if show_exportPressure
                checkedPressure = 'on';
            else
                checkedPressure = 'off';
            end
            
            uimenu(menu, 'Label',  'Pressure', 'Checked', checkedPressure, 'Callback', @toggle_pressure);
            if show_exportThermo
                checkedThermo = 'on';
            else
                checkedThermo = 'off';
            end
            uimenu(menu, 'Label',  'Thermocouple', 'Checked', checkedThermo, 'Callback', @toggle_thermo);
            if show_exportSyringe
                checkedSyringe = 'on';
            else
                checkedSyringe = 'off';
            end
            uimenu(menu, 'Label',  'Syringe', 'Checked', checkedSyringe, 'Callback', @toggle_syringe);
            
            %uimenu(menu, 'Label', 'Command', 'Pressure', 'Thermocouple', 'Syringe/vacuum', 'Checked', checked, 'Callback', @toggle_show_text_labels)
            set(menu,'Visible','on')
            
            function show_about(varargin)
                msgbox({'Works for artificial sniff files (.ofd) only (so far).','Sorry.','',...
                    'Sends individual, multiple, or averaged traces from selected trials into workspace.',...
                    'There are options for filtering, differentiating, and inverting single, multiple, or averaged traces.',...
                    '','MCC','28 February 2008'}, 'Extract Traces Scripts')
            end
            
             function toggle_runbp(varargin)
                 show_runbp = ~show_runbp;
             end
            
            function toggle_command(varargin)
              show_exportCommand = ~show_exportCommand;  
            end
            
             function toggle_invert(varargin)
                 show_invert = ~show_invert;
             end
            
             function toggle_diff(varargin)
                 show_firstderiv = ~show_firstderiv;

             end
             

             
            function toggle_average(varargin)
              show_exportAvg = ~show_exportAvg;  
            end
             function toggle_pressure(varargin)
                show_exportPressure = ~show_exportPressure;
             end
             
             function toggle_thermo(varargin)
                show_exportThermo = ~show_exportThermo;
             end
             
             function toggle_syringe(varargin)
                 show_exportSyringe = ~show_exportSyringe;
             end
             

         end
     end
 
 
 
            function nextname = availablename(nom)
                %find next available 'nom#'

                suffix = '';
                counter = 0;

                
                while evalin('base', ['exist(''' nom suffix ''',''var'')'])
                    counter = counter + 1;
                    suffix = int2str(counter);
                end
                nextname = [nom suffix];

            end 
end