How to build the TARMII windows installer
=========================================

Update the buildout checkout
----------------------------

  run::

    bin\develop up

Rebuild tarmii
--------------

  run::

    bin\buildout.exe -c windows.cfg

Get the latest blob and filestorage
-----------------------------------
  
  they are at: tarmii.upfronthosting.co.za

  put them in c:\tarmii\var

Start the instance
------------------

  by running::

    bin\run-instance.exe

Add a VHM entry
---------------
  
  at::

    http://localhost:8080/virtual_hosting/manage_main

  details::

    localhost:8080 /tarmii

Browse to
---------

  In a web browser navigate to http://localhost:8080/tarmii

Check the teacher data upload settings
--------------------------------------

  navigate to::

    http://localhost:8080/tarmii/@@remote-server-settings

  Remote Server Url::

    http://tarmii.upfronthosting.co.za/@@teacher-data

  Data upload user name::

    teacherdata

  Upload password::

    12345
 
Check the synchronisation settings
----------------------------------

  navigate to::

    http://localhost:8080/tarmii/@@remote-server-settings

  Synchronisation Server Url::

    http://tarmii.upfronthosting.co.za
 
  Synchronisation Server user name::

    teacherdata
 
  Synchronisation Server password::
 
    12345

Move data and blobs away
------------------------
  
  The data and blobs are packaged as tar gzip separate from the
  application code.  This makes distribution easier.

  Shutdown the running instance.

  Move the filestorage and blobstorage folders out of the instance.

  Make sure that there is a var folder.

  Make sure that there is a var/log folder.

Package the new installer
-------------------------

  Run the compiler::

    compile_installer.bat

