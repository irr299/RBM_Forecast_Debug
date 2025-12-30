% data assimilative forecast code:

% runs VERB in one step mode with constant boundary conditions but assimilates data
% on each of the three diffusion operations.

% firsr we must load initial condition from a special DA_init_file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create simulation directory if necessary
make_sim_dir(fcopt,simulation.dir)

d_time = fcopt.timestep/24 ; %time step in days

if fcopt.use_lanlstar
    fname='lanlextrap';
    gname=''
else
    fname='oneraextrap';
    gname='onera';
end

% loads magnetopause data, only T89 ATM. We could implement a computation for the 
% period of interest, though I think this would be computationally expensive for the time being
if fcopt.use_MP
    if (~fcopt.real_MP)
        kpdata = load(['files/MP_centeredDip__LCDS_T89.txt']);
        mp_data = reshape(kpdata,18,27,4);
        if fcopt.use_ext_MP % then extend MP by 1 Re
            mp_data(:,:,3) = mp_data(:,:,3) + fcopt.ext_MP_val;
        end
        mp_Kp = squeeze(mp_data(1,:,1));
    end
end

disp("PARPOOL STARTING")
if ~fcopt.run_cpp_only % no need if running cpp
    try
        parpool(fcopt.numcpu);
    catch 
            disp('parpool already started');
    end
end
disp("PARPOOL SUCCEED")

%%UTC:
%---------------------------------
if fcopt.use_specified_utc
    utc = specified_utc;
else
    [~,utc] = system('date -u +"%Y%m%d%H%M%S"');
    utc = datenum(str2num(utc(1:4)),str2num(utc(5:6)),str2num(utc(7:8)),...
    str2num(utc(9:10)),str2num(utc(11:12)),str2num(utc(13:14))); %define utc
end
new_utc = utc;
fprintf('UTC = %ws\n',datestr(utc));
fprintf('Setting end time to be UTC + %s\n',num2str(fcopt.forecast_duration));
end_time = utc + fcopt.forecast_duration;
if utc > end_time
    error('utc must be <= end_time');
end
%---------------------------------
fcopt.target_pc = pfunc(fcopt.target_epc);
fcopt.target_alpha_rad = degtorad(fcopt.target_alpha);

%% time to check the current grid file
%% current

dxx_folder = [simulation.dir,'DiffCoeff/'];
fck = dir([dxx_folder,'perp_grid.plt']);
if ~isempty(fck)
    [dxxL, dxxepc, dxxalpha, ~] = load_plt([dxx_folder, 'perp_grid.plt']);

    gc_ok = true;
    if dxxL.arr(1,1,1) ~= fcopt.L_min || ... 
        dxxL.arr(end,1,1) ~= fcopt.L_max || ... 
        size(dxxL.arr,1) ~=  fcopt.NL  
        fprintf('Lstar grid missmatch\n')
        gc_ok = false;
    end

    if dxxepc.arr(end,1,1) ~= fcopt.E_min || ... 
        dxxepc.arr(end,end,1) ~= fcopt.E_max
        fprintf('Energy grid missmatch\n')
        gc_ok = false;
    end

    if abs(dxxalpha.arr(end,1,1).*180/pi - fcopt.a_min) > 1e-4 || ... 
        abs(dxxalpha.arr(end,1,end).*180/pi - fcopt.a_max) > 1e-4 
        fprintf('Pitch Angle grid missmatch\n')
        gc_ok = false;
    end
else
    gc_ok = false;
end 
if (~gc_ok)
    % we need to reinterpolate dxx
    % first step is to run VERB and let it fail
    % it will compute a new grid in the processes
    if fcopt.Dxx_opt > 0
        create_dxx_ini(simulation.dir,fcopt.Dxx_opt);
    end
    VERB_dummy %run simulation to get the grid
    if fcopt.Dxx_opt > 0
        Interp_Dxx(simulation.dir,fcopt.Dxx_opt);
    end
end 

rsflag = false;
if fcopt.restart_simulation
    fck = dir(restart_file);
    if ~isempty(fck)
        restart_date = utc - fcopt.restart_offset;
        if strcmp(newfile,restart_file)
            warning(['save file and restart filenames are the same, reanalysis will',...
                'overwrite the original file']);
        end
        load(restart_file)
        %save(['./Output/',sftxt,'.mat'],'PSD','reanalysis_time','Kp',...
        % this utc is from the load file (old)
        otime = new_utc-fcopt.restart_cat_offset;

        [~,restart_inx] = min(abs(simulation.time - restart_date));
        [~,sinx] = min(abs(simulation.time - otime));
        previous_PSD = simulation.PSD(sinx:restart_inx-1,:,:,:);
        restart_IPSD = simulation.PSD(restart_inx,:,:,:);
        previous_Kp = Kp(sinx:restart_inx-1);
        %restart_IKp = Kp(restart_inx);
        previous_time = simulation.time(sinx:restart_inx-1);
        utc = new_utc;
        start_time = simulation.time(restart_inx);
        rsflag = true; % success
    end
end

time_range = [start_time end_time];

% this file contains the grid data, specified in Ini_dirs.m
folder = [simulation.dir,'Output/'];
[L, epc, alpha, pc] = load_plt([folder, 'perp_grid.plt']);
model.lstar = L.arr;
model.energy = epc.arr;
model.alpha = alpha.arr;
model.pc = pc.arr;

lvals = model.lstar(:,end,end);
model.invk = Lalpha2K(model.lstar,model.alpha);
model.invmu = pc2mu(model.lstar,model.pc,model.alpha);

% let's make a really simple model
% Fig. 6 Schulz and Lanzerotti
%clf

Lvals = [1 2 4 8];        
Evals = 10.^[-3 -2 -1 0 1 2 3];

[xi,yi] = ndgrid(Lvals,Evals);

Dtime = nan(length(Lvals),length(Evals));
Dtime(1,1) = 0.0003;
Dtime(1,2) = 0.003;
Dtime(end,1) = 0.003;
Dtime(end,2) = 0.03;

Dtime(1,end-1) = 25;
Dtime(1,end) = 200;
Dtime(end,end-1) = 200;
Dtime(end,end) = 1200;

LQ = 1:0.1:8;
EQ = 10.^(-4:0.1:4);
[xq,yq] = ndgrid(LQ,EQ); %1:0.5:8,-4:0.5:4);
if (true)
    nn = find(~isnan(Dtime(:)));
    F1 = scatteredInterpolant(log10(xi(nn)),log10(yi(nn)),log10(Dtime(nn)),...
        'linear','linear');

    %Dtime = 10.^(F1(log10(xq),log10(yq)));

else
    for il = 1:length(Lvals)
        nn = find(~isnan(Dtime(il,:)))
        if ~isempty(nn)
            Dtime(il,:) = 10.^interp1(log10(Evals(nn)),log10(Dtime(il,nn)),log10(Evals),'linear','extrap');
        end
    end
    for ie = 1:length(Evals)
        nn = find(~isnan(Dtime(:,ie)))
        if ~isempty(nn)
        Dtime(:,ie) = 10.^interp1(log10(Lvals(nn)),log10(Dtime(nn,ie)),log10(Lvals),'linear');
        %Dtime(:,ie) = interp1(Lvals(nn),Dtime(nn,ie),Lvals,'linear');
        end
    end
end

xq = model.lstar;
yq = model.energy;
Drift_freq = 10.^(F1(log10(model.lstar),log10(model.energy)));
Drift_time = (1 ./ (Drift_freq.*1e-3)) ./ 3600; % to hours

