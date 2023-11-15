% Load the Simulink model
load_system('simulink_model');  % Replace with your actual Simulink model name

% Simulate the model
simOut = sim("simulink_model.slx");

% Access the simulation data
Height = CPos.data(:,1);
Latitude = CPos.data(:,2);
Longitude = CPos.data(:,3);
RangeTarget = RTar.data;
DistanceObstacle = DObs.data;
Time = time.data;

% Calculate ZVelocity
delta_h = diff(Height);
delta_t = diff(Time);
Zvelocity = delta_h ./ delta_t;

% Calculate distance between consecutive latitude and longitude points
distance = zeros(size(Latitude));
for i = 2:length(Latitude)
    lat1 = Latitude(i-1);
    lon1 = Longitude(i-1);
    lat2 = Latitude(i);
    lon2 = Longitude(i);
    
    % Haversine formula to calculate distance between two points on a sphere
    dlat = deg2rad(lat2 - lat1);
    dlon = deg2rad(lon2 - lon1);
    a = sin(dlat/2)^2 + cos(deg2rad(lat1)) * cos(deg2rad(lat2)) * sin(dlon/2)^2;
    c = 2 * atan2(sqrt(a), sqrt(1-a));
    distance(i) = R * c;
end

% Calculate Ground speed
Gspeed = abs(distance(2:end) ./ delta_t);

% Calculate Missile speed
Mspeed = sqrt(Gspeed.^2 + Zvelocity.^2);


% Plotting
figure;

% Plot Height
subplot(4, 3, 1);
plot(Time, Height);
title('Missile Height');
xlabel('Time');
ylabel('Height');

% Plot RTar
subplot(4, 3, 2);
plot(Time, RangeTarget);
title('Range Target');
xlabel('Time');
ylabel('RTar');

% Plot DObs
subplot(4, 3, 3);
plot(Time, DistanceObstacle);
title('Distance Obstacle');
xlabel('Time');
ylabel('DObs');

% Plot ZVelocity
subplot(4, 3, 4);
plot(Time(1:end-1), Zvelocity);
title('Zvelocity');
xlabel('Time');
ylabel('Zvel');

%Plot Ground Speed
subplot(4, 3, 5);
plot(Time(1:end-1), Gspeed);
title('Ground Speed');
xlabel('Time');
ylabel('Gspd');

%Plot Missile Speed
subplot(4, 3, 6);
plot(Time(1:end-1), Mspeed);
title('Missile Speed');
xlabel('Time');
ylabel('Mspd');


% Plot 3D Trajectory
subplot(4, 3, [7:12]);
plot3(Longitude, Latitude, Height);
xlabel('Longitude');
ylabel('Latitude');
zlabel('Height');
grid on;

