# Makefile for specs and stats (very sloppy)

DIR_CHECK = mkdir -p
SIZE = Rscript --vanilla scripts/size.Rscript
#MINFEAT = Rscript --vanilla scripts/minfeat.Rscript
FBALANCE = python src/contrastive-symmetry/balance.py --max-dim=0 --jobs=4
FNPAIRS = python src/contrastive-symmetry/pair_counts.py --jobs=7
SUM_FBALANCE = Rscript --vanilla scripts/sum_fbalance.Rscript
SUM_FNPAIRS = Rscript --vanilla scripts/sum_fnpairs.Rscript
AGGREGATE = bash scripts/aggregate_csv.sh
SPECS = python src/contrastive-symmetry/subset.py --binary \
				--max-frontier-expansion-cost=30000 --jobs=4 

all: stats
clean: clean-specs clean-stats

# Specifications

specs: specs/whole specs/cons specs/stop specs/vowel
specs/whole: specs/whole/nat/all.csv specs/whole/ctrl/all.csv \
						 specs/whole/wtd/all.csv specs/whole/unif/all.csv
specs/cons: specs/cons/nat/all.csv specs/cons/ctrl/all.csv \
						 specs/cons/wtd/all.csv specs/cons/unif/all.csv
specs/stop: specs/stop/nat/all.csv specs/stop/ctrl/all.csv \
						 specs/stop/wtd/all.csv specs/stop/unif/all.csv
specs/vowel: specs/vowel/nat/all.csv specs/vowel/ctrl/all.csv \
						 specs/vowel/wtd/all.csv specs/vowel/unif/all.csv

specs/whole/nat/all.csv:
	$(SPECS) data/whole/nat/all.csv specs/whole/nat/by_language
	$(AGGREGATE) specs/whole/nat/by_language > specs/whole/nat/all.csv
specs/whole/ctrl/all.csv:
	$(SPECS) data/whole/ctrl/all.csv specs/whole/ctrl/by_language
	$(AGGREGATE) specs/whole/ctrl/by_language > specs/whole/ctrl/all.csv
specs/whole/unif/all.csv:
	$(SPECS) data/whole/unif/all.csv specs/whole/unif/by_language
	$(AGGREGATE) specs/whole/unif/by_language > specs/whole/unif/all.csv
specs/whole/wtd/all.csv: 
	$(SPECS) data/whole/wtd/all.csv specs/whole/wtd/by_language
	$(AGGREGATE) specs/whole/wtd/by_language > specs/whole/wtd/all.csv

specs/cons/nat/all.csv:
	$(SPECS) data/cons/nat/all.csv specs/cons/nat/by_language
	$(AGGREGATE) specs/cons/nat/by_language > specs/cons/nat/all.csv
specs/cons/ctrl/all.csv:
	$(SPECS) data/cons/ctrl/all.csv specs/cons/ctrl/by_language
	$(AGGREGATE) specs/cons/ctrl/by_language > specs/cons/ctrl/all.csv
specs/cons/unif/all.csv:
	$(SPECS) data/cons/unif/all.csv specs/cons/unif/by_language
	$(AGGREGATE) specs/cons/unif/by_language > specs/cons/unif/all.csv
specs/cons/wtd/all.csv: 
	$(SPECS) data/cons/wtd/all.csv specs/cons/wtd/by_language
	$(AGGREGATE) specs/cons/wtd/by_language > specs/cons/wtd/all.csv

specs/stop/nat/all.csv:
	$(SPECS) data/stop/nat/all.csv specs/stop/nat/by_language
	$(AGGREGATE) specs/stop/nat/by_language > specs/stop/nat/all.csv
specs/stop/ctrl/all.csv:
	$(SPECS) data/stop/ctrl/all.csv specs/stop/ctrl/by_language
	$(AGGREGATE) specs/stop/ctrl/by_language > specs/stop/ctrl/all.csv
specs/stop/unif/all.csv:
	$(SPECS) data/stop/unif/all.csv specs/stop/unif/by_language
	$(AGGREGATE) specs/stop/unif/by_language > specs/stop/unif/all.csv
specs/stop/wtd/all.csv: 
	$(SPECS) data/stop/wtd/all.csv specs/stop/wtd/by_language
	$(AGGREGATE) specs/stop/wtd/by_language > specs/stop/wtd/all.csv

specs/vowel/nat/all.csv:
	$(SPECS) data/vowel/nat/all.csv specs/vowel/nat/by_language
	$(AGGREGATE) specs/vowel/nat/by_language > specs/vowel/nat/all.csv
specs/vowel/ctrl/all.csv:
	$(SPECS) data/vowel/ctrl/all.csv specs/vowel/ctrl/by_language
	$(AGGREGATE) specs/vowel/ctrl/by_language > specs/vowel/ctrl/all.csv
specs/vowel/unif/all.csv:
	$(SPECS) data/vowel/unif/all.csv specs/vowel/unif/by_language
	$(AGGREGATE) specs/vowel/unif/by_language > specs/vowel/unif/all.csv
specs/vowel/wtd/all.csv: 
	$(SPECS) data/vowel/wtd/all.csv specs/vowel/wtd/by_language
	$(AGGREGATE) specs/vowel/wtd/by_language > specs/vowel/wtd/all.csv

# Specifications (clean)

clean-specs: clean-specs-whole clean-specs-cons clean-specs-stop \
						 clean-specs-vowel
clean-specs-whole: clean-specs-whole-nat clean-specs-whole-ctrl \
						 clean-specs-whole-wtd clean-specs-whole-unif
clean-specs-cons: clean-specs-cons-nat clean-specs-cons-ctrl \
						 clean-specs-cons-wtd clean-specs-cons-unif