%specification of initial analysis error covariance matrices
if ~exist('Pa_alpha','var') || fcopt.reset_cov_mat
    Pa_alpha=zeros(fcopt.NL,fcopt.NE,fcopt.NA,fcopt.NA); % then initialize as zero
end
if ~exist('Pa_pc','var') || fcopt.reset_cov_mat;
    Pa_pc=zeros(fcopt.NL,fcopt.NA,fcopt.NE,fcopt.NE);
end
if ~exist('Pa_L','var') || fcopt.reset_cov_mat;
    Pa_L=zeros(fcopt.NE,fcopt.NA,fcopt.NL,fcopt.NL);
end

simulation.time = time_range(1):d_time:time_range(end);
nt = length(simulation.time);
%get_kp
kp_source="GFZ";
if exist([getenv('FC_HOME') '/3DDA/' 'maginput.mat'])
	vars=load([getenv('FC_HOME') '/3DDA/' 'maginput.mat']);
	% check if identical time series already exists
	if (sum(vars.simulation.time==simulation.time)==length(simulation.time))==1
	    maginput=vars.maginput;
    else
        [maginput] = make_maginput_all_realtime_from_mat(simulation.time,getenv('FC_ACE_REALTIME_PROCESSED_DATA_DIR'),getenv('FC_KP_MAT'),getenv('FC_DST_PRE'),getenv('FC_DST_ACT'));
	    maginput = maginput';
        kp_source=load(getenv('FC_KP_MAT')).fc_used;
	    save([getenv('FC_HOME') '/3DDA/' 'maginput.mat'],'maginput','simulation');
	end
else
        [maginput] = make_maginput_all_realtime_from_mat(simulation.time,getenv('FC_ACE_REALTIME_PROCESSED_DATA_DIR'),getenv('FC_KP_MAT'),getenv('FC_DST_PRE'),getenv('FC_DST_ACT'));
        kp_source=load(getenv('FC_KP_MAT')).fc_used;
    maginput = maginput';
    save([getenv('FC_HOME') '/3DDA/' 'maginput.mat'],'maginput','simulation');
end
kp_index=maginput(:,1);
kp_time=simulation.time;

% loss cone values:
alc_arr = alc(L.arr);

%% we only need to load data if we are assimilating it
if ~fcopt.model_simulation_only
    clear spc_time spc_PSD spc_Lstar spc_InvK spc_InvMu 
    if fcopt.use_high_p
        hptxt = 'HPREC';
    else
        hptxt = ''; 
    end
%% load realtime data
    rb_data_dir = [getenv('FC_RBSP_REALTIME_PROCESSED_DATA_DIR')];
    goes_data_dir = [getenv('FC_GOES_REALTIME_PROCESSED_DATA_DIR')];
    arase_data_dir = [getenv('FC_ARASE_REALTIME_PROCESSED_DATA_DIR')];
    arase_xep_data_dir = [getenv('FC_ARASE_XEP_REALTIME_PROCESSED_DATA_DIR')];
    poes_data_dir = [getenv('FC_POES_REALTIME_PROCESSED_DATA_DIR')];

    nspc = 4;
    nt2 = length(simulation.time);
    simulation.obs_PSD = nan(nspc,nt2,fcopt.NL,fcopt.NE,fcopt.NA);
    %simulation.obs_PSD_err = nan(size(PSD_obs,1),nt2,fcopt.NL,fcopt.NE,fcopt.NA);
    %load([rb_data_dir,'rba_flux_and_psd.mat']);
    rbspa = load_rbsp_data(start_time,utc,rb_data_dir,'rba_MAGEIS_',fcopt.mfmtxt,fname);
    rbspb = load_rbsp_data(start_time,utc,rb_data_dir,'rbb_MAGEIS_',fcopt.mfmtxt,fname);
    goes_primary = load_goes_data(start_time,utc,goes_data_dir,'primary_flux_e_',fcopt.mfmtxt,fname);
    goes_secondary = load_goes_data(start_time,utc,goes_data_dir,'secondary_flux_e_',fcopt.mfmtxt,fname);
    
    % arase = load_arase_data(start_time,utc,arase_data_dir,'arase_hep_',fcopt.mfmtxt,fname);
    arase_xep = load_arase_xep_data(start_time,utc,arase_xep_data_dir,'Arase_n4_4_',fcopt.mfmtxt,fname);
%     poes_m01 = load_poes_data_trapped(start_time,utc,poes_data_dir,'poes_m01_',fcopt.mfmtxt,fname)
%     poes_m02 = load_poes_data_trapped(start_time,utc,poes_data_dir,'poes_m02_',fcopt.mfmtxt,fname)
%     poes_m03 = load_poes_data_trapped(start_time,utc,poes_data_dir,'poes_m03_',fcopt.mfmtxt,fname)
%     poes_n15 = load_poes_data_trapped(start_time,utc,poes_data_dir,'poes_n15_',fcopt.mfmtxt,fname)
%     poes_n18 = load_poes_data_trapped(start_time,utc,poes_data_dir,'poes_n18',fcopt.mfmtxt,fname)
%     poes_n19 = load_poes_data_trapped(start_time,utc,poes_data_dir,'poes_n19_',fcopt.mfmtxt,fname)
    
    rbspa.InvK = Lalpha2K(rbspa.Lstar,rbspa.Pitch_Angles.*pi/180);
    rbspb.InvK = Lalpha2K(rbspb.Lstar,rbspb.Pitch_Angles.*pi/180);
    goes_primary.InvK = Lalpha2K(goes_primary.Lstar,goes_primary.Pitch_Angles.*pi/180);
    goes_secondary.InvK = Lalpha2K(goes_secondary.Lstar,goes_secondary.Pitch_Angles.*pi/180);
    % arase.InvK = Lalpha2K(arase.Lstar,arase.Pitch_Angles.*pi/180);
    arase_xep.InvK = Lalpha2K(arase_xep.Lstar,arase_xep.Pitch_Angles.*pi/180);
