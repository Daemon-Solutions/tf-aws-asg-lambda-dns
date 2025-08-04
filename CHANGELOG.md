## [4.0.10](https://github.com/Daemon-Solutions/tf-aws-asg-lambda-dns/compare/v4.0.9...v4.0.10) (2025-08-04)

### Bug Fixes

* **sd-4482:** install boto3 before running publish.py ([8ff7423](https://github.com/Daemon-Solutions/tf-aws-asg-lambda-dns/commit/8ff742318b62e33ab0578464a8e61299fbd36de0))

## 1.4.1 (November 10, 2017)

BUG FIXES:
* Reduced the boilerplate prefix as it cannot be longer than 32 characters

## 1.4.0 (November 9, 2017)

BUG FIXES:
* Changed IAM role name to be a prefix so multiple versions of the same service can run in the same region

## 1.3.0 (September 12, 2017)

IMPROVEMENTS:
* Streamlined DNS management code
* Simplified record template management


## 1.2.0 (September 06, 2017)

IMPROVEMENTS:
* Allow the specification of multiple ASGs


## 1.1.1 (June 23, 2017)

IMPROVEMENTS:
* Added region-only template

BUG FIXES:
* Removed unused variables


## 1.1.0 (June 15, 2017)

IMPROVEMENTS:
* Add region-only option to DNS name format

BUG FIXES:
* Stopped "filename changed" issue from occurring - https://github.com/hashicorp/terraform/issues/7613


## 1.0.1 (June 05, 2017)

IMPROVEMENTS:
* Converted python template to use Lambda environment variables instead of supplied runtime variables

* No longer using S3 bucket to store intermediate Lambda package

* Applied best practice guidelines from PEP8 to python scripting


## 1.0.0 (June 01, 2017)

IMPROVEMENTS:
* Major code refactor


## 0.2.1 (May 31, 2017)

BUG FIXES:
* Fixed problem with changes to resource records occuring event firing when no changes are to be made

* ASG TERMINATE event may come after LAUNCH, fixed a problem where the current DNS record was being deleted when this pattern of events occur


## 0.2.0 (May 02, 2017)

IMPROVEMENTS:
* New DNS record template for private Autoscale Group record added


## 0.1.1 (April 26, 2017)

BUG FIXES:
* Fixed a problem with IAM resource names, can now use multiple declarations of the module


## 0.1.0 (April 26, 2017)

Initial version