clean-specs-stop: clean-specs-stop-nat clean-specs-stop-ctrl \
						 clean-specs-stop-wtd clean-specs-stop-unif
clean-specs-vowel: clean-specs-vowel-nat clean-specs-vowel-ctrl \
						 clean-specs-vowel-wtd clean-specs-vowel-unif
clean-specs-whole-nat:
	rm -rf specs/whole/nat
clean-specs-whole-ctrl:
	rm -rf specs/whole/ctrl
clean-specs-whole-wtd:
	rm -rf specs/whole/wtd
clean-specs-whole-unif:
	rm -rf specs/whole/unif
clean-specs-cons-nat:
	rm -rf specs/cons/nat
clean-specs-cons-ctrl:
	rm -rf specs/cons/ctrl
clean-specs-cons-wtd:
	rm -rf specs/cons/wtd
clean-specs-cons-unif:
	rm -rf specs/cons/unif
clean-specs-stop-nat:
	rm -rf specs/stop/nat
clean-specs-stop-ctrl:
	rm -rf specs/stop/ctrl
clean-specs-stop-wtd:
	rm -rf specs/stop/wtd
clean-specs-stop-unif:
	rm -rf specs/stop/unif
clean-specs-vowel-nat:
	rm -rf specs/vowel/nat
clean-specs-vowel-ctrl:
	rm -rf specs/vowel/ctrl
clean-specs-vowel-wtd:
	rm -rf specs/vowel/wtd
clean-specs-vowel-unif:
	rm -rf specs/vowel/unif

# Statistics

stats: stats/size stats/sum_fbalance stats/sum_fnpairs

#stats/minfeat: stats/minfeat/whole stats/minfeat/cons stats/minfeat/stop \
#							 stats/minfeat/vowel 
#stats/minfeat/whole: stats/minfeat/whole/nat/all.csv \
#										 stats/minfeat/whole/ctrl/all.csv \
#										 stats/minfeat/whole/wtd/all.csv \
# 									   stats/minfeat/whole/unif/all.csv
#stats/minfeat/cons: stats/minfeat/cons/nat/all.csv \
#										 stats/minfeat/cons/ctrl/all.csv \
#										 stats/minfeat/cons/wtd/all.csv \
# 									   stats/minfeat/cons/unif/all.csv
#stats/minfeat/stop: stats/minfeat/stop/nat/all.csv \
#										 stats/minfeat/stop/ctrl/all.csv \
#										 stats/minfeat/stop/wtd/all.csv \
# 									   stats/minfeat/stop/unif/all.csv
#stats/minfeat/vowel: stats/minfeat/vowel/nat/all.csv \
#										 stats/minfeat/vowel/ctrl/all.csv \
#										 stats/minfeat/vowel/wtd/all.csv \
# 									   stats/minfeat/vowel/unif/all.csv
#
#stats/minfeat/whole/nat/all.csv: specs/whole/nat/all.csv
#	$(DIR_CHECK) stats/minfeat/whole/nat
#	$(MINFEAT) specs/whole/nat/all.csv stats/minfeat/whole/nat/all.csv
#stats/minfeat/whole/ctrl/all.csv: specs/whole/ctrl/all.csv
#	$(DIR_CHECK) stats/minfeat/whole/ctrl
#	$(MINFEAT) specs/whole/ctrl/all.csv stats/minfeat/whole/ctrl/all.csv
#stats/minfeat/whole/unif/all.csv: specs/whole/unif/all.csv
#	$(DIR_CHECK) stats/minfeat/whole/unif
#	$(MINFEAT) specs/whole/unif/all.csv stats/minfeat/whole/unif/all.csv
#stats/minfeat/whole/wtd/all.csv: specs/whole/wtd/all.csv
#	$(DIR_CHECK) stats/minfeat/whole/wtd
#	$(MINFEAT) specs/whole/wtd/all.csv stats/minfeat/whole/wtd/all.csv
#
#stats/minfeat/cons/nat/all.csv: specs/cons/nat/all.csv
#	$(DIR_CHECK) stats/minfeat/cons/nat
#	$(MINFEAT) specs/cons/nat/all.csv stats/minfeat/cons/nat/all.csv
#stats/minfeat/cons/ctrl/all.csv: specs/cons/ctrl/all.csv
#	$(DIR_CHECK) stats/minfeat/cons/ctrl
#	$(MINFEAT) specs/cons/ctrl/all.csv stats/minfeat/cons/ctrl/all.csv
#stats/minfeat/cons/unif/all.csv: specs/cons/unif/all.csv
#	$(DIR_CHECK) stats/minfeat/cons/unif
#	$(MINFEAT) specs/cons/unif/all.csv stats/minfeat/cons/unif/all.csv
#stats/minfeat/cons/wtd/all.csv: specs/cons/wtd/all.csv
#	$(DIR_CHECK) stats/minfeat/cons/wtd
#	$(MINFEAT) specs/cons/wtd/all.csv stats/minfeat/cons/wtd/all.csv
#
#stats/minfeat/stop/nat/all.csv: specs/stop/nat/all.csv
#	$(DIR_CHECK) stats/minfeat/stop/nat
#	$(MINFEAT) specs/stop/nat/all.csv stats/minfeat/stop/nat/all.csv
#stats/minfeat/stop/ctrl/all.csv: specs/stop/ctrl/all.csv
#	$(DIR_CHECK) stats/minfeat/stop/ctrl
#	$(MINFEAT) specs/stop/ctrl/all.csv stats/minfeat/stop/ctrl/all.csv
#stats/minfeat/stop/unif/all.csv: specs/stop/unif/all.csv
#	$(DIR_CHECK) stats/minfeat/stop/unif
#	$(MINFEAT) specs/stop/unif/all.csv stats/minfeat/stop/unif/all.csv
#stats/minfeat/stop/wtd/all.csv: specs/stop/wtd/all.csv
#	$(DIR_CHECK) stats/minfeat/stop/wtd
#	$(MINFEAT) specs/stop/wtd/all.csv stats/minfeat/stop/wtd/all.csv
#
#stats/minfeat/vowel/nat/all.csv: specs/vowel/nat/all.csv
#	$(DIR_CHECK) stats/minfeat/vowel/nat
#	$(MINFEAT) specs/vowel/nat/all.csv stats/minfeat/vowel/nat/all.csv
#stats/minfeat/vowel/ctrl/all.csv: specs/vowel/ctrl/all.csv
#	$(DIR_CHECK) stats/minfeat/vowel/ctrl
#	$(MINFEAT) specs/vowel/ctrl/all.csv stats/minfeat/vowel/ctrl/all.csv
#stats/minfeat/vowel/unif/all.csv: specs/vowel/unif/all.csv
#	$(DIR_CHECK) stats/minfeat/vowel/unif
#	$(MINFEAT) specs/vowel/unif/all.csv stats/minfeat/vowel/unif/all.csv
#stats/minfeat/vowel/wtd/all.csv: specs/vowel/wtd/all.csv
#	$(DIR_CHECK) stats/minfeat/vowel/wtd
#	$(MINFEAT) specs/vowel/wtd/all.csv stats/minfeat/vowel/wtd/all.csv

