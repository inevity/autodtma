You can use the scripts through the following step by step procedure:

In the local client machine:

1) Create a folder and name it "RUNs" in the directory that contains the scripts.
2) Open "Core.sh" and read the specification of input parameters form the header comments
3) Setup the constant parameters at the first block of the script. The "username" is for the server and all the clients. Please note that if your username is not consistent in all the machines you need to either make it consistent or change the scripts.
4) Fill the request rate file with the request rates you want to test. The first column is 1/rate and the next column is the set length (connections/rate)
5) Save the IP addresses of other clients in a test file each in a single line. An example is clients.txt

In the Server machine:

1) Create a folder in the home folder and name it "WebserverSetting", this folder include all versions of Webserver Configuration files
2) Create a folder in the home folder and name it "ProfileLog" to save profiling logs
3) Create a folder in the home folder and name it "UtilLog" to save the collectl data.
4) Copy the rsh "Affinity.sh" and "SetInterruptsAffinity.sh" scripts to the home folder

In the other Clients:

1) Create a folder and name it "RUNs" in the home folder of all the clients
2) Install httperf in all clients from the source codes provided with the scripts
3) Copy the "httperf.sh", and "Saveoutput"(a perl script) file to the home folder of all clients



Please remember to change the access level of all scripts to executable

After following the above steps you can run the Core.sh script to run an experiment.

root$./Core.sh  Testname  ./cores.txt ./rates.txt 2 ./clients.txt 8 2 192.168.0.100 80,80  1K.html 200000  0  1 1 1
