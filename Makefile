
VERSION = 1.7

## Splus source files, note that options.S MUST come first as it has the 
## configurable settings in it. 

## pick up the source files, note that AAoptions.S should always be the
## first file in this bundle
SFILES = src/*.S 

# documentation files in R doc format
RDFILES = man/*.Rd

all: R S

Ssource: $(SFILES) version-info
	rm -f Ssource
	cat $(SFILES) > Ssource

S:	Ssource html-help 
	mkdir emu-S
	cp Ssource emu-S
	cp INSTALL.Splus emu-S/INSTALL.txt
	cp -R html emu-S
	tar czf emu-S_$(VERSION).tar.gz emu-S
	zip -r emu-S_$(VERSION).zip emu-S
	rm -rf emu-S


Sbin: Ssource version-info
	mkdir -p .Data
	rm -rf .Data/*
	Splus < Ssource

R: $(SFILES)  emu/INDEX description version-info 
	rm -f emu_$(VERSION)*.tar.gz	
	mkdir -p emu/R
	mkdir -p emu/man 
	rm -f emu/R/* emu/man/*
	cp $(SFILES) emu/R/
	cp man/*.Rd emu/man
#	R CMD check emu
	R CMD build emu
	tar xzf emu_$(VERSION)*.tar.gz
	zip -r emu_$(VERSION).zip emu
	tar czf emu_$(VERSION).tar.gz emu

version-info:
	sed -e 's/\(emu\.version<-\)"[0-9.]*"/\1"$(VERSION)"/' src/AAoptions.S > tmp
	mv tmp src/AAoptions.S

description:
	sed -e 's/Version: [0-9.]*/Version: $(VERSION)/' DESCRIPTION > emu/DESCRIPTION


emu/INDEX: $(RDFILES)
	mkdir -p emu
	rm -f emu/INDEX
	R CMD Rdindex $(RDFILES) > emu/INDEX

emu-R.pdf: $(RDFILES)
	R CMD Rd2dvi --pdf --title="Emu/R Documentation" --output=emu-R.pdf  $(RDFILES)

## make standalone html help for distribution with Splus, these files
## really need fixing up a bit so that links work properly
## - replace the stylsheet with one in the current dir
## - map links to "../../../doc/html/search/SearchObject.html?fname" with 
##   just fname.html
## 
html-help: $(RDFILES)
	mkdir -p html
	rm -f html/index.html
	cp style.css html
	cp index.html.head html/index.html 
	echo "<table width=90%>" >> html/index.html
	for f in $(RDFILES); do \
	  echo $$f; \
	  R CMD Rdconv --type=html $$f | sed -e 's/..\/..\/R.css/style.css/' | sed -e 's/00Index.html/index.html/' > html/`basename $$f | sed -e 's/Rd//'`html;\
	  R CMD Rdindex -r 300 $$f | sed -e "s/\([a-zA-Z.-]*\)\(.*\)/<tr><td><a href=`basename $$f | sed -e 's/Rd//'`html>\1<\/a><\/td><td>\2<\/td><\/tr>/" >> html/index.html; \
	done;
	echo "</table>" >> html/index.html
	echo "<p>The following functions are not yet documented:</p>" >> html/index.html
	echo "<p>" >> html/index.html
	 R CMD Rdindex man/*.Rdx | sed -e 's/~~.*~~/ /'  >> html/index.html
	echo "</p>" >> html/index.html
	cat index.html.tail >> html/index.html
	for f in html/*.html; do\
	  ./fix-help.pl $$f > tmp; \
	  mv tmp $$f; \
	done; 


