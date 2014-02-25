CrashStats
==========

CrashStats is a simple way to export your data from Crashlytics. 

Crashlytics is a fantastic service that we've used for quite a while, and reached a point where we wanted to have raw access to our data. 

Specifically, I wanted to know which of our files had the most issues over time, and which methods within those files were the culprits. 


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

Output:
````
[
  {
    "id": "528a8572e2c70d3456654",
    "name": "Your App",
    "bundle_identifier": "com.app",
    "platform": "ios",
    "status": "activated",
    "latest_build": "2.2.19.RC4 (beta)",
    "icon_url": "https://s3.amazonaws.com/assets...",
    "icon_hash": "....",
    "icon32_url": "https://s3.amazonaws.com/assets...",
    "icon64_url": "https://s3.amazonaws.com/assets....",
    "icon128_url": "https://s3.amazonaws.com/assets....",
    "impacted_devices_count": 8,
    "unresolved_issues_count": 8,
    "organization_id": "5086fc1976fa53641b264562",
    "dashboard_url": "https://www.crashlytics.com/....",
    "settings_url": "https://www.crashlytics.com/....",
    "issues": [
      {
        "id": "52d6cc32e2c70d5d81366532",
        "display_id": 2,
        "impact_level": 1,
        "title": "UIKit",
        "subtitle": "__53-[UITableView _configureCellForDisplay:forIndexPath:]_block_invoke",
        "crashes_count": 11,
        "event_type": 1,
        "impacted_devices_count": 5,
        "average_free_space": null,
        "average_free_ram": null,
        "notes_count": 0,
        "resolved_at": null,
        "suggestion": null,
        "build": "2.2.19 (xcd)",
        "url": "https://www.crashlytics.com....",
        "share_url": "http://crashes.to/s/....",
        "shares_base_uri": "http://crashes.to",
        "latest_cls_id": "52de90e403620001038639234552",
        "file": "UIKit",
        "class": "__53UITableView",
        "method": "_configureCellForDisplay:forIndexPath:_block_invoke"
      }
    }
]
````

Backtraces
----------
By including the `-b` option, backtraces will be downloaded and stored on your file system using the following path format:

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