stats/size: stats/size/whole stats/size/cons stats/size/stop \
							 stats/size/vowel 
stats/size/whole: stats/size/whole/nat/all.csv \
										 stats/size/whole/ctrl/all.csv \
										 stats/size/whole/wtd/all.csv \
 									   stats/size/whole/unif/all.csv
stats/size/cons: stats/size/cons/nat/all.csv \
										 stats/size/cons/ctrl/all.csv \
										 stats/size/cons/wtd/all.csv \
 									   stats/size/cons/unif/all.csv
stats/size/stop: stats/size/stop/nat/all.csv \
										 stats/size/stop/ctrl/all.csv \
										 stats/size/stop/wtd/all.csv \
 									   stats/size/stop/unif/all.csv
stats/size/vowel: stats/size/vowel/nat/all.csv \
										 stats/size/vowel/ctrl/all.csv \
										 stats/size/vowel/wtd/all.csv \
 									   stats/size/vowel/unif/all.csv

stats/size/whole/nat/all.csv: 
	$(DIR_CHECK) stats/size/whole/nat
	$(SIZE) data/whole/nat/all.csv stats/size/whole/nat/all.csv
stats/size/whole/ctrl/all.csv:
	$(DIR_CHECK) stats/size/whole/ctrl
	$(SIZE) data/whole/ctrl/all.csv stats/size/whole/ctrl/all.csv
stats/size/whole/unif/all.csv: 
	$(DIR_CHECK) stats/size/whole/unif
	$(SIZE) data/whole/unif/all.csv stats/size/whole/unif/all.csv
stats/size/whole/wtd/all.csv: 
	$(DIR_CHECK) stats/size/whole/wtd
	$(SIZE) data/whole/wtd/all.csv stats/size/whole/wtd/all.csv

stats/size/cons/nat/all.csv: 
	$(DIR_CHECK) stats/size/cons/nat
	$(SIZE) data/cons/nat/all.csv stats/size/cons/nat/all.csv
stats/size/cons/ctrl/all.csv:
	$(DIR_CHECK) stats/size/cons/ctrl
	$(SIZE) data/cons/ctrl/all.csv stats/size/cons/ctrl/all.csv
stats/size/cons/unif/all.csv: 
	$(DIR_CHECK) stats/size/cons/unif
	$(SIZE) data/cons/unif/all.csv stats/size/cons/unif/all.csv
stats/size/cons/wtd/all.csv: 
	$(DIR_CHECK) stats/size/cons/wtd
	$(SIZE) data/cons/wtd/all.csv stats/size/cons/wtd/all.csv

stats/size/stop/nat/all.csv:
	$(DIR_CHECK) stats/size/stop/nat
	$(SIZE) data/stop/nat/all.csv stats/size/stop/nat/all.csv
stats/size/stop/ctrl/all.csv: 
	$(DIR_CHECK) stats/size/stop/ctrl
	$(SIZE) data/stop/ctrl/all.csv stats/size/stop/ctrl/all.csv
stats/size/stop/unif/all.csv: 
	$(DIR_CHECK) stats/size/stop/unif
	$(SIZE) data/stop/unif/all.csv stats/size/stop/unif/all.csv
stats/size/stop/wtd/all.csv: 
	$(DIR_CHECK) stats/size/stop/wtd
	$(SIZE) data/stop/wtd/all.csv stats/size/stop/wtd/all.csv

stats/size/vowel/nat/all.csv: 
	$(DIR_CHECK) stats/size/vowel/nat
	$(SIZE) data/vowel/nat/all.csv stats/size/vowel/nat/all.csv
stats/size/vowel/ctrl/all.csv: 
	$(DIR_CHECK) stats/size/vowel/ctrl
	$(SIZE) data/vowel/ctrl/all.csv stats/size/vowel/ctrl/all.csv
stats/size/vowel/unif/all.csv: 
	$(DIR_CHECK) stats/size/vowel/unif
	$(SIZE) data/vowel/unif/all.csv stats/size/vowel/unif/all.csv
stats/size/vowel/wtd/all.csv: 
	$(DIR_CHECK) stats/size/vowel/wtd
	$(SIZE) data/vowel/wtd/all.csv stats/size/vowel/wtd/all.csv



