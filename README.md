CrashStats
==========

CrashStats is a simple way to export your data from Crashlytics. 

Crashlytics is a fantastic service that we've used for quite a while, and reached a point where we wanted to have raw access to our data. 

Specifically, I wanted to know which of our files had the most issues over time, and which methods within those files were the culprits. 

Authentication
--------------
CrashStats uses [Mechanize](https://github.com/sparklemotion/mechanize) to login to Crashlytics and store the session data for subsequent requests. Optionally pass your email `-e` and password `-p` each time, or store your credentials in your environment:
````
export CRASHLYTICS_EMAIL=<email>
export CRASHLYTICS_PASSWORD=<password>
````


Stats
-----
Running the `stats` command will import all `unresolved` issues and aggregate them per file, sorting by highest issue count. 

````
./crashstats.rb -e <email> -p <password> stats
````

Output:
````
{
    "name": "com.app",
    "files": [
     [
        "FloorMapIndex+Actions.m",
        {
          "count": 18,
          "methods": {
            "seatVisit:atTables:": 10,
            "requireSchedule": 4,
            "finishVisit:": 2,
            "finishVisit:_block_invoke": 1,
            "removeVisit:_block_invoke": 1
          }
        }
      ]
}
````

Issues
------
Importing the raw JSON of all issues is also possible via the `issues` command:
````
./crashstats.rb -e <email> -p <password> issues
````

Backtraces
----------
By including the `-b` option, backtraces will be downloaded and stored on your file system using the following format:

````
backtraces/<bundle_identifier>/<issue_id>.txt
````

Output
------
By default, all output will print to your console. However, the `-o <filename>` option will store the output on your file system and optionally make it pretty with `-P`. 

````
./crashstats.rb -e <email> -p <password> -P -o issues.json issues
````


Options
------
````
Usage: crashstats.rb [options] COMMAND (issues|stats)
    -i, --issue-status [STATUS]      Issue status - unresolved (default), resolved, or all
    -e, --email [EMAIL]              Email used for login, or ENV['CRASHLYTICS_EMAIL']
        --password [PASSWORD]        Password used for login, or ENV['CRASHLYTICS_PASSWORD']
    -v, --verbose                    Output debug information
    -o, --output [FILE]              File path to write output
    -p, --pretty                     Pretty print JSON ouput
    -b, --backtraces                 Include backtraces with issues
````
