function nfc_basic_antenna_simulation()
%% NFC_BASIC_ANTENNA_SIMULATION - NFC PCB Antenna Analysis (Basic MATLAB Only)
%
% DESCRIPTION:
%   NFC PCB business card antenna simulation using only core MATLAB   
%functions.
%   No toolboxes required - implements fundamental RF calculations and 
 %circuit
%   analysis using basic mathematical operations.
%
% FEATURES:
%   - Spiral antenna inductance calculation using Wheeler's formula
%   - Circuit analysis using basic complex impedance mathematics
%   - S11 parameter calculation from impedance
%   - Resonance frequency determination
%   - Comprehensive plotting and analysis
%
% REQUIREMENTS:
%   - Basic MATLAB (no toolboxes required)
%   - Works with MATLAB Mobile
%
% AUTHOR: Umar
% REFERENCE: STM AN2972, GitHub: https://github.com/Raziz1/
%PCB_Business_Card
%
% USAGE:
%   >> nfc_basic_antenna_simulation()

clear; 
clc;
close all;
fprintf('=== NFC PCB Business Card Antenna Simulation (Basic MATLAB) ===\n');
fprintf('No toolboxes required - Using fundamental RF calculations\n\n');

%% Part 1: Antenna Physical Parameters (Based on STM AN2972)
fprintf('1. Defining antenna physical parameters...\n');
% Spiral antenna geometry from your design
N = 6;                      % Number of turns
r_inner = 17.5e-3;          % Inner radius (m)
r_outer = 20.5e-3;          % Outer radius (m)
trace_width = 0.4e-3;       % Trace width (m)
trace_spacing = 0.4e-3;     % Spacing between traces (m)
copper_thickness = 35e-6;   % 35μm copper thickness
% PCB substrate properties (FR-4)
epsilon_r = 4.4;            % Relative permittivity
tan_delta = 0.02;           % Loss tangent
substrate_thickness = 1.6e-3; % PCB thickness (m)
% Physical constants
mu_0 = 4*pi*1e-7;          % Permeability of free space (H/m)
epsilon_0 = 8.854e-12;      % Permittivity of free space (F/m)
c = 3e8;                    % Speed of light (m/s)
sigma_copper = 5.96e7;      % Copper conductivity (S/m)
% NFC operating parameters
f_nfc = 13.56e6;           % NFC frequency (Hz)
omega_nfc = 2*pi*f_nfc;    % Angular frequency (rad/s)
fprintf('   Spiral: %d turns, Rin=%.1fmm, Rout=%.1fmm\n', N, r_inner*1000, r_outer*1000);
fprintf('   Trace: %.1fmm width, %.1fmm spacing\n', trace_width*1000, trace_spacing*1000);

%% Part 2: Calculate Antenna Inductance using Wheeler's Formula
fprintf('\n2. Calculating antenna inductance...\n');
% Wheeler's formula for spiral inductance (modified for PCB)
% L = μ₀ * N² * r_avg * K₁ * K₂
r_avg = (r_inner + r_outer) / 2;        % Average radius
fill_factor = (r_outer - r_inner) / (r_outer + r_inner);
% Layout factor K1 (spiral geometry factor)
K1 = log(2.46/fill_factor) + 0.2 * fill_factor^2;
% Substrate factor K2 (accounts for PCB substrate)
K2 = 1 + substrate_thickness/(5*(r_outer - r_inner)) * ...
   (1 + log(4*pi*trace_width/substrate_thickness));
% Calculate inductance
L_antenna = mu_0 * N^2 * r_avg * K1 * K2 * 1e9; % Convert to nH
L_antenna_H = L_antenna * 1e-9; % Convert back to H for calculations
fprintf('   Average radius: %.2f mm\n', r_avg*1000);
fprintf('   Fill factor: %.3f\n', fill_factor);
fprintf('   Layout factor K1: %.3f\n', K1);
fprintf('   Substrate factor K2: %.3f\n', K2);
fprintf('   Calculated inductance: %.1f nH (%.2f μH)\n', L_antenna, L_antenna*1e-3);

%% Part 3: Calculate Antenna Resistance (AC + DC components)
fprintf('\n3. Calculating antenna resistance...\n');
% DC resistance
trace_length = 2*pi*r_avg*N; % Approximate total trace length
trace_area = trace_width * copper_thickness;
R_dc = trace_length / (sigma_copper * trace_area);
% AC resistance due to skin effect
skin_depth = sqrt(2 / (omega_nfc * mu_0 * sigma_copper));
if copper_thickness > 2*skin_depth
  % Thick conductor - skin effect dominates
  R_ac = trace_length / (sigma_copper * trace_width * skin_depth);
