WinKeys
=======

Use the extra keys on a Windows Keyboard.


Introduction
------------

Windows Keys is a utility to make it easier to use the MS Windows specific keys under RISC OS 4. Although the new OS recognises the keys, there is no easy way to use them. Some applications, such as Zap, will support them but in general there is no easy way to get them to do anything.

Windows Keys allows star commands to be attached to the Windows and Menu keys, for all of the Shift and Ctrl combinations. These cam be used to launch applications, open directories or almost anything else.



Building
--------

WinKeys consists of a collection of ARM assembler and un-tokenised BASIC, which must be assembled using the [SFTools build environment](https://github.com/steve-fryatt). It will be necessary to have suitable Linux system with a working installation of the [GCCSDK](http://www.riscos.info/index.php/GCCSDK) to be able to make use of this.

With a suitable build environment set up, making WinKeys is a matter of running

	make

from the root folder of the project. This will build everything from source, and assemble a working WinKeys module and its associated files within the build folder. If you have access to this folder from RISC OS (either via HostFS, LanManFS, NFS, Sunfish or similar), it will be possible to run it directly once built.

To clean out all of the build files, use

	make clean

To make a release version and package it into Zip files for distribution, use

	make release

This will clean the project and re-build it all, then create a distribution archive (no source), source archive and RiscPkg package in the folder within which the project folder is located. By default the output of `git describe` is used to version the build, but a specific version can be applied by setting the `VERSION` variable -- for example

	make release VERSION=1.23


Licence
-------

WinKeys is licensed under the EUPL, Version 1.2 only (the "Licence"); you may not use this work except in compliance with the Licence.

You may obtain a copy of the Licence at <http://joinup.ec.europa.eu/software/page/eupl>.

Unless required by applicable law or agreed to in writing, software distributed under the Licence is distributed on an "**as is**"; basis, **without warranties or conditions of any kind**, either express or implied.

See the Licence for the specific language governing permissions and limitations under the Licence.