stats/fbalance: stats/fbalance/whole stats/fbalance/cons \
									  stats/fbalance/stop stats/fbalance/vowel 
stats/fbalance/whole: stats/fbalance/whole/nat/all.csv \
										 stats/fbalance/whole/ctrl/all.csv \
										 stats/fbalance/whole/wtd/all.csv \
										 stats/fbalance/whole/unif/all.csv 
stats/fbalance/cons: stats/fbalance/cons/nat/all.csv \
										 stats/fbalance/cons/ctrl/all.csv \
										 stats/fbalance/cons/wtd/all.csv \
										 stats/fbalance/cons/unif/all.csv 
stats/fbalance/stop: stats/fbalance/stop/nat/all.csv \
										 stats/fbalance/stop/ctrl/all.csv \
										 stats/fbalance/stop/wtd/all.csv \
										 stats/fbalance/stop/unif/all.csv 
stats/fbalance/vowel: stats/fbalance/vowel/nat/all.csv \
										 stats/fbalance/vowel/ctrl/all.csv \
										 stats/fbalance/vowel/wtd/all.csv \
										 stats/fbalance/vowel/unif/all.csv 

stats/fbalance/whole/nat/all.csv: specs/whole/nat/all.csv
	$(FBALANCE) data/whole/nat/all.csv specs/whole/nat/all.csv \
						  stats/fbalance/whole/nat/by_language
	$(AGGREGATE) stats/fbalance/whole/nat/by_language > \
							 stats/fbalance/whole/nat/all.csv
	$(SUM_FBALANCE) stats
stats/fbalance/whole/ctrl/all.csv: specs/whole/ctrl/all.csv
	$(FBALANCE) data/whole/ctrl/all.csv specs/whole/ctrl/all.csv \
						  stats/fbalance/whole/ctrl/by_language
	$(AGGREGATE) stats/fbalance/whole/ctrl/by_language > \
							 stats/fbalance/whole/ctrl/all.csv
stats/fbalance/whole/unif/all.csv: specs/whole/unif/all.csv
	$(FBALANCE) data/whole/unif/all.csv specs/whole/unif/all.csv \
						  stats/fbalance/whole/unif/by_language
	$(AGGREGATE) stats/fbalance/whole/unif/by_language > \
							 stats/fbalance/whole/unif/all.csv
stats/fbalance/whole/wtd/all.csv: specs/whole/wtd/all.csv
	$(FBALANCE) data/whole/wtd/all.csv specs/whole/wtd/all.csv \
						  stats/fbalance/whole/wtd/by_language
	$(AGGREGATE) stats/fbalance/whole/wtd/by_language > \
							 stats/fbalance/whole/wtd/all.csv

stats/fbalance/cons/nat/all.csv: specs/cons/nat/all.csv
	$(FBALANCE) data/cons/nat/all.csv specs/cons/nat/all.csv \
						  stats/fbalance/cons/nat/by_language
	$(AGGREGATE) stats/fbalance/cons/nat/by_language > \
							 stats/fbalance/cons/nat/all.csv
stats/fbalance/cons/ctrl/all.csv: specs/cons/ctrl/all.csv
	$(FBALANCE) data/cons/ctrl/all.csv specs/cons/ctrl/all.csv \
						  stats/fbalance/cons/ctrl/by_language
	$(AGGREGATE) stats/fbalance/cons/ctrl/by_language > \
							 stats/fbalance/cons/ctrl/all.csv
stats/fbalance/cons/unif/all.csv: specs/cons/unif/all.csv
	$(FBALANCE) data/cons/unif/all.csv specs/cons/unif/all.csv \
						  stats/fbalance/cons/unif/by_language
	$(AGGREGATE) stats/fbalance/cons/unif/by_language > \
							 stats/fbalance/cons/unif/all.csv
stats/fbalance/cons/wtd/all.csv: specs/cons/wtd/all.csv
	$(FBALANCE) data/cons/wtd/all.csv specs/cons/wtd/all.csv \
						  stats/fbalance/cons/wtd/by_language
	$(AGGREGATE) stats/fbalance/cons/wtd/by_language > \
							 stats/fbalance/cons/wtd/all.csv

stats/fbalance/stop/nat/all.csv: specs/stop/nat/all.csv
	$(FBALANCE) data/stop/nat/all.csv specs/stop/nat/all.csv \
						  stats/fbalance/stop/nat/by_language
	$(AGGREGATE) stats/fbalance/stop/nat/by_language > \
							 stats/fbalance/stop/nat/all.csv
stats/fbalance/stop/ctrl/all.csv: specs/stop/ctrl/all.csv
	$(FBALANCE) data/stop/ctrl/all.csv specs/stop/ctrl/all.csv \
						  stats/fbalance/stop/ctrl/by_language
	$(AGGREGATE) stats/fbalance/stop/ctrl/by_language > \
							 stats/fbalance/stop/ctrl/all.csv
stats/fbalance/stop/unif/all.csv: specs/stop/unif/all.csv
	$(FBALANCE) data/stop/unif/all.csv specs/stop/unif/all.csv \
						  stats/fbalance/stop/unif/by_language
	$(AGGREGATE) stats/fbalance/stop/unif/by_language > \
							 stats/fbalance/stop/unif/all.csv
stats/fbalance/stop/wtd/all.csv: specs/stop/wtd/all.csv
	$(FBALANCE) data/stop/wtd/all.csv specs/stop/wtd/all.csv \
						  stats/fbalance/stop/wtd/by_language
	$(AGGREGATE) stats/fbalance/stop/wtd/by_language > \
							 stats/fbalance/stop/wtd/all.csv