else
  % Thin conductor - use thin film correction
  R_ac = R_dc * (1 + copper_thickness/(3*skin_depth));
end
% Substrate losses (dielectric loss)
% Simplified substrate loss model
R_substrate = omega_nfc * L_antenna_H * tan_delta / epsilon_r;
% Total antenna resistance
R_antenna = R_dc + R_ac + R_substrate;
fprintf('   Trace length: %.1f mm\n', trace_length*1000);
fprintf('   Skin depth at 13.56MHz: %.1f μm\n', skin_depth*1e6);
fprintf('   DC resistance: %.2f mΩ\n', R_dc*1000);
fprintf('   AC resistance: %.2f mΩ\n', R_ac*1000);
fprintf('   Substrate loss: %.2f mΩ\n', R_substrate*1000);
fprintf('   Total antenna resistance: %.2f Ω\n', R_antenna);

%% Part 4: NFC IC Equivalent Circuit
fprintf('\n4. Modeling NFC IC equivalent circuit...\n');
% NFC IC parameters (from your circuit diagram)
R_ic = 100e3;           % 100kΩ parallel resistance
C_ic = 50e-12;          % 50pF parallel capacitance
% Calculate IC impedance vs frequency
freq_range = linspace(10e6, 20e6, 1001); % Focus around 13.56 MHz
omega_range = 2*pi*freq_range;
% IC impedance: Z_ic = R_ic || (1/jωC_ic)
Z_ic_complex = zeros(size(freq_range));
for i = 1:length(freq_range)
  omega = omega_range(i);
  Z_cap = -1j/(omega*C_ic);           % Capacitive reactance
  Z_ic_complex(i) = (R_ic * Z_cap) / (R_ic + Z_cap); % Parallel combination
end
fprintf('   IC resistance: %.0f kΩ\n', R_ic/1000);
fprintf('   IC capacitance: %.0f pF\n', C_ic*1e12);
%% Part 5: Total System Impedance and S11 Calculation
fprintf('\n5. Calculating system impedance and S11...\n');
% System impedance: Z_system = Z_antenna + Z_ic (series connection)
Z_antenna_complex = zeros(size(freq_range));
Z_system_complex = zeros(size(freq_range));
for i = 1:length(freq_range)
  omega = omega_range(i);
    % Antenna impedance: Z_ant = R_ant + jωL_ant
    Z_antenna_complex(i) = R_antenna + 1j*omega*L_antenna_H;
    % Total system impedance
    Z_system_complex(i) = Z_antenna_complex(i) + Z_ic_complex(i);
  end
% Calculate S11 parameters
Z0 = 50; % Reference impedance (50Ω)
S11_complex = (Z_system_complex - Z0) ./ (Z_system_complex + Z0);
S11_dB = 20*log10(abs(S11_complex));
S11_phase = angle(S11_complex) * 180/pi;
% Find resonant frequency (where imaginary part is minimum)
reactance_system = imag(Z_system_complex);
[~, resonant_idx] = min(abs(reactance_system));
f_resonant = freq_range(resonant_idx);
Z_resonant = Z_system_complex(resonant_idx);
fprintf('   Reference impedance: %.0f Ω\n', Z0);
fprintf('   Resonant frequency: %.3f MHz\n', f_resonant/1e6);
fprintf('   System impedance at resonance: %.2f + j%.2f Ω\n', real(Z_resonant), imag(Z_resonant));
fprintf('   S11 at resonance: %.2f dB\n', S11_dB(resonant_idx));

%% Part 6: Calculate Tuning Capacitance
fprintf('\n6. Calculating tuning requirements...\n');
% Find impedance at target frequency
[~, target_idx] = min(abs(freq_range - f_nfc));
Z_at_target = Z_system_complex(target_idx);
X_at_target = imag(Z_at_target);
if X_at_target > 0
  % Inductive - need series capacitance
  C_tune = 1 / (omega_nfc * X_at_target);
  fprintf('   System is inductive at 13.56 MHz\n');
  fprintf('   Required series tuning capacitance: %.1f pF\n', C_tune*1e12);
else
  % Capacitive - need series inductance
  L_tune = -X_at_target / omega_nfc;
  fprintf('   System is capacitive at 13.56 MHz\n');
  fprintf('   Required series tuning inductance: %.1f nH\n', L_tune*1e9);
end

