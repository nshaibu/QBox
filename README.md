QBox Easy VM Manager
=========================================================================================================================

Installation
=========================
Go to the QBox Folder and type this command: sudo ./install.sh.
Uninstall QBox
=========================
type this command: sudo QBox unistall

Date:1/nov/16 Time:4:49PM
=========================
1. For tap interface networking module, user can only boot one vm at a time because it hungs up shell preventing
execution of further instructions. I think this is because super user privilege is require in creating tap interfaces
for the vm and thus the vm runs in root's user-space. Also most variables given to it ends up disappear after
vm has been closed and thus tap interfaces created have to be destroyed manually.

2. Event listener to make sure that vms that were kill or stop by the user manually are been notify to QBox so that respective
data in pid database is cleared completed.

TO DO
=====
3. To generalize directory system containing QBox code [**SOLVED @ 9:44pm @ 1/nov/16**]

Date:2/nov/16 Time:8:01PM
=========================
1. Installation menu completed.

TODO
====
1. Adding QBox server