stats/fbalance/vowel/nat/all.csv: specs/vowel/nat/all.csv
	$(FBALANCE) data/vowel/nat/all.csv specs/vowel/nat/all.csv \
						  stats/fbalance/vowel/nat/by_language
	$(AGGREGATE) stats/fbalance/vowel/nat/by_language > \
							 stats/fbalance/vowel/nat/all.csv
stats/fbalance/vowel/ctrl/all.csv: specs/vowel/ctrl/all.csv
	$(FBALANCE) data/vowel/ctrl/all.csv specs/vowel/ctrl/all.csv \
						  stats/fbalance/vowel/ctrl/by_language
	$(AGGREGATE) stats/fbalance/vowel/ctrl/by_language > \
							 stats/fbalance/vowel/ctrl/all.csv
stats/fbalance/vowel/unif/all.csv: specs/vowel/unif/all.csv
	$(FBALANCE) data/vowel/unif/all.csv specs/vowel/unif/all.csv \
						  stats/fbalance/vowel/unif/by_language
	$(AGGREGATE) stats/fbalance/vowel/unif/by_language > \
							 stats/fbalance/vowel/unif/all.csv
stats/fbalance/vowel/wtd/all.csv: specs/vowel/wtd/all.csv
	$(FBALANCE) data/vowel/wtd/all.csv specs/vowel/wtd/all.csv \
						  stats/fbalance/vowel/wtd/by_language
	$(AGGREGATE) stats/fbalance/vowel/wtd/by_language > \
							 stats/fbalance/vowel/wtd/all.csv


stats/sum_fbalance: stats/sum_fbalance/whole stats/sum_fbalance/cons \
									  stats/sum_fbalance/stop stats/sum_fbalance/vowel 
stats/sum_fbalance/whole: stats/sum_fbalance/whole/nat/all.csv \
										 stats/sum_fbalance/whole/ctrl/all.csv \
										 stats/sum_fbalance/whole/wtd/all.csv \
										 stats/sum_fbalance/whole/unif/all.csv 
stats/sum_fbalance/cons: stats/sum_fbalance/cons/nat/all.csv \
										 stats/sum_fbalance/cons/ctrl/all.csv \
										 stats/sum_fbalance/cons/wtd/all.csv \
										 stats/sum_fbalance/cons/unif/all.csv 
stats/sum_fbalance/stop: stats/sum_fbalance/stop/nat/all.csv \
										 stats/sum_fbalance/stop/ctrl/all.csv \
										 stats/sum_fbalance/stop/wtd/all.csv \
										 stats/sum_fbalance/stop/unif/all.csv 
stats/sum_fbalance/vowel: stats/sum_fbalance/vowel/nat/all.csv \
										 stats/sum_fbalance/vowel/ctrl/all.csv \
										 stats/sum_fbalance/vowel/wtd/all.csv \
										 stats/sum_fbalance/vowel/unif/all.csv 

stats/sum_fbalance/whole/nat/all.csv: stats/fbalance/whole/nat/all.csv
	$(DIR_CHECK) stats/sum_fbalance/whole/nat
	$(SUM_FBALANCE) stats/fbalance/whole/nat/all.csv \
		stats/sum_fbalance/whole/nat/all.csv

stats/sum_fbalance/whole/ctrl/all.csv: stats/fbalance/whole/ctrl/all.csv
	$(DIR_CHECK) stats/sum_fbalance/whole/ctrl
	$(SUM_FBALANCE) stats/fbalance/whole/ctrl/all.csv \
		stats/sum_fbalance/whole/ctrl/all.csv

stats/sum_fbalance/whole/wtd/all.csv: stats/fbalance/whole/wtd/all.csv
	$(DIR_CHECK) stats/sum_fbalance/whole/wtd
	$(SUM_FBALANCE) stats/fbalance/whole/wtd/all.csv \
		stats/sum_fbalance/whole/wtd/all.csv

stats/sum_fbalance/whole/unif/all.csv: stats/fbalance/whole/unif/all.csv 
	$(DIR_CHECK) stats/sum_fbalance/whole/unif
	$(SUM_FBALANCE) stats/fbalance/whole/unif/all.csv \
		stats/sum_fbalance/whole/unif/all.csv 


stats/sum_fbalance/cons/nat/all.csv: stats/fbalance/cons/nat/all.csv 
	$(DIR_CHECK) stats/sum_fbalance/cons/nat
	$(SUM_FBALANCE) stats/fbalance/cons/nat/all.csv \
		stats/sum_fbalance/cons/nat/all.csv 

stats/sum_fbalance/cons/ctrl/all.csv: stats/fbalance/cons/ctrl/all.csv 
	$(DIR_CHECK) stats/sum_fbalance/cons/ctrl
	$(SUM_FBALANCE) stats/fbalance/cons/ctrl/all.csv\
	 	stats/sum_fbalance/cons/ctrl/all.csv 

stats/sum_fbalance/cons/wtd/all.csv: stats/fbalance/cons/wtd/all.csv 
	$(DIR_CHECK) stats/sum_fbalance/cons/wtd
	$(SUM_FBALANCE) stats/fbalance/cons/wtd/all.csv\
	 	stats/sum_fbalance/cons/wtd/all.csv 

stats/sum_fbalance/cons/unif/all.csv: stats/fbalance/cons/unif/all.csv 
	$(DIR_CHECK) stats/sum_fbalance/cons/unif
	$(SUM_FBALANCE) stats/fbalance/cons/unif/all.csv\
	 	stats/sum_fbalance/cons/unif/all.csv 


stats/sum_fbalance/stop/nat/all.csv: stats/fbalance/stop/nat/all.csv 
	$(DIR_CHECK) stats/sum_fbalance/stop/nat
	$(SUM_FBALANCE) stats/fbalance/stop/nat/all.csv\
	 	stats/sum_fbalance/stop/nat/all.csv 

