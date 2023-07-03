classdef Patient < handle

    properties
        name
        surname
        priority
        complexity
        day
    end

    methods

        function pt = Patient(name,surname,priority,complexity,day)
            %Constructor Function
            pt.name = name;
            pt.surname = surname;
            pt.complexity = complexity;
            % It should be noted that the ways that heuristic objectives
            % are written patients priority and day's are stored as
            % the day and priority they end up with, i.e., if they get
            % scheduled to the next day their priority is stored as -1 and 
            % day +1
            pt.priority = priority;
            pt.day = day;
        end

        function p = getPatientPriority(self)
            p = self.priority;
        end

        function setPatientPriority(self,p)
            self.priority = p;
        end

        function c = getPatientComplexity(self)
            c = self.complexity;
        end

        function d = getPatientDay(self)
            d = self.day;
        end

        function setPatientDay(self,d)
            self.day = d;
        end

    end % Methods

end % classdef