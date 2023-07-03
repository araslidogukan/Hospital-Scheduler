clear class
clear all
clc

% 5 days 3 rooms 8 hours
s = Schedule(480,5,3);

s.constructSchedule(1,'InputData.xlsx','Schedule_objective1.xlsx');
disp('--------------------------------------------')
s.constructSchedule(2,'InputData.xlsx','Schedule_objective2.xlsx');
disp('--------------------------------------------')
s.constructSchedule(3,'InputData.xlsx','Schedule_objective3.xlsx');
disp('--------------------------------------------')

% 5 days 4 rooms 8 hours
s = Schedule(480,5,4);

s.constructSchedule(1,'InputData.xlsx','Schedule_objective1_4rooms.xlsx');
disp('--------------------------------------------')
s.constructSchedule(2,'InputData.xlsx','Schedule_objective2_4rooms.xlsx');
disp('--------------------------------------------')
s.constructSchedule(3,'InputData.xlsx','Schedule_objective3_4rooms.xlsx');