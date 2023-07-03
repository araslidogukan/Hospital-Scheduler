classdef Schedule < handle

    properties
        dailyPlanningHorizon
        planningDays
        numberOfRooms
        finalSchedule
    end

    methods

        function s = Schedule(dailyplanninghorizon,planningdays,numberofroom)
            %Constructor function
            s.dailyPlanningHorizon = dailyplanninghorizon;
            s.planningDays = planningdays;
            s.numberOfRooms = numberofroom;
            s.finalSchedule = [];
        end

        function constructSchedule(self,objective,filedir,outdir)
            %Inputs:
            %objective: enumarated objective type. 1,2 or 3
            %filedir: input file's directory
            %outdir: directory of excel export's

            %This method calls the corresponding scheduler function,
            %perform scheduling and reports the required metrics based on
            %the schedule. Finally exports the results to a xlsx file.
            
            if objective == 1
                [self.finalSchedule,a,utils,shifts] = self.schedule_objective_1(filedir);
                self.printSchedule(outdir,objective)
                fprintf('Number of people who did recieve a treatment on their original time: %d.\n', a)
                for u = 1:length(utils)
                    fprintf('Utilization of room %d is %f percent.\n', u, utils(u))
                end
                for s = 1:length(shifts)
                    fprintf('Number of Operations shifted in priority %d is %d.\n',s,shifts(s))
                end
            elseif objective == 2
                [self.finalSchedule,a,utils,shifts] = self.schedule_objective_2(filedir);
                self.printSchedule(outdir,objective)
                fprintf('Number of people who did recieve a treatment on their original time: %d.\n', a)
                for u = 1:length(utils)
                    fprintf('Utilization of room %d is %f percent.\n', u, utils(u))
                end
                for s = 1:length(shifts)
                    fprintf('Number of Operations shifted in priority %d is %d.\n',s,shifts(s))
                end
            elseif objective == 3
                [self.finalSchedule,a,utils,shifts,total_delay] = self.schedule_objective_3(filedir);
                self.printSchedule(outdir,objective)
                fprintf('Total minutes delayed for patients is %d.\n', total_delay)
                fprintf('Number of people who did recieve a treatment on their original time: %d.\n', a)
                for u = 1:length(utils)
                    fprintf('Utilization of room %d is %f percent.\n', u, utils(u))
                end
                for s = 1:length(shifts)
                    fprintf('Number of Operations shifted in priority %d is %d.\n',s,shifts(s))
                end
            else
                error('Please enter a valid objective enumaration')
            end
        end

        
       
        
        function [final_schedule,count,utilizations,shiftments] = schedule_objective_2(self,filedir)
            % A function using the data in filedir aiming to maximize
            % the utilization of rooms
            
            patients = readtable(filedir);
            % Get the First Priorities of patients to see whether they were
            % postponed to next day or not and store it as new column
            patients = addvars(patients,patients.Priority(:),'NewVariableNames',{'FirstPriority'});
            patients = addvars(patients,(patients.AvailableFinish(:) - patients.AvailableStart(:)) ./ patients.Duration, ...
                'NewVariableNames',{'WOD'}); %As a crucial part of this objective we calculate the width of available interval
            % and its ratio to duration for each patient and store it as a
            % new column
            
            patients = sortrows(patients,'WOD');
            % Note that Width over Duration (WOD) ratio also denotes the
            % delayability of that patient. e.g., if WOD = 1, then if any
            % single minute was used of this patient's available interval in all rooms,
            % then he/she would have been shifted certainly.
            
            schedule = zeros(self.planningDays,self.numberOfRooms,self.dailyPlanningHorizon + 1);
            % Schedule is a matrix of 1's and zero to check if someone was
            % already scheduled in a certain room at a certain minute.
            % However it is only used for this checking and nothing else
            
            final_schedule = [];
            count = 0;
            shiftments = zeros(4,1);
            
            for d = 1:self.planningDays
                for p = 0:4
                    mask = logical((patients.Day == d) .* (patients.Priority == p));
                    candidates = patients(mask,:);
                    for i = 1:size(candidates,1)
                        candidate = candidates(i,:);
                        flag = true;
                        % Set the patient object of the current person
                        sick = Patient(candidate.Name,candidate.Surname,candidate.Priority,candidate.Complexity,candidate.Day);
                        % Set the operation object and currently schedule
                        % it to 0,0 at room 0 (artificial schedule)
                        oper = Operation(candidate.ID,sick,Interval(candidate.AvailableStart,candidate.AvailableFinish), ...
                            Interval(0,0),candidate.Duration,sick.day,0);
                         
                        earliest_start = candidate.AvailableStart + 1;
                        latest_start = candidate.AvailableFinish - candidate.Duration + 2;
                        
                        for r = 1:size(schedule,2) % for number of rooms available
                            for current_start = linspace(earliest_start,latest_start,latest_start-earliest_start + 1)    
                                current_finish = current_start + oper.duration - 1; %checking for all available start times
                                current_done = min(current_finish + (candidate.Complexity-1) * 20,481);
                                if ~schedule(d,r,current_start:current_done) % if current interval is not sceduled
                                    schedule(d,r,current_start:current_finish) = 1;
                                    schedule(d,r,current_finish+1:current_done) = -1;
                                    oper.setScheduledInterval(Interval(current_start,current_finish))
                                    oper.setRoomNo(r)
                                    final_schedule = [final_schedule, oper];
                                    flag = false;
                                    if candidate.FirstPriority == candidate.Priority
                                        count = count + 1; % if that person was not shifted
                                    else
                                        shiftments(candidate.FirstPriority) = shiftments(candidate.FirstPriority) + 1;
                                    end
                                    break
                                end
                            end
                            if ~flag % if a person is fitted break the outer loop too
                                break
                            end
                        end
                        if flag && candidate.FirstPriority == candidate.Priority % If we didn't shift the person before
                            if oper.patient.getPatientPriority == 1
                                patients(patients.ID == oper.id,:).Priority = 0;
                                patients(patients.ID == oper.id,:).AvailableStart = 0;
                                patients(patients.ID == oper.id,:).AvailableFinish = oper.duration - 1;
                                patients(patients.ID == oper.id,:).Day = d + 1;
                            else
                                patients(patients.ID == oper.id,:).Priority = p - 1;
                                patients(patients.ID == oper.id,:).Day = d + 1;
                            end
                        end                           
                    end % checking all candidates
                end %priority
            end %day
            utilizations = zeros(self.numberOfRooms,1);
            for r = 1:self.numberOfRooms
                utilizations(r) = sum(schedule(:,r,:) == 1,"all");
            end
            utilizations = (utilizations / ((self.dailyPlanningHorizon + 1) * 5)) * 100 ;
        end % function

        
        
        function [final_schedule,count,utilizations,shiftments] = schedule_objective_1(self,filedir)
            % A function using the data in filedir aiming to maximize
            % the people operated in initial available time
            
            patients = readtable(filedir);
            patients = addvars(patients,patients.Priority(:),'NewVariableNames',{'FirstPriority'});
            patients = addvars(patients,patients.AvailableFinish(:)-patients.AvailableStart(:),'NewVariableNames',{'LatestStart'});
            %Adding a new column to the table to hold latest start times
            patients = sortrows(patients,'Duration');
            %We sort the table with respect to Latest Start time
            schedule = zeros(self.planningDays,self.numberOfRooms,self.dailyPlanningHorizon + 1);
            % Schedule is a matrix of 1's and zero to check if someone was
            % already scheduled in a certain room at a certain minute.
            % However it is only used for this checking and nothing alse
            
            final_schedule = [];
            count = 0;
            shiftments = zeros(4,1);
            
            for d = 1:self.planningDays
                for p = 0:4
                    mask = logical((patients.Day == d) .* (patients.Priority == p));
                    candidates = patients(mask,:);
                    for i = 1:size(candidates,1)
                        candidate = candidates(end-i+1,:);
                        % Going backwards since we sorted the data in
                        % ascending order where a descending order is
                        % needed.
                        flag = true;
                        % Set the patient object of the current person
                        sick = Patient(candidate.Name,candidate.Surname,candidate.Priority,candidate.Complexity,candidate.Day);
                        % Set the operation object and currently schedule
                        % it to 0,0 at room 0
                        oper = Operation(candidate.ID,sick,Interval(candidate.AvailableStart,candidate.AvailableFinish), ...
                            Interval(0,0),candidate.Duration,sick.day,0);
                         
                        earliest_start = candidate.AvailableStart + 1;
                        latest_start = candidate.AvailableFinish - candidate.Duration + 2;
                        
                        for r = 1:size(schedule,2) % for number of rooms available
                            for current_start = linspace(earliest_start,latest_start,latest_start-earliest_start + 1)    
                                current_finish = current_start + oper.duration - 1; %checking for all available start times
                                current_done = min(current_finish + (candidate.Complexity-1) * 20,481);
                                if ~schedule(d,r,current_start:current_done) % if current interval is not sceduled
                                    schedule(d,r,current_start:current_finish) = 1;
                                    schedule(d,r,current_finish+1:current_done) = -1;
                                    oper.setScheduledInterval(Interval(current_start,current_finish))
                                    oper.setRoomNo(r)
                                    final_schedule = [final_schedule, oper];
                                    flag = false;
                                    if candidate.FirstPriority == candidate.Priority
                                        count = count + 1; % if that person was not shifted
                                    else
                                        shiftments(candidate.FirstPriority) = shiftments(candidate.FirstPriority) + 1;
                                    end
                                    break
                                end
                            end
                            if ~flag % if a person is fitted break the outer loop too
                                break
                            end
                        end
                        if flag && candidate.FirstPriority == candidate.Priority % If we didn't shift the person before
                            if oper.patient.getPatientPriority == 1
                                patients(patients.ID == oper.id,:).Priority = 0;
                                patients(patients.ID == oper.id,:).AvailableStart = 0;
                                patients(patients.ID == oper.id,:).AvailableFinish = oper.duration - 1;
                                patients(patients.ID == oper.id,:).Day = d + 1;
                                oper.setAvailableInterval(Interval(0,oper.duration-1))
                                oper.operationDay = d + 1;
                            else
                                patients(patients.ID == oper.id,:).Priority = p - 1;
                                patients(patients.ID == oper.id,:).Day = d + 1;
                                oper.operationDay = d + 1;
                            end
                        end                           
                    end % checking all candidates
                end %priority
            end %day
            utilizations = zeros(self.numberOfRooms,1);
            for r = 1:self.numberOfRooms
                utilizations(r) = sum(schedule(:,r,:) == 1,"all");
            end
            utilizations = (utilizations / ((self.dailyPlanningHorizon + 1) * 5)) * 100 ;
        end % function


        
        function [final_schedule,count,utilizations,shiftments,total_delay] = schedule_objective_3(self,filedir)
            % A function using the data in filedir aiming to minimize
            % the delay of patients from their initial times.
            
            patients = readtable(filedir);
            % Get the First Priorities of patients to see whether they were
            % postponed to next day or not and store it as new column
            patients = addvars(patients,patients.Priority(:),'NewVariableNames',{'FirstPriority'});
            patients = addvars(patients,zeros(height(patients),1),'NewVariableNames',{'Delay'});
            patients = sortrows(patients,'Complexity');
            
            schedule = zeros(self.planningDays,self.numberOfRooms,self.dailyPlanningHorizon + 1);
            % Schedule is a matrix of 1's and zero to check if someone was
            % already scheduled in a certain room at a certain minute.
            % However it is only used for this checking and nothing else
            
            final_schedule = [];
            count = 0;
            shiftments = zeros(4,1);
            
            for d = 1:self.planningDays
                for p = 0:4
                    mask = logical((patients.Day == d) .* (patients.Priority == p));
                    candidates = patients(mask,:);
                    for i = 1:size(candidates,1)
                        candidate = candidates(i,:);
                        flag = true;
                        % Set the patient object of the current person
                        sick = Patient(candidate.Name,candidate.Surname,candidate.Priority,candidate.Complexity,candidate.Day);
                        % Set the operation object and currently schedule
                        % it to 0,0 at room 0 (artificial schedule)
                        oper = Operation(candidate.ID,sick,Interval(candidate.AvailableStart,candidate.AvailableFinish), ...
                            Interval(0,0),candidate.Duration,sick.day,0);
                         
                        earliest_start = candidate.AvailableStart + 1;
                        latest_start = self.dailyPlanningHorizon + 2 - candidate.Duration;
                        
                        for r = 1:size(schedule,2) % for number of rooms available
                            for current_start = linspace(earliest_start,latest_start,latest_start-earliest_start + 1)    
                                current_finish = current_start + oper.duration - 1; %checking for all available start times
                                current_done = min(current_finish + (candidate.Complexity-1) * 20,481);
                                if ~schedule(d,r,current_start:current_done) % if current interval is not scheduled
                                    schedule(d,r,current_start:current_finish) = 1;
                                    schedule(d,r,current_finish+1:current_done) = -1;
                                    oper.setScheduledInterval(Interval(current_start,current_finish))
                                    oper.setRoomNo(r)
                                    final_schedule = [final_schedule, oper];
                                    flag = false;
                                    if candidate.FirstPriority == candidate.Priority
                                        patients(patients.ID == oper.id,:).Delay = min(max(0,current_finish-candidate.AvailableFinish-1),oper.duration);
                                        % if current finish is after than
                                        % available finish and it is
                                        % not fully outside of available
                                        % interval
                                        if patients(patients.ID == oper.id,:).Delay == 0
                                            count = count + 1; % if that person was not shifted
                                        end
                                    else
                                        shiftments(candidate.FirstPriority) = shiftments(candidate.FirstPriority) + 1;
                                        patients(patients.ID == oper.id,:).Delay = candidate.Duration;
                                    end
                                    break
                                end
                            end
                            if ~flag % if a person is fitted break the outer loop too
                                break
                            end
                        end
                        if flag && candidate.FirstPriority == candidate.Priority % If we didn't shift the person before
                            if oper.patient.getPatientPriority == 1
                                patients(patients.ID == oper.id,:).Priority = 0;
                                patients(patients.ID == oper.id,:).AvailableStart = 0;
                                patients(patients.ID == oper.id,:).AvailableFinish = oper.duration - 1;
                                patients(patients.ID == oper.id,:).Day = d + 1;
                            else
                                patients(patients.ID == oper.id,:).Priority = p - 1;
                                patients(patients.ID == oper.id,:).Day = d + 1;
                            end
                        end                           
                    end % checking all candidates
                end %priority
            end %day
            utilizations = zeros(self.numberOfRooms,1);
            for r = 1:self.numberOfRooms
                utilizations(r) = sum(schedule(:,r,:) == 1,"all");
            end
            utilizations = (utilizations / ((self.dailyPlanningHorizon + 1) * 5)) * 100 ;
            total_delay = sum(patients.Delay(:));
        end % function
                                                        
        
       
       
       function printSchedule(self,outdir,obj)
            
            varnames = {'Room No','Available Interval','Duration (min)','Sched Interval','Patient Name', ...
                'Patient Surname','Patient Priority','Operation Day'};
            out = table([],[],[],[],[],[],[],[],VariableNames=varnames);

            %Exporting results to a excel file
            for idx = 1:length(self.finalSchedule)
                oper = self.finalSchedule(idx);
                out_ainterval = '(' + string(oper.availableInterval.left) + ',' + string(oper.availableInterval.right) + ')';
                out_sinterval = '(' + string(oper.scheduledInterval.left - 1) + ',' + string(oper.scheduledInterval.right - 1) + ')';
                row = {oper.roomNo, out_ainterval, oper.duration, out_sinterval, oper.patient.name, ...
                    oper.patient.surname, oper.patient.getPatientPriority, oper.operationDay};
                out = [out; cell2table(row, "VariableNames",varnames)];
            end
            out = sortrows(out,"Room No");
            writetable(out, outdir)
            
            %Gantt Chart
            for d = 1:self.planningDays
                figure
                for idx = 1:length(self.finalSchedule)
                    oper = self.finalSchedule(idx);
                    if oper.operationDay == d
                        hold on
                        ttl = 'Day ' + string(d) + ' for Objective ' + string(obj);
                        title(ttl)
                        xlabel('Minutes from Start')
                        ylabel('Room No')
                        fill([oper.scheduledInterval.left oper.scheduledInterval.left oper.scheduledInterval.right ...
                            oper.scheduledInterval.right],[oper.roomNo-0.05,oper.roomNo+0.05,oper.roomNo+0.05,oper.roomNo-0.05], ...
                            [0 1 1],'EdgeColor','none')
                        plot([oper.availableInterval.left oper.availableInterval.left oper.availableInterval.right ...
                            oper.availableInterval.right, oper.availableInterval.left], ...
                            [oper.roomNo-0.05,oper.roomNo+0.05,oper.roomNo+0.05,oper.roomNo-0.05, oper.roomNo-0.05], Color='black')
                        len = oper.scheduledInterval.getWidth;
                        text(oper.scheduledInterval.left + len/2,oper.roomNo,string(oper.id))
                        hold off
                    end
                end
            end
        
        end

    end % methods

end % classdef