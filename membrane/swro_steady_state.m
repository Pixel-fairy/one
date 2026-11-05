function out = swro_steady_state(p)

required = {'feed_flow_m3s','feed_salinity_kgm3','feed_temp_C', ...
    'feed_pressure_bar','permeate_pressure_bar','membrane_area_m2', ...
    'pressure_drop_bar','A_LMH_bar','B_LMH','k_LMH','pump_eff', ...
    'ERD_eff','n_steps'};
for i = 1:numel(required)
    if ~isfield(p, required{i})
        error('Missing parameter: p.%s', required{i});
    end
end
if ~isfield(p, 'auxiliary_kW'), p.auxiliary_kW = 0; end

validateattributes(p.feed_flow_m3s, {'numeric'}, {'scalar','positive','finite'});
validateattributes(p.feed_salinity_kgm3, {'numeric'}, {'scalar','positive','finite'});
validateattributes(p.membrane_area_m2, {'numeric'}, {'scalar','positive','finite'});
validateattributes(p.n_steps, {'numeric'}, {'scalar','integer','>=',10});
validateattributes(p.pump_eff, {'numeric'}, {'scalar','>',0,'<=',1});
validateattributes(p.ERD_eff, {'numeric'}, {'scalar','>=',0,'<=',1});
if p.pressure_drop_bar < 0 || p.A_LMH_bar <= 0 || p.B_LMH < 0 || p.k_LMH <= 0
    error('Pressure drop must be >=0, A and k must be >0, and B must be >=0.');
end
if p.feed_pressure_bar <= p.permeate_pressure_bar
    error('Feed pressure must exceed permeate pressure.');
end
if p.pressure_drop_bar >= p.feed_pressure_bar - p.permeate_pressure_bar
    error('Pressure drop is too large relative to the available feed pressure.');
end

A = p.A_LMH_bar * 1e-3 / 3600;
B = p.B_LMH * 1e-3 / 3600;
k = p.k_LMH * 1e-3 / 3600;
T = p.feed_temp_C + 273.15;
if T <= 0, error('Temperature must be above absolute zero.'); end

n = double(p.n_steps);
dA = p.membrane_area_m2 / n;
q = zeros(n+1,1); saltRate = zeros(n+1,1);
pressure = zeros(n+1,1); feedC = zeros(n+1,1);
permeateCum = zeros(n+1,1); flux = zeros(n,1); cpLocal = zeros(n,1);
area = linspace(0, p.membrane_area_m2, n+1)';
q(1) = p.feed_flow_m3s;
saltRate(1) = p.feed_flow_m3s * p.feed_salinity_kgm3;
permeateSaltTotal = 0;

for j = 1:n
    xmid = (j - 0.5) / n;
    pressure(j) = p.feed_pressure_bar - p.pressure_drop_bar*xmid;
    feedC(j) = saltRate(j) / q(j);
    if q(j) <= 0 || saltRate(j) <= 0
        error('Feed flow or salt rate became non-positive. Reduce membrane area or increase feed flow.');
    end

    Jw = max(A * (pressure(j)-p.permeate_pressure_bar- ...
        osmotic_bar(feedC(j),T)), 0);
    for it = 1:60
        exponent = min(max(Jw/k,0), 2.5);
        Csurface = feedC(j) * exp(exponent);
        if Jw + B > 0
            Cp = B*Csurface/(Jw+B);
        else
            Cp = Csurface;
        end
        deltaPi = osmotic_bar(Csurface,T) - osmotic_bar(Cp,T);
        Jnew = A * max(pressure(j)-p.permeate_pressure_bar-deltaPi,0);
        if abs(Jnew-Jw) < max(1e-12,1e-7*max(Jnew,1e-12))
            Jw = Jnew;
            break;
        end
        Jw = 0.5*Jw + 0.5*Jnew;
    end

    exponent = min(max(Jw/k,0), 2.5);
    Csurface = feedC(j) * exp(exponent);
    if Jw + B > 0
        Cp = B*Csurface/(Jw+B);
    else
        Cp = Csurface;
    end

    dQp = Jw*dA;
    dSaltP = Cp*dQp;
    if dQp >= 0.98*q(j)
        error('A membrane-area step removes nearly all remaining feed. Increase n_steps, lower area, or raise feed flow.');
    end
    q(j+1) = q(j) - dQp;
    saltRate(j+1) = saltRate(j) - dSaltP;
    if saltRate(j+1) <= 0
        error('Salt balance became non-positive; inspect membrane parameters and discretization.');
    end
    permeateCum(j+1) = permeateCum(j) + dQp;
    permeateSaltTotal = permeateSaltTotal + dSaltP;
    flux(j) = Jw * 3600 / 1e-3;
    cpLocal(j) = Cp;
end
pressure(end) = p.feed_pressure_bar - p.pressure_drop_bar;
feedC(end) = saltRate(end)/q(end);

Qp = permeateCum(end);
if Qp <= 0
    error('The model predicted zero permeate production. Increase pressure or membrane permeability.');
end
productC = permeateSaltTotal/Qp;
recovery = Qp/p.feed_flow_m3s;
if recovery >= 1
    error('Calculated recovery is >=100%%; check parameters and discretization.');
end
brineC = saltRate(end)/q(end);
rejection = 100*(1-productC/p.feed_salinity_kgm3);

pump_kW = p.feed_pressure_bar*1e5*p.feed_flow_m3s/p.pump_eff/1000;
brinePressureBar = max(p.feed_pressure_bar-p.pressure_drop_bar,0);
recovered_kW = brinePressureBar*1e5*q(end)*p.ERD_eff/1000;
net_kW = max(pump_kW-recovered_kW,0) + p.auxiliary_kW;
product_m3h = Qp*3600;
SEC_kWhm3 = net_kW/product_m3h;

out.parameters = p;
out.summary.feed_flow_m3s = p.feed_flow_m3s;
out.summary.feed_salinity_kgm3 = p.feed_salinity_kgm3;
out.summary.permeate_flow_m3s = Qp;
out.summary.permeate_flow_m3h = product_m3h;
out.summary.brine_flow_m3s = q(end);
out.summary.recovery_fraction = recovery;
out.summary.recovery_percent = 100*recovery;
out.summary.product_salinity_kgm3 = productC;
out.summary.brine_salinity_kgm3 = brineC;
out.summary.salt_rejection_percent = rejection;
out.summary.average_flux_LMH = Qp/p.membrane_area_m2*3600/1e-3;
out.summary.pump_power_kW = pump_kW;
out.summary.energy_recovery_kW = recovered_kW;
out.summary.net_power_kW = net_kW;
out.summary.specific_energy_kWh_m3 = SEC_kWhm3;
out.profile.area_m2 = area;
out.profile.feed_flow_m3s = q;
out.profile.feed_salinity_kgm3 = feedC;
out.profile.pressure_bar = pressure;
out.profile.permeate_cumulative_m3s = permeateCum;
out.profile.local_flux_LMH = flux;
out.profile.local_permeate_salinity_kgm3 = cpLocal;
end

function pi_bar = osmotic_bar(C_kgm3, T_K)

R = 8.314462618;
MW_NaCl = 0.05844;
vanthoff_i = 2.0;
C_molm3 = max(C_kgm3,0)/MW_NaCl;
pi_bar = vanthoff_i*R*T_K*C_molm3/1e5;
end