%     poes_m01.InvK = Lalpha2K(poes_m01.Lstar,poes_m01.Pitch_Angles.*pi/180);
%     poes_m02.InvK = Lalpha2K(poes_m02.Lstar,poes_m02.Pitch_Angles.*pi/180);
%     poes_m03.InvK = Lalpha2K(poes_m03.Lstar,poes_m03.Pitch_Angles.*pi/180);
%     poes_n15.InvK = Lalpha2K(poes_n15.Lstar,poes_n15.Pitch_Angles.*pi/180);
%     poes_n18.InvK = Lalpha2K(poes_n18.Lstar,poes_n18.Pitch_Angles.*pi/180);
%     poes_n19.InvK = Lalpha2K(poes_n19.Lstar,poes_n19.Pitch_Angles.*pi/180);
%     poes_m01.PSD=poes_m01.PSD.*1000;  % MeV to keV
%     poes_m02.PSD=poes_m02.PSD.*1000;  % MeV to keV
%     poes_m03.PSD=poes_m03.PSD.*1000;  % MeV to keV
%     poes_n15.PSD=poes_n15.PSD.*1000;  % MeV to keV
%     poes_n18.PSD=poes_n18.PSD.*1000;  % MeV to keV
%     poes_n19.PSD=poes_n19.PSD.*1000;  % MeV to keV
%     arase.PSD=arase.PSD.*1000;  % MeV to keV
%     arase.PSD=arase.PSD.*pi;
%     arase.PSD=arase.PSD.*10;
%    arase.PSD=arase.PSD.*(4*pi);
%     arase.PSD=arase.PSD;
%     goes_primary.InvMu=goes_primary.InvMu./1e5;
%     scale_goes_psd=1e3;
%     goes_primary.PSD=goes_primary.PSD./1e6;
%     arase_xep.PSD=arase_xep.PSD.*1000./(4*pi);
%     arase_xep.PSD=arase_xep.PSD.*1000;
    % arase_xep.PSD=arase_xep.PSD.*(4*pi);


    fprintf('interpolating RBSPa data:\n');
    [rbspa.PSD_g] = interp2grid(simulation.time,model.invmu,model.invk,model.lstar,rbspa.time,rbspa.InvMu,rbspa.InvK,rbspa.Lstar,rbspa.PSD);
    fprintf('interpolating RBSPb data:\n');
    [rbspb.PSD_g] = interp2grid(simulation.time,model.invmu,model.invk,model.lstar,rbspb.time,rbspb.InvMu,rbspb.InvK,rbspb.Lstar,rbspb.PSD);
    fprintf('interpolating GOES primary data:\n');
    [goes_primary.PSD_g] = interp2grid(simulation.time,model.invmu,model.invk,model.lstar,goes_primary.time,goes_primary.InvMu,goes_primary.InvK,goes_primary.Lstar,goes_primary.PSD);
    fprintf('interpolating GOES secondary data:\n');
    [goes_secondary.PSD_g] = interp2grid(simulation.time,model.invmu,model.invk,model.lstar,goes_secondary.time,goes_secondary.InvMu,goes_secondary.InvK,goes_secondary.Lstar,goes_secondary.PSD);
    fprintf('interpolating ARASE data:\n');
    % [arase.PSD_g] = interp2grid(simulation.time,model.invmu,model.invk,model.lstar,arase.time,arase.InvMu,arase.InvK,arase.Lstar,arase.PSD);
    fprintf('interpolating ARASE_XEP data:\n');
    [arase_xep.PSD_g] = interp2grid(simulation.time,model.invmu,model.invk,model.lstar,arase_xep.time,arase_xep.InvMu,arase_xep.InvK,arase_xep.Lstar,arase_xep.PSD);
    % sel_mlt=arase_xep.MLT<18;
    sel_mlt=(arase_xep.MLT>10)&(arase_xep.MLT<15);
    [arase_xep.PSD_g] = interp2grid(simulation.time,model.invmu,model.invk,model.lstar,arase_xep.time(sel_mlt),arase_xep.InvMu(sel_mlt,:,:),arase_xep.InvK(sel_mlt,:),arase_xep.Lstar(sel_mlt,:),arase_xep.PSD(sel_mlt,:,:));
%     fprintf('interpolating POES M01 data:\n');
%     [poes_m01.PSD_g] = interp2grid(simulation.time,model.invmu,model.invk,model.lstar,poes_m01.time,poes_m01.InvMu,poes_m01.InvK,poes_m01.Lstar,poes_m01.PSD);
%     fprintf('interpolating POES M02 data:\n');
%     [poes_m02.PSD_g] = interp2grid(simulation.time,model.invmu,model.invk,model.lstar,poes_m02.time,poes_m02.InvMu,poes_m02.InvK,poes_m02.Lstar,poes_m02.PSD);
%     fprintf('interpolating POES M03 data:\n');
%     [poes_m03.PSD_g] = interp2grid(simulation.time,model.invmu,model.invk,model.lstar,poes_m03.time,poes_m03.InvMu,poes_m03.InvK,poes_m03.Lstar,poes_m03.PSD);
%     fprintf('interpolating POES N15 data:\n');
%     [poes_n15.PSD_g] = interp2grid(simulation.time,model.invmu,model.invk,model.lstar,poes_n15.time,poes_n15.InvMu,poes_n15.InvK,poes_n15.Lstar,poes_n15.PSD);
%     fprintf('interpolating POES N18 data:\n');
%     [poes_n18.PSD_g] = interp2grid(simulation.time,model.invmu,model.invk,model.lstar,poes_n18.time,poes_n18.InvMu,poes_n18.InvK,poes_n18.Lstar,poes_n18.PSD);
%     fprintf('interpolating POES N19 data:\n');
%     [poes_n19.PSD_g] = interp2grid(simulation.time,model.invmu,model.invk,model.lstar,poes_n19.time,poes_n19.InvMu,poes_n19.InvK,poes_n19.Lstar,poes_n19.PSD);

    sat_i=0;
%     sat_i=sat_i+1;simulation.obs_PSD(sat_i,:,:,:,:) = rbspa.PSD_g .* 2.997e7 ; %convert to VERB units
%     sat_i=sat_i+1;simulation.obs_PSD(sat_i,:,:,:,:) = rbspb.PSD_g .* 2.997e7 ; %convert to VERB units
    sat_i=sat_i+1;simulation.obs_PSD(sat_i,:,:,:,:) = goes_primary.PSD_g .* 2.997e7 ; %convert to VERB units
    sat_i=sat_i+1;simulation.obs_PSD(sat_i,:,:,:,:) = goes_secondary.PSD_g .* 2.997e7 ; %convert to VERB units
    % sat_i=sat_i+1;simulation.obs_PSD(sat_i,:,:,:,:) = arase.PSD_g .* 2.997e7 ; %convert to VERB units
    sat_i=sat_i+1;simulation.obs_PSD(sat_i,:,:,:,:) = arase_xep.PSD_g .* 2.997e7 ; %convert to VERB units
%     sat_i=sat_i+1;simulation.obs_PSD(sat_i,:,:,:,:) = poes_m01.PSD_g .* 2.997e7 ; %convert to VERB units
%     sat_i=sat_i+1;simulation.obs_PSD(sat_i,:,:,:,:) = poes_m02.PSD_g .* 2.997e7 ; %convert to VERB units
%     sat_i=sat_i+1;simulation.obs_PSD(sat_i,:,:,:,:) = poes_n15.PSD_g .* 2.997e7 ; %convert to VERB units
%     sat_i=sat_i+1;simulation.obs_PSD(sat_i,:,:,:,:) = poes_n18.PSD_g .* 2.997e7 ; %convert to VERB units
%     sat_i=sat_i+1;simulation.obs_PSD(sat_i,:,:,:,:)= poes_n19.PSD_g .* 2.997e7 ; %convert to VERB units
%     sat_i=sat_i+1;simulation.obs_PSD(sat_i,:,:,:,:)= poes_m03.PSD_g .* 2.997e7 ; %convert to VERB units
else
    % really need to rewrite this again so that the following is not dependent on existance of simulation.obs_PSD
    % then we wouldn't have to allocate these arrays as nans
    nspc = 5;
    nt2 = length(simulation.time);
    simulation.obs_PSD = nan(nspc,nt2,fcopt.NL,fcopt.NE,fcopt.NA);
    simulation.obs_PSD_err = nan(nspc,nt2,fcopt.NL,fcopt.NE,fcopt.NA);
end

%% obs errors
% errors = sum ( w.*PSD) ./ (w)

