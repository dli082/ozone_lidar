function mwr=loadMWRdata(mwrfilename)
%% read the microwave radiometer whole file
opts = delimitedTextImportOptions;
opts.Delimiter=',';
% mwrfilename='2021-09-24_00-04-06_lv2.csv';
rm=readtable(mwrfilename,opts);

%parse the height
height=cell2mat(cellfun(@str2num,table2array(rm(7,5:end-5)),'UniformOutput',false));% altitude of temperature profile /km

%parse the code for temperature and pressure
Tcode=cell2mat(cellfun(@str2num,table2array(rm(:,3)),'UniformOutput',false));% code to find temp
ind_temp=(Tcode==401);% rows index for temperature 
ind_p=(Tcode==201);% row index for surface pressure

% parse the time
time_array_utc=datetime(table2array(rm(ind_temp,2)),'inputFormat','MM/dd/yy HH:mm:ss');% time array for radiometer
[h,m,s] = hms(time_array_utc);
TimeInHour_utc=h+m./60+s./3600;
N=length(TimeInHour_utc);
% get the date(utc) of the first data 
mwrdate=datestr(time_array_utc(1),'yyyymmdd');

% parse the temperature and pressure using their code
temp_array=cell2mat(cellfun(@str2num,table2array(rm(ind_temp,5:end-5)),'UniformOutput',false))';% temperature profiles (each row)
p_array=100*cell2mat(cellfun(@str2num,table2array(rm(ind_p,6)),'UniformOutput',false));% surface pressure (Pa)

% P=P0(1-L(h-h0)/T0)^(gM/RL)
% Constant
R=8.31446;%ideal gas constant(J/mol.K)
g=9.80665;% gravitational acceleration (m/s^2)
M=0.0289652;% molar mass of dry air 0.0289652 (kg/mol)
%L=0.0065; %K/m
Na=6.02214*10^23;% [/mol]
T0=temp_array(1);% surface temperature (K)
h0=height(1);

Pres=nan(length(height),N);
ND_air=nan(length(height),N);% m^-3
for i=1:N
    p = polyfit(height',temp_array(:,i),1);
    L=-p(1)*1e-3;% K/m
    T0=p(2);
    Pres(:,i)=p_array(i).*(1-L*1e3*(height-h0)./T0).^(g*M/(R*L));%Pa
    ND_air(:,i)= Na/R.*Pres(:,i)./temp_array(:,i);
end 
 
mwr.time_array_utc=time_array_utc;
mwr.TimeInHour_utc=TimeInHour_utc;
mwr.mwrdate=mwrdate;
mwr.temp_array=temp_array;
mwr.p_array=p_array;
mwr.pres=Pres;
mwr.height=height;
mwr.NDAir_m3=ND_air;
% savefileName=['MWR',mwrdate,'.mat'];
% save(savefileName,'mwr');
end