%% Part 7: Quality Factor Analysis
fprintf('\n7. Analyzing quality factor...\n');
Q_antenna = omega_nfc * L_antenna_H / R_antenna;
Q_system = abs(imag(Z_system_complex)) ./ real(Z_system_complex);
% Find -3dB bandwidth
S11_linear = abs(S11_complex);
S11_min = min(S11_linear);
S11_3dB = S11_min * sqrt(2);
% Find bandwidth indices
bandwidth_indices = find(S11_linear <= S11_3dB);
if ~isempty(bandwidth_indices)
  bandwidth_Hz = freq_range(bandwidth_indices(end)) - freq_range(bandwidth_indices(1));
  bandwidth_percent = bandwidth_Hz / f_nfc * 100;
else
  bandwidth_Hz = 0;
  bandwidth_percent = 0;
end
fprintf('   Antenna Q factor: %.1f\n', Q_antenna);
fprintf('   System Q at 13.56MHz: %.1f\n', Q_system(target_idx));
fprintf('   -3dB Bandwidth: %.1f kHz (%.2f%%)\n', bandwidth_Hz/1000, bandwidth_percent);

%% Part 8: Comprehensive Results Plotting
fprintf('\n8. Generating analysis plots...\n');
% Create comprehensive figure with subplots
figure('Name', 'NFC Antenna Analysis - Basic MATLAB', 'Position', [100 100 1400 900]);
% Plot 1: S11 magnitude and phase
subplot(2,4,1);
yyaxis left
plot(freq_range/1e6, S11_dB, 'b-', 'LineWidth', 2);
ylabel('S_{11} Magnitude (dB)', 'Color', 'b');
xlabel('Frequency (MHz)');
title('S_{11} Parameter');
grid on;
yyaxis right
plot(freq_range/1e6, S11_phase, 'r--', 'LineWidth', 1.5);
ylabel('S_{11} Phase (°)', 'Color', 'r');
xline(f_nfc/1e6, 'k--', '13.56 MHz');
% Plot 2: System impedance
subplot(2,4,2);
plot(freq_range/1e6, real(Z_system_complex), 'r-', 'LineWidth', 2); hold on;
plot(freq_range/1e6, imag(Z_system_complex), 'b-', 'LineWidth', 2);
plot(f_nfc/1e6, real(Z_at_target), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
plot(f_nfc/1e6, imag(Z_at_target), 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
xlabel('Frequency (MHz)');
ylabel('Impedance (Ω)');
title('System Impedance');
legend('Resistance', 'Reactance', 'R @ 13.56MHz', 'X @ 13.56MHz');
grid on;
xline(f_nfc/1e6, 'k--', '13.56 MHz');
% Plot 3: Smith Chart (simplified)
subplot(2,4,3);
% Normalized impedance for Smith chart
Z_norm = Z_system_complex / Z0;
smith_R = real(Z_norm);
smith_X = imag(Z_norm);
plot(smith_R, smith_X, 'b-', 'LineWidth', 2); hold on;
plot(smith_R(target_idx), smith_X(target_idx), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
% Add unit circle and basic Smith chart grid
theta = linspace(0, 2*pi, 100);
plot(cos(theta), sin(theta), 'k--', 'LineWidth', 0.5); % Unit circle
plot([-1 1], [0 0], 'k--', 'LineWidth', 0.5); % Real axis
plot([0 0], [-1 1], 'k--', 'LineWidth', 0.5); % Imaginary axis
xlabel('Normalized Resistance');
ylabel('Normalized Reactance');
title('Simplified Smith Chart');
axis equal; grid on;
xlim([-2 2]); ylim([-2 2]);
% Plot 4: Quality factor
subplot(2,4,4);
plot(freq_range/1e6, Q_system, 'g-', 'LineWidth', 2);
xlabel('Frequency (MHz)');
ylabel('Quality Factor');
title('System Q Factor');
grid on;
xline(f_nfc/1e6, 'k--', '13.56 MHz');
ylim([0 min(50, max(Q_system))]);
% Plot 5: VSWR
subplot(2,4,5);
VSWR = (1 + abs(S11_complex)) ./ (1 - abs(S11_complex));
VSWR(VSWR > 10) = 10; % Limit for plotting
plot(freq_range/1e6, VSWR, 'm-', 'LineWidth', 2);
xlabel('Frequency (MHz)');
ylabel('VSWR');
title('Voltage Standing Wave Ratio');
grid on;
xline(f_nfc/1e6, 'k--', '13.56 MHz');
ylim([1 10]);
% Plot 6: Return loss
subplot(2,4,6);
return_loss = -S11_dB;
plot(freq_range/1e6, return_loss, 'c-', 'LineWidth', 2);
xlabel('Frequency (MHz)');
ylabel('Return Loss (dB)');
title('Return Loss');
grid on;
xline(f_nfc/1e6, 'k--', '13.56 MHz');
% Plot 7: Component impedances
subplot(2,4,7);
plot(freq_range/1e6, abs(Z_antenna_complex), 'r-', 'LineWidth', 2); hold on;
plot(freq_range/1e6, abs(Z_ic_complex), 'b-', 'LineWidth', 2);
plot(freq_range/1e6, abs(Z_system_complex), 'k-', 'LineWidth', 2);
xlabel('Frequency (MHz)');
ylabel('Impedance Magnitude (Ω)');
title('Component Impedances');
legend('Antenna', 'NFC IC', 'Total System', 'Location', 'best');
grid on;
xline(f_nfc/1e6, 'k--', '13.56 MHz');
% Plot 8: Phase relationships
subplot(2,4,8);
plot(freq_range/1e6, angle(Z_antenna_complex)*180/pi, 'r-', 'LineWidth', 2);     
hold on;
plot(freq_range/1e6, angle(Z_ic_complex)*180/pi, 'b-', 'LineWidth', 2);
plot(freq_range/1e6, angle(Z_system_complex)*180/pi, 'k-', 'LineWidth', 2);
xlabel('Frequency (MHz)');
ylabel('Phase (°)');
title('Impedance Phase');
legend('Antenna', 'NFC IC', 'Total System', 'Location', 'best');
grid on;
xline(f_nfc/1e6, 'k--', '13.56 MHz');
% Add main title
sgtitle('NFC PCB Business Card Antenna - Complete Analysis (Basic MATLAB)', ...
      'FontSize', 14, 'FontWeight', 'bold');
%% Part 9: Performance Summary
fprintf('\n=== NFC ANTENNA SIMULATION SUMMARY ===\n');
fprintf('Target Frequency: %.2f MHz\n', f_nfc/1e6);
fprintf('Resonant Frequency: %.2f MHz\n', f_resonant/1e6);
fprintf('Frequency Error: %.2f%% \n', abs(f_resonant - f_nfc)/f_nfc * 100);
fprintf('Antenna Inductance: %.1f nH (%.2f μH)\n', L_antenna, L_antenna*1e-3);
fprintf('Antenna Resistance: %.2f Ω\n', R_antenna);
fprintf('System Impedance @ 13.56MHz: %.2f + j%.2f Ω\n', real(Z_at_target), imag(Z_at_target));
fprintf('S11 @ 13.56MHz: %.2f dB\n', S11_dB(target_idx));
fprintf('VSWR @ 13.56MHz: %.2f\n', VSWR(target_idx));
fprintf('Q Factor: %.1f (antenna), %.1f (system)\n', Q_antenna, Q_system(target_idx));
fprintf('Bandwidth (-3dB): %.1f kHz\n', bandwidth_Hz/1000);

%% Part 10: Design Recommendations
fprintf('\n=== DESIGN RECOMMENDATIONS ===\n');
freq_error = abs(f_resonant - f_nfc)/f_nfc * 100;
if freq_error < 1
  fprintf('✓ Excellent frequency accuracy (%.2f%% error)\n', freq_error);
elseif freq_error < 5
  fprintf('○ Good frequency accuracy (%.2f%% error)\n', freq_error);
else
  fprintf('✗ Poor frequency accuracy (%.2f%% error)\n', freq_error);
  fprintf('  → Consider adjusting number of turns or dimensions\n');
end
if abs(imag(Z_at_target)) < real(Z_at_target)/10
  fprintf('✓ Well-matched system (low reactance)\n');
else
  fprintf('○ System needs tuning (high reactance)\n');
  if imag(Z_at_target) > 0
      fprintf('  → Add series capacitance: %.1f pF\n', C_tune*1e12);
  else
      fprintf('  → Add series inductance: %.1f nH\n', L_tune*1e9);
  end
end
if Q_system(target_idx) > 10 && Q_system(target_idx) < 50
  fprintf('✓ Good Q factor for NFC application\n');
else
  fprintf('○ Q factor may need optimization\n');
end
%% Save results
save('nfc_basic_simulation_results.mat', 'freq_range', 'Z_system_complex', ...
   'S11_complex', 'L_antenna_H', 'R_antenna', 'f_resonant', 'Q_antenna');
fprintf('\nSimulation completed! Results saved to: nfc_basic_simulation_results.mat\n');
fprintf('All calculations performed using basic MATLAB - no toolboxes required.\n');
end