%%Missile Model

% Let the User only set the Total mass, Initial Velocity and Axial Acceleration 
In_v0 = abs(input("Initial Velocity: "));       %m/sec
In_m = abs(input("Total Missile mass: "));      %kg
In_Ax0 = -1*abs(input("Axial Acceleration: ")); %m/s^2

% Change the Input unit
v0 = In_v0 * 3.2808399; %ft/sec
m = In_m * 0.0685217659; %slug
Ax0 = In_Ax0 * 3.2808399; %ft/sec^2

% Set the constant
Iyy = 137.8;        %Pitch Moment of Inertia (slug*ft^2)
xbar = 1.2;         %Distance from CG to IMU Positive Forward (ft)
Cfaoa = -5.5313;    %Pitch Force Coefficient due to Angle of Attack (no unit)
Cmaoa = 6.6013;     %Pitch Moment Coefficient due to Angle of Attack (no unit)
Cffd = -1.2713;     %Pitch Force Coefficient due to Fin Deflection (no unit)
Cmfd = -7.5368;     %Pitch Moment Coefficuent due to Fin Deflection (no unt)
Qbar = 13332;       %Dynamic Pressure (lb/ft^2)
% We also se the dimension of the missile to be constant
s = 0.5454;         %Reference Area (ft^2)
d = 0.8333;         %Reference Length (ft)
g = 32.174;         %Gravity Constant (ft/sec^2)

%Calculate the state Matrix
A11 = (1/v0) * ( (Qbar*s*Cfaoa)/m - Ax0 );
A21 = (Qbar*s*d*Cmaoa) / Iyy;
A = [A11 1 ; A21 0]

%Calculate the Input Matrix
B11 = (Qbar*s*Cffd) / (m*v0);
B21 = (Qbar*s*d*Cmfd) / Iyy;
B = [B11 ; B21]

%Calculate the Output Matrix
C11 = (Qbar*s*Cfaoa)/(m*g) - (Qbar*s*d*Cmaoa*xbar)/(g*Iyy);
C = [C11 0 ; 0 1]

%Calculate the Feedforward Matrix
D11 = (Qbar*s*Cffd)/(m*g) - (Qbar*s*d*Cmfd*xbar)/(g*Iyy);
D = [D11 ; 0]

% Defines names for the states, inputs and outputs of the system
states = {'AoA', 'q'};
inputs = {'\delta_c'};
outputs = {'Az','q'};

% Creates a state-space (ss) model (sys) using the matrices A, B, C, and D, and specifies names for states, inputs, and outputs.
sys = ss(A,B,C,D,'statename',states,...
    'inputname',inputs,...
    'outputname',outputs);

% our TF (control q)
% Converting the state-space model to transfer function
TFs = tf(sys);
TF = TFs(2,1);
disp(pole(TF));

%% inner loop design (control q) - R >> Q, K is not f(C) - NOISE FREE

% weight matrices on states and control for LQR controller
Q = [0.1 0; 0 0.1];
R = 0.5; 

% Computes the LQR gain matrix K that minimizes the cost function based on the specified weighting matrices
[K,S,e] = lqr(A,B,Q,R);
fprintf('eigenvalues A-BK\n'); %state feedback
disp(eig(A-B*K));
fprintf('eigenvalues A-BKC\n'); %output feedback (not a good idea)s
disp(eig(A-B*K*C));
fprintf('Feedback gain K'); %LQR gain 
disp(K)

%closed loop system
Acl = A-B*K;
Bcl = B;
syscl = ss(Acl,Bcl,C,D,'statename',states,...
    'inputname',inputs,...
    'outputname',outputs);
%our TF (control q)
TF = tf(syscl);
TFc = TF(2,1);

%% inner loop design (control q) - NOISE  - KALMAN COMMAND

%other
G = eye(2);
H = 0*eye(2);

%covariance noise matrices, process Q, measurement R
Qbar = diag(0.00015*ones(1,2));
Rbar  = diag(0.55*ones(1,2)); 

%this is your state space with disturbances
sys_n = ss(A,[B G],C,[D H]);
[kest,L,P] = kalman(sys_n,Qbar,Rbar,0);

%assess the stability
Aob = A-L*C;

fprintf('Observer Eigenvalues\n');
disp(eig(Aob));

%%process and measurement noise sample times
dT1 = 0.75;
dT2 = 0.25;

%% same as above with LQG command

% Qx = blkdiag(Q,R);
% Qw = blkdiag(Qbar,Rbar);
% 
% [Klqg,info] = lqg(sys,Qx,Qw);

%% missile parameters 

Vel = 1021.08; %m/s (3350ft/s)
m2f = 3.2811;

%target location
LAT_TARGET = 34.6588;
LON_TARGET = -118.769745;
ELEV_TARGET = 795; %m - MSL

%INITIAL LOCATION
LAT_INIT = 34.2329;
LON_INIT = -119.4573;
ELEV_INIT = 10000; %m p- MSL

%OBSTACLE MIDPOINT LOCATION
LAT_OBS = 34.61916;
LON_OBS = -118.8429;

%% distance calculator (init to target) (test with other example) - (t = 0)

R = 6371e3; %earth radius (m)
d2r = pi/180;

l1 = LAT_INIT*d2r;
u1 = LON_INIT *d2r;
l2 = LAT_TARGET*d2r;
u2 = LON_TARGET*d2r;

dl = l2-l1;
du = u2-u1;

a = sin(dl/2)^2 + cos(l1)*cos(l2)*sin(du/2)^2;

c = 2*atan2(sqrt(a),sqrt(1-a));

d = R*c; %horizontal distance (in m)

%inital range (k (how far from target)
r = sqrt(d^2+(ELEV_TARGET-ELEV_INIT)^2);

%% azimuth (yaw) calculator (t = 0), stays constant

yaw_init = azimuth(LAT_INIT,LON_INIT,LAT_TARGET,LON_TARGET);
yaw = yaw_init*d2r;

%% initial flight path angle

dh = abs(ELEV_TARGET-ELEV_INIT);
FPA_INIT = atan(dh/d); %rad