stats/sum_fbalance/stop/ctrl/all.csv: stats/fbalance/stop/ctrl/all.csv 
	$(DIR_CHECK) stats/sum_fbalance/stop/ctrl
	$(SUM_FBALANCE) stats/fbalance/stop/ctrl/all.csv\
	 	stats/sum_fbalance/stop/ctrl/all.csv 

stats/sum_fbalance/stop/wtd/all.csv: stats/fbalance/stop/wtd/all.csv 
	$(DIR_CHECK) stats/sum_fbalance/stop/wtd
	$(SUM_FBALANCE) stats/fbalance/stop/wtd/all.csv\
	 	stats/sum_fbalance/stop/wtd/all.csv 

stats/sum_fbalance/stop/unif/all.csv: stats/fbalance/stop/unif/all.csv 
	$(DIR_CHECK) stats/sum_fbalance/stop/unif
	$(SUM_FBALANCE) stats/fbalance/stop/unif/all.csv\
	 	stats/sum_fbalance/stop/unif/all.csv 


stats/sum_fbalance/vowel/nat/all.csv: stats/fbalance/vowel/nat/all.csv 
	$(DIR_CHECK) stats/sum_fbalance/vowel/nat
	$(SUM_FBALANCE) stats/fbalance/vowel/nat/all.csv\
	 	stats/sum_fbalance/vowel/nat/all.csv 

stats/sum_fbalance/vowel/ctrl/all.csv: stats/fbalance/vowel/ctrl/all.csv 
	$(DIR_CHECK) stats/sum_fbalance/vowel/ctrl
	$(SUM_FBALANCE) stats/fbalance/vowel/ctrl/all.csv\
	 	stats/sum_fbalance/vowel/ctrl/all.csv 

stats/sum_fbalance/vowel/wtd/all.csv: stats/fbalance/vowel/wtd/all.csv 
	$(DIR_CHECK) stats/sum_fbalance/vowel/wtd
	$(SUM_FBALANCE) stats/fbalance/vowel/wtd/all.csv\
	 	stats/sum_fbalance/vowel/wtd/all.csv 

stats/sum_fbalance/vowel/unif/all.csv: stats/fbalance/vowel/unif/all.csv 
	$(DIR_CHECK) stats/sum_fbalance/vowel/unif
	$(SUM_FBALANCE) stats/fbalance/vowel/unif/all.csv\
	 	stats/sum_fbalance/vowel/unif/all.csv 



stats/fnpairs: stats/fnpairs/whole stats/fnpairs/cons stats/fnpairs/stop \
							 stats/fnpairs/vowel 
stats/fnpairs/whole: stats/fnpairs/whole/nat/all.csv \
										 stats/fnpairs/whole/ctrl/all.csv \
										 stats/fnpairs/whole/wtd/all.csv \
										 stats/fnpairs/whole/unif/all.csv
stats/fnpairs/cons: stats/fnpairs/cons/nat/all.csv \
										 stats/fnpairs/cons/ctrl/all.csv \
										 stats/fnpairs/cons/wtd/all.csv \
										 stats/fnpairs/cons/unif/all.csv 
stats/fnpairs/stop: stats/fnpairs/stop/nat/all.csv \
										 stats/fnpairs/stop/ctrl/all.csv \
										 stats/fnpairs/stop/wtd/all.csv \
										 stats/fnpairs/stop/unif/all.csv 
stats/fnpairs/vowel: stats/fnpairs/vowel/nat/all.csv \
										 stats/fnpairs/vowel/ctrl/all.csv \
										 stats/fnpairs/vowel/wtd/all.csv \
										 stats/fnpairs/vowel/unif/all.csv 

stats/fnpairs/whole/nat/all.csv: specs/whole/nat/all.csv
	$(FNPAIRS) data/whole/nat/all.csv specs/whole/nat/all.csv \
						  stats/fnpairs/whole/nat/by_language
	$(AGGREGATE) stats/fnpairs/whole/nat/by_language > \
							 stats/fnpairs/whole/nat/all.csv
stats/fnpairs/whole/ctrl/all.csv: specs/whole/ctrl/all.csv
	$(FNPAIRS) data/whole/ctrl/all.csv specs/whole/ctrl/all.csv \
						  stats/fnpairs/whole/ctrl/by_language
	$(AGGREGATE) stats/fnpairs/whole/ctrl/by_language > \
							 stats/fnpairs/whole/ctrl/all.csv
stats/fnpairs/whole/unif/all.csv: specs/whole/unif/all.csv
	$(FNPAIRS) data/whole/unif/all.csv specs/whole/unif/all.csv \
						  stats/fnpairs/whole/unif/by_language
	$(AGGREGATE) stats/fnpairs/whole/unif/by_language > \
							 stats/fnpairs/whole/unif/all.csv
stats/fnpairs/whole/wtd/all.csv: specs/whole/wtd/all.csv
	$(FNPAIRS) data/whole/wtd/all.csv specs/whole/wtd/all.csv \
						  stats/fnpairs/whole/wtd/by_language
	$(AGGREGATE) stats/fnpairs/whole/wtd/by_language > \
							 stats/fnpairs/whole/wtd/all.csv

stats/fnpairs/cons/nat/all.csv: specs/cons/nat/all.csv
	$(FNPAIRS) data/cons/nat/all.csv specs/cons/nat/all.csv \
						  stats/fnpairs/cons/nat/by_language
	$(AGGREGATE) stats/fnpairs/cons/nat/by_language > \
							 stats/fnpairs/cons/nat/all.csv