if fcopt.load_errors_from_file
    fprintf('combining data errors and PSD...');
    t1 = tic;
    zz = find(isnan(simulation.obs_PSD));
    simulation.obs_PSD_err(zz) = NaN;
    num = nansum(simulation.obs_PSD ./ simulation.obs_PSD_err,1);
    den = nansum(1./simulation.obs_PSD_err,1) ; % simulation.obs_PSD may have nans, while w may not
    simulation.obs_PSD = squeeze(num ./ den);        
    simulation.obs_PSD_err = squeeze(1 ./ den);
    clear num den

    errt = toc(t1);
    [tstr] = format_time(errt);
    fprintf('done in %s\n',tstr);
    
    fprintf('combining model errors and PSD...');

    %extrap_err_file = ['./Archive/Extrap_errors_',fstr.FDxxtxt,fstr.gtxt,fstr.cov_txt,'_',...
    %    fcopt.sol_meth,'_',fstr.dxxstr,'_outer',fstr.LUtxt,'_ts',...
    %    fstr.ts_str,fcopt.mfmtxt,fstr.mp_txt,fstr.mp_ext_txt,fstr.mp_r_txt,'.mat'];
    extrap_err_file = [fstr.err_sim_dir,'Archive/Extrap_errors.mat']; % by default, the error file lives in the equivalent directory when the load_errors_from_file fcopt switch is disabled

    fck = dir(extrap_err_file);
    if ~isempty(fck)
        load(extrap_err_file)
    else
        error('error file does not exist: %s\n',extrap_err_file);
    end

    fprintf('gridding errors...');
    m_err = griddata(reshape(errL,[],1),log10(reshape(errInvEnergy,[],1)),...
        reshape(errInvAlpha,[],1),reshape(verb_std,[],1),reshape(model.lstar,[],1),...
        reshape(log10(model.energy),[],1),reshape(model.alpha,[],1),'natural');
    m_err(isnan(m_err)) = 0.5;

    % we do not scale the errors, they are computed for each particular time step
    PSD_mod_err = reshape(m_err,fcopt.NL,fcopt.NE,fcopt.NA);
    
    fprintf('done\n');
    if fcopt.use_bias
        error('bias not implemented yet');
        fprintf('gridding bias to current grid and time step...');
        m_bias = griddata(reshape(errL,[],1),log10(reshape(errInvEnergy,[],1)),...
            reshape(errInvAlpha,[],1),reshape(verb_bias,[],1),reshape(model.lstar,[],1),...
            reshape(log10(model.energy),[],1),reshape(model.alpha,[],1),'natural');
        m_bias(isnan(m_err)) = 1.0; %default 1.0, which is no bias
        m_bias = m_bias .* fcopt.timestep; %bias is also saved in hourly format, so scaling is trivial
        model.bias = reshape(m_bias,fcopt.NL,fcopt.NE,fcopt.NA);
        fprintf('done\n');
    else
        model.bias = ones(fcopt.NL,fcopt.NE,fcopt.NA);
    end 
    clear verb_std verb_bias m_err m_bias errL errInvAlpha errInvEnergy
else    
    simulation.obs_PSD = squeeze(nanmean2(simulation.obs_PSD,1));
        %simulation.obs_PSD = simulation.obs_PSD;
    PSD_mod_err = ones(fcopt.NL,fcopt.NE,fcopt.NA) .* fcopt.mod_err_fix;
end

if fcopt.prog_plot
    mp_pos_arr = nan(nt,1);
end
simulation.PSD = nan(nt,fcopt.NL,fcopt.NE,fcopt.NA);
if fcopt.save_verb_xf
    ModPSD = nan(nt,fcopt.NL,fcopt.NE,fcopt.NA);
    dPSD = nan(nt,fcopt.NL,fcopt.NE,fcopt.NA);
    ModPSDup = zeros(nt,fcopt.NL,fcopt.NE,fcopt.NA);
end

% now let's clean up the inner belt based on MAGEIS obs. Fennel.
if fcopt.clean_innerBelt
    for il = 1:fcopt.NL
        % use dipole approx
        if model.lstar(il,1,1) < 2.6 % inner zone
            elim = 0.7; % MeV
            mc2=0.511; %MeV
            pclim = pfunc(elim);
            for ia=1:fcopt.NA
                mulim = (pclim.*sin(model.alpha(il,1,ia))).^2 ./ (2 .* mc2 .* 0.31/model.lstar(il,1,1)^.3);
                mtmp = model.invmu(il,:,ia);
                zz = find(mtmp > mulim);
                simulation.obs_PSD(:,il,zz,ia) = NaN;
            end
        end
    end
end

% set up Kp, remove any NaN's
% since Kp represents activity over time, we should interpolate to the time point
% midway between each time step: if simulating from t = 0 to t = 1 then we should 
% find the kp at t = 0.5 to best represent the interval.

% the variable 'simulation.time' represents the assimilation of data on time step t = 1
% and model results from time step t = 0 to t = 1; 
% therefore, Kp should be for t = t-dt/2;
% since we run the simulation one index behind (start at index t, but reference index t-1), we should actually
% compute kp for t = t+dt/2 to represent the simulation from t=1 to t=2;

Kp_t = simulation.time + d_time/2;
% so that on index 2, we will reference Kp(1), which will correspond to the interval t1 to t2
zz=find(~isnan(kp_index));
Kp_smooth = interp1(kp_time(zz),kp_index(zz),Kp_t,'linear');
Kp = interp1(kp_time(zz),kp_index(zz),Kp_t,'nearest','extrap');
Kp_recent = -1;  % we introduce this factor for the case when we load precomputed ABC matrices (suboptimal matrices, but faster. That method is not particularly accurate but may give a first approximation)

if fcopt.prog_plot
    lz = find(kp_time >= start_time-1 & kp_time < end_time + 1);
    fprintf('computing Lpp...');
    Lpp = calc_Lpp(kp_time(lz),kp_index(lz));
    Lpp_time = kp_time(lz);
    fprintf('done\n');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%%%     Start simulation/assimilation 
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5

if ~rsflag
    Kp_sim = Kp(1);   
    if isequal(Kp_sim,1e-32)
        Kp_sim=0;
    end
    run_VERB_SS %run simulation to get initial PSD
    IPSD(IPSD <= 1e-21) = 1e-21;
end

if fcopt.run_cpp_only 
    % then we can initialize the computation in cpp only and skip the for loop below.

    % In this case, we want to interpolate Kp to the mid time of the simulation interval, 
    % we do this, as VERB will read the kp and update Kp
    % by interpolating to the closest kp points in time surrounding the current simulation time point
    % the current simulation time represents the END of the interval, so really we need to shift the Kp by 
    % dt/2. 

    % note that the simulation time here is similar to that for the data assimilation, but the VERB code
    % referencing is different. VERB references index t for time interval t so we must set the Kp time 
    % differently

    % Simulation interval
    % t=0 -------dt-------t=1-------dt-------t=2;

    % For simulation at t=1 (representative of 0 to 1) VERB chooses Kp value at Kp time interpolated linearly
    % to t=1;

    % Hence to make sure Kp is accurate, we should interpolate Kp appropriatly

    % in Load_kp we load kp_time as the midpoint in the kp interval (1.5 represents 0-3 hrs)
    % so to interpolate it to t=1 we should interpolate the kp value to (t=0+dt/2)
    % this is the same as what we have done above for reanalysis, so we can keep the Kp

    % Then to read it correctly in VERB we should adjust the time to equal the simulation.time + dt;
    % this way, the kp read into VERB is representative of the interval which is simulated 
    % and not interpolated in some strange way. This also forces a ~= 0 in the Parameters.cpp, load_1d;

    Kp_tverb = simulation.time + d_time - simulation.time(1); %sim starts from 0 

    if size(Kp_tverb,1) == 1;
        Kp_tverb = Kp_tverb';
    end
    if size(Kp,1) == 1;
        Kp = Kp';
    end
    timekp = cat(2,Kp_tverb,Kp);
    saveascii(timekp,[simulation.dir,'Input/kp.dat'],5)
    ndays = time_range(2) - time_range(1);

    output_step = 1; %each step = 1

    mp_set = false; %no mp yet

    lastPSD.time = 0;
    lastPSD.arr = squeeze(IPSD);  %only if we load from a file
    run_VERB_noMM
    simulation.PSD = PSD.arr;
    save(newfile,'simulation','Kp','utc');

    return
end

