classdef Operation < handle

    properties
        id
        patient
        availableInterval
        scheduledInterval
        duration
        operationDay
        roomNo % roomNo that this operation is scheduled for (because of the way heuristics are defined this is necessary)
    end

    methods

        function o = Operation(id,patient,availableInterval,scheduledInterval,duration,operationDay,roomNo)
            %Constructor Function
            o.id = id;
            o.patient = patient;
            o.availableInterval = availableInterval;
            o.scheduledInterval = scheduledInterval;
            o.duration = duration;
            o.operationDay = operationDay;
            o.roomNo = roomNo;
        end

        function setAvailableInterval(self,I)
            self.availableInterval = I;
        end
        
        function setScheduledInterval(self,I)
            self.scheduledInterval = I;
        end

        function r = getRoomNo(self)
            % Getter function for roomNo property
            % returns the roomNo operation was in.
            r = self.roomNo;
        end
        
        function setRoomNo(self,r)
            % Setter function for roomNo property
            % sets the roomNo of self as r
            self.roomNo = r;
        end

    end % methods

end %classdef