stats/fnpairs/cons/ctrl/all.csv: specs/cons/ctrl/all.csv
	$(FNPAIRS) data/cons/ctrl/all.csv specs/cons/ctrl/all.csv \
						  stats/fnpairs/cons/ctrl/by_language
	$(AGGREGATE) stats/fnpairs/cons/ctrl/by_language > \
							 stats/fnpairs/cons/ctrl/all.csv
stats/fnpairs/cons/unif/all.csv: specs/cons/unif/all.csv
	$(FNPAIRS) data/cons/unif/all.csv specs/cons/unif/all.csv \
						  stats/fnpairs/cons/unif/by_language
	$(AGGREGATE) stats/fnpairs/cons/unif/by_language > \
							 stats/fnpairs/cons/unif/all.csv
stats/fnpairs/cons/wtd/all.csv: specs/cons/wtd/all.csv
	$(FNPAIRS) data/cons/wtd/all.csv specs/cons/wtd/all.csv \
						  stats/fnpairs/cons/wtd/by_language
	$(AGGREGATE) stats/fnpairs/cons/wtd/by_language > \
							 stats/fnpairs/cons/wtd/all.csv

stats/fnpairs/stop/nat/all.csv: specs/stop/nat/all.csv
	$(FNPAIRS) data/stop/nat/all.csv specs/stop/nat/all.csv \
						  stats/fnpairs/stop/nat/by_language
	$(AGGREGATE) stats/fnpairs/stop/nat/by_language > \
							 stats/fnpairs/stop/nat/all.csv
stats/fnpairs/stop/ctrl/all.csv: specs/stop/ctrl/all.csv
	$(FNPAIRS) data/stop/ctrl/all.csv specs/stop/ctrl/all.csv \
						  stats/fnpairs/stop/ctrl/by_language
	$(AGGREGATE) stats/fnpairs/stop/ctrl/by_language > \
							 stats/fnpairs/stop/ctrl/all.csv
stats/fnpairs/stop/unif/all.csv: specs/stop/unif/all.csv
	$(FNPAIRS) data/stop/unif/all.csv specs/stop/unif/all.csv \
						  stats/fnpairs/stop/unif/by_language
	$(AGGREGATE) stats/fnpairs/stop/unif/by_language > \
							 stats/fnpairs/stop/unif/all.csv
stats/fnpairs/stop/wtd/all.csv: specs/stop/wtd/all.csv
	$(FNPAIRS) data/stop/wtd/all.csv specs/stop/wtd/all.csv \
						  stats/fnpairs/stop/wtd/by_language
	$(AGGREGATE) stats/fnpairs/stop/wtd/by_language > \
							 stats/fnpairs/stop/wtd/all.csv

stats/fnpairs/vowel/nat/all.csv: specs/vowel/nat/all.csv
	$(FNPAIRS) data/vowel/nat/all.csv specs/vowel/nat/all.csv \
						  stats/fnpairs/vowel/nat/by_language
	$(AGGREGATE) stats/fnpairs/vowel/nat/by_language > \
							 stats/fnpairs/vowel/nat/all.csv
stats/fnpairs/vowel/ctrl/all.csv: specs/vowel/ctrl/all.csv
	$(FNPAIRS) data/vowel/ctrl/all.csv specs/vowel/ctrl/all.csv \
						  stats/fnpairs/vowel/ctrl/by_language
	$(AGGREGATE) stats/fnpairs/vowel/ctrl/by_language > \
							 stats/fnpairs/vowel/ctrl/all.csv
stats/fnpairs/vowel/unif/all.csv: specs/vowel/unif/all.csv
	$(FNPAIRS) data/vowel/unif/all.csv specs/vowel/unif/all.csv \
						  stats/fnpairs/vowel/unif/by_language
	$(AGGREGATE) stats/fnpairs/vowel/unif/by_language > \
							 stats/fnpairs/vowel/unif/all.csv
stats/fnpairs/vowel/wtd/all.csv: specs/vowel/wtd/all.csv
	$(FNPAIRS) data/vowel/wtd/all.csv specs/vowel/wtd/all.csv \
						  stats/fnpairs/vowel/wtd/by_language
	$(AGGREGATE) stats/fnpairs/vowel/wtd/by_language > \
							 stats/fnpairs/vowel/wtd/all.csv


stats/sum_fnpairs: stats/sum_fnpairs/whole stats/sum_fnpairs/cons \
									  stats/sum_fnpairs/stop stats/sum_fnpairs/vowel 
stats/sum_fnpairs/whole: stats/sum_fnpairs/whole/nat/all.csv \
										 stats/sum_fnpairs/whole/ctrl/all.csv \
										 stats/sum_fnpairs/whole/wtd/all.csv \
										 stats/sum_fnpairs/whole/unif/all.csv 
stats/sum_fnpairs/cons: stats/sum_fnpairs/cons/nat/all.csv \
										 stats/sum_fnpairs/cons/ctrl/all.csv \
										 stats/sum_fnpairs/cons/wtd/all.csv \
										 stats/sum_fnpairs/cons/unif/all.csv 
stats/sum_fnpairs/stop: stats/sum_fnpairs/stop/nat/all.csv \
										 stats/sum_fnpairs/stop/ctrl/all.csv \
										 stats/sum_fnpairs/stop/wtd/all.csv \
										 stats/sum_fnpairs/stop/unif/all.csv 
stats/sum_fnpairs/vowel: stats/sum_fnpairs/vowel/nat/all.csv \
										 stats/sum_fnpairs/vowel/ctrl/all.csv \
										 stats/sum_fnpairs/vowel/wtd/all.csv \
										 stats/sum_fnpairs/vowel/unif/all.csv 

