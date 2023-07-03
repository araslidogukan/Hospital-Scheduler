classdef Interval < handle
   
    properties
       left
       right
    end
    
    methods
        function Inter = Interval(lt, rt)
        % Constructor:  construct an Interval object
            Inter.left= lt;
            Inter.right= rt;
        end
        
        function w = getWidth(self)
            % Return the width of the Interval
            w = self.right - self.left ;
        end
        
        function scale(self, f)
            % Scale self by a factor f
            self.right = self.right / f;
            self.left = self.left / f;
        end
        
        function shift(self, s)
            % Shift self by constant s
            self.right = self.right + s;
            self.left = self.left + s;
        end
        
        function tf = isIn(self, other)
            % tf is true (1) if self is in the other Interval
            % e.g., tf = 1 if self is a subset of other
            if self.left >= other.left && self.right <= other.right
                tf = 1;
            else
                tf = 0;
            end
        end
        
        function Inter = add(self, other)
            % Inter is the new Interval formed by adding self and the 
            % the other Interval
            Inter = Interval(self.left + other.left, self.right + other.right);
        end
        
        function disp(self)
        % Display self, if not empty, in this format: (left,right)
        % If empty, display 'Empty <classname>'
            if isempty(self)
                fprintf('Empty %s\n', class(self))
            else
                fprintf('(%d,%d)\n', self.left, self.right)
            end
        end
        
    end %methods
    
end %classdef