make_py_proj is a function
make_py_proj () 
{ 
    projname=$1;
    pkgname=$(echo $1 | tr 'A-Z' 'a-z');
    if [[ -z $1 ]]; then
        echo "Usage: $0 <projectname>";
        return 1;
    fi;
    cd $HOME/$ENV;
    if [ -d $1 ]; then
        echo "Environment $1 exists.";
        return 1;
    fi;
    mkvirtualenv $1 && cd $1 && . bin/activate && cat >> bin/postactivate  <<EOF
function cdp {
	cd $HOME/$PRJ
}

function cde {
	cd $HOME/$ENV
}
EOF
 && cat >> bin/postactivate  <<EOF

cd $HOME/$PRJ/$1
EOF
 && cat >> bin/predeactivate  <<EOF
#!/bin/bash
# put custom predeactivate hooks here
unset cdp
unset cde
EOF
 && cd $HOME/$PRJ
    mkdir -p $projname;
    touch $projname/CHANGES.txt;
    touch $projname/LICENSE.txt;
    touch $projname/README.txt;
    touch $projname/MANIFEST.in;
    touch $projname/setup.py;
    touch $projname/setup.cfg;
    touch $projname/.gitignore;
    touch $projname/runner-$projname.py;
    mkdir $projname/bin;
    mkdir $projname/docs;
    mkdir $projname/test;
    touch $projname/test/__init__.py;
    mkdir -p $projname/$pkgname/test;
    touch $projname/$pkgname/__init__.py;
    touch $projname/$pkgname/main.py;
    touch $projname/$pkgname/test/__init__.py;
    touch $projname/$pkgname/test/main.py;
    chmod +x $projname/runner-$projname.py;
    chmod +x $projname/$pkgname/main.py;
    cat  > $projname/setup.cfg <<EOF
[bdist_rpm]
doc_files = README.txt
EOF

    cat  > $projname/$pkgname/test/test_main.py <<EOF
import unittest

class TestMain(unittest.TestCase):
   def setUp(self):
      print "In setup()"

   def tearDown(self):
      print "In teardown()"

   def test_main(self):
      print "test()"


if __name__ == '__main__':
   unittest.main()
EOF

    cat  > $projname/$pkgname/main.py <<EOF
#
# $projname
#

def main():
   print "Template main function"
   
if __name__ == '__main__':
   main()
EOF

    cat  > $projname/$pkgname/__init__.py <<EOF
__version__ = "0.1.0"
EOF

    cat  > $projname/CHANGES.txt <<EOF
* 0.1.0, $(date "+%B %d, %Y")
- Initial build
EOF

    cat  > $projname/MANIFEST.in <<EOF
include *.py
EOF

    cat  > $projname/runner-$projname.py <<EOF
#!/usr/bin/python

from $projname.main import main


if __name__ == '__main__':
           main()
EOF

    cat  > $projname/README.txt <<EOF
###################
# Building
###################
Increment version number in $projname/__init__.py

Python egg:
------------
To build python egg, run: python setup.py bdist

RPM
------------
bdst_rpm doesn't seem to build the RPM properly with requirements.  As a
workaround, you can do this.

First, run: python setup.py bdist_rpm
Note that the package under dist/ *doesn't* work

Go to the SPEC file: build/bdist.linux-x86_64/rpm/SPECS/$projname.spec

Add the following lines:
--------------------------

Requires: python-setuptools
Requires: python-pip

%post
pip install pysphere
--------------------------

Then from build/bdist.linux-x86_64/rpm, run the following (be sure the _topdir
property is set, or rpmbuild won't know where to look):
rpmbuild -ba --define "_topdir /root/automation/$projname/build/bdist.linux-x86_64/rpm" SPECS/$projname.spec

The RPM should build, and you should be able to find it under:
/root/automation/$projname/build/bdist.linux-x86_64/rpm/RPMS/noarch


Quick Steps:
python setup.py bdist_rpm
vim build/bdist.linux-x86_64/rpm/SPECS/$projname.spec
>Requires: python-setuptools
>Requires: python-pip
>Requires: python-argparse
>%post
>pip install pysphere
cd build/bdist.linux-x86_64/rpm
rpmbuild -ba --define "_topdir /root/automation/$projname/build/bdist.linux-x86_64/rpm" SPECS/$projname.spec
EOF

    cat  > $projname/setup.py <<EOF
import re
from setuptools import setup

version = re.search(
   '^__version__\s*=\s*"(.*)"',
   open('$projname/__init__.py').read(),
   re.M
   ).group(1)

setup(
   name = "$projname",
   packages = ["$projname", "$projname/lib"],
   entry_points = {
      "console_scripts": ['$projname = $projname.main:main']
   },
   version = version,
   description = "<description>",
   author = "Kyle Flavin",
   author_email = "Kyle.Flavin@citrix.com",
   url = "http://www.citrix.com",
   long_description = "<description>",
   license = "GPL",
   requires = ['pysphere', 'argparse', 'setuptools'],
   install_requires = [
   'argparse',
   'setuptools',
   'pysphere',
   ],
)
EOF

    cat  > $projname/.gitignore <<EOF
bin
build
dist
docs
*.egg-info
*.pyc
*.swp
*.log
*.vim*
EOF

    deactivate;
    workon $1;
    git init;
    git add .;
    git commit -m "Initial commit for $projname.";
    git config --global user.name "Kyle Flavin";
    git config --global user.email Kyle.Flavin@citrix.com;
    echo "Project $projname created."
}
