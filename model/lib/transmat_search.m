function Qr = transmat_search(Vopt,Vref,dFrep,nopt,nref,na)
% Build transition matrix at search stage.

% Replicate value of option 
Vopt_rep = repmat(reshape(Vopt,na,nopt),nref,1);
Vopt_idx = repmat(reshape((1:na*nopt)',na,nopt),nref,1); % corresponding index in j

% Replicate reference value
Vref_rep = repmat(Vref,1,nopt);
Vref_idx = repmat((1:na*nref)',1,nopt); % corresponding index in i

% Probability of getting draw and accepting
dF_dec = (Vopt_rep>Vref_rep).*dFrep;

% Sparse transition matrix constructor
Qr = sparse(Vref_idx(:),Vopt_idx(:),dF_dec(:),na*nref,na*nopt);



