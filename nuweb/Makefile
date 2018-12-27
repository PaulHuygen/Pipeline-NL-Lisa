all : cltl-magicplace.pdf
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
htmlsource=cltl-magicplace.w cltl-magicplace.bib html.sty artikel3.4ht w2html
htmlmaterial=$(foreach fil, $(htmlsource), $(htmldir)/$(fil))
htmltarget=$(htmldir)/cltl-magicplace.html
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

m4_cltl-magicplace.w : a_cltl-magicplace.w
	gawk '{if(match($$0, "@%")) {printf("%s", substr($$0,1,RSTART-1))} else print}' a_cltl-magicplace.w \
          | gawk '{gsub(/[\\][\$$]/, "$$");print}'  > m4_cltl-magicplace.w

cltl-magicplace.w : m4_cltl-magicplace.w inst.m4
	m4 -P m4_cltl-magicplace.w > cltl-magicplace.w

bibfile : cltl-magicplace.aux /home/paul/bin/mkportbib
	/home/paul/bin/mkportbib cltl-magicplace litprog

.PHONY : bibfile
$(W2PDF) : cltl-magicplace.w $(NUWEB)
	$(NUWEB) cltl-magicplace.w
$(htmldir) : 
	mkdir -p $(htmldir)

$(htmltarget) : $(htmlmaterial) $(htmldir) 
	cd $(htmldir) && chmod 775 w2html
	cd $(htmldir) && ./w2html nlpp.w


clean:
	rm -rf ../nuweb-1.58
	

pdf : cltl-magicplace.pdf

print : cltl-magicplace.pdf
	lpr cltl-magicplace.pdf

view : cltl-magicplace.pdf
	evince cltl-magicplace.pdf

cltl-magicplace.pdf : cltl-magicplace.w $(W2PDF)  $(PDF_FIG_NAMES) $(PDFT_NAMES)
	chmod 775 $(W2PDF)
	$(W2PDF) $*

htm : $(htmldir) $(htmltarget)

DIRS = ../nuweb/bin 

$(DIRS) : 
	$(MKDIR) $@

source : cltl-magicplace.w $(DIRS) $(NUWEB)
	$(NUWEB) cltl-magicplace.w
	chmod 775 /home/phuijgen/nlp/cltl-magicplace/runit
	chmod -R 775  ../env/bin/*
	


