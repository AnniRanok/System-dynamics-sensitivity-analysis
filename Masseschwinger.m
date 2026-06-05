%% Mathematische Modellierung des Masseschwingers
%  Vollstaendige Loesung gemaess Aufgabenstellung
%
%  Differentialgleichung: M*z'' + D*z' + C*z = F(t)
%
%  Parameter:
%    M = 300 kg,  C = 200000 N/m,  D = 1125 N*s/m (konstant)
%    H = 1111 N,  omega = 0.9 rad/s
%    F(t) = 0.5*H*step(t-3) + H*(step(t-1)-step(t-3))*sin(omega*t)
%    StepSize = 100 micro Sekunden
%
%  Zustandsform (State-Space):
%    x1 = z    =>  x1' = x2
%    x2 = z'   =>  x2' = (F(t) - F_Daempfer(z') - C*x1) / M

clc; clear; close all;

%%  PARAMETER

M     = 300;       % kg
C     = 200e3;     % N/m
D     = 1125;      % N*s/m (konstante Daempfung)
H     = 1111;      % N
omega = 0.9;       % rad/s
dt    = 100e-6;    % 100 micro Sekunden
t_end = 30;        % Sekunden

%%  LOOK-UP TABLE — Daten (Daempfung_Look_up)
%  Vector_Z_ = Geschwindigkeit z' [m/s]
%  Vector_F_ = Daempfungskraft  F_D [N]

Vector_Z_ = [-0.52 -0.4 -0.3 -0.2 -0.13 -0.1 -0.075 -0.05 ...
              0  0.05  0.075  0.1  0.13  0.2  0.3  0.4  0.52];
Vector_F_ = [-433 -400 -367 -325 -285 -257 -220 -133 ...
              0  500  660  770  855  975  1100  1200  1300];

fprintf('=== Look-Up Table ===\n');
fprintf('Stuetzpunkte: %d\n', length(Vector_Z_));
fprintf('z_min = %.3f m/s  ->  F_D = %d N\n', Vector_Z_(1),   Vector_F_(1));
fprintf('z_max = %.3f m/s  ->  F_D = %d N\n', Vector_Z_(end), Vector_F_(end));

%%  SCHRITT 1 — Daempfung_Look_up.jpg ERSTELLEN und SPEICHERN

fig_lut = figure('Name','Daempfung Look-Up Table', ...
                 'Color','w','Position',[100 100 750 480], ...
                 'Visible','off');

% Feiner Plot (Interpolation)
z_fine  = linspace(min(Vector_Z_), max(Vector_Z_), 500);
FD_fine = interp1(Vector_Z_, Vector_F_, z_fine, 'pchip');

plot(z_fine, FD_fine, 'b-', 'LineWidth', 2.5, ...
     'DisplayName', 'F_D(z'') interpoliert'); hold on;
plot(Vector_Z_, Vector_F_, 'ro', 'MarkerSize', 8, ...
     'MarkerFaceColor', 'r', 'LineWidth', 1.5, ...
     'DisplayName', 'Stuetzpunkte (Dozent)');

% Referenzlinien
xline(0, 'k--', 'LineWidth', 1, 'HandleVisibility','off');
yline(0, 'k--', 'LineWidth', 1, 'HandleVisibility','off');

% Konstante Daempfung zum Vergleich
z_ref  = linspace(min(Vector_Z_), max(Vector_Z_), 100);
FD_ref = D * z_ref;   % F = D * z' (lineare Daempfung)
plot(z_ref, FD_ref, 'g--', 'LineWidth', 1.8, ...
     'DisplayName', sprintf('Konstant D=%d (linear)', D));

xlabel('Geschwindigkeit z'' [m/s]',    'FontSize', 12);
ylabel('Daempfungskraft F_D [N]',      'FontSize', 12);
title({'Daempfung Look up — 1-D Look-Up Table', ...
       'F_D = f(z'') — Hydrodaempfer Kennlinie (vom Dozenten)'}, ...
      'FontSize', 11, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 10);
grid on; grid minor;

lut_filename = 'Daempfung_Look_up.jpg';
exportgraphics(fig_lut, lut_filename, 'Resolution', 150);
fprintf('\n>>> Gespeichert: %s\n', lut_filename);
close(fig_lut);

%% KRAFTFUNKTION F(t)

F_func = @(t) 0.5*H*(t>=3) + H*((t>=1)-(t>=3)).*sin(omega*t);

%% SIMULATION 1 — Konstante Daempfung
%  F_Daempfer = D * z'  (linear)

fprintf('\n>>> Simulation 1: Konstante Daempfung D = %d N*s/m ...\n', D);

ode_const = @(t, x) [ x(2);
    (F_func(t) - D*x(2) - C*x(1)) / M ];

t_span  = 0 : dt : t_end;
options = odeset('MaxStep', dt*10, 'RelTol', 1e-5);
[t_sol, x_sol] = ode23(ode_const, t_span, [0;0], options);

z_const  = x_sol(:,1);
dz_const = x_sol(:,2);
F_sol    = arrayfun(F_func, t_sol);
fprintf('    Fertig. %d Punkte.\n', length(t_sol));

%%  SIMULATION 2 — Variable Daempfung (Look-Up Table)
%  F_Daempfer = interp1(Vector_Z_, Vector_F_, z')
%  Wichtig: z' kann negativ sein -> keine Abs noetig!
%  Die Tabelle deckt negative Werte ab: -0.52 bis +0.52 m/s

fprintf('>>> Simulation 2: Variable Daempfung (Look-Up Table) ...\n');

% Clamp: z' bleibt im Bereich der Tabelle
z_min_lut = min(Vector_Z_);
z_max_lut = max(Vector_Z_);

ode_var = @(t, x) [ x(2);
    (F_func(t) ...
     - interp1(Vector_Z_, Vector_F_, ...
               max(z_min_lut, min(z_max_lut, x(2))), ...
               'linear', 'extrap') ...
     - C*x(1)) / M ];

[t_var, x_var] = ode23(ode_var, t_span, [0;0], options);

z_var  = x_var(:,1);
dz_var = x_var(:,2);
fprintf('    Fertig. %d Punkte.\n\n', length(t_var));

%%  KENNWERTE + AUSGABE

wn   = sqrt(C/M);
zeta = D / (2*sqrt(M*C));
z_ss = 0.5*H / C;   % Steady-State: F_ss/C (unabhaengig von D)

z_max_const  = max(abs(z_const));
z_max_var    = max(abs(z_var));
verbesserung = (1 - z_max_var/z_max_const) * 100;

disp('================================================');
disp('   Masseschwinger — Ergebnisse              ');
disp('================================================');
fprintf('Eigenfrequenz       wn   = %.4f rad/s\n', wn);
fprintf('Daempfungsgrad      zeta = %.4f  (unterdaempft < 1)\n', zeta);
disp(' ');
fprintf('--- Konstante Daempfung (D = %d N*s/m) ---\n', D);
fprintf('  Steady-State z_ss       = %.6f m  =  %.4f mm\n', z_ss, z_ss*1000);
fprintf('  Max. Auslenkung |z_max| = %.6f m  =  %.4f mm\n', z_max_const, z_max_const*1000);
disp(' ');
fprintf('--- Variable Daempfung (Look-Up Tabelle) ---\n');
fprintf('  Steady-State z_ss       = %.6f m  =  %.4f mm\n', z_ss, z_ss*1000);
fprintf('  Max. Auslenkung |z_max| = %.6f m  =  %.4f mm\n', z_max_var, z_max_var*1000);
disp(' ');
fprintf('--- Verbesserung durch variable Daempfung ---\n');
fprintf('  Amplitudenreduktion     = %.2f %%\n', verbesserung);
fprintf('  Steady-State:  GLEICH in beiden Faellen\n');
fprintf('  Begruendung:   z_ss = F_ss/C  (unabhaengig von D)\n');
disp('================================================');

%% GRAFIKEN


%--- Grafik 1: Look-Up Table anzeigen ---
figure('Name',' Daempfung Look-Up Table','Color','w', ...
       'Position',[50 500 750 420]);

z_fine2  = linspace(z_min_lut, z_max_lut, 500);
FD_fine2 = interp1(Vector_Z_, Vector_F_, z_fine2, 'pchip');

plot(z_fine2, FD_fine2, 'b-', 'LineWidth', 2.5, ...
     'DisplayName', 'F_D(z'') interpoliert'); hold on;
plot(Vector_Z_, Vector_F_, 'ro', 'MarkerSize', 8, ...
     'MarkerFaceColor','r', 'DisplayName', 'Stuetzpunkte');
plot(z_fine2, D*z_fine2, 'g--', 'LineWidth', 1.8, ...
     'DisplayName', sprintf('Konstant D=%d (linear)', D));
xline(0,'k--','LineWidth',1,'HandleVisibility','off');
yline(0,'k--','LineWidth',1,'HandleVisibility','off');
xlabel('z'' [m/s]');  ylabel('F_D [N]');
title('Daempfung Look up — F_D = f(z'')');
legend('Location','northwest');
grid on; grid minor;

%--- Grafik 2: Konstante Daempfung ---
figure('Name',' Konstante Daempfung','Color','w', ...
       'Position',[50 50 1000 650]);

subplot(3,1,1);
plot(t_sol, F_sol,'m-','LineWidth',1.5);
xlabel('Zeit [s]');  ylabel('F(t) [N]');
title('Erregerkraft F(t)');
grid on; grid minor;

subplot(3,1,2);
plot(t_sol, z_const*1000,'b-','LineWidth',2); hold on;
yline(z_ss*1000,'r--','LineWidth',1.8, ...
      'Label',sprintf('z_{ss} = %.3f mm',z_ss*1000), ...
      'LabelHorizontalAlignment','right');
xlabel('Zeit [s]');  ylabel('z [mm]');
title(sprintf('Position z(t) — Konstante Daempfung D = %d N·s/m', D));
grid on; grid minor;

subplot(3,1,3);
plot(t_sol, dz_const*1000,'r-','LineWidth',1.5);
xlabel('Zeit [s]');  ylabel('z'' [mm/s]');
title('Geschwindigkeit z''(t)');
grid on; grid minor;

sgtitle(' Masseschwinger — Konstante Daempfung', ...
        'FontSize',13,'FontWeight','bold');

%--- Grafik 3: Variable Daempfung ---
figure('Name',' Variable Daempfung','Color','w', ...
       'Position',[100 50 1000 650]);

subplot(3,1,1);
plot(t_sol, F_sol,'m-','LineWidth',1.5);
xlabel('Zeit [s]');  ylabel('F(t) [N]');
title('Erregerkraft F(t)');
grid on; grid minor;

subplot(3,1,2);
plot(t_var, z_var*1000,'g-','LineWidth',2); hold on;
yline(z_ss*1000,'r--','LineWidth',1.8, ...
      'Label',sprintf('z_{ss} = %.3f mm',z_ss*1000), ...
      'LabelHorizontalAlignment','right');
xlabel('Zeit [s]');  ylabel('z [mm]');
title('Position z(t) — Variable Daempfung (Look-Up Table)');
grid on; grid minor;

subplot(3,1,3);
plot(t_var, dz_var*1000,'k-','LineWidth',1.5);
xlabel('Zeit [s]');  ylabel('z'' [mm/s]');
title('Geschwindigkeit z''(t)');
grid on; grid minor;

sgtitle(' Masseschwinger — Variable Daempfung (Look-Up)', ...
        'FontSize',13,'FontWeight','bold');

%--- Grafik 4: Vergleich ---
figure('Name',' Vergleich','Color','w','Position',[150 50 1000 450]);

plot(t_sol, z_const*1000,'b-','LineWidth',2, ...
     'DisplayName',sprintf('Konstant D=%d N·s/m',D)); hold on;
plot(t_var, z_var*1000,  'r-','LineWidth',2, ...
     'DisplayName','Variabel (Look-Up Table)');
yline(z_ss*1000,'k--','LineWidth',1.5, ...
      'Label',sprintf('z_{ss} = %.3f mm',z_ss*1000), ...
      'LabelHorizontalAlignment','right','HandleVisibility','off');
xlabel('Zeit [s]');  ylabel('z [mm]');
title(sprintf(' Vergleich — Amplitudenreduktion: %.1f %%', verbesserung));
legend('Location','best');
grid on; grid minor;


