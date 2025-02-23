function bridgeOfDoomQEA2020()

% This script pilots the Neato along a parameterized curve (R).  The major
% components of this challenge are to compute the linear and angular
% velocity required to traverse the curve.  While not shown in this code,
% we also require that they set the left and right wheel velocities
% directly (rather than linear and angular velocity as in this example).

visualize = false;

% define u explicitly to avoid error when using sub functions
% see: https://www.mathworks.com/matlabcentral/answers/268580-error-attempt-to-add-variable-to-a-static-workspace-when-it-is-not-in-workspace
u = [];
% u will be our parameter
syms u;

% these assumptions are not strictly necessary, but they do make some of
% the expressions a bit tidier.
assume(u,'positive');
assume(u,'real');

% dilation is the conversion from the raw parameterization of the curve
% to time.  Larger dilation means that the robot will traverse the curve
% more slowly (taking a longer time)
dilation = 10;

% scale the bridge
R = 4*[0.396*cos(2.65*(u/dilation+1.4));...
     -0.99*sin(u/dilation+1.4);...
     0];

% the parameters u goes from 0 3.2.  Since we want to dilate time, we set
% our time bounds based on the approporiate factor
timeBounds = [0 (3.2)*dilation];
width = 0.6;

% tangent vector
T = diff(R);

% normalized tangent vector
That = T/norm(T);

% normal vector
N = diff(That);

% angular velocity vector
omega = cross(That, N);

% the instantaneous speed of the robot
linearSpeed = norm(T);

% the simulated Neato we used in 2020 had a wheel base of 0.235m
d = 0.235;
velocityLeftWheel = linearSpeed - d/2*omega(3);
velocityRightWheel = linearSpeed + d/2*omega(3);

if visualize
    % plot the path itself
    figure;
    fplot(R(1), R(2), timeBounds);
    axis equal;

    figure;

    % plot the angular velocity and linear speed over time
    fplot(linearSpeed, timeBounds);
    hold on;
    fplot(omega(3), timeBounds);
    legend({'Linear velocity', 'Angular velocity'});
end

pub = rospublisher('raw_vel', 'islatching', false);
pause(1);
% stop the robot if it's going right now
stopMsg = rosmessage(pub);
stopMsg.Data = [0 0];
send(pub, stopMsg);
pause(1);

bridgeStart = double(subs(R,u,timeBounds(1)));
startingThat = double(subs(That,u,timeBounds(1)));
placeNeato(bridgeStart(1),  bridgeStart(2), startingThat(1), startingThat(2), 0.55);

% wait a bit for robot to fall onto the bridge
pause(5);

rostic;
disp('starting trajectory');
while true
    u_val = rostoc() + timeBounds(1);
    if u_val > timeBounds(2)
        break
    end
    msg = rosmessage(pub);
    % subsitute the current time into the computed expressions
    vL = double(subs(velocityLeftWheel, u, u_val));
    vR = double(subs(velocityRightWheel, u, u_val));
    msg.Data = [vL, vR];
    % send to the robot
    send(pub, msg);
    % wait a little bit before the next iteration
    pause(0.01);
end
% stop the robot
msg = rosmessage(pub);
msg.Data = [0 0];
send(pub, msg);
clear pub;

end