stats/sum_fnpairs/whole/nat/all.csv: stats/fnpairs/whole/nat/all.csv
	$(DIR_CHECK) stats/sum_fnpairs/whole/nat
	$(SUM_FNPAIRS) stats/fnpairs/whole/nat/all.csv \
		stats/sum_fnpairs/whole/nat/all.csv

stats/sum_fnpairs/whole/ctrl/all.csv: stats/fnpairs/whole/ctrl/all.csv
	$(DIR_CHECK) stats/sum_fnpairs/whole/ctrl
	$(SUM_FNPAIRS) stats/fnpairs/whole/ctrl/all.csv \
		stats/sum_fnpairs/whole/ctrl/all.csv

stats/sum_fnpairs/whole/wtd/all.csv: stats/fnpairs/whole/wtd/all.csv
	$(DIR_CHECK) stats/sum_fnpairs/whole/wtd
	$(SUM_FNPAIRS) stats/fnpairs/whole/wtd/all.csv \
		stats/sum_fnpairs/whole/wtd/all.csv

stats/sum_fnpairs/whole/unif/all.csv: stats/fnpairs/whole/unif/all.csv 
	$(DIR_CHECK) stats/sum_fnpairs/whole/unif
	$(SUM_FNPAIRS) stats/fnpairs/whole/unif/all.csv \
		stats/sum_fnpairs/whole/unif/all.csv 


stats/sum_fnpairs/cons/nat/all.csv: stats/fnpairs/cons/nat/all.csv 
	$(DIR_CHECK) stats/sum_fnpairs/cons/nat
	$(SUM_FNPAIRS) stats/fnpairs/cons/nat/all.csv \
		stats/sum_fnpairs/cons/nat/all.csv 

stats/sum_fnpairs/cons/ctrl/all.csv: stats/fnpairs/cons/ctrl/all.csv 
	$(DIR_CHECK) stats/sum_fnpairs/cons/ctrl
	$(SUM_FNPAIRS) stats/fnpairs/cons/ctrl/all.csv\
	 	stats/sum_fnpairs/cons/ctrl/all.csv 

stats/sum_fnpairs/cons/wtd/all.csv: stats/fnpairs/cons/wtd/all.csv 
	$(DIR_CHECK) stats/sum_fnpairs/cons/wtd
	$(SUM_FNPAIRS) stats/fnpairs/cons/wtd/all.csv\
	 	stats/sum_fnpairs/cons/wtd/all.csv 

stats/sum_fnpairs/cons/unif/all.csv: stats/fnpairs/cons/unif/all.csv 
	$(DIR_CHECK) stats/sum_fnpairs/cons/unif
	$(SUM_FNPAIRS) stats/fnpairs/cons/unif/all.csv\
	 	stats/sum_fnpairs/cons/unif/all.csv 


stats/sum_fnpairs/stop/nat/all.csv: stats/fnpairs/stop/nat/all.csv 
	$(DIR_CHECK) stats/sum_fnpairs/stop/nat
	$(SUM_FNPAIRS) stats/fnpairs/stop/nat/all.csv\
	 	stats/sum_fnpairs/stop/nat/all.csv 

stats/sum_fnpairs/stop/ctrl/all.csv: stats/fnpairs/stop/ctrl/all.csv 
	$(DIR_CHECK) stats/sum_fnpairs/stop/ctrl
	$(SUM_FNPAIRS) stats/fnpairs/stop/ctrl/all.csv\
	 	stats/sum_fnpairs/stop/ctrl/all.csv 

stats/sum_fnpairs/stop/wtd/all.csv: stats/fnpairs/stop/wtd/all.csv 
	$(DIR_CHECK) stats/sum_fnpairs/stop/wtd
	$(SUM_FNPAIRS) stats/fnpairs/stop/wtd/all.csv\
	 	stats/sum_fnpairs/stop/wtd/all.csv 

stats/sum_fnpairs/stop/unif/all.csv: stats/fnpairs/stop/unif/all.csv 
	$(DIR_CHECK) stats/sum_fnpairs/stop/unif
	$(SUM_FNPAIRS) stats/fnpairs/stop/unif/all.csv\
	 	stats/sum_fnpairs/stop/unif/all.csv 


stats/sum_fnpairs/vowel/nat/all.csv: stats/fnpairs/vowel/nat/all.csv 
	$(DIR_CHECK) stats/sum_fnpairs/vowel/nat
	$(SUM_FNPAIRS) stats/fnpairs/vowel/nat/all.csv\
	 	stats/sum_fnpairs/vowel/nat/all.csv 

stats/sum_fnpairs/vowel/ctrl/all.csv: stats/fnpairs/vowel/ctrl/all.csv 
	$(DIR_CHECK) stats/sum_fnpairs/vowel/ctrl
	$(SUM_FNPAIRS) stats/fnpairs/vowel/ctrl/all.csv\
	 	stats/sum_fnpairs/vowel/ctrl/all.csv 

stats/sum_fnpairs/vowel/wtd/all.csv: stats/fnpairs/vowel/wtd/all.csv 
	$(DIR_CHECK) stats/sum_fnpairs/vowel/wtd
	$(SUM_FNPAIRS) stats/fnpairs/vowel/wtd/all.csv\
	 	stats/sum_fnpairs/vowel/wtd/all.csv 

stats/sum_fnpairs/vowel/unif/all.csv: stats/fnpairs/vowel/unif/all.csv 
	$(DIR_CHECK) stats/sum_fnpairs/vowel/unif
	$(SUM_FNPAIRS) stats/fnpairs/vowel/unif/all.csv\
	 	stats/sum_fnpairs/vowel/unif/all.csv 




# Statistics (clean)

clean-stats:
	rm -rf stats


