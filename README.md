# security-center-update-asset
Bash script that updates a Tenable Security Center asset list with AWS IP addresses via a REST API call.


**Author: mpb10**

**July 24th, 2018**

**v2.0.0**

#

 - [INSTALLATION](#installation)
 - [USAGE](#usage)
 - [CHANGE LOG](#change-log)
 - [ADDITIONAL NOTES](#additional-notes)
 
#

# INSTALLATION

**ATTENTION:** Never run unverified scripts or code in any production environment. Always be sure to thoroughly read through the contents of the files and understand them before using them in your environment.

To set up this script, copy this script onto the AWS instance that hosts your installation of Tenable Security Center. A good place to put the script would be a directory named 'scripts' in the root install directory of Security Center. Modify the script's permissions so that it is executable. Then, the script can be ran as a one-off using the script options, or the script's default variables can be modified so that a simple cron job can be set up.

An example cron entry would be:
	59 * * * * /opt/sc/scripts/update_asset.sh

Make sure that when you run the script you either provide the necessary options or modify the default variables in the script.

# USAGE

This script is primarily used to get a list of your running AWS instances' IP addresses and then upload that to an asset list in Tenable Security Center via a REST API call. This ensures that your scans have an up-to-date asset list of IP addresses to scan.

The script logs to the syslog using the 'logger' command to help in troubleshooting. The file that it will most likely log to is `/var/log/messages`. This can varry depending on which distribution of Linux you are using.

To maintain security, the REST API login token is created every time the script is ran and subsequently deleted before the script exits. Also, it is a good idea to utilize AWS KMS to encrypt your Security Center password in a file instead of having the password be passed to the script in plaintext every time it is ran. Details can be found [here](https://aws.amazon.com/blogs/security/how-to-help-protect-sensitive-data-with-aws-kms/) and [here](https://aws.amazon.com/blogs/security/how-to-encrypt-and-decrypt-your-data-with-the-aws-encryption-cli/).

**Using the Script Options:**
If the default variables in the script are not modified, then those variables must be provided to the script as options. The following are required options:

	-u (Security Center username)
	-p (Security Center password) OR -P (Credential file to have AWS KMS decrypt)
	-c (Cookie file for Security Center login)
	-i (Security Center asset ID) OR -I (Security Center asset name)
	-l (Security Center address)

Example: `/opt/sc/scripts/update_asset.sh -u svc_sc -p P@ssw0rd -c /opt/sc/scripts/sc_cookiefile -i 123 -l securitycenter.local`
Example: `/opt/sc/scripts/update_asset.sh -u svc_sc -P /opt/sc/scripts/sc_credfile -c /opt/sc/scripts/sc_cookiefile -I 'Running AWS Addresses' -l securitycenter.local`

The following option is not required:

	-k (Don't have curl verify the SSL certificates (NOT RECOMMENDED))

**Modifying the Script Variables:**
Instead of passing options to the script, default values can be saved in the script itself. This is useful when the script is to be used with cron, Chef, or some other form of automation. Simply set each variable to it's corresponding option's value. These are the variables' corresponding options:

	USERNAME (-u) (Ex: 'svc_sc')
	PASSWORD (-p) (Ex: 'P@ssw0rd')
	CREDFILE (-P) (Ex: '/opt/sc/scripts/sc_credfile')
	ASSETNUM (-i) (Ex: '123')
	ASSETNAME (-I) (Ex: 'Running AWS Addresses')
	COOKIEFILE (-c) (Ex: '/opt/sc/scripts/sc_cookiefile')
	SSLVERIFY (-k) (Ex: '-k')
	SECURITYCENTERURI (-l) (Ex: 'securitycenter.local')
	CERTPATH (none) (Ex: '--capath /etc/ssl/certs/')
	CERTFILE (none) (Ex: '--cacert /etc/ssl/certs/ca-bundle.crt')

# CHANGE LOG

	1.0.0	September 11th, 2018
		Uploaded script and Chef recipe to Github.
		Created readme.

# ADDITIONAL NOTES

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
		