if ~rsflag
    %simulation.PSD(1,:,:,:) = IPSD(1,:,:,:); % set the first point to SS solution
    simulation.PSD(1,:,:,:) = IPSD;%(1,:,:,:); % set the first point to SS solution
else
    simulation.PSD(1,:,:,:) = restart_IPSD; % in VERB units    
end

if (fcopt.use_obs_medIPSD)
    PSD_medobs = squeeze(nanmedian(simulation.obs_PSD,1));
    for il=1:fcopt.NL
        for ia=1:fcopt.NA
            zz=find(~isnan(PSD_medobs(il,:,ia)));
            if length(zz) > 3
                PSD_medobs(il,:,ia) = 10.^interp1(log10(model.invmu(il,zz,ia)),...
                    log10(PSD_medobs(il,zz,ia)),log10(model.invmu(il,:,ia)),'linear','extrap');
            end
        end
        for ie=1:fcopt.NE
            zz=find(~isnan(PSD_medobs(il,ie,:)));
            if length(zz) > 3
                PSD_medobs(il,ie,:) = 10.^interp1(squeeze(model.invk(il,ie,zz)).^(1/3),...
                    log10(squeeze(PSD_medobs(il,ie,zz))),squeeze(model.invk(il,ie,:)).^(1/3),'nearest','extrap');
                zz=find(~isnan(PSD_medobs(il,ie,:)));
                if ~isempty(zz)
                    simulation.PSD(1,il,ie,zz) = PSD_medobs(il,ie,zz);
                end
            end
        end
    end
    use_obs_medIPSD = false;
end

lastPSD.time = 0;

fprintf('\n');
fprintf('Beginning Simulation\n\n');
totaltime = tic;
oKp_sim = -1;
if fcopt.use_dxx_forecast
    fc_tinx = find(simulation.time <= utc);
    nt_sim = fc_tinx(end);
else
    nt_sim = nt;
end

index_start_fc=min(find(simulation.time >= utc));

