%% OpenEMS NFC Antenna Example (Equivalent to pcbStack)
close all; clear; clc;

%% Simulation setup
unit     = 1;          % geometry in meters
f_start  = 50e6;       % start frequency
f_stop   = 80e6;      % stop frequency

%% FDTD Setup
FDTD = InitFDTD('NrTs', 1e6, 'EndCriteria', 1e-5);
FDTD = SetGaussExcite(FDTD, (f_start+f_stop)/2, (f_stop-f_start)/2);

% Boundary conditions: Absorbing (PML) on all sides
BC = {'PML_8','PML_8','PML_8','PML_8','PML_8','PML_8'};
FDTD = SetBoundaryCond(FDTD, BC);

%% Init CSX geometry
CSX = InitCSX();

%% Materials
copper_thickness = 0.00035;  % 0.35 mm
substrate_thickness = 0.0016;
air_thickness = 0.0001;

CSX = AddMetal(CSX,'Copper');
CSX = AddMaterial(CSX,'FR4');
CSX = SetMaterialProperty(CSX,'FR4','Epsilon',4.4,'Kappa',0.026);

%% Board Polygon (equivalent to Polygon1)
board_vertices = [ ...
    0.09471803   0.13904510   0.13904510   0.09471803;  % x row
   -0.108669    -0.108669    -0.069669    -0.069669   % y row
];

%% Substrate box (FR4 below the copper)
xmin = min(board_vertices(1,:));
xmax = max(board_vertices(1,:));
ymin = min(board_vertices(2,:));
ymax = max(board_vertices(2,:));

CSX = AddBox(CSX,'FR4',0,[xmin ymin 0],[xmax ymax substrate_thickness]);

%% Copper coil from STL

coil_stl_file = fullfile(pwd,'PCB_Coil_STL.stl'); % ensures full path
coil_prio     = 20;                % priority above substrate
zpos_coil     = 0; 
scale_factor  = 1e-3;              % convert STL units from mm to meters (adjust if needed)

% Import the STL as a copper layer
CSX = ImportSTL(CSX, 'Copper', coil_prio, coil_stl_file, ...
                'Transform', {'Scale', scale_factor, 'Translate', [0 0 zpos_coil]});

%% Lumped feed port
port_x = 0.138;
port_y = -0.0885;
port_z = 0.00001;  % lift slightly above PCB

port_width = 0.0003 * 2;  % ~2 cells
[CSX, port] = AddLumpedPort(CSX, 5, 1, 50, ...
    [port_x - port_width/2, port_y - port_width/2, port_z], ...
    [port_x + port_width/2, port_y + port_width/2, port_z+substrate_thickness], ...
    [0 0 1], true);


%% Mesh
mesh_res = 0.0001; % 0.1 mm
mesh.x = SmoothMeshLines([xmin xmax], mesh_res, 1.3);
mesh.y = SmoothMeshLines([ymin ymax], mesh_res, 1.3);
%mesh.z = SmoothMeshLines([0 substrate_thickness+copper_thickness+air_thickness], mesh_res, 1.3);

% Mesh resolutions
mesh_res_z_coarse = 0.001;  % 1 mm for air / substrate below
mesh_res_z_fine   = 0.00015; % 0.15 mm for copper

% Z-layers
z_bottom     = 0;                       % bottom of substrate
z_copper_top = substrate_thickness + copper_thickness;
z_air_top    = z_copper_top + air_thickness;     % 1mm air above

% Z-mesh
mesh.z = [ ...
    SmoothMeshLines([z_bottom substrate_thickness], mesh_res_z_coarse, 1.3), ...
    SmoothMeshLines([substrate_thickness z_copper_top], mesh_res_z_fine, 1.3), ...
    SmoothMeshLines([z_copper_top z_air_top], mesh_res_z_coarse, 1.3) ...
];

CSX = DefineRectGrid(CSX, unit, mesh);

%% Write and run openEMS
Sim_Path = 'OpenEMS_Sim';
Sim_CSX  = 'pcb.xml';
[~,~] = mkdir(Sim_Path);

WriteOpenEMS(fullfile(Sim_Path,Sim_CSX), FDTD, CSX);

%% Visualization of the PCB
CSXGeomPlot(fullfile(Sim_Path,Sim_CSX)); % Plot the CSX geometry


RunOpenEMS(Sim_Path, Sim_CSX, '--disable-dumps', '-v');

%% Post-processing
freq = linspace(f_start,f_stop,201);
port = calcPort(port, Sim_Path, freq);

s11 = port.uf.ref ./ port.uf.inc;

figure;
plot(freq/1e6,20*log10(abs(s11)),'LineWidth',2);
grid on;
xlabel('Frequency (MHz)');
ylabel('S11 (dB)');
title('NFC Antenna S11 (OpenEMS)');
