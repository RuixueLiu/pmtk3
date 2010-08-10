function logB = mkSoftEvidence(localCPD, X)
%% Make a soft evidence matrix logB(j, t) = log p(X(:, t), S(t) = j)
% (unnormalized), where S(t) denotes the state of node t. 
%
%% Inputs:
%
% localCPD - a struct as created by e.g. gaussCpdCreate, representing a
%            local conditional probability distribution in a directed
%            graphical model.
%
% X       -  a dense matrix of size d-by-nnodes, where nnodes is e.g. the
%            number of nodes 'parameter-tied' to localCPD, or e.g. the
%            number of time steps in an hmm model, (the sequence
%            length).
%
%  Use NaN's in X for unobserved nodes. The corresponding column of B 
% will contain NaNs.
%%
assert(size(X, 1) == localCPD.d); 
[d, seqlen] = size(X); 
observed    = ~any(isnan(X), 1);
Xobs        = X(:, observed);
switch lower(localCPD.cpdType)
    case 'tabular'
        
        T              = localCPD.T;
        nstates        = size(T, 1); 
        B              = nan(nstates, seqlen);
        B(:, observed) = T(:, Xobs); % must have only one parent
        logB = log(B); 
        
    case 'condgauss'
        
        nstates  = localCPD.nstates;
        logB     = nan(nstates, seqlen);
        mu       = localCPD.mu;
        Sigma    = localCPD.Sigma;
        for j=1:nstates
            logB(j, observed) = rowvec(gaussLogprob(mu(:, j), Sigma(:, :, j), Xobs'));
        end
        
    case 'condmixgausstied'
        
        nstates = localCPD.nstates;
        nmix    = localCPD.nmix; 
        mu      = localCPD.mu;
        Sigma   = localCPD.Sigma;
        M       = localCPD.M;  % nstates-by-nmix
        logM    = log(M); 
        
        logP = nan(nmix, seqlen); 
        for k=1:nmix
           logP(k, observed) = rowvec(gaussLogprob(mu(:, k), Sigma(:, :, k), Xobs')); 
        end
        logB = nan(nstates, seqlen); 
        for j = 1:nstates
           logBj = bsxfun(@plus, logM(j, :)', logP(:, observed)); 
           logB(j, observed) = logsumexp(logBj, 1); 
        end
        
    otherwise
        error('%s is not a recognized CPD type', localCPD.cpdType);
end
end