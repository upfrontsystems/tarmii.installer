How to build the TARMII windows installer
=========================================

Update the installer builder checkout
-------------------------------------

  run::

    bin\develop up

Copy the windows.cfg
--------------------
  
  from the tarmii installer folder

  to tarmii/windows.cfg

Rebuild tarmii
--------------

  run::

    bin\buildout.exe -Nvc windows.cfg

Get the latest blob and filestorage
-----------------------------------
  
  they are at: tarmii.upfronthosting.co.za

  put them in c:\tarmii\var

Start the instance
------------------

  by running::

    bin\run-instance.exe

Check where the images are stored
---------------------------------

  If they are still in the root, run the script::

    bin\instance run scripts\move_images.zctl tarmii

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

    yu0aid6V
 
Check the synchronisation settings
----------------------------------

  navigate to::

    http://localhost:8080/tarmii/@@remote-server-settings

  Synchronisation Server Url::

    http://tarmii.upfronthosting.co.za
 
  Synchronisation Server user name::

    teacherdata
 
  Synchronisation Server password::
 
    yu0aid6V

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

