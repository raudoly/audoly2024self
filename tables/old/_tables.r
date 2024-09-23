# convert/format a bunch of tables to Tex
# requires the 'Hmisc' package

require(Hmisc)

## Table: transition rates in the data 

dat <- read.csv("transitions.csv")
trans <- matrix(nrow = 3, ncol = 3)
trans[1,1] <- dat$PP_rate
trans[1,2] <- dat$PS_rate
trans[1,3] <- dat$PU_rate
trans[2,1] <- dat$SP_rate
trans[2,2] <- dat$SS_rate
trans[2,3] <- dat$SU_rate
trans[3,1] <- dat$UP_rate
trans[3,2] <- dat$US_rate
trans[3,3] <- dat$UU_rate

rownames(trans) <- c("P","S","U")
colnames(trans) <- c("P","S","U")

textab <- latex(trans,file = "transitions.tex",
           rowlabel = "Orig./Dest.",dec = 3,
           table.env=F,booktabs=T,center="none")

## Table: externally calibrated parameters

dat <- read.csv("../model/inputs/transitions.csv")


params.name <- c("$\\sigma$",
                 "$r$",
                 "$\\delta_p$",
                 "$\\delta_s$")

params.desc <- c("CRRA utility parameter",
                 "risk-free rate",
                 "separation rate (paid-)",
                 "termination rate (self-)") 

params.value <- c("2",
                   "$(1+.045)^{1/12}-1$",
                   format(dat$PU, digits = 2),
                   format(dat$SU, digits = 2))

params.target <- c("\\cite{LiseOntheJobSearchPrecautionary2013,Saporta-EkstenJoblossconsumption2014}",
                   "4.5\\% annual return",
                   "SIPP",
                   "SIPP")

params.table <- data.frame(params.name,
                           params.desc,
                           params.value,
                           params.target)

textab <- latex(params.table, file = "calibrated_params.tex",
           colheads = c("Parameter","Description","Value","Target/Source"),
           rowlabel = "", rowname = NULL, 
           table.env = F, booktabs = T, center="none")


## Table: internally calibrated parameters

dat <- read.csv("../model/inputs/params.csv", header = F, col.names = "Value")

params.names <- c("$\\lambda_{PP}$",
                  "$\\lambda_{SS}$",
                  "$\\lambda_{SP}$",
                  "$\\lambda_{PS}$",
                  "$\\lambda_{UP}$",
                  "$\\lambda_{US}$",
                  "$\\beta$",
                  "$\\alpha_1^P$",
                  "$\\alpha_1^S$",
                  "$\\alpha_2^P$",
                  "$\\alpha_2^S$",
                  "$\\alpha_3^P$",
                  "$\\alpha_3^S$",
                  "$\\alpha_4^P$",
                  "$\\alpha_4^S$",
                  "$\\alpha_5^P$",
                  "$\\alpha_5^S$")

params.desc <- c("",
                 "$\\lambda_{ss'}$ is chance to sample from $F_k^{s'}$, when in state $s$",
                 "\\qquad $s$: origin state",
                 "\\qquad $F_k^{s'}$: labor income draw for worker of type $k$ in state $s'$",
                 "",
                 "",
                 "Monthly discount factor",
                 "",
                 "",
                 "",
                 "Income draw is parametrized as truncated Pareto($\\underline{y}_k^s$,$\\overline{y}_k^s$,$\\alpha_k^s$)",
                 "\\qquad $\\underline{y}_k^s$: p02 of income distribution for type $k$ in state $s$",
                 "\\qquad $\\overline{y}_k^s$: p98 of income distribution for type $k$ in state $s$",
                 "\\qquad $\\alpha_k^s$: shape parameter for type $k$ in state  $s$",
                 "",
                 "",
                 "")

params.table <- data.frame(Parameter = params.names,
                           Value = dat,
                           Description = params.desc)

textab <- latex(params.table, file = "estimated_params.tex", 
           rowlabel = "", rowname = NULL,
           dec = 3, table.env = F, 
           booktabs = T, center="none")


## Table: model fit to transition rates

dat <- read.csv("fit_transitions.csv")
rownames(dat) <- c("UP rate","US rate","SP rate","SS rate","PS rate","PP rate","PU rate","SU rate")
textab <- latex(dat,file = "fit_transitions.tex", 
           rowlabel = "",
           dec=4, table.env=F, booktabs=T, center="none")


## Table: contribution vs payouts

dat <- read.csv("cont_ben.csv", header = T)
dat <- dat[with(dat, order(auxinc)), ]
colnames(dat) <- c("Worker class ($\\$y_k^{HH}$)",
                   "$E$(contributions)",
                   "$E$(benefits)",
                   "Ratio cont. to ben.")

textab <- latex(dat, file = "cont_ben.tex",
                rowlabel = "", rowname = NULL,
                cdec = c(0,1,1,2), table.env = F,
                booktabs = T, center="none")

## Table: insurance value - paper

dat <- read.csv("comp_diff.csv", header = TRUE)
dat <- dat[with(dat,order(auxinc)),]

rownames(dat) <- dat$auxinc
dat$auxinc <- NULL
dat$Delta_dura <- NULL # Should be included in table at some point!
dat$Delta_cons <- 100*dat$Delta_cons
dat$Delta_cons_s <- 100*dat$Delta_cons_s
dat$Delta_cons_c <- 100*dat$Delta_cons_c

textab <- latex(dat, file = "comp_diff.tex",
                rowlabel = "Worker class  ($\\$y_k^{HH}$)",
                cgroup = c("All workers","$s = S$","$s = C$"),
                colheads = c("\\% $\\Delta^\\text{comp}_{b,\\tau}$","$\\Delta^\\text{transfer}_{b,\\tau}$",
                             "\\% $\\Delta^\\text{comp}_{b,\\tau}$","$\\Delta^\\text{transfer}_{b,\\tau}$",
                             "\\% $\\Delta^\\text{comp}_{b,\\tau}$","$\\Delta^\\text{transfer}_{b,\\tau}$"),
                table.env = F, cdec = c(2,0,1,0,1,0),
                booktabs = T, center="none")


## Table: insurance value - slides

dat <- read.csv("comp_diff.csv", header = TRUE)
dat <- dat[with(dat,order(auxinc)),]

rownames(dat) <- dat$auxinc
dat <- subset(dat, select = c(Delta_cash_s,Delta_cash_c,Delta_dura))

textab <- latex(dat, file = "comp_diff_pres.tex",
                rowlabel = "class  ($\\$y_k^{HH}$)",
                colheads = c("$\\Delta^\\text{transfer}_{b,\\tau} s = S$","$\\Delta^\\text{transfer}_{b,\\tau} s = C$","$\\Delta^\\text{duration}_{b,\\tau}$"),
                table.env = F, cdec = c(0,0,2),
                booktabs = T, center="none")

## Table: optimal policies

dat <- read.csv("opt_pol.csv")
dat <- dat[with(dat,order(auxinc)),]

rownames(dat) <- dat$auxinc
dat$auxinc <- NULL

textab <- latex(dat, file = "opt_pol.tex",
                rowlabel = "Worker class  ($\\$y_k^{HH}$)",
                colheads = c("replacement ($b_S^*$)","contribution ($\\tau_S^*$)"),
                cdec = c(2,3), table.env = F,
                booktabs = T, center="none")

