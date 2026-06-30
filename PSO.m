%% PSO for joint placement of Edges & Servers + line plots
clc; clear; close all; rng(1);

%% ---- Settings --------------------------------------------------------
numParticles = 80;  T = 60;
wMax = 0.9; wMin = 0.4;
c1 = 1.6; c2 = 1.6; vmax = 0.15;
alpha = 0.25; beta = 0.25; gamma = 0.25; delta = 0.25;

% min–max normalization bounds
NB.latency = [0, 50];
NB.energy  = [0, 1.5];
NB.loadVar = [0, 10];
NB.hotspot = [0, sqrt(2)];

results = []; 
k = 1;

%% ---- Sweep Edge/Server sizes -----------------------------------------
for N = 10:10:100
  for S = 3:3:30
    fprintf('PSO: N=%d, S=%d\n', N, S);

    Edge0   = rand(N,2);
    Server0 = rand(S,2);

    [bestPlacement, bestFit, M] = runPSO(Edge0, Server0, ...
        numParticles, T, wMax, wMin, c1, c2, vmax, ...
        alpha, beta, gamma, delta, NB);

    optEdges   = bestPlacement(1:N,:);
    optServers = bestPlacement(N+1:end,:);

    % ================================================================
    % 🔵 METHOD 2 — EXPORT OPTIMIZED COORDINATES FOR COOJA
    % ================================================================
    filename = sprintf('coords_E%d_S%d.txt', N, S);
    fid = fopen(filename,'w');
    fprintf(fid, "NODE_ID\tX\tY\tROLE\n");

    % write edge coordinates
    for i = 1:N
        fprintf(fid, "%d\t%.4f\t%.4f\tEDGE\n", i, optEdges(i,1), optEdges(i,2));
    end

    % write server coordinates
    for j = 1:S
        id = N + j;
        fprintf(fid, "%d\t%.4f\t%.4f\tSERVER\n", id, optServers(j,1), optServers(j,2));
    end

    fclose(fid);
    fprintf("Saved optimized placement: %s\n", filename);
    % ================================================================

    % store results row
    results = [results; N, S, bestFit, ...
               M.latency, M.energy, M.loadStd, M.hotspotMean]; %#ok<AGROW>

    % ---- Before vs After Plot --------------------------------------
    f = figure('Name',sprintf('Before vs After (E=%d,S=%d)',N,S),'Color','w');
    hold on; grid on; axis([0 1 0 1]); box on;

    scatter(Edge0(:,1),Edge0(:,2),30,'r','filled','MarkerFaceAlpha',0.4);
    scatter(Server0(:,1),Server0(:,2),60,'k^','filled','MarkerFaceAlpha',0.4);

    scatter(optEdges(:,1),optEdges(:,2),25,'g','filled');
    scatter(optServers(:,1),optServers(:,2),60,'b^','filled');

    title(sprintf('Before vs After (Edges=%d, Servers=%d)',N,S));
    legend('Initial Edge','Initial Server','Optimized Edge','Optimized Server','Location','best');
    xlabel('X'); ylabel('Y');

    saveas(f,sprintf('Plot_E%d_S%d.png',N,S));
    close(f);
    k = k+1;

  end
end

%% ---- Table of results -------------------------------------------------
ResultsTable = array2table(results, ...
  'VariableNames',{'Edges','Servers','Fitness','Latency_ms','Energy','LoadStd','HotspotMean'});

disp('--- Aggregate Results ---'); 
disp(ResultsTable);

save('ResultsTable.mat','ResultsTable');

%% =================== Line plots =======================================
allN = unique(ResultsTable.Edges);
NsToShow = [10 30 60 90];
NsToShow = NsToShow(ismember(NsToShow,allN));

metricList = { ...
   'Latency_ms','Latency (ms)','Latency_vs_Servers.png'; ...
   'Energy','Energy Proxy','Energy_vs_Servers.png'; ...
   'LoadStd','Workload Std. Dev.','Workload_vs_Servers.png'; ...
   'HotspotMean','Mean Hotspot Distance','Hotspot_vs_Servers.png'; ...
   'Fitness','Fitness (lower is better)','Fitness_vs_Servers.png' ...
};

styles = {'-o','-s','-^','-d','-x','-*','-v','-p'};

for m = 1:size(metricList,1)
    metricName = metricList{m,1};
    ylab       = metricList{m,2};
    outfile    = metricList{m,3};

    f = figure('Name',[ylab ' vs Servers'],'Color','w'); 
    hold on; grid on; box on;
    lg = strings(0,1);

    for k = 1:numel(NsToShow)
        Nval = NsToShow(k);
        rows = ResultsTable.Edges==Nval;
        Svals = ResultsTable.Servers(rows);
        Yvals = ResultsTable.(metricName)(rows);

        [Svals, idx] = sort(Svals); 
        Yvals = Yvals(idx);

        plot(Svals, Yvals, styles{mod(k-1,numel(styles))+1}, ...
             'LineWidth',1.6, 'MarkerSize',6);

        lg(end+1) = "Edges = " + string(Nval);
    end

    xlabel('Servers'); ylabel(ylab);
    title([ylab ' vs. Servers']);
    legend(lg,'Location','best');
    saveas(f, outfile);
