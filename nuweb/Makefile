all : Pipeline_NL_Lisa.pdf
.PHONY : all



NUWEB=../env/bin/nuweb
.SUFFIXES: .pdf .w .tex .html .aux .log .php

FIGFILES=fileschema directorystructure

FIGFILENAMES=$(foreach fil,$(FIGFILES), $(fil).fig)
PDFT_NAMES=$(foreach fil,$(FIGFILES), $(fil).pdftex_t)
PDF_FIG_NAMES=$(foreach fil,$(FIGFILES), $(fil).pdftex)
PST_NAMES=$(foreach fil,$(FIGFILES), $(fil).pstex_t)
PS_FIG_NAMES=$(foreach fil,$(FIGFILES), $(fil).pstex)

W2PDF=../nuweb/bin/w2pdf
htmldir=../nuweb/html
htmlsource=Pipeline_NL_Lisa.w Pipeline_NL_Lisa.bib html.sty artikel3.4ht w2html
htmlmaterial=$(foreach fil, $(htmlsource), $(htmldir)/$(fil))
htmltarget=$(htmldir)/Pipeline_NL_Lisa.html
MKDIR = mkdir -p

 

%.pdf: %.w
	./w2pdf $<

%.eps: %.fig
	fig2dev -L eps $< > $@

%.pstex: %.fig
	fig2dev -L pstex $< > $@

.PRECIOUS : %.pstex
%.pstex_t: %.fig %.pstex
	fig2dev -L pstex_t -p $*.pstex $< > $@

%.pdftex: %.fig
	fig2dev -L pdftex $< > $@

.PRECIOUS : %.pdftex
%.pdftex_t: %.fig %.pstex
	fig2dev -L pdftex_t -p $*.pdftex $< > $@

$(htmldir)/% : % $(htmldir)
	cp $< $(htmldir)/



nuweb: $(NUWEB)

$(NUWEB): ../nuweb-1.58
	mkdir -p ../env/bin
	cd ../nuweb-1.58 && make nuweb
	cp ../nuweb-1.58/nuweb $(NUWEB)

../nuweb-1.58:
	cd .. && wget http://kyoto.let.vu.nl/~huygen/nuweb-1.58.tgz
	cd .. &&  tar -xzf nuweb-1.58.tgz

m4_Pipeline_NL_Lisa.w : a_Pipeline_NL_Lisa.w
	gawk '{if(match($$0, "@%")) {printf("%s", substr($$0,1,RSTART-1))} else print}' a_Pipeline_NL_Lisa.w \
          | gawk '{gsub(/[\\][\$$]/, "$$");print}'  > m4_Pipeline_NL_Lisa.w

Pipeline_NL_Lisa.w : m4_Pipeline_NL_Lisa.w inst.m4
	m4 -P m4_Pipeline_NL_Lisa.w > Pipeline_NL_Lisa.w

bibfile : Pipeline_NL_Lisa.aux /home/paul/bin/mkportbib
	/home/paul/bin/mkportbib Pipeline_NL_Lisa litprog

.PHONY : bibfile
$(W2PDF) : Pipeline_NL_Lisa.w $(NUWEB)
	$(NUWEB) Pipeline_NL_Lisa.w
$(htmldir) : 
	mkdir -p $(htmldir)

$(htmltarget) : $(htmlmaterial) $(htmldir) 
	cd $(htmldir) && chmod 775 w2html
	cd $(htmldir) && ./w2html nlpp.w


clean:
	rm -rf ../nuweb-1.58
	

pdf : Pipeline_NL_Lisa.pdf

print : Pipeline_NL_Lisa.pdf
	lpr Pipeline_NL_Lisa.pdf

view : Pipeline_NL_Lisa.pdf
	evince Pipeline_NL_Lisa.pdf

Pipeline_NL_Lisa.pdf : Pipeline_NL_Lisa.w $(W2PDF)  $(PDF_FIG_NAMES) $(PDFT_NAMES)
	chmod 775 $(W2PDF)
	$(W2PDF) $*

htm : $(htmldir) $(htmltarget)

DIRS = ../nuweb/bin 

$(DIRS) : 
	$(MKDIR) $@

source : Pipeline_NL_Lisa.w $(DIRS) $(NUWEB)
	$(NUWEB) Pipeline_NL_Lisa.w
	chmod 775 /home/phuijgen/nlp/test/Pipeline-NL-Lisa/runit
	chmod -R 775  ../env/bin/*
	