for it=2:nt_sim % simulation always starts at point 2 (first computation is from f(t[1]) to f(t[2]);
    loopt = tic;
    Kp_step = Kp(it-1); % what was the kp representative of the transition of PSD
                        % to the current time? We will use this in the simulation
    %Kp_sim = Kp_smooth(it-1);
    Kp_sim = Kp_step;
    if isequal(Kp_sim,1e-32)
        Kp_sim=0;
    end


    %% for MP stuff, find the corresponding Kp value
    if fcopt.use_MP
        if (fcopt.real_MP)
            mp_set = true;
        else
            mp_set=false;
        end
    else
        mp_set = false;
    end
    if mp_set
        mpontxt = 'on';
        mpltxt = num2str(minL);
        mp_pos_arr(it) = minL;
    else
        mpontxt = 'off';
        mpltxt = '';
    end

    fprintf('Time: %s\n', datestr(simulation.time(it),'yyyy-mm-dd, HH:MM'));
    fprintf('Step: %s/%s, Kp: %s, MPset: %s %s\n',num2str(it),num2str(nt_sim),...
        num2str(Kp_sim,2),mpontxt,mpltxt);

    yrng = [-8 8];
    l_rng = [model.lstar(1,1,1) model.lstar(end,1,1)];

    if (fcopt.plot_PSD_profiles)
        plot_psd_profile
    end
    % introduce loop-specific variables
    % data
    if fcopt.ndastep > 1
        % need to reconsider this part    
        %PSD_d_loop = squeeze(nanmean2(simulation.obs_PSD(it-(fcopt.ndastep-1):it,:,:,:),1));  
        PSD_d_loop = squeeze(simulation.obs_PSD(it,:,:,:));  
    else
        PSD_d_loop = squeeze(simulation.obs_PSD(it,:,:,:));  
    end

    % reanalysis/simulation
    PSD_r_loop = squeeze(simulation.PSD(it-1,:,:,:));
    PSD_r_loop(PSD_r_loop <= 1e-21) = 1e-21;
    PSD_r_loop(isnan(PSD_r_loop)) = 1e-21;
    
    if fcopt.load_errors_from_file
        obs_err_loop = squeeze(simulation.obs_PSD_err(it,:,:,:));
        mod_err_loop = PSD_mod_err;
    else
        obs_err_loop = ones(fcopt.NL,fcopt.NE,fcopt.NA) .* fcopt.obs_err_fix;
        mod_err_loop = ones(fcopt.NL,fcopt.NE,fcopt.NA) .* fcopt.mod_err_fix;
    end
    %% run VERB for this time step

    %run_VERB_onestep_neumann_steps

   % 'here we now want to try to run the simulation but compute matrices each time'
   %' Compare with above'

    lastPSD.arr = PSD_r_loop;

    [~,~] = mkdir([simulation.dir,'DiffMat/']);

    if (fcopt.real_MP)
        [yr,mo,~,~,~,~] = datevec(simulation.time(it));
        dates = make_dates(yr,mo);
        mp_r_folder = [Satellite_data_dir,'MP/MP/Processed_Mat_Files/'];
        mp_lstar_file = [mp_r_folder,'MP_nopos_',fcopt.lcds,'_',dates,'_lstar_',fcopt.mfmtxt,'_ver3.mat'];
        mp_invk_file = [mp_r_folder,'MP_nopos_',fcopt.lcds,'_',dates,'_invk_',fcopt.mfmtxt,'_ver3.mat'];
        fck1 = dir(mp_lstar_file);
        fck2 = dir(mp_invk_file);
        if isempty(fck1) || isempty(fck2)
        fprintf('no real mp files found for this date\n');
            mp_L =[11.9 12 12.1];
            mp_K =[0 5 999];
        else
            load(mp_lstar_file);
            load(mp_invk_file);
            [~,mininx] = min(abs(simulation.time(it) - time));
            mp_L = Lstar(mininx,:);
            mp_K = InvK(mininx,:);
            zz = find(~isnan(mp_L) & ~isnan(mp_K));
            if isempty(zz)
                mp_L =[11.9 12 12.1];
                mp_K =[0 5 999];
            else
                mp_L = mp_L(zz);
                mp_K = mp_K(zz);
            end
        end
    else
        kpi=find(mp_Kp == round(Kp_step*10));
        mp_L = squeeze(mp_data(:,kpi,3));
        mp_K = squeeze(mp_data(:,kpi,4));
    end
    [mp_K,i_sortK] = sort(mp_K);
    mp_L = mp_L(i_sortK);
    [mp_K,b] = unique(mp_K);
    mp_L = mp_L(b);
    minL=min(mp_L);
    
    if minL < lvals(end) % then load MP coefficients for time step
        mp_set = true;
    else
        mp_set = false;
    end            
    if it<index_start_fc
        % reanalsyis
        if mp_set
            % low L magnetopause wrt boundary of 6.6
            matrices_file = [simulation.dir,fcopt.matfiles_reanalysis_lowmp,'Kp=',num2str(Kp_sim,2),'.mat'];
        else
            % high L magnetopause wrt boundary of 6.6
            matrices_file = [simulation.dir,fcopt.matfiles_reanalysis_highmp,'Kp=',num2str(Kp_sim,2),'.mat'];
        end
    else
        % forecast
        if mp_set
            % low L magnetopause wrt boundary of 6.6
            matrices_file = [simulation.dir,fcopt.matfiles_forecast_lowmp,'Kp=',num2str(Kp_sim,2),'.mat'];
        else
            % high L magnetopause wrt boundary of 6.6
            matrices_file = [simulation.dir,fcopt.matfiles_forecast_highmp,'Kp=',num2str(Kp_sim,2),'.mat'];
        end
    end


    fprintf('matrices_file: %s\n',matrices_file);

    if fcopt.fast_Dxx_load
        % use matrix load/save
        if oKp_sim ~= Kp_sim
            grd_fck = dir(matrices_file);
            matr_ok = false;
            if ~isempty(grd_fck)
                fprintf('loading matrices for Kp=%s...',num2str(Kp_sim,2));
                load(matrices_file);
                sz=size(alpha_matr_C);
                if sz(1) == fcopt.NL && sz(2) == fcopt.NE && sz(3) == fcopt.NA
                    matr_ok = true;
                    fprintf('ok\n');
                else
                    fprintf('matrix size mismatch\n');
                end
            end
            if ~matr_ok            
                run_VERB_loaddxx   
                [fPath, fName, fExt] = fileparts(matrices_file);
                [~,~]=mkdir(fPath);
                save(matrices_file,'L_matr_A','L_matr_B','L_matr_C',...
                                    'pc_matr_A','pc_matr_B','pc_matr_C',...
                                    'alpha_matr_A','alpha_matr_B','alpha_matr_C');

            end
            oKp_sim = Kp_sim;
        end

    %    VERB_MM_new
        if exist('oL_matr_A','var') && false % for testing
            L_A = isequal(oL_matr_A,L_matr_A);
            L_B = isequal(oL_matr_B,L_matr_B);
            L_C = isequal(oL_matr_C,L_matr_C);

            pc_A = isequal(opc_matr_A,pc_matr_A);
            pc_B = isequal(opc_matr_B,pc_matr_B);
            pc_C = isequal(opc_matr_C,pc_matr_C);
        
            alpha_A = isequal(oalpha_matr_A,alpha_matr_A);
            alpha_B = isequal(oalpha_matr_B,alpha_matr_B);
            alpha_C = isequal(oalpha_matr_C,alpha_matr_C);

            fprintf('Matrix summary\n==============\n');
            fprintf('L_A = %i\n',L_A);
            fprintf('L_B = %i\n',L_B);
            fprintf('L_C = %i\n\n',L_C);
            fprintf('pc_A = %i\n',pc_A);
            fprintf('pc_B = %i\n',pc_B);
            fprintf('pc_C = %i\n\n',pc_C);
            fprintf('alpha_A = %i\n',alpha_A);
            fprintf('alpha_B = %i\n',alpha_B);
            fprintf('alpha_C = %i\n\n',alpha_C);
            if L_A == 0 || ...
            L_B == 0 || ...
            L_C == 0 || ...
            pc_A == 0 || ...
            pc_B == 0 || ...
            pc_C == 0 || ...
            alpha_A == 0 || ...
            alpha_B == 0 || ...
            alpha_C == 0
            pause
            end
        end
    else
        run_VERB_loaddxx    
    end
   
    if fcopt.save_verb_xf
        PSD_m_loop = PSD_r_loop;
    end

    assimt = tic;        
    %%%diffusion for L
    if fcopt.use_Dll
        parfor j=1:fcopt.NE
        %for j=1:fcopt.NE
            w = warning ('off','all');
            PSD_L=PSD_r_loop(:,j,:);
            P_L = Pa_L(j,:,:,:);
            for k=1:fcopt.NA
                [PSD_L(:,1,k),matmodel]=matsolve(L_matr_A(j,k,:,:),...
                    L_matr_B(j,k,:),L_matr_C(j,k,:),PSD_L(:,1,k),'solution_method',fcopt.sol_meth);
                if ~(fcopt.model_simulation_only) && (mod(it,fcopt.ndastep) == 0)
                    [PSD_L(:,1,k),P_L(1,k,:,:)] = KalmanFilter_1Derrs(...
                        squeeze(PSD_L(:,1,k)),...
                        mod_err_loop(:,j,k),matmodel,squeeze(P_L(1,k,:,:)),...
                        squeeze(PSD_d_loop(:,j,k))',obs_err_loop(:,j,k));
                end
            end
            PSD_r_loop(:,j,:) = PSD_L;
            Pa_L(j,:,:,:) = P_L;
        end
        if fcopt.save_verb_xf
            parfor j=1:fcopt.NE
                PSD_L = PSD_m_loop(:,j,:);
                for k=1:fcopt.NA
                    [PSD_L(:,1,k),matmodel]=matsolve(L_matr_A(j,k,:,:),...
                        L_matr_B(j,k,:),L_matr_C(j,k,:),PSD_L(:,1,k),'solution_method',fcopt.sol_meth);
                end
                PSD_m_loop(:,j,:) = PSD_L;
            end
            PSD_m_loop(PSD_m_loop <= 1e-21 | isnan(PSD_m_loop)) = 1e-21;
        end

        PSD_r_loop(PSD_r_loop <= 1e-21) = 1e-21;
        PSD_r_loop(isnan(PSD_r_loop)) = 1e-21;
    end
%     if (fcopt.plot_PSD_profiles)
%         subplot(4,2,3:4)
%         plot(model.lstar(:,1,1),squeeze(log10(PSD_r_loop(:,:,12))));
%         xlim(l_rng);
%         ylim(yrng);
%     end

    %%%diffusion for alpha
    if fcopt.use_Daa
        parfor j=1:fcopt.NE
            PSD_A=PSD_r_loop(:,j,:);
            P_al = Pa_alpha(:,j,:,:);

            for i=1:fcopt.NL
                [PSD_A(i,1,:),matmodel]=matsolve(alpha_matr_A(i,j,:,:),...
                    alpha_matr_B(i,j,:),alpha_matr_C(i,j,:),PSD_A(i,1,:),'solution_method',fcopt.sol_meth);  
                if (fcopt.model_simulation_only==0 && mod(it,fcopt.ndastep)==0)
                    [PSD_A(i,1,:),P_al(i,1,:,:)] = KalmanFilter_1Derrs(...
                        squeeze(PSD_A(i,1,:)),squeeze(mod_err_loop(i,j,:)),matmodel,...
                        squeeze(P_al(i,1,:,:)),...
                        squeeze(PSD_d_loop(i,j,:))',squeeze(obs_err_loop(i,j,:)));
                end
            end
            PSD_r_loop(:,j,:) = PSD_A;
            Pa_alpha(:,j,:,:) = P_al;
        end
        if fcopt.save_verb_xf
            parfor j=1:fcopt.NE
                PSD_A=PSD_m_loop(:,j,:);
                P_al = Pa_alpha(:,j,:,:);
                for i=1:fcopt.NL
                    [PSD_A(i,1,:),matmodel]=matsolve(alpha_matr_A(i,j,:,:),...
                        alpha_matr_B(i,j,:),alpha_matr_C(i,j,:),PSD_A(i,1,:),'solution_method',fcopt.sol_meth);  
                end
                PSD_m_loop(:,j,:) = PSD_A;
            end
            PSD_m_loop(PSD_m_loop <= 1e-21 | isnan(PSD_m_loop)) = 1e-21;
        end
        PSD_r_loop(PSD_r_loop <= 1e-21 | isnan(PSD_r_loop)) = 1e-21;
    end

%     if (fcopt.plot_PSD_profiles)
%         subplot(4,2,5:6)
%         plot(model.lstar(:,1,1),squeeze(log10(PSD_r_loop(:,:,12))));
%         xlim(l_rng);
%         ylim(yrng);
%     end

    %%%diffusion for energy
    if fcopt.use_Dpp
        parfor k=1:fcopt.NA
            PSD_E = PSD_r_loop(:,:,k);
            P_pc = Pa_pc(:,k,:,:);
            for i=1:fcopt.NL
                [PSD_E(i,:,1),matmodel]=matsolve(pc_matr_A(i,k,:,:),...
                    pc_matr_B(i,k,:),pc_matr_C(i,k,:),PSD_E(i,:,1),'solution_method',fcopt.sol_meth);
                if (fcopt.model_simulation_only==0 && mod(it,fcopt.ndastep)==0)
                    [PSD_E(i,:,1),P_pc(i,1,:,:)] = KalmanFilter_1Derrs(...
                        squeeze(PSD_E(i,:,1)),squeeze(mod_err_loop(i,:,k))',matmodel,squeeze(P_pc(i,1,:,:)),...
                        squeeze(PSD_d_loop(i,:,k))',squeeze(obs_err_loop(i,:,k))');
                end 
            end                           
            PSD_r_loop(:,:,k) = PSD_E;
            Pa_pc(:,k,:,:) = P_pc;
        end
        if fcopt.save_verb_xf
            parfor k=1:fcopt.NA
                PSD_E = PSD_m_loop(:,:,k);
                P_pc = Pa_pc(:,k,:,:);
                for i=1:fcopt.NL
                    [PSD_E(i,:,1),matmodel]=matsolve(pc_matr_A(i,k,:,:),...
                        pc_matr_B(i,k,:),pc_matr_C(i,k,:),PSD_E(i,:,1),'solution_method',fcopt.sol_meth);
                end
                PSD_m_loop(:,:,k) = PSD_E;
            end
            PSD_m_loop(PSD_m_loop <= 1e-21 | isnan(PSD_m_loop)) = 1e-21;
        end

        PSD_r_loop(PSD_r_loop <= 1e-21 | isnan(PSD_r_loop)) = 1e-21;
    end
    if mp_set
        if minL < fcopt.L_max
            for iL=1:fcopt.NL
                if lvals(iL) >= minL
                    for iK = 1:fcopt.NA
                        Kval = model.invk(iL,1,iK);
                        MP_L_max = interp1(mp_K,mp_L,Kval,'nearest','extrap');
                        if lvals(iL) >= MP_L_max %then we are outside 
                            % take half the drift time
                            DT = squeeze(Drift_time(iL,:,iK)./2);
                            %PSD_r_loop(iL,:,iK) = PSD_r_loop(iL,:,iK) ...
                            %    .*exp(-100 .* fcopt.timestep ./ DT); % exp decay
                            PSD_r_loop(iL,:,iK) = PSD_r_loop(iL,:,iK) .* 1e-21;
                            %  PSD_d_loop(iL,:,iK) = NaN; % set to zero
                        end
                    end
                end
            end
        end
    end
    %% we have to empty the loss cone. Note that if you introduce further losses,
        %i.e. taulpp they need to be manually added here too
%     for i=1:fcopt.NL
%         PSDt = squeeze(PSD_r_loop(i,:,:));
%         for j=1:fcopt.NE
%             for k=1:fcopt.NA
%                 if alpha.arr(i,j,k) <= alc_arr(i,j,k) % works from 0 to pi/2 only
%                     taulc = 0.25 * bounce_time_new(L.arr(i,j,k), pc.arr(i,j,k), alpha.arr(i,j,k));
%                     PSDt(j,k) = PSDt(j,k) ./ d_time / (1/d_time + 1/taulc); %% implicit
%                 end
%             end
%         end
%         PSD_r_loop(i,:,:) = PSDt;
%     end
%     if fcopt.save_verb_xf
%         for i=1:fcopt.NL
%             PSDt = squeeze(PSD_m_loop(i,:,:));
%             for j=1:fcopt.NE
%                 for k=1:fcopt.NA
%                     if alpha.arr(i,j,k) <= alc_arr(i,j,k) % works from 0 to pi/2 only
%                         taulc = 0.25 * bounce_time_new(L.arr(i,j,k), pc.arr(i,j,k), alpha.arr(i,j,k));
%                         PSDt(j,k) = PSDt(j,k) ./ d_time / (1/d_time + 1/taulc); %% implicit
%                     end
%                 end
%             end
%             PSD_m_loop(i,:,:) = PSDt;
%         end
%     end 
    % ##################
    
%     if (fcopt.plot_PSD_profiles)
%         subplot(4,2,7:8)
%         plot(model.lstar(:,1,1),squeeze(log10(PSD_r_loop(:,:,12))));
%         xlim(l_rng);
%         ylim(yrng);
%     end

    if fcopt.save_verb_xf
        updatepts = find(~isnan(PSD_d_loop));
        ModPSD(it,:,:,:) = PSD_m_loop;
        dPSD(it,:,:,:) = PSD_d_loop;
        PSDup = zeros(fcopt.NL,fcopt.NE,fcopt.NA);
        PSDup(updatepts) = 1;
        ModPSDup(it,:,:,:) = PSDup;
    end
    
    simulation.PSD(it,:,:,:) = PSD_r_loop;

    if fcopt.plot_psd            
        plot_psd
    else
        plot_flux
    end
    
    if (fcopt.plot_PSD_profiles)
       plot_psd_profiles
       drawnow
    end
    tstr = format_time(toc(assimt));
    fprintf('ASSIMILATION TIME: %s\n',tstr);
    tstr = format_time(toc(loopt));
    fprintf('TOTAL STEP TIME: %s\n',tstr);
    tstr = format_time(toc(totaltime));
    fprintf('TOTAL SIMULATION TIME: %s\n',tstr);
    fprintf('Estimated Completion: %s\n',estimation_time(totaltime,it-1,nt_sim-1));
    fprintf('################\n')
    fprintf(' \n')
end
if fcopt.use_dxx_forecast
    for it=nt_sim+1:nt % simulation always starts at point 2 (first computation is from f(t[1]) to f(t[2]);
        loopt = tic;
        Kp_step = Kp(it-1); % what was the kp representative of the transition of PSD
                            % to the current time? We will use this in the simulation

        %% for MP stuff, find the corresponding Kp value
        if fcopt.use_MP
            if (fcopt.real_MP)
                [yr,mo,~,~,~,~] = datevec(simulation.time(it));
                dates = make_dates(yr,mo);
                mp_r_folder = [Satellite_data_dir,'MP/MP/Processed_Mat_Files/'];
                mp_lstar_file = [mp_r_folder,'MP_nopos_',fcopt.lcds,'_',dates,'_lstar_',fcopt.mfmtxt,'_ver3.mat'];
                mp_invk_file = [mp_r_folder,'MP_nopos_',fcopt.lcds,'_',dates,'_invk_',fcopt.mfmtxt,'_ver3.mat'];
                fck1 = dir(mp_lstar_file);
                fck2 = dir(mp_invk_file);
                if isempty(fck1) || isempty(fck2)
                fprintf('no real mp files found for this date\n');
                    mp_L =[11.9 12 12.1];
                    mp_K =[0 5 999];
                else
                    load(mp_lstar_file);
                    load(mp_invk_file);
                    [~,mininx] = min(abs(simulation.time(it) - time));
                    mp_L = Lstar(mininx,:);
                    mp_K = InvK(mininx,:);
                    zz = find(~isnan(mp_L) & ~isnan(mp_K));
                    if isempty(zz)
                        mp_L =[11.9 12 12.1];
                        mp_K =[0 5 999];
                    else
                        mp_L = mp_L(zz);
                        mp_K = mp_K(zz);
                    end
                end
            else
                kpi=find(mp_Kp == round(Kp_step*10));
                mp_L = squeeze(mp_data(:,kpi,3));
                mp_K = squeeze(mp_data(:,kpi,4));
            end
            [mp_K,i_sortK] = sort(mp_K);
            mp_L = mp_L(i_sortK);
            [mp_K,b] = unique(mp_K);
            mp_L = mp_L(b);
            minL=min(mp_L);
            if minL < lvals(end); % then load MP coefficients for time step
                mp_set = true;
            else
                mp_set = false;
            end            
        else
            mp_set = false;
        end
        if mp_set
            mpontxt = 'on';
            mpltxt = num2str(minL);
            mp_pos_arr(it) = minL;
        else
            mpontxt = 'off';
            mpltxt = '';
        end

        fprintf('Time: %s\n', datestr(simulation.time(it),'yyyy-mm-dd, HH:MM'));
        fprintf('Step: %s/%s, Kp: %s, MPset: %s %s\n',num2str(it),num2str(nt),...
            num2str(Kp_step,3),mpontxt,mpltxt);

        yrng = [-8 8];
        l_rng = [model.lstar(1,1,1) model.lstar(end,1,1)];

        if (fcopt.plot_PSD_profiles)
            plot_psd_profile
        end
        % introduce loop-specific variables
        % data

        % reanalysis/simulation
        PSD_r_loop = squeeze(simulation.PSD(it-1,:,:,:));
        PSD_r_loop(PSD_r_loop <= 1e-21) = 1e-21;
        PSD_r_loop(isnan(PSD_r_loop)) = 1e-21;
%         if mp_set && false
%             if minL < fcopt.L_max
%                 for iL=1:fcopt.NL
%                     if lvals(iL) >= minL
%                         for iK = 1:fcopt.NA
%                             Kval = model.invk(iL,1,iK);
%                             MP_L_max = interp1(mp_K,mp_L,Kval,'nearest','extrap');
%                             if lvals(iL) >= MP_L_max %then we are outside 
%                                 %PSD_r_loop(iL,:,iK) = 1e-21; % set to zero
% 
%                                 % take half the drift time
%                                 DT = squeeze(Drift_time(iL,:,iK)./2);
%                                 PSD_r_loop(iL,:,iK) = PSD_r_loop(iL,:,iK) ...
%                                     .*exp(-1.0 .* fcopt.timestep ./ DT); % exp decay
%                             end
%                         end
%                     end
%                 end
%             end
%         end
        %% run VERB for this time step
        lastPSD.arr = PSD_r_loop;
        run_VERB_FF_onestep
        PSD_r_loop = squeeze(PSD.arr(end,:,:,:));
        PSD_r_loop(PSD_r_loop <= 1e-21) = 1e-21;
        PSD_r_loop(isnan(PSD_r_loop)) = 1e-21;
        if mp_set
            if minL < fcopt.L_max
                parfor iL=1:fcopt.NL
                    if lvals(iL) >= minL
                        for iK = 1:fcopt.NA
                            Kval = model.invk(iL,1,iK);
                            MP_L_max = interp1(mp_K,mp_L,Kval,'nearest','extrap');
                            if lvals(iL) >= MP_L_max %then we are outside 
                                %PSD_r_loop(iL,:,iK) = 1e-21; % set to zero
                                % take half the drift time
                                DT = squeeze(Drift_time(iL,:,iK)./2);
                                PSD_r_loop(iL,:,iK) = PSD_r_loop(iL,:,iK) ...
                                    .*exp(-1.0 .* fcopt.timestep ./ DT); % exp decay
                            end
                        end
                    end
                end
            end
        end
        if mp_set
            if minL < fcopt.L_max
                parfor iL=1:fcopt.NL
                    if lvals(iL) >= minL
                        for iK = 1:fcopt.NA
                            Kval = model.invk(iL,1,iK);
                            MP_L_max = interp1(mp_K,mp_L,Kval,'nearest','extrap');
                            if lvals(iL) >= MP_L_max %then we are outside 
                                % take half the drift time
                                DT = squeeze(Drift_time(iL,:,iK)./2);
                                PSD_r_loop(iL,:,iK) = PSD_r_loop(iL,:,iK) ...
                                    .*exp(-10 .* fcopt.timestep ./ DT); % exp decay
                                %  PSD_d_loop(iL,:,iK) = NaN; % set to zero
                            end
                        end
                    end
                end
            end
        end
        simulation.PSD(it,:,:,:) = PSD_r_loop;

        tstr = format_time(toc(loopt));
        fprintf('TOTAL STEP TIME: %s\n',tstr);
        tstr = format_time(toc(totaltime));
        fprintf('TOTAL SIMULATION TIME: %s\n',tstr);
        fprintf('Estimated Completion: %s\n',estimation_time(totaltime,it-1,nt-1));
        fprintf('################\n')
        fprintf(' \n')

    end
end

if rsflag
    simulation.PSD=cat(1,previous_PSD,simulation.PSD);
    Kp=cat(2,previous_Kp,Kp);
    simulation.time=cat(2,previous_time,simulation.time);
end
%[maginput] = make_maginput_all(simulation_time);
%maginput = maginput';
%[maginput] = make_maginput_all_realtime(newtime);
%maginput = maginput';
%[maginput] = make_maginput_all_realtime(simulation.time,getenv('FC_SW_ACE'),getenv('FC_KP_FORECAST'),getenv('FC_KP_NOWCAST_ACT'),getenv('FC_KP_NOWCAST_PRE'),getenv('FC_DST_PRE'),getenv('FC_DST_ACT'));
%maginput = maginput';

% define satellite input data
% sat_input.rbspa=rbspa;
% sat_input.rbspb=rbspb;
sat_input.goes_primary=goes_primary;
sat_input.goes_secondary=goes_secondary;
% sat_input.arase=arase;
sat_input.arase_xep=arase_xep;

% if isrow(sat_input.arase.time)
%     sat_input.arase.time = sat_input.arase.time.';
% end

if isrow(sat_input.arase_xep.time)
    sat_input.arase_xep.time = sat_input.arase_xep.time.';
end


% sat_input.metop1b=poes_m01;
% sat_input.metop2a=poes_m02;
% sat_input.metopc=poes_m03;
% sat_input.noaa15=poes_n15;
% sat_input.noaa18=poes_n18;
% sat_input.noaa19=poes_n19;

mp.t=simulation.time;
mp.L=minL_from_mp(Kp,mp_data,mp_Kp);

savefig('output.fig');close(gcf)
[~,~] = mkdir(fileparts([getenv('FC_OUTPUTS_DIR') '/fullMat/' newfile]));
if length(newfile)>0
    save([getenv('FC_OUTPUTS_DIR') '/fullMat/' newfile],'simulation','utc','Pa_alpha','Pa_pc','Pa_L','maginput','sat_input','model','fcopt','mp','kp_source');
    fprintf('Output: %s\n',[getenv('FC_OUTPUTS_DIR') '/fullMat/' newfile]);
end
[~,~] = mkdir(fileparts([getenv('FC_PRODUCTS_DIR') '/latest/' newfile_latest_filename]));
if length(newfile_latest_filename)>0
    save([getenv('FC_PRODUCTS_DIR') '/latest/' newfile_latest_filename],'simulation','utc','Pa_alpha','Pa_pc','Pa_L','maginput','sat_input','model','fcopt','mp','kp_source');
    fprintf('Output: %s\n',[getenv('FC_PRODUCTS_DIR') '/latest/' newfile_latest_filename]);
end
if length(newfile_latest)>0
    save([getenv('FC_HOME') '/3DDA/' newfile_latest],'simulation','utc','Pa_alpha','Pa_pc','Pa_L','maginput','sat_input','model','fcopt','mp','kp_source');
    fprintf('Output: %s\n',[getenv('FC_HOME') '/3DDA/' newfile_latest]);
end
if fcopt.save_verb_xf
    save(newfile_err,'ModPSD','ModPSDup','dPSD');
end