end

%% -------- Optional: vs Edges ------------------------------------------
doAlsoPlotVsEdges = true;

if doAlsoPlotVsEdges
    allS = unique(ResultsTable.Servers);
    SsToShow = [6 15 24 30];
    SsToShow = SsToShow(ismember(SsToShow,allS));

    metricList2 = { ...
       'Latency_ms','Latency (ms)','Latency_vs_Edges.png'; ...
       'Energy','Energy Proxy','Energy_vs_Edges.png'; ...
       'LoadStd','Workload Std. Dev.','Workload_vs_Edges.png'; ...
       'HotspotMean','Mean Hotspot Distance','Hotspot_vs_Edges.png'; ...
       'Fitness','Fitness (lower is better)','Fitness_vs_Edges.png' ...
    };

    for m = 1:size(metricList2,1)
        metricName = metricList2{m,1};
        ylab       = metricList2{m,2};
        outfile    = metricList2{m,3};

        f = figure('Name',[ylab ' vs Edges'],'Color','w'); 
        hold on; grid on; box on;
        lg = strings(0,1);

        for k = 1:numel(SsToShow)
            Sval = SsToShow(k);
            rows = ResultsTable.Servers==Sval;
            Nvals = ResultsTable.Edges(rows);
            Yvals = ResultsTable.(metricName)(rows);

            [Nvals, idx] = sort(Nvals); 
            Yvals = Yvals(idx);

            plot(Nvals, Yvals, styles{mod(k-1,numel(styles))+1}, ...
                 'LineWidth',1.6, 'MarkerSize',6);

            lg(end+1) = "Servers = " + string(Sval);
        end

        xlabel('Edges'); ylabel(ylab);
        title([ylab ' vs. Edges']);
        legend(lg,'Location','best');
        saveas(f, outfile);
    end
end

disp('Saved plots to PNG files.')

%% ======================= FUNCTIONS =====================================
function [bestPlacement, bestFitness, bestMetrics] = runPSO(EdgeNodes,ServerNodes, ...
    numParticles,T,wMax,wMin,c1,c2,vmax,alpha,beta,gamma,delta,NB)

  N = size(EdgeNodes,1);  
  S = size(ServerNodes,1);
  D = N+S;
  P(numParticles) = struct();

  for i=1:numParticles
      P(i).pos = rand(D,2);
      P(i).vel = zeros(D,2);

      [f,m] = fitnessOf(P(i).pos,N,S,alpha,beta,gamma,delta,NB);

      P(i).pbestPos = P(i).pos; 
      P(i).pbestFit = f; 
      P(i).pbestMet = m;
  end

  [~,idx] = min([P.pbestFit]); 
  gbest = P(idx); 
  elite = gbest;

  for t=1:T
      w = wMax - (wMax-wMin)*(t-1)/(T-1);

      for i=1:numParticles
          [f,m] = fitnessOf(P(i).pos,N,S,alpha,beta,gamma,delta,NB);

          if f < P(i).pbestFit
              P(i).pbestFit = f;
              P(i).pbestPos = P(i).pos;
              P(i).pbestMet = m;
          end
      end

      [~,idx] = min([P.pbestFit]); 
      gbest = P(idx);

      if gbest.pbestFit > elite.pbestFit
          gbest = elite;
      else
          elite = gbest;
      end

      for i=1:numParticles
          r1 = rand(D,2); 
          r2 = rand(D,2);

          P(i).vel = w.*P(i).vel ...
                     + c1.*r1.*(P(i).pbestPos - P(i).pos) ...
                     + c2.*r2.*(gbest.pbestPos - P(i).pos);

          P(i).vel = max(min(P(i).vel,vmax),-vmax);
          P(i).pos = P(i).pos + P(i).vel;
          P(i).pos = min(max(P(i).pos,0),1);
      end
  end

  bestPlacement = gbest.pbestPos;
  bestFitness   = gbest.pbestFit;
  bestMetrics   = gbest.pbestMet;
end

function [fit, M] = fitnessOf(placement,N,S,alpha,beta,gamma,delta,NB)
  edges   = placement(1:N,:);
  servers = placement(N+1:N+S,:);

  D = pdist2(edges, servers);
  [dmin, assign] = min(D,[],2);

  latency_ms  = mean(dmin) * 10;
  energyProxy = mean(dmin.^2);
  loadCount   = accumarray(assign,1,[S,1],@sum,0);
  loadStd     = std(loadCount,1);
  hotspot     = [0.5,0.5];

  hotspotMean = mean(vecnorm(placement - hotspot,2,2));

  Lz = z(latency_ms,NB.latency);
  Ez = z(energyProxy,NB.energy);
  Vz = z(loadStd,NB.loadVar);
  Hz = z(hotspotMean,NB.hotspot);

  fit = alpha*Lz + beta*Ez + gamma*Vz + delta*Hz;

  M.latency = latency_ms;
  M.energy = energyProxy;
  M.loadStd = loadStd;
  M.hotspotMean = hotspotMean;
end

function y = z(x,b)
  y = (x - b(1)) / (b(2)-b(1));
  y = min(max(y,0),1